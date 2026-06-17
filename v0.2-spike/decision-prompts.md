---
name: laifaxin-outreach-v0.2 · decision-prompts
type: meta
status: active
version: 0.2.0-alpha.1
created: 2026-06-17
updated: 2026-06-17
tags: [v0.2, decision-prompts, llm-nodes, browser-agent, output-contract]
description: v0.2 alpha 浏览器 agent 3 个 LLM 决策节点 · 输出 contract(合法 exemplar + schema 验证 + repair retry + fail-closed)+ 可验证决策条件(不靠 self-reported confidence)+ 统一 audit + failure_diagnostics · r1 deep-review 全面重写
---

# Decision Prompts · v0.2 alpha(r1/r2/r3/r4 累积)

> **Loader contract**(r4 必修):本文 markdown 含 5 类内容,**loader 都要解析**:
> 1. ` ```yaml ` blocks → schema / disposition contracts
> 2. ` ```python ` blocks → decision policy(`decide()` 函数体)
> 3. 普通 prose code fence(无语言标识)→ LLM prompts(节点 1/2/3 的 prompt 文本)
> 4. ` ```yaml audit_entry ` block → audit schema
> 5. inline 字段引用(如 `prev_page_accuracy`) → input/output 字段名
>
> 故 `DecisionCaller.from_md_yaml_blocks()` 名字不准确 · **实际是 `from_md_sections()`** · 按段标题(§ 1.x / § 2.x / § 3.x)分发到对应节点。

> **r1 deep-review 反馈**:原版 🔴 大改 · 12 条硬伤
> 1) 伪 YAML 占位符 · LLM 抄不准 · 2) `confidence` 不是已测概率,降级为 audit 字段 · 3) 节点 2 阈值 0.7 与权威 docs ≥80% 冲突 · 4) 单页判 boundary 不稳 · 5) 节点 3 漏真询盘风险 · 6) audit 不闭环
>
> **重写策略**:每节点改"合法 exemplar + schema validation + repair retry + fail-closed"· 决策条件改可验证(双页 / argmax gap / evidence 命中)· 统一 audit + 加 failure_diagnostics

## § 0 · 通用执行流(所有节点遵守)

```
1. 准备 inputs(structured · 不混 natural language 自由文本)
2. send prompt to Codex `gpt-5.4`
3. parse YAML
   - 失败 → repair retry (1 次 · 提示 "return ONLY raw YAML · NO code fences · NO comments")
4. schema validate(JSON Schema-like · uniqueness/range/consistency)
   - 失败 → repair retry (1 次)
5. 仍失败 → fail-closed:
   - audit.failure_diagnostics 记 error_type
   - pause + 人工接管(不静默推进)
6. 通过 validate → decision policy 判决(用可验证条件 · 不用 self-reported confidence)
7. 写 audit(raw + normalized + validation + retry + final_disposition + human_override)
```

## § 1 · LLM 节点 1 · 选客群(`choose_audience`)

### 1.1 Inputs(structured)

```yaml
inputs:
  product_positioning: "用户输入的产品定位 1-2 段"
  candidates:
    - audience_index: 1
      audience_slug: "north-america-asian-food-distributor"   # r2 #1 必修 · 给比对用
      name: "北美亚洲食品分销商"
      recommend_reason: "..."
      coverage_estimate: 5000
      laifaxin_score: 0.82
    - { audience_index: 2, audience_slug: "...", name: "...", ... }
    - { audience_index: 3, ... }
    - { audience_index: 4, ... }
  historical_dead_audiences:
    - audience_slug: "north-america-led-distributor"          # 唯一标识
      dead_reason: "已死客群无回复"
```

### 1.2 Prompt(中文 · 紧)· 全节点共通 strict rules

> **全节点 strict output rules**(节点 1/2/3 都遵守):
> - Return raw YAML.
> - NO code fences (no ```).
> - NO comments anywhere (no `#`).
> - NO placeholder syntax like `<...>`.
> - Output exactly ONE YAML document matching the schema.
> - Match schema EXACTLY (no extra keys, no missing required keys).

