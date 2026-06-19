---
name: laifaxin-outreach-v0.2 · parameters-defaults
type: meta
status: active
version: 0.2.0-alpha.3
created: 2026-06-18
updated: 2026-06-18
tags: [v0.2, alpha, parameters, defaults, user-overrides, conversational]
description: v0.2 alpha 全部可调参数 default schema · 用户启动 skill 时通过对话覆盖 · 整个 run 用 effective config · 记 run.json.user_overrides audit · 强约束(security_hard_ceiling)用户可放宽但有 hard cap
---

# Parameters Defaults · v0.2 alpha(W2 canonical)

> **设计原则(r3 修正 · 不再前后矛盾)**:
> 1. **default 写在本文** · 用户改只影响**本次 run** · 不动 markdown
> 2. **每次 run 必须由 Codex 启动对话**列出 defaults · 问"要改吗"(详见 SKILL.md § 0.5)
> 3. **运行时配置** 写入 `run.json.effective_config`(整 run 用)+ `run.json.user_overrides`(audit 用户改了什么)
> 4. **三类参数**:
>    - `override_via: conversation` + `range` — 用户可改 · 范围内接受
>    - `override_via: conversation` + `hard_ceiling` — 用户可改 · 但有不可越上限
>    - `override_via: never` + `type: frozen` — 用户不可改(`permanently_blocked` / `scope_out` / `llm_model`)
> 5. **不写新 DSL** · 用户自然语言改 · Codex LLM 解析成结构化 override

## § 1 · 决策阈值类(decision-prompts.md 引用)

```yaml
boundary_high:
  default: 0.80
  range: [0.70, 0.90]
  type: float
  rationale: "对齐 docs/zhinan/02-filter-customers ≥80% 抽样标准 · 单页 accuracy ≥ 此值翻下页"
  override_via: conversation
  used_in: "decide_per_page() · ACCURATE_HIGH"

boundary_low:
  default: 0.60
  range: [0.50, 0.75]
  type: float
  rationale: "双页连续跌破此值才判定 boundary · 防单页误判"
  override_via: conversation
  used_in: "decide_per_page() · BOUNDARY_LOW"
  constraint: "MUST be < boundary_high - 0.10"

hopeless_min_pages:
  default: 3
  range: [2, 5]
  type: integer
  rationale: "detail 轮 · Tony 决策:至少看满此页数才允许 Hopeless 放弃当前客群 · 防首屏噪声误杀好客群"
  override_via: conversation
  used_in: "decide_per_page() · Hopeless 触发下限"
  constraint: "MUST be <= hopeless_window_pages"

hopeless_window_pages:
  default: 5
  range: [3, 10]
  type: integer
  rationale: "前 N 页累计平均窗口 · cumulative_avg 在此窗口内 < boundary_low 才 Hopeless"
  override_via: conversation
  used_in: "decide_per_page() · Hopeless 上窗"

# ⚠️ r7 删除 · 死参数(decision-prompts § 6.2 明示 confidence 不参与决策门 · 只入 audit)
# llm_node_1_confidence:
#   default: 0.70 ...

# detail 轮(F18)· 节点 3(询盘识别)v0.2 alpha **scope-out** · 不在主流程 · 参数改 override_via:never
#   不进 §0.5 启动对话(否则问一堆本次 run 永不生效的参数 · 误导用户)· v0.3+ 解封时改回 conversation
llm_node_3_inquiry_auto_threshold:
  default: 0.85
  range: [0.70, 0.95]
  type: float
  rationale: "询盘 auto-apply 的 candidate_tags.inquiry 阈值(节点 3 · v0.2 scope-out)"
  override_via: never        # detail 轮 · v0.2 不可改(节点 3 不在主流程)

llm_node_3_inquiry_flag_threshold:
  default: 0.55
  range: [0.40, 0.70]
  type: float
  rationale: "询盘候选 ≥ 此值强制人工升级(recall-safe · 节点 3 · v0.2 scope-out)"
  override_via: never        # detail 轮 · v0.2 不可改
  constraint: "MUST be < llm_node_3_inquiry_auto_threshold"
```

## § 2 · ~~跟进节奏类~~(r7 删除 · alpha scope-out)

> ⚠️ **r7 删除**:跟进节奏属于"智能跟进计划" · v0.2 alpha **scope-out** 永久 block
> · 这些参数没有本次 run 执行消费者 · 不应进启动对话(噪音)
> · 未来 v0.3+ 解封 sequence scope 时再恢复

