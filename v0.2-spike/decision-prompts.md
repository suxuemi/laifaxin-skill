---
name: laifaxin-outreach-v0.2 · decision-prompts
type: meta
status: active
version: 0.2.0-alpha.0
created: 2026-06-17
updated: 2026-06-17
tags: [v0.2, decision-prompts, llm-nodes, browser-agent]
description: v0.2 alpha 浏览器 agent 决策节点完整 prompt 框架 · 3 个 LLM 节点(选客群 / 每页判精度 / 询盘识别)的输入 / 输出 / forbidden / confidence threshold / audit log · 落地 spec § 5.2
---

# Decision Prompts · v0.2 alpha

> 本文是 spec § 5.2 三个 LLM 节点的可执行 prompt 框架。
> 主路径 Tony § 0 #8:**不用 AI 评分** · 完全靠翻页 + LLM 节点 2 判精度。

## LLM 节点 1 · 选客群(deferential + Confirm 闸 1)

### 输入

```yaml
inputs:
  product_positioning: <用户输入的产品定位 1-2 段>
  candidates:                                       # 来发信 AI 推演返回的 4 客群
    - audience_index: 1
      name: <客群中文名>
      recommend_reason: <推演给的理由>
      coverage_estimate: <推演估的客群规模>
    - audience_index: 2
      ...
  historical_dead_audiences:                        # grep raw/prospecting/<product>/audiences/*.md status=dead
    - audience_slug: <已知不对路的客群>
      dead_reason: <死亡原因>
```

### Prompt

```
你是来发信外贸开发军师。

任务:从 4 个客群候选中选 1 个最对路的客群,**写邮件开发它**。

判定原则:
1. 必须是**客户产品词**对路(他们卖什么) · 不是你产品词(避免找同行)
2. 避开历史 dead 客群(下方 historical_dead_audiences 列表)
3. 优先选**采购方向**清晰 + **规模适中**(几百到几千家公司)的客群
4. 推演 confidence < 0.7 时 · 输出 reject_all(让用户重搜)

输出 strictly yaml:
chosen: <audience_index 1-4 或 null>
reasoning: <50-100 字 · 为什么这个对路 · 为什么没选其他>
confidence: <0-1 浮点>
warnings: [<list of strings · 如有可疑 · 比如规模太大或对路度低>]
```

### 输出约束

```yaml
allowed_outputs:
  - chosen: 1-4   # 选 1 个 audience_index
  - chosen: null  # 全部不对路 · 触发关键词重搜
forbidden_outputs:
  - chosen: [1,2]    # 不可多选
  - chosen: 5        # 超范围
  - 无 reasoning
  - 无 confidence

confidence_threshold: 0.7
on_low_confidence: pause + Confirm 闸 1(让用户拍板)
```

### Audit log 字段

```yaml
audit:
  inputs:
    - 4 候选完整文本
    - 历史 dead 列表
  llm_raw_output: <strictly yaml>
  llm_normalized:
    chosen: 2
    reasoning: "..."
    confidence: 0.82
  user_decision:
    presented_at: 2026-06-17T10:02:30
    user_response: approved   # or modified_chose=3, or rejected_all
```

---

## LLM 节点 2 · 每页判精度(per-page accuracy)

### 输入(每翻一页调用一次)

```yaml
inputs:
  page_number: <当前页码>
  rows:                          # 当前页 10 行
    - company_name: <公司名>
      country: <国家>
      description: <业务描述 1-2 句>
    - ...
  product_positioning: <用户产品定位>
  audience_context: <选定客群>
  cumulative_pages_read: <已读累积页数>
```

### Prompt

```
你是外贸客户精准度判定军师。

任务:看本页 10 个公司,判断有几个真的对路(客户 = 会买你产品的)。

判定原则:
1. 业务描述明确卖 / 经营**你的产品类**(或上下游) → 对路
2. 描述含糊 / 主营业务无关 → 不对路
3. **是同行**(也做你产品的工厂 / 制造商)→ 不对路
4. 公司名 / 国家不影响判定 · 只看业务描述本质

输出 strictly yaml:
total_rows: <int · 当前页行数,通常 10>
on_target_count: <int · 对路数>
accuracy: <float = on_target / total>
verdict: <accurate_continue | boundary_reached | hopeless>
  # accurate_continue: accuracy ≥ 0.7 · 翻下一页
  # boundary_reached: accuracy < 0.7 · 记录精度边界
  # hopeless: cumulative_pages_read < 5 AND accuracy < 0.3 · 触发重搜
flagged_rows: [<list of 该被拒/被存疑的行 index 0-9>]
confidence: <0-1>
```