```
You are a foreign-trade prospecting strategist for laifa.xin.

TASK: 从 4 个客群候选中选 1 个最对路的客群,**写邮件开发它**。

判定原则(按顺序):
1. 客户产品词对路(他们卖什么)· 不是你产品词(避免找同行)
2. 避开 historical_dead_audiences
3. 规模 = 几百到几千家公司最适合 supervised spike
4. 推演 laifaxin_score 仅作参考 · 不作硬标准

OUTPUT RULES(STRICT):
- Return raw YAML.
- NO code fences (no ```).
- NO Chinese comments / no explanation paragraphs.
- NO placeholder syntax like <...>.
- Output exactly one YAML document matching the example below.

EXAMPLE (this is a LEGAL output — copy structure exactly):
chosen: 2
evidence_snippets:
  - "candidate 2 name = 北美亚洲食品分销商"
  - "candidate 2 recommend_reason = 主营亚洲食品 SKU 与产品定位'手工面'对路"
applied_rules:
  - rule_1_customer_product_match
  - rule_3_size_suitable
why_not_top_alt:
  audience_index: 1
  reason: "candidate 1 规模偏大 · 1.5 万家 · 不适合 spike"
warnings: []
```

### 1.3 Output Schema(JSON Schema-like)

```yaml
schema:
  type: object
  required: [chosen, evidence_snippets, applied_rules, why_not_top_alt, warnings]
  properties:
    chosen:
      oneOf:
        - type: integer
          enum: [1, 2, 3, 4]
        - type: "null"        # "全部不对路 → 触发关键词重搜"路径
    evidence_snippets:
      type: array
      items: { type: string, minLength: 10, maxLength: 200 }
      minItems: 1
      maxItems: 5
    applied_rules:
      type: array
      items: { type: string }
      uniqueItems: true
      minItems: 1
    why_not_top_alt:
      type: object
      required: [audience_index, reason]
      properties:
        audience_index: { type: integer, enum: [1, 2, 3, 4, 0] }  # 0 = 不适用(chosen=null)
        reason: { type: string }
    warnings:
      type: array
      items: { type: string }
```

### 1.4 Decision Policy(可验证 · 不用 self-confidence)

```python
def decide(parsed, inputs):
    # 条件 A:chosen 是有效候选
    if parsed.chosen not in [1, 2, 3, 4, None]:
        return Failure(reason="invalid chosen")

    # 条件 B:applied_rules 至少 1 条 + evidence_snippets 至少 1 条 + r4 #4 hit validation
    if not parsed.applied_rules or not parsed.evidence_snippets:
        return Failure(reason="missing evidence/rules")
    # r4 #4 · evidence 必须命中 inputs(防 LLM 编造)
    candidates_text = " ".join(c.name + " " + c.recommend_reason for c in inputs.candidates)
    if not any(snippet_keyword_in_text(snip, candidates_text) for snip in parsed.evidence_snippets):
        return Failure(reason="evidence_snippets_no_input_hit")

    # 条件 C:why_not_top_alt 一致性(chosen=null 必须 audience_index=0)
    if parsed.chosen is None and parsed.why_not_top_alt.audience_index != 0:
        return Failure(reason="inconsistent why_not_top_alt")

    # 条件 D:chosen 对应的 audience_slug 在 historical_dead 中 → 拒绝(r2 #1 必修)
    if parsed.chosen is not None:
        chosen_candidate = next((c for c in inputs.candidates if c.audience_index == parsed.chosen), None)
        if chosen_candidate is None:
            return Failure(reason="chosen index not in candidates")
        dead_slugs = {h.audience_slug for h in inputs.historical_dead_audiences}
        if chosen_candidate.audience_slug in dead_slugs:
            return Failure(reason="chosen audience_slug overlaps dead audiences")

    return Success(audience_id=parsed.chosen)
```

**Confirm 闸 1**:无论 LLM 输出多"自信" · 都必须用户拍板才进入下一步(spec § 5.1)。

## § 2 · LLM 节点 2 · 每页判精度(`per_page_accuracy`)· 双页连续确认

> **r1 deep-review #D3.1-3.2 必修**:不用单页判 boundary(误判一页就砍批量)· 改"双页连续跌破"· 阈值与权威 docs `≥80%` 对齐(参 [docs/zhinan/02-filter-customers](https://www.laifa.xin/zhinan/02-filter-customers))。

### 2.1 Inputs

```yaml
inputs:
  page_number: 61
  rows:
    - { index: 0, company_name: "...", country: "...", description: "..." }
    - { index: 1, ... }
    # ... 10 行
  product_positioning: "..."
  audience_context: { audience_id: 2, name: "..." }
  cumulative_pages_read: 61
  prev_page_accuracy: 0.85   # 上一页 (page=60) 的 accuracy · None if page=1