## § 3 · 保存类(SKILL.md § 4 / spec § 0 #9 引用)

```yaml
emails_per_company:
  default: 5
  range: [3, 10]
  type: integer
  rationale: "Tony § 0 #9 单家公司保存邮箱数上限(整数 · 实际有几个存几个 · 不超此值)· 预算预演按此整数 × 公司数 × 单价估"
  override_via: conversation
  used_in: "saving stage · 邮箱选择数量 + Confirm 闸 2 预算预演"
  note: "r10 钉死类型 = 整数 · 全链路(SKILL/runner/safety-gates 预算公式)都用此整数 · 不再出现 \"5-10\" 字符串"

save_companies_formula:
  default: "boundary_page * 10"
  type: string
  # detail 轮(F15)· 不用裸 eval · runner 用受限 AST 解析器 safe_arith_eval 求值:
  #   只放行 名字 boundary_page · 整数字面量 · 运算 + - * / · 函数 min/max · 其它一律拒(防代码注入)
  enum_or_safe_arith: true
  alternatives:                # 推荐用这几条预设 · 自定义也必须过 safe_arith_eval + 结果校验
    - "boundary_page * 10"     # 全保存(默认 · = 最后高精页 × 每页 10 行)
    - "boundary_page * 8"      # 保守保存
    - "min(boundary_page * 10, 500)"   # 自带 cap
  rationale: "动态保存范围公式 · 默认 boundary_page(=last_high_page)× 10"
  override_via: conversation
  # detail 轮(F25)· 约束改 "post-cap result" · 因为 boundary_page 最大可到 max_boundary_pages(200)
  #   裸公式 boundary_page*10 在 200 时 = 2000 > 1000 · 单独看公式会违约 · 真实由 runner min(.., max_save_companies) 兜
  constraint: "post-cap: runner 求值后强制 save_count = min(result, max_save_companies) · 且必须 1 <= save_count <= max_save_companies 整数 · 否则 fail-closed"

save_task_timeout_s:
  default: 120
  range: [30, 600]
  type: integer
  rationale: "detail 轮(F21)· 保存为异步任务 · 轮询任务终态的超时 · 超时记 partial + 人工核对"
  override_via: conversation
  used_in: "runner poll_save_task()"

max_save_companies:
  default: 1000
  range: [50, 5000]
  type: integer
  rationale: "单次 run 最多保存公司数 · 防失控 · runner 对 save_count 做 post-cap"
  override_via: conversation

max_boundary_pages:
  default: 50
  range: [10, 200]
  type: integer
  rationale: "翻页上限 · 防 LLM 节点 2 死循环"
  override_via: conversation
```

## § 4 · 标签类(SKILL.md § 1 引用)

```yaml
label_format:
  default: "{lang}-{country}-{product}-{role}"
  type: string
  custom: true
  rationale: "对齐 docs/zhinan/03-save-customers 公式 · 用户可自定义模板"
  override_via: conversation
  example_overrides:
    - "{country}-{product}-{role}"           # 不含 lang
    - "{lang}-{country}-{product}/{industry}-{role}"   # 含 industry(03-save 选用形)
```

## § 5 · 安全类(strong constraints · 用户可放宽 · 不可越 hard ceiling)

