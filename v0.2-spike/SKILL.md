---
name: laifaxin-outreach-v0.2
description: 你在场监督 · AI 帮你在「来发信」网页里实际操作 —— ① 输产品 → 选客群 ② 翻页判精度 → 保存对的公司联系人 · 写信发信回信不碰(走 v0.1)· 适配 Claude Code 自动加载 + Codex 手动 @ 引用 · 仅当用户明确要"在网页里实际操作 / 接管已登录的 web.laifaxin.com / 走 browser spike"时触发 · "问方法/出关键词/写文案/排序列/处理回信"一律走 v0.1 不触发本 skill
---

# Laifaxin Outreach v0.2 · 浏览器陪跑 spike(alpha)

> **一句话**:你打开 [web.laifaxin.com](https://web.laifaxin.com) 登录好,本 skill 让 AI 帮你做 ① 输产品选客群 + ② 翻页 + 保对的联系人 —— 你全程坐旁边看 · 关键动作要你点 Y。
>
> **2 分钟上手** → [INSTALL.md](INSTALL.md)(Claude Code 自动 / Codex 手动两种用法)
>
> ⚠️ **alpha · 高风险 · 用户必须在场 · 用户真账户 · 不保证 SLA · 不是无人值守 agent**

## TL;DR · 这个 skill 适合谁

| ✅ 你应该用 | ❌ 你不该用(走 v0.1) |
|---|---|
| "在来发信网页里帮我搜一批食品分销商 · 翻页判对不对 · 保对的" | "帮我写一封开发信 / 排 sequence / 处理回信" |
| "接管我已登录的 web.laifaxin.com · 找完一批客户保进我的客户库" | "我还没用过来发信 · 帮我搞个 SOP" |
| 你在场 + 你自己账户 + 接受半监督 | 想要无人值守的 24h 自动化 |

> Canonical 5 文件:本 `SKILL.md` + [parameters-defaults.md](parameters-defaults.md) + [safety-gates.md](safety-gates.md) + [decision-prompts.md](decision-prompts.md) + [HOW-TO-START-SPIKE.md](HOW-TO-START-SPIKE.md) · 详见 [INSTALL.md](INSTALL.md)
> 背景资料(已 freeze · 不作 canonical):`specs/done/2026-06-17-laifa-browser-agent-v0.2.md`(含已被 r1-r5 覆盖的旧公式)· 执行 runners:`runners/`(W3 实施 · 当前 stub-only)

## § 0.0 · 客户端兼容(Claude Code + Codex CLI 双适配)

本 skill 是**纯文档 + 纯 markdown**,任何能读 markdown 的 LLM agent 都能跑。已验证两套入口:

- **Claude Code**:扔进 `~/.claude/skills/laifaxin-outreach-v0.2/` → 自动按 frontmatter `description` 触发 → 自动加载 5 canonical 文件
- **Codex CLI**:用户在 prompt 里 `@SKILL.md @parameters-defaults.md @safety-gates.md @decision-prompts.md @HOW-TO-START-SPIKE.md` → Codex 读完按 § 0.5 启动对话 → 走主流程
- **其他 agent**:粘 [INSTALL.md](INSTALL.md) 「通用 agent 启动指令」一段进 system prompt 即可

**Codex 用户最短启动指令**(粘进 Codex 即可,不需要 frontmatter 加载机制):

```
我已经在 Chrome 登录了 web.laifaxin.com · 帮我用 laifaxin-outreach-v0.2 skill 跑 browser spike
读以下 5 文件 · 按 SKILL.md § 0.5 启动对话先确认参数 · 然后按 § 4 主流程走:
@skills-public/laifaxin-outreach-v0.2/SKILL.md
@skills-public/laifaxin-outreach-v0.2/parameters-defaults.md
@skills-public/laifaxin-outreach-v0.2/safety-gates.md
@skills-public/laifaxin-outreach-v0.2/decision-prompts.md
@skills-public/laifaxin-outreach-v0.2/HOW-TO-START-SPIKE.md
```

## § 0 · Trigger Precedence(触发优先级 · 防抢 v0.1)

| 用户问的 | 应触发哪个 skill |
|---|---|
| "用来发信开发外贸客户 / 找美国客户 / 帮我搜客户" | **v0.1**(SOP / 出关键词) · v0.2 不抢 |
| "帮我写一封开发信" / "写第一轮邮件" / "搞一个 sequence" | **v0.1** |
| "客户回复了 X · 怎么办" / "客户回信怎么打标签" | **v0.1** + reply playbook |
| **"在来发信网页里帮我实际操作搜客 / 翻页 / 保存"** | **v0.2** ✅ |
| **"接管当前登录的 web.laifaxin.com 会话跑 browser spike"** | **v0.2** ✅ |
| **"用 Codex 在浏览器里点 AI 推演 / 翻页判精度 / 保存联系人"** | **v0.2** ✅ |
| 用户明确说"走 browser spike 模式"(natural language flag) | **v0.2** ✅ |

**严格 negative trigger**(v0.2 不应触发):
- 任何邮件文案写作 / sequence 设计 / 回信处理诉求 → v0.1
- 任何不涉及"在来发信网页内实际操作"的诉求 → v0.1
- 任何涉及"AI 评分 / 智能跟进激活 / 邮件群发"的诉求 → 永久 block(scope out)

## § 0.5 · 启动对话:参数确认(每次 run 必跑 · alpha-α.3 起新增)

> **r6/r5 后的产品级补充**(Tony 提案):skill 之前所有参数硬编码 · 用户改要 fork repo · 不实用。
> 改为**对话式 override** · 整个 run 用 effective config · 不动 markdown。

每次用户触发 v0.2 skill · Codex 必须:

```
1. 读 parameters-defaults.md
2. 列出所有 `override_via: conversation` 参数 · 显示 defaults
3. 问用户:"默认参数如上 · 这次跑要改哪些?(说'默认'直接跑)"
4. 解析用户自然语言改动 → 结构化 override yaml
5. 验证 constraints(range / hard_ceiling / `override_via: never` 一律拒(含 frozen 的 llm_model/policy 清单 + 非 frozen 的 max_run_*/node3)/ 派生约束)
6. 显示 effective config 给用户确认
7. 写入 run.json.user_overrides · 整个 run 用 effective config
```

**effective_config 单一所有权(α.4 钉死 · 构建在 main · runner 持有)**:
- **构建职责在 `main`**(需与用户交互):`main` 读 parameters-defaults → `run_startup_dialog()` 产 user_overrides → `build_effective_config(defaults, overrides)`(内部硬校验派生约束 · 失败不启动)→ 把成品 dict 注入 `V02SpikeRunner(effective_config=...)`
- **runner 是唯一持有/写入者**:`Runner.__init__(effective_config)` 接收已校验 dict → 写 `run.json.effective_config` → 注入下游消费者
- DecisionCaller / safety-gates / promote 脚本等 **所有 config 消费者都只读 runner 注入的 `effective_config`**,不再自己加载 parameters-defaults · 也不在 `__init__` 里现造(避免未定义 user_overrides)
- `DecisionCaller.from_md_sections(path, effective_config=<runner 注入>)`:**仍读 `decision-prompts.md`** markdown(取 prompt 文本 / schema / policy 这些"代码+数据"内容)· **但不读 `parameters-defaults.md`**(参数值由 runner 注入)· 无 `set_effective_config()` 二段装配

**强约束**(参 `parameters-defaults.md` § 5):
- `permanently_blocked_actions` / `scope_out_modules` = **frozen** · 用户不可改
- `token_expire_minutes` / `token_abandoned_minutes` 有 hard_ceiling(≤10)· 用户可放宽但有上限
- **`override_via: never` 一律不可改**(校验时拒绝 + 解释)· 两类:① frozen(`llm_model` · `permanently_blocked`/`scope_out` policy 清单)② 非 frozen 但 never(`max_run_*` 无消费者 · 节点 3 参数 scope-out)· 详见 parameters-defaults 前言"参数类别"
- 派生约束自动 enforce(`build_effective_config` 硬校验:`boundary_low < boundary_high - 0.10` · `hopeless_min_pages ≤ hopeless_window_pages` 等 · 失败不启动)

**default canonical** 在 `parameters-defaults.md` · 本 SKILL 不重复列。

## § 1 · Scope(严格 · 不得越界)

```yaml
in_scope:
  - 段 1 客群推演(AI 数据库输入产品 → AI 推演 → 选客群)
  - 段 2 翻页判精度(逐页 LLM 看 → 找精度边界 → 动态保存范围)
  - 联系人保存(单家最多 emails_per_company 个邮箱 · default 5 · range 3-10)
  - 打标签(公式:语言-国家-产品/行业-供应链角色)

out_of_scope:                       # 任何操作 = 立即 stop + alert
  - 智能跟进计划(创建 / 编辑 / 添加 / 激活 / 任何操作)
  - 邮件模板(创建 / 编辑 / 测试发送 / 插入变量 / 任何操作)
  - AI 评分(任何按钮 · 全链路)
  - 邮件群发 / 发送 / 收发
  - 删除 / 导出 / 黑名单
  - 设置 / 权限 / 充值
```

**scope 越界检测**:状态机检测 page url 进入 out_of_scope 模块(`/marketing/sequences/*` / `/contacts/templates/*` 等)→ **立即 pause + alert**(铁律 5)。

## § 2 · 5 项入口硬铁律(违反任意 = 立即 stop)

| # | 铁律 | 详细位置 |
|---|---|---|
| 1 | **用户在场监控** · 用户必须能随时介入 / 终止 run(不要求 Chrome 前台 · 但要求用户 watching) | spec § 2.1 |
| 2 | **scope 越界 = 立即 stop + alert** · 进入 § 1 out_of_scope 模块的 URL / 页面 → fail-closed · URL 判定 best-effort(`chrome.url()` W3 未坐实 · 用 a11y page heading / breadcrumb 兜底)| safety-gates.md § 0 + 状态机 |
| 3 | **危险按钮(发送 / 激活 / 删除 / 导出 / 黑名单 / AI 评分 / 插入变量 / 创建模板 等)永久 block** · 不接受 token 也不点 | safety-gates.md § 2.3 + § 3 |
| 4 | **Guarded 动作(弹窗"确认转化 / 确认保存" · action_id=confirm_save_contacts)必须 one-time token** · "保存联系人"本身是 allowed(开弹窗 · 不需 token)· token 5 分钟过期 · abandoned 无响应 = pause + 等人工 resume · revoked 用户取消 | safety-gates.md § 4 |
| 5 | **登录失效 / 验证码 / 反爬迹象 / 权限弹窗 = pause + alert** · 不得自动 retry / 自动恢复 / 自动绕过 | HOW-TO-START-SPIKE.md § 4.3 状态机 + safety-gates.md § 7 失败矩阵 |

> **r1 deep-review 反馈**:
> - 删旧"完整性铁律"(过宽 + 跟 spec § 4 完整性约束重复)
> - 删旧"变量占位符"(scope out · 模板编辑被永久 block)
> - 删旧"Chrome 必须前台"(spec 关键能力之一是不要求前台)
> - 加 scope 越界 + 登录失效 = 必修(alpha 受监控 agent 基础)

## § 3 · Audit 最小闭环(铁律 4 详细)

每 run 必须生成:

```
~/.codex/runs/<run_id>/                             # 本地大附件(不入 repo)
  ├── tokens.sqlite                                  # safety controller 状态
  ├── screenshots/                                    # 每步截图
  └── llm_logs.jsonl                                  # 每节点 LLM 输入/输出/validation/retry/failure_diagnostics

raw/prospecting/<product>/runs/<run_id>/            # 入 repo(跨设备审计)
  ├── run.json                                        # 结构化 run 元数据 · schema 见 § 3.1(spec § 6.2 是旧版,以本节为准)
  ├── summary.md                                      # 人读摘要(从 run.json 派生)
  └── artifacts.json                                  # 指针 + screenshots/llm_logs hash list
```

### § 3.1 run.json schema(W2 canonical · 覆盖 spec § 6.2 旧版)

```yaml
run_id: timestamp-slug-<n>             # 不是 Codex SESSION_ID(UUID)
started_at / finished_at / duration_seconds
result: success | partial | failed | aborted | repick   # detail 轮 · 加 repick(用户拒客群/Hopeless 提前退)
# detail 轮(F20)· 各阶段 phase-scoped · 允许 null + 带 status · 失败/提前退出 run 不必造假填成功字段
phase_status:                          # 每阶段独立状态 · 让失败 run 也能如实落盘
  inference: pending | done | skipped | failed
  sampling:  pending | done | skipped | failed
  saving:    pending | done | partial | skipped | failed
user_overrides:                        # § 0.5 启动对话产物(同 parameters-defaults § 9 正式 schema)
  - { param, default, user_value, original_utterance, normalized_value, at, constraint_passed, rejection_reason, applied_fallback }
effective_config:                      # default + overrides 合并 · 整个 run 真正用 · required_keys 见 parameters-defaults § 9
  # ... 全 § 1-7 in_effective_config 参数(不含 permanently_blocked/scope_out policy 清单)
inference:                             # nullable · 未到此阶段 = null · phase_status.inference 记状态
  chosen_audience: { audience_index, audience_slug, name } | null
sampling:                             # nullable
  method: sequential_paging
  pages_read: int
  per_page_accuracy: [{page, accuracy}]   # array
  terminal: BoundaryReached | NoNextPage | MaxPages | Hopeless   # detail 轮 · 翻页如何收尾
  boundary_page: int | null               # = last_high_page(最后一个 ≥ boundary_high 的页)· 无高精页时 null
  save_companies: int | null              # = safe_arith_eval(save_companies_formula, {boundary_page}) post-cap · 见 runner
saving:                               # nullable · 异步保存
  task_id: str | null
  task_state: pending | done | failed     # detail 轮 F21 · 只有 done 才允许 result=success
  saved_companies / saved_emails / tags_applied
audit:
  user_interventions: [{at, reason, response}]
  warnings: []
  permanently_blocked_hits: int           # 0 = 没碰过永久 block(promote 必要)· 由 safe_click record_blocked 递增
  anti_bot_trigger_count: int
  screenshots_dir: ~/.codex/runs/<run_id>/screenshots/
  llm_logs: ~/.codex/runs/<run_id>/llm_logs.jsonl
  artifacts_manifest: artifacts.json
failure_diagnostics:                      # null if successful · 任一阶段 failed/aborted 必填
  error_type / invalid_fragment / repair_attempts / taken_over_by_human / final_action
```

**每个 LLM 节点失败也要写 `failure_diagnostics`**:error_type / invalid_fragment / repair_attempts / taken_over_by_human / final_action(对齐 decision-prompts.md § 4)。

## § 4 · 主流程(对齐 decision-prompts.md 最新 canonical · 不复述策略)

```
1. 启动 + session 检查(Chrome 已登录 web.laifaxin.com 任一搜客页 + 非登录页面 + cookie 有效)
2. 输入产品 → 点 AI 推演(或 AI 智能生成) → 等 4 客群卡片
3. LLM 节点 1(decision-prompts.md § 1):选客群 · Confirm 闸 1 用户拍板
4. 点"立即查看"进入搜索结果
5. 翻页 sequential · 每翻一页调用 LLM 节点 2(decision-prompts.md § 2)· **阈值全部来自 `effective_config`**(下面只是 default · 用户可在 § 0.5 启动对话覆盖):
   - 当前页 ≥ `boundary_high`(default 0.80) → 翻下一页(记为高精页 · 更新 last_high_page)
   - `boundary_low` ~ `boundary_high` 中间区 → 翻下一页(不停 · **不算高精页**)
   - 当前 < `boundary_low`(default 0.60) 且 上一页 ≥ `boundary_low` → 翻下一页确认(单页不判 boundary)
   - **双页连续 < `boundary_low` → boundary 确认** · `boundary_page = last_high_page`(最后一个 ≥0.80 页 · Tony 决策:中间区未证实页不纳入保存)
   - 翻页前查"下一页"可点性 · 空页/不可点 = 真实末页 → **NoNextPage 终态**
   - 跑满 `max_boundary_pages`(default 50)未触边界 → **MaxPages 终态** · 回退用 last_high_page
   - Hopeless(累计 ≥`hopeless_min_pages`(default 3)页均值仍 < boundary_low)→ 重选客群(repick)
   - **终态收口**:若整段无任何高精页 → 不进保存 · repick(没东西值得存)
6. 保存范围 = `safe_arith_eval(effective_config.save_companies_formula, {boundary_page})` · **受限 AST 求值不用裸 eval**(只放行 boundary_page/整数/+-*//min/max)· default `boundary_page * 10` · post-cap `min(.., max_save_companies)` · 结果强校验为 [1, max_save_companies] 整数否则 fail-closed · 邮箱/家 = `effective_config.emails_per_company`(整数 · default 5)
7. 保存动作两步(对齐 safety-gates.md § 2):
   - ① `safe_click("保存联系人")` — **allowed**(开保存弹窗 · 不需 token)· 然后 runner 显式设置/校验弹窗"选择前 N 条"= save_count · 不一致 = fail-closed
   - ② Confirm 闸 2:用户签发 one-time token(action_id = `confirm_save_contacts` · 预算预演保守上界 = `save_count × emails_per_company × 2`(全有效价 · 真实有效2/未知1/无效0))· **审批唯一**:runner 预签透传给 `safe_click("确认转化", pre_signed_token=...)`,gates 校验后**只 consume** · guarded 缺 token = fail-closed
8. **异步保存收尾**(detail 轮):点确认 ≠ 保存完成 · 拿 task_id 轮询保存任务到终态 · `done` 才记 `result=success`;超时/未达终态记 `partial` + 人工核对
9. 写回 run.json + summary.md + artifacts.json · 完成 · 用户 review
```

**⚠️ 主流程**:
- **不包含**段 3 写邮件 / 段 4 sequence 配置 / 段 5 回信处理(scope out)
- **不调用**AI 评分按钮(Tony § 0 #8)
- LLM 节点 3 询盘识别**不在 v0.2 alpha 主流程**(scope out · 暂留 spec § 5.1 设计 · 实际触发在 v0.3+)

## § 5 · Executor 路(对齐 safety-gates.md § 1 + spec § 1.4)

- **主路**:`computer-use@openai-bundled` plugin(看屏幕 + macOS a11y + action)· 实查 `codex plugin list` installed, enabled
- **辅助路**:`chrome@openai-bundled` plugin(仅查 URL / tab title)· 实查 installed, enabled
- **⚠️ 架构修正**:之前 spec / safety-gates 写的 `browser-use@openai-bundled` **不存在**(plugin list 无此 plugin · `~/.codex/config.toml` 是过时配置)· 已删除所有依赖

## § 6 · 触发后必须先读的文件(顺序)

**运行本 skill(alpha · Codex/Claude 操作浏览器)读 5 canonical**(行为完全由这 5 份定义 · 与 § 0.0 一致):

1. **`SKILL.md`(本文)** — 入口 + 触发 + scope + 主流程 + run.json schema
2. **`parameters-defaults.md`** — 启动对话需要(§ 0.5)· 参数 default/range/frozen
3. `safety-gates.md` — scope + 白名单 + token + 失败矩阵
4. `decision-prompts.md` — 3 LLM 节点 prompt + schema + decision policy
5. `HOW-TO-START-SPIKE.md` — preflight + smoke + promote(启动/验收用)

> **`runners/README.md` 不是第 6 个 canonical**,是 **W3 实施参考(stub · 把上面 5 份的契约翻成 runner 伪代码 + 测试期望 + 待补清单)**。
> 只有当你要**写真 runner 代码(prospect.py / safety_enforcer.py / decision_caller.py)** 时才读它 · 日常运行不需要 · 它与 5 canonical 一致(不引入新规则)。
> `INSTALL.md` 是安装/上手指南(给人读)· 也非 canonical。
5. `HOW-TO-START-SPIKE.md`(本目录)— 启动预飞 + 紧急停 + 反馈

## § 7 · 关联

- spec(已归档 · 背景资料 · **不作 canonical**):`specs/done/2026-06-17-laifa-browser-agent-v0.2.md` · 旧公式已被本目录 5 文件覆盖
- 关键决策回顾:`wiki/history/2026-06-laifa-browser-agent-v0.2-design.md`
- safety-gates(本目录)
- decision-prompts(本目录)
- runners(本目录 · stub)
- HOW-TO-START(本目录)
- v0.1 包(已发):[github.com/suxuemi/laifaxin-skill](https://github.com/suxuemi/laifaxin-skill)
- spike 分支:[github.com/suxuemi/laifaxin-skill/tree/spike/v0.2-alpha](https://github.com/suxuemi/laifaxin-skill/tree/spike/v0.2-alpha)