```

### 2.2 Disposition payload schema(r4 必修 · Continue/Hopeless/BoundaryReached 都填一致 accuracy)

```yaml
final_disposition:
  Continue:
    type: "Continue"
    payload:
      accuracy: 0.85          # 当前页 accuracy · 必填
      note: "accurate"        # accurate / middle_zone_unstable / suspect_boundary_need_confirm
  BoundaryReached:
    type: "BoundaryReached"
    payload:
      accuracy: 0.50          # 触发边界的当前页 accuracy · 必填
      at_page: 60             # 最后准页(= page - 2)
      save_companies: 600     # at_page × 10
  Hopeless:
    type: "Hopeless"
    payload:
      accuracy: 0.30          # 当前页 accuracy · 必填
      cumulative_avg: 0.28
      reason: "cumulative_avg_low_in_first_5_pages"
  Failure:
    type: "Failure"
    payload: null             # ⚠️ 可能没 payload · runner 必须先判 type
    failure_diagnostics: {...}
```

### 2.3 Prompt

```
You are an evaluator for outbound prospecting per-page accuracy.

TASK:看本页 10 个公司 · 数有几个真的对路(客户 = 会买你产品的)。

JUDGMENT(每行):
1. 业务描述明确卖 / 经营你的产品类(或上下游)→ 对路
2. 描述含糊 / 主营无关 → 不对路
3. 是同行(也做工厂 / 制造商)→ 不对路
4. 公司名 / 国家不影响判定 · 只看业务描述本质

OUTPUT RULES(STRICT):
- Return raw YAML.
- NO code fences.
- NO explanation paragraphs.
- NO placeholder syntax.

EXAMPLE:
total_rows: 10
on_target_count: 5
on_target_indices: [0, 2, 5, 7, 8]
not_on_target_indices: [1, 3, 4, 6, 9]
flagged_indices: [3, 6]
accuracy: 0.50
evidence_snippets:
  - "row 0 description 亚洲食品零售 5000+ SKU 对路"
  - "row 3 description 面条工厂江苏南京 同行 flagged"
```

### 2.3 Output Schema

```yaml
schema:
  type: object
  required: [total_rows, on_target_count, on_target_indices, not_on_target_indices, flagged_indices, accuracy, evidence_snippets]
  properties:
    total_rows: { type: integer, enum: [10] }   # 来发信每页恒 10 行
    on_target_count: { type: integer, minimum: 0, maximum: 10 }
    on_target_indices:
      type: array
      items: { type: integer, minimum: 0, maximum: 9 }
      uniqueItems: true
    not_on_target_indices:
      type: array
      items: { type: integer, minimum: 0, maximum: 9 }
      uniqueItems: true
    flagged_indices:
      type: array
      items: { type: integer, minimum: 0, maximum: 9 }
      uniqueItems: true
      # 必须是 not_on_target_indices 的子集(r2 #D2.2 修)
    accuracy: { type: number, minimum: 0, maximum: 1 }
    evidence_snippets:
      type: array
      items: { type: string }
      minItems: 1

cross_field_validation:
  - len(on_target_indices) == on_target_count
  - len(on_target_indices) + len(not_on_target_indices) == total_rows
  - intersection(on_target_indices, not_on_target_indices) == []
  - accuracy == on_target_count / total_rows
  - set(flagged_indices).issubset(set(not_on_target_indices))   # r2 #D2.2 子集约束