```yaml
token_expire_minutes:
  default: 5
  range: [3, 10]
  hard_ceiling: 10                    # 永不接受 > 10
  type: integer
  rationale: "one-time approval token 过期 · alpha 阶段不让用户开过宽"
  override_via: conversation
  constraint: "MUST be ≤ 10"

token_abandoned_minutes:
  default: 5
  range: [3, 10]
  hard_ceiling: 10
  type: integer
  rationale: "用户无响应 5 分钟自动 abandoned · run paused"
  override_via: conversation
  constraint: "MUST be ≤ 10"

# detail 轮(F24)· max_run_duration_minutes / max_runs_per_day 当前包内**无执行消费者**(典型 fail-open)
#   W3 真接线前:① runner 不读它们限时/限频 ② 故 override_via 改 never · 不进 §0.5 启动对话(避免"以为改了会限制其实不会")
#   W3 落地"耗时看门狗 + 当日 run 计数"后 · 再改回 conversation 并标 used_in
max_run_duration_minutes:
  default: 30
  range: [10, 120]
  hard_ceiling: 120
  type: integer
  rationale: "单次 run 总耗时上限 · ⚠️ W3 未接线 · 当前无消费者"
  override_via: never                 # detail 轮 · 无消费者 → 暂冻结 · 不误导用户
  status: not_wired_until_w3

max_runs_per_day:
  default: 3
  range: [1, 10]
  hard_ceiling: 10
  type: integer
  rationale: "防 dogfood 失控 · ⚠️ W3 未接线 · 当前无消费者"
  override_via: never                 # detail 轮 · 无消费者 → 暂冻结
  status: not_wired_until_w3

# r7 一致性修正:permanently_blocked / scope_out 是 **frozen**(用户不可改)· 不是"可放宽不可越界"
# detail 轮(F28)· 这两个是 **policy list**,不是可调参数 · 其 canonical 值在 safety-gates.md(白名单/scope)
#   **不进 run.json.effective_config**(effective_config 只装 §1-7 的可调/冻结标量参数 · 不装策略清单)
#   runner 不为它们在 effective_config 写值 · 消费者(safe_click)直接读 safety-gates 加载的清单
permanently_blocked_actions:
  type: frozen
  override_via: never                 # r7 明示 · 用户改请求 → Codex 拒绝并解释
  canonical_source: "safety-gates.md § 2.3 permanently_blocked"   # detail 轮 · 值在那 · 本文不重列
  in_effective_config: false
  rationale: "永久 block 列表(发送/激活/删除/导出/黑名单/退订/AI 评分)· scope out · 不接受用户改"

scope_out_modules:
  type: frozen
  override_via: never
  canonical_source: "safety-gates.md § 0 alpha_scope.out"
  in_effective_config: false
  rationale: "段 3/4/5 邮件模板/智能跟进/邮件群发 永久 scope out · 不接受用户改"
```

## § 6 · Promote 类(HOW-TO § 6.3 引用)

```yaml
promote_consecutive_successes:
  default: 5
  range: [3, 10]
  type: integer
  rationale: "alpha → beta promote 需连续 N 次 result=success"
  override_via: conversation

promote_duration_reduction_pct:
  default: 40
  range: [20, 80]
  type: integer
  rationale: "promote 条件 ④ · 客户开发耗时减少 ≥ 此值 vs v0.1 baseline"
  override_via: conversation

promote_max_user_interventions_per_run:
  default: 1
  range: [0, 3]
  type: integer
  rationale: "promote 条件 ② · 平均每 run 用户介入 ≤ 此值"
  override_via: conversation

v01_baseline_minutes:
  default: 45                         # Tony 自报实测
  range: [20, 120]
  type: integer
  rationale: "v0.1 手动模式跑通段 1+2 耗时 baseline · 用户自报"
  override_via: conversation
```

## § 7 · LLM Provider 类(decision-prompts.md § 6.1 引用)

```yaml
llm_model:
  default: "gpt-5.4"
  type: frozen   # r7 改 frozen · alpha 期不可改(对齐 decision-prompts § 6.2)
  override_via: never   # detail 轮(F26)· 补齐 · 让解析器按统一机器规则(type:frozen + override_via:never)识别全部 frozen
  in_effective_config: true
  rationale: "Codex CLI 内部 LLM · 见 ~/.codex/config.toml · alpha 期锁定 gpt-5.4 减少变量"
  warning: "切换 model 会破坏 r1-r7 调优数据 · v0.3+ 再解封"

llm_max_retries:
  default: 1
  range: [0, 3]
  type: integer
  rationale: "repair retry 次数 · 0=fail-closed · 1=允许 1 次修复 retry"
  override_via: conversation
```

## § 8 · Effective Config 解析协议(给 Codex 启动对话用)

启动对话流程(见 SKILL.md § 0.5):

