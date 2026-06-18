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

# ⚠️ r7 删除 · 死参数(decision-prompts § 6.2 明示 confidence 不参与决策门 · 只入 audit)
# llm_node_1_confidence:
#   default: 0.70 ...

llm_node_3_inquiry_auto_threshold:
  default: 0.85
  range: [0.70, 0.95]
  type: float
  rationale: "询盘 auto-apply 的 candidate_tags.inquiry 阈值"
  override_via: conversation

llm_node_3_inquiry_flag_threshold:
  default: 0.55
  range: [0.40, 0.70]
  type: float
  rationale: "询盘候选 ≥ 此值强制人工升级(recall-safe)"
  override_via: conversation
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
  alternatives:
    - "boundary_page * 10"     # 全保存(默认)
    - "boundary_page * 8"      # 保守保存
    - "min(boundary_page * 10, 500)"   # 加 cap
  rationale: "动态保存范围公式 · 默认 boundary × 10 (= 最后准页 × 每页 10 行)"
  override_via: conversation
  constraint: "result MUST be ≤ max_save_companies"

max_save_companies:
  default: 1000
  range: [50, 5000]
  type: integer
  rationale: "单次 run 最多保存公司数 · 防失控"
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

max_run_duration_minutes:
  default: 30
  range: [10, 120]
  hard_ceiling: 120
  type: integer
  rationale: "单次 run 总耗时上限"
  override_via: conversation

max_runs_per_day:
  default: 3
  range: [1, 10]
  hard_ceiling: 10
  type: integer
  rationale: "防 dogfood 失控"
  override_via: conversation

# r7 一致性修正:permanently_blocked / scope_out 是 **frozen**(用户不可改)· 不是"可放宽不可越界"
permanently_blocked_actions:
  type: frozen
  override_via: never                 # r7 明示 · 用户改请求 → Codex 拒绝并解释
  rationale: "永久 block 列表(发送/激活/删除/导出/黑名单/退订/AI 评分)· scope out · 不接受用户改"

scope_out_modules:
  type: frozen
  override_via: never
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
1. Codex 读本文 · 列出所有 override_via: conversation 参数 + defaults
2. Codex 问用户:"默认参数如上 · 这次跑要改哪些?(说'默认'直接跑)"
3. 用户自然语言改(r8 必修 · 删 sequence 残留):
   - "boundary 改 0.85/0.65"
   - "单家保存 7 邮箱"
   - "promote 耗时减少阈值改 30%"
   - "max_boundary_pages 改 80"
4. Codex 解析成结构化 override:
   {
     "boundary_high": 0.85,
     "boundary_low": 0.65,
     "emails_per_company": 7,
     "promote_duration_reduction_pct": 30,
     "max_boundary_pages": 80
   }
5. 验证 constraints:
   - boundary_low MUST < boundary_high - 0.10 ✓
   - 每个值在 range 内
   - 强约束(token_expire 等)不超 hard_ceiling
   - frozen 参数(permanently_blocked / scope_out)拒绝改
6. Codex 显示 effective config yaml + 问"确认?"
7. 用户确认 → 写入 run.json.user_overrides · 整个 run 用 effective config
```

## § 9 · run.json.user_overrides 字段 schema(对齐 SKILL.md § 3.1)

```yaml
user_overrides:
  - param: boundary_high
    default: 0.80
    user_value: 0.85
    original_utterance: "boundary 改 0.85/0.65"     # r7 必修 · 用户原话
    normalized_value: 0.85                            # 解析后值
    at: 2026-06-18T20:00:00+08:00
    constraint_passed: true
    rejection_reason: null                            # 接受 · 无 rejection
  - param: token_expire_minutes
    default: 5
    user_value: 15                                    # 超 hard_ceiling 10
    original_utterance: "token 改 15 分钟"
    normalized_value: 15
    at: 2026-06-18T20:00:00+08:00
    constraint_passed: false                          # 不接受
    rejection_reason: "exceeds hard_ceiling (10)"     # r7 必修 · 拒绝原因
    applied_fallback: 5                               # 退回 default

# effective_config 独立顶层字段 · 整个 run 真正用的 config(r7 必修 · 持久化)
effective_config:
  boundary_high: 0.85                                 # 接受了 user override
  boundary_low: 0.65
  token_expire_minutes: 5                             # rejected · fallback to default
  emails_per_company: 5                               # default
  # ... 全 § 1-7 参数
```

## § 10 · 关联

- 启动对话流程:`SKILL.md` § 0.5
- 阈值消费方:`decision-prompts.md`(§ 2.4 / § 3.4)+ `safety-gates.md`(§ 4 token)
- audit 落点:`SKILL.md` § 3.1 run.json schema
- alpha → beta promote:`HOW-TO-START-SPIKE.md` § 6.3