```

### 2.4 Decision Policy · 双页连续跌破 + 80% 对齐(r1 + r2 必修)

```python
def decide_per_page(parsed, inputs, page_history):
    """
    page_history: list of {page: int, accuracy: float}  # 截至当前的所有页历史
    r2 #2-3 必修:boundary 计算 + hopeless 分支可达
    """
    current = parsed.accuracy
    page = inputs.page_number
    prev = inputs.prev_page_accuracy   # = page_history[-2].accuracy if exist else None

    ACCURATE_HIGH = 0.80
    BOUNDARY_LOW = 0.60

    # ---- DecisionCaller 内部前置:append 当前页到 page_history(r3 #1 必修)
    # page_history 在 call 时由 DecisionCaller 注入"含当前页" · runner stub 传入的是上一轮结束时的
    # 所以下面 page_history 已含本页 · len ≥ 1(防 div0)

    # ---- Hopeless 优先判 · 防 r2 #3 不可达 ----
    # 前 5 页累积平均 < BOUNDARY_LOW · 触发 hopeless(早期就垃圾)
    if len(page_history) > 0 and len(page_history) <= 5:
        cumulative_avg = sum(p.accuracy for p in page_history) / len(page_history)
        if cumulative_avg < BOUNDARY_LOW:
            return Hopeless(reason="cumulative_avg_low_in_first_5_pages",
                            avg=cumulative_avg)

    # ---- Continue 准 ----
    if current >= ACCURATE_HIGH:
        return Continue(direction="next_page", note="accurate")

    # ---- Boundary 双页确认 · 计算正确(r2 #2 必修)----
    # 双页连续 < BOUNDARY_LOW · "boundary 在第一个低页之前"
    # page-1 = 第一个低页 / page = 第二个低页(当前)
    # 所以 boundary = page - 2(最后一个准页) · 保存范围 = page_history[boundary] 累积
    if current < BOUNDARY_LOW and (prev is not None and prev < BOUNDARY_LOW):
        boundary_page = page - 2   # 最后一个"准"页 · 双页连续低之前一页
        return BoundaryReached(
            at_page=boundary_page,
            save_companies=boundary_page * 10,
            note="two_consecutive_low_pages_confirm"
        )

    # ---- Suspect boundary · 单页低 · 翻下一页确认 ----
    if current < BOUNDARY_LOW:   # prev is None or prev >= BOUNDARY_LOW(已隐含)
        return Continue(direction="next_page", note="suspect_boundary_need_confirm")

    # ---- 中间区 · 翻下一页(不停)----
    if BOUNDARY_LOW <= current < ACCURATE_HIGH:
        return Continue(direction="next_page", note="middle_zone_unstable")

    return Failure(reason="unreachable_policy_branch_should_never_hit")
```

**关键差异 vs 原版**:
- 单页跌破 0.7 不再立判 boundary · 必须**双页连续 < 0.6** 才确认
- 中间区(0.6-0.8)继续翻 · 不停
- `accuracy` 是 schema 验证过的整数比 · 不是模型 self-reported confidence

## § 3 · LLM 节点 3 · 询盘识别(`inquiry_recognition`)· Recall-safe

> **r1 deep-review #D3.3 必修**:原版 0.85 高阈值 + 低 confidence → neutral 静默沉 = **倾向漏真询盘**。改为非对称:`非 inquiry` 维持高阈值 / `inquiry` 候选领先就强制人工升级。

### 3.1 Inputs

```yaml
inputs:
  customer_email_body: "客户回信全文 · 英文"   # 原文存 repo 外 · 见 audit
  customer_company: "..."
  customer_country: "..."
  sequence_round: 2
  historical_replies:
    - { round: 1, summary: "...", tag_applied: "ooo" }
```

### 3.2 Prompt

```
You are a foreign-trade reply-classification assistant for laifa.xin.

TASK:看客户这封回信 · 判定该打哪个标签:
- inquiry: 明确问价 / 索样 / 约通话 / 想了解产品
- ooo: 节假日 / 出差 / 假期自动回复
- referral: "我不负责 · 联系 X"
- rejection: 明确"不需要 / 已有供应商"
- neutral: 语气模糊 / 信息不足

OUTPUT RULES(STRICT):
- Return raw YAML.
- NO code fences.
- NO explanation paragraphs.
- candidate_tags 必须恰好 5 个 key · 值在 [0,1] · sum 可不为 1。

EXAMPLE:
tag: inquiry
evidence_keywords: [pricing, MOQ, samples]
evidence_quotes:
  - "Could you send pricing for 100 units?"
  - "What's the MOQ?"
candidate_tags:
  inquiry: 0.85
  ooo: 0.02
  referral: 0.04
  rejection: 0.05
  neutral: 0.04