```
1. Codex 读本文 · 列出参数(detail 轮 F29 · 分两组展示 · 避免误导)
   - active_this_run(本次 run 真生效 · 必问):boundary_high/low · hopeless_min_pages/window · emails_per_company
     · save_companies_formula · save_task_timeout_s · max_save_companies · max_boundary_pages · token_expire/abandoned · llm_max_retries
     · label_format(保存弹窗"公司标签/联系人标签"用 · saving.tags_applied · 本次 run 生效)
   - inactive / post-run(本次主流程不生效 · 默认折叠 · 用户主动问才列):
     · promote_*（仅周度 promote 汇总用)· v01_baseline_minutes
   - 不列(override_via: never):llm_model · node3 · max_run_*（无消费者)· permanently_blocked/scope_out（policy 清单)
2. Codex 问用户:"默认参数如上(active 组)· 这次跑要改哪些?(说'默认'直接跑)"
3. 用户自然语言改:
   - "boundary 改 0.85/0.65" · "单家保存 7 邮箱" · "max_boundary_pages 改 80"
4. Codex 解析成结构化 override:{ "boundary_high": 0.85, "boundary_low": 0.65, "emails_per_company": 7, "max_boundary_pages": 80 }
5. 验证 constraints(派生约束在 build_effective_config 里**硬校验** · 失败 = 拒绝启动 · 不只是 prose):
   - 单值在 range 内
   - 派生:boundary_low < boundary_high - 0.10 · hopeless_min_pages <= hopeless_window_pages · flag < auto
   - hard_ceiling:token_expire/abandoned <= 10
   - frozen / override_via:never → 拒绝改并解释
   - **组合非法**(如 boundary_high=boundary_low=0.70 各自在 range 但派生违约)→ 拒绝 · 不生成 effective_config
6. Codex 显示 effective config yaml + 问"确认?"
7. 用户确认 → 写入 run.json.user_overrides + effective_config · 整个 run 用 effective config
```

## § 9 · run.json.user_overrides 字段 schema(对齐 SKILL.md § 3.1)

**正式 schema(detail 轮 F27 · 不再只是 exemplar)**:

```yaml
user_overrides_item_schema:
  type: object
  additionalProperties: false
  required: [param, default, user_value, original_utterance, normalized_value, at, constraint_passed]
  properties:
    param:              { type: string, enum_ref: "§1-7 中 override_via:conversation 的参数名" }
    default:            {}                       # 该参数 default(类型随参数)
    user_value:         {}                       # 用户给的原始值
    original_utterance: { type: string }         # 用户原话
    normalized_value:   {}                       # 解析后值
    at:                 { type: string, format: date-time }
    constraint_passed:  { type: boolean }
    # 下面两个按 constraint_passed 二选一(detail 轮钉死可空规则):
    rejection_reason:   { type: [string, "null"] }   # accepted → null · rejected → 必填字符串
    applied_fallback:   {}                            # accepted → 省略/null · rejected → 必填(退回值)
  conditional:
    - if: "constraint_passed == true"  then: "rejection_reason == null AND applied_fallback 省略"
    - if: "constraint_passed == false" then: "rejection_reason 非空 AND applied_fallback 必填"
```

示例:

```yaml
user_overrides:
  - { param: boundary_high, default: 0.80, user_value: 0.85, original_utterance: "boundary 改 0.85/0.65",
      normalized_value: 0.85, at: 2026-06-19T20:00:00+08:00, constraint_passed: true, rejection_reason: null }
  - { param: token_expire_minutes, default: 5, user_value: 15, original_utterance: "token 改 15 分钟",
      normalized_value: 15, at: 2026-06-19T20:00:00+08:00, constraint_passed: false,
      rejection_reason: "exceeds hard_ceiling (10)", applied_fallback: 5 }
```

**effective_config 顶层字段(detail 轮 F35 · required schema · 消费者不得用 `// default` 静默补)**:

```yaml
# 必含全部 §1-7 中 in_effective_config 的标量参数(缺键 = build 失败 · 不静默)
# 不含:permanently_blocked_actions / scope_out_modules(policy 清单 · in_effective_config:false · 见 § 5)
effective_config:
  required_keys:        # runner build_effective_config 必须全部写齐 · promote/decision/safety 直接读 · 无 fallback
    - boundary_high
    - boundary_low
    - hopeless_min_pages
    - hopeless_window_pages
    - emails_per_company
    - save_companies_formula
    - save_task_timeout_s
    - max_save_companies
    - max_boundary_pages
    - token_expire_minutes
    - token_abandoned_minutes
    - max_run_duration_minutes      # 值在 · 但 status:not_wired_until_w3(无消费者)
    - max_runs_per_day              # 同上
    - llm_model
    - llm_max_retries
    - llm_node_3_inquiry_auto_threshold     # frozen · 值在但 v0.2 不消费
    - llm_node_3_inquiry_flag_threshold
    - promote_consecutive_successes
    - promote_duration_reduction_pct
    - promote_max_user_interventions_per_run
    - v01_baseline_minutes
    - label_format
```

## § 10 · 关联

- 启动对话流程:`SKILL.md` § 0.5
- 阈值消费方:`decision-prompts.md`(§ 2.4 / § 3.4)+ `safety-gates.md`(§ 4 token)
- audit 落点:`SKILL.md` § 3.1 run.json schema
- alpha → beta promote:`HOW-TO-START-SPIKE.md` § 6.3