### 输出约束

```yaml
allowed_outputs:
  - verdict: accurate_continue
  - verdict: boundary_reached
  - verdict: hopeless
forbidden_outputs:
  - 无 accuracy
  - flagged_rows 含超 9 的 index

confidence_threshold: 0.7
on_low_confidence: pause + 用户审核当前页判断
boundary_threshold: 0.7   # 精准/不精准的分界
```

### Audit log 字段

```yaml
audit:
  page_number: 61
  raw_rows: [...]
  llm_output:
    on_target_count: 5
    accuracy: 0.50
    verdict: boundary_reached
    flagged_rows: [1, 3, 4, 7, 9]
    confidence: 0.85
  user_decision:
    presented_at: 2026-06-17T10:08:00
    user_response: approved_boundary   # or moved_boundary=60, or rejected_continue
```

---

## LLM 节点 3 · 询盘识别(handoff 标签 · Tony § 0 #7)

### 输入(客户回信时触发 · 跨 run)

```yaml
inputs:
  customer_email_body: <客户回信全文 · 英文 · 脱敏前预处理>
  customer_company: <公司名>
  customer_country: <国家>
  sequence_round: <当前在 sequence 第几轮>
  historical_replies:                    # 该联系人之前的回信(如有)
    - round: 1
      summary: <一句话摘要>
      tag_applied: <如有打的标签>
```

### Prompt

```
你是外贸跟进推进军师。

任务:看客户这封回信 · 判定该打哪个标签:
- inquiry: 询盘(明确问价 / 索样 / 约 call / 想了解产品)→ 高优先 · 立即转人工
- ooo: Out of Office 自动回复(节假日 / 出差 / 假期)→ 不算回复
- referral: 转介(对方说"我不负责 · 联系 X")→ 触发新联系人流程
- rejection: 拒绝(明确"不需要 / 不感兴趣 / 已有供应商")→ 永久跳过
- neutral: 不确定(语气模糊 · 信息不足 · 需人工审核)→ 不动 sequence

判定原则:
1. inquiry 必须明确表达"想了解 / 想买 / 给我看 / 报价"等积极意图
2. ooo 关键词:"out of office" / "OOO" / "vacation" / "auto-reply" / 节假日提及
3. 拿不准 → neutral · 严禁瞎打 inquiry / rejection

输出 strictly yaml:
tag: <inquiry | ooo | referral | rejection | neutral>
reasoning: <50-100 字>
confidence: <0-1>
flagged_keywords: [<list · 你看到的关键证据词>]
candidate_tags:                    # 5 个标签的 confidence
  inquiry: <0-1>
  ooo: <0-1>
  referral: <0-1>
  rejection: <0-1>
  neutral: <0-1>
```

### 输出约束

```yaml
allowed_outputs:
  - tag: <one of 5>
forbidden_outputs:
  - tag: null
  - 同时多个标签
  - 无 reasoning

confidence_threshold: 0.85   # 询盘错判代价大 · 阈值更高
on_low_confidence: pause + 人工审核 · 默认标 neutral · sequence 不动
```

### Audit log 字段

```yaml
audit:
  customer_email_hash: sha256(原文)     # 不存原文 · 防隐私(Tony § 0 #10 不考虑合规 但工程仍存 hash)
  llm_output:
    tag: inquiry
    reasoning: "..."
    confidence: 0.91
    flagged_keywords: ["pricing", "MOQ", "samples"]
    candidate_tags: {inquiry: 0.91, ooo: 0.02, referral: 0.04, rejection: 0.01, neutral: 0.02}
  agent_action:
    label_applied_to_contact: <contact_id>
    sequence_step_skipped: <如有>
  user_review:
    reviewed_at: <如有人工审核>
    user_override: <如有覆盖 LLM 标签>
```

---

## 全局约束

### Confidence threshold(spec § 11 #3 · 维持默认 · W5 实测后微调)

| 节点 | 默认 threshold | 理由 |
|---|---|---|
| 1 选客群 | 0.7 | 有 Confirm 闸 1 兜底 · 错了用户能拨回 |
| 2 每页判精度 | 0.7 | 累积多页判定 · 单页错不致命 |
| 3 询盘识别 | 0.85 | 错判代价大 · 错过真询盘比误标更糟 |

### LLM 提供商

alpha 期内主用 Codex CLI 内部 LLM(`gpt-5.4 via aihubmix` · 见 `~/.codex/config.toml`)· 不切换 · 减少变量。

### Audit 落点

每个节点 audit 落 `~/.codex/runs/<run_id>/llm_logs.jsonl` 一行 · `run.json` 引用 summary。