sequence_round_aware: true
```

### 3.3 Output Schema

```yaml
schema:
  required: [tag, evidence_keywords, evidence_quotes, candidate_tags, sequence_round_aware]
  properties:
    tag:
      type: string
      enum: [inquiry, ooo, referral, rejection, neutral]
    evidence_keywords:
      type: array
      items: { type: string }
      minItems: 1
    evidence_quotes:
      type: array
      items: { type: string }
      minItems: 1
    candidate_tags:
      type: object
      required: [inquiry, ooo, referral, rejection, neutral]
      additionalProperties: false   # r2 #D2.3 硬约束 · 严禁第 6 个 key
      properties:
        inquiry: { type: number, minimum: 0, maximum: 1 }
        ooo: { type: number, minimum: 0, maximum: 1 }
        referral: { type: number, minimum: 0, maximum: 1 }
        rejection: { type: number, minimum: 0, maximum: 1 }
        neutral: { type: number, minimum: 0, maximum: 1 }
    sequence_round_aware: { type: boolean }

cross_field_validation:
  - argmax(candidate_tags) == tag   # 标签一致性
```

### 3.4 Decision Policy · 非对称 Recall-safe

```python
def decide_inquiry(parsed, inputs):
    # validate 已通过(上方 schema + cross_field)
    INQUIRY_AUTO_THRESHOLD = 0.85   # auto-apply inquiry 标签
    INQUIRY_FLAG_THRESHOLD = 0.55   # 召人工 · 不静默沉
    NON_INQUIRY_AUTO_THRESHOLD = 0.85   # 其他标签 auto

    p = parsed.candidate_tags

    # 条件 1:inquiry 候选超 0.85 → auto-apply
    if p.inquiry >= INQUIRY_AUTO_THRESHOLD and parsed.tag == "inquiry":
        return AutoApply(tag="inquiry")

    # 条件 2:inquiry 候选 0.55-0.85 之间 OR argmax 但低于 0.85 → 强制人工升级
    # ⚠️ 不静默沉到 neutral · 必须召人工
    if p.inquiry >= INQUIRY_FLAG_THRESHOLD:
        return EscalateToHuman(
            reason="inquiry candidate elevated",
            pre_filled_tag="inquiry"   # 提示人工"AI 倾向 inquiry"
        )

    # 条件 3:非 inquiry 标签超 0.85 → auto-apply
    if parsed.tag != "inquiry" and max(p[t] for t in ["ooo", "referral", "rejection", "neutral"]) >= NON_INQUIRY_AUTO_THRESHOLD:
        return AutoApply(tag=parsed.tag)

    # 条件 4(r2 #4 修紧):argmax gap > 0.4 仅在 top ≥ NON_INQUIRY_AUTO_THRESHOLD 时才 auto
    # 之前的"gap > 0.4 即 auto"过松 · 绕开 0.85 阈值 · 现在要求双重门
    sorted_p = sorted(p.values(), reverse=True)
    if sorted_p[0] - sorted_p[1] > 0.4 and sorted_p[0] >= NON_INQUIRY_AUTO_THRESHOLD and parsed.tag != "inquiry":
        return AutoApply(tag=parsed.tag, reason="high_gap_and_high_top")

    # 兜底:不静默 · 召人工
    return EscalateToHuman(
        reason="low confidence / ambiguous",
        pre_filled_tag=parsed.tag
    )
```

**关键差异 vs 原版**:
- inquiry 倾向(0.55+)即使没到 0.85 也**召人工**,不是默默标 neutral
- 用 `argmax gap` 验证 · 不用 self-reported confidence
- "不漏真询盘"通过非对称阈值 + 强制 escalate 实现

## § 4 · 统一 audit schema(三节点共用)

```yaml
audit_entry:
  node: choose_audience | per_page_accuracy | inquiry_recognition
  run_id: 2026-06-17T10:00:00-001
  step_index: 12
  timestamp: 2026-06-17T10:08:35+08:00

  # inputs 快照(脱敏 OK · 但失败诊断需要)
  raw_input_snapshot_ref: ~/.codex/runs/<run_id>/inputs/step-12.json   # repo 外
  inputs_hash: sha256(serialized inputs)

  # 模型原始输出(无论成功失败都存)
  llm_raw_output: "<raw text from gpt-5.4>"
  llm_raw_output_ref: ~/.codex/runs/<run_id>/llm/step-12-raw.txt        # 大时外置 · repo 外

  # 解析 + 验证 + 修复
  llm_normalized:                                # null if parsing failed
    chosen: 2
    evidence_snippets: ["..."]
    # ... 跟具体 schema 一致
  validation_errors: []                          # list of {field, error_code, msg}
  retry_count: 0                                 # 0 / 1

  # 最终判决
  final_disposition:
    type: AutoApply | EscalateToHuman | Continue | BoundaryReached | Hopeless | Failure
    reason: "..."
    payload:
      tag: inquiry                               # 或 audience_id / boundary_page 等

  # 人工接管(如有)
  human_override:
    reviewed_at: 2026-06-17T10:09:00+08:00
    user_response: approved | modified | rejected
    user_decided_tag: inquiry                    # 如有
    user_note: "AI 标签正确"

  # 失败诊断(失败 run 必填)
  failure_diagnostics:                           # null if successful
    error_type: yaml_parse_fail | schema_fail | cross_field_inconsistent | repair_max_retry | timeout | other
    invalid_fragment: "candidates: <missing field>"
    repair_attempts: 1
    taken_over_by_human: true
    final_action: pause_and_alert
```

### 4.1 节点 3 customer_email_body 处理(r1 #D4.2)

> Tony § 0 #10 不考虑合规 · 但工程理由(体积 / repo 整洁)仍存

```yaml
节点 3 audit:
  customer_email_body: ~/.codex/runs/<run_id>/llm/step-12-email.txt   # 原文外置 · repo 外
  customer_email_hash: sha256(原文)                                    # 入 repo 做指纹
  customer_email_summary: "100 字精简摘要"                            # 入 repo 做证据
```

**hash 不替代证据** · 只做指纹去重。复盘时:hash 指针 → 找本地 txt 原文 → 看 LLM 推理。

## § 5 · Repair Retry Policy(全节点共用)

```python
def call_with_repair(node_name, inputs, max_retries=1):
    raw = await codex_llm_call(node_name, inputs)
    parsed, errors = parse_and_validate(raw, schema)
    if not errors:
        return parsed, raw, retry_count=0

    # repair retry
    repair_prompt = f"""
    Previous output failed validation:
    {format_errors(errors)}

    OUTPUT RULES(STRICT · REPEAT):
    - Return raw YAML.
    - NO code fences.
    - NO explanation paragraphs.
    - Match schema EXACTLY.

    Return ONLY the corrected YAML now:
    """
    raw2 = await codex_llm_call_with_history([raw, repair_prompt])
    parsed2, errors2 = parse_and_validate(raw2, schema)
    if not errors2:
        return parsed2, raw2, retry_count=1

    # fail-closed
    raise FailClosed(node=node_name, errors=errors2, retry_count=1)
```

**Fail-closed 行为**:
- 不静默推进
- audit 完整记 failure_diagnostics
- 整个 run pause · 召用户(SkyComputerUseClient.app 通知)

## § 6 · 全局约束

### 6.1 LLM 提供商锁定

- alpha 期内主用 Codex CLI 内部 LLM(`gpt-5.4 via aihubmix` · 见 `~/.codex/config.toml`)
- 不切换 · 减少变量

### 6.2 confidence 字段语义(Important · r1 #D3.4)

- `confidence`(若 LLM 主动给)只入 audit · **不参与决策门**
- 决策门用可验证条件:**双页连续(节点 2)**, **argmax gap(节点 3)**, **schema/cross-field validation(节点 1/2/3)**, **evidence_snippets 命中(节点 1)**

### 6.3 audit 落点

每节点 audit 落 `~/.codex/runs/<run_id>/llm_logs.jsonl` 一行 · 字段对齐 § 4 audit_entry。

- 体积:100KB/run × 3/day × 30d ≈ 9 MB · 不算大
- 控制重点是 screenshots / 大附件 · 不是 llm_logs.jsonl

### 6.4 Retention/Rotation

```yaml
~/.codex/runs/<run_id>/:
  - 保留 30 天(cron 自动清理)
  - 大于 100 MB 的 run · 截图压缩 + 长期归档(如有 W3 需求)
  - llm_logs.jsonl 单文件 · 不分片(单 run 小)
```

## § 7 · 关联

- 主 SKILL.md(本目录)
- safety-gates.md(本目录)
- runners/README.md(本目录 · prospect.py 调本 contract)
- spec § 5.2 / § 6.2(本仓 specs/done/)
- r1 deep-review:`raw/inbox/2026-06-17-codex-deep-审-decision-prompts.md`
