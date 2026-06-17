---
name: laifaxin-outreach-v0.2
description: Supervised browser spike (alpha) — ONLY for when user explicitly asks to OPERATE the Laifaxin (来发信) web UI (https://web.laifaxin.com) via Codex CLI + computer-use plugin · Scope strictly limited to 段 1 (input product → AI 推演 → choose audience) + 段 2 (page-by-page accuracy judgment → save contacts with dynamic range) · Does NOT use AI rating, does NOT operate templates/sequences/sending/inbox, does NOT handle replies · For cold-email copywriting, sequence design, reply handling, or generic prospecting advice → DEFER to laifaxin-outreach v0.1 · User must be present (alpha · supervised) · Existing logged-in account, no canary
---

# Laifaxin Outreach v0.2 · Supervised Browser Spike (alpha)

> ⚠️ **alpha · 高风险 · 用户必须在场 · 用户真账户 · 不保证 SLA · 不是无人值守 agent**
>
> **Canonical 来源(α.3 起的权威 · 5 文件)**:本目录 `SKILL.md` + `parameters-defaults.md`(α.3 新增 · 首读)+ `safety-gates.md` + `decision-prompts.md` + `HOW-TO-START-SPIKE.md`(5 文件互引一致)
> **背景资料(已 freeze · 不作 canonical)**:`specs/done/2026-06-17-laifa-browser-agent-v0.2.md` 含旧公式(70% 单页 / boundary=61 / browser-use 引用 / AI 评分小样本)· 已被 r1-r5 演化覆盖 · **读者应以本目录 5 文件为准**
> **执行 runners**:`runners/`(本目录 · W3 实施 · 当前 stub-only)

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
5. 验证 constraints(range / hard_ceiling / frozen / 派生约束)
6. 显示 effective config 给用户确认
7. 写入 run.json.user_overrides · 整个 run 用 effective config
```

**强约束**(参 `parameters-defaults.md` § 5):
- `permanently_blocked_actions` / `scope_out_modules` = **frozen** · 用户不可改
- `token_expire_minutes` / `max_run_duration_minutes` 有 hard_ceiling · 用户可放宽但有上限
- 派生约束自动 enforce(如 `boundary_low < boundary_high - 0.10`)

**default canonical** 在 `parameters-defaults.md` · 本 SKILL 不重复列。

## § 1 · Scope(严格 · 不得越界)

```yaml
in_scope:
  - 段 1 客群推演(AI 数据库输入产品 → AI 推演 → 选客群)
  - 段 2 翻页判精度(逐页 LLM 看 → 找精度边界 → 动态保存范围)
  - 联系人保存(单家 5-10 邮箱)
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
| 4 | **Guarded 动作(保存联系人 / 确认转化)必须 one-time token** · 5 分钟过期 · abandoned 5 分钟无响应 = pause + 等人工 resume · revoked 用户取消 | safety-gates.md § 4 |
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
result: success | failed | aborted | partial
user_overrides:                        # § 0.5 启动对话产物(α.3.3 同 parameters-defaults § 9)
  - { param, default, user_value, original_utterance, normalized_value, at, constraint_passed, rejection_reason, applied_fallback }
effective_config:                      # default + overrides 合并后 · 整个 run 真正用的 config
  boundary_high: 0.85                  # 若用户改了 · 否则填 default
  emails_per_company: 7
  # ... 全 § 1-7 参数
inference:
  chosen_audience: { audience_index, audience_slug, name }
sampling:
  method: sequential_paging
  pages_read: int
  per_page_accuracy: [{page, accuracy}]   # array
  boundary_page: int                      # 最后准页(双页 < 0.6 之前)
  save_companies: int                     # = boundary_page × 10
saving:
  task_id, saved_companies, saved_emails, tags_applied
audit:
  user_interventions: [{at, reason, response}]
  warnings: []
  permanently_blocked_hits: int           # 0 = 没碰过永久 block(promote 必要)
  anti_bot_trigger_count: int
  screenshots_dir: ~/.codex/runs/<run_id>/screenshots/
  llm_logs: ~/.codex/runs/<run_id>/llm_logs.jsonl
  artifacts_manifest: artifacts.json
failure_diagnostics:                      # null if successful
  error_type / invalid_fragment / repair_attempts / taken_over_by_human / final_action
```

**每个 LLM 节点失败也要写 `failure_diagnostics`**:error_type / invalid_fragment / repair_attempts / taken_over_by_human / final_action(对齐 decision-prompts.md § 4)。

## § 4 · 主流程(对齐 decision-prompts.md 最新 canonical · 不复述策略)

```
1. 启动 + session 检查(Chrome 已登录 web.laifaxin.com 任一搜客页 + 非登录页面 + cookie 有效)
2. 输入产品 → 点 AI 推演(或 AI 智能生成) → 等 4 客群卡片
3. LLM 节点 1(decision-prompts.md § 1):选客群 · Confirm 闸 1 用户拍板
4. 点"立即查看"进入搜索结果
5. 翻页 sequential · 每翻一页调用 LLM 节点 2(decision-prompts.md § 2):
   - 当前页 ≥ 0.80 对口 → 翻下一页
   - 0.60 ~ 0.80 中间区 → 翻下一页(不停)
   - 当前 < 0.60 且 上一页 ≥ 0.60 → 翻下一页确认(单页不判 boundary)
   - **双页连续 < 0.60 → boundary 确认**(此即"精度边界")
6. 保存范围 = **boundary_page × 10** 公司 × 5-10 邮箱/家(对齐 decision-prompts.md § 2.4 canonical · `boundary_page` 已是"最后准页" · 不再 -1)
7. Confirm 闸 2:用户签发 one-time token(预算预演:估算总邮箱数 × 单价)
8. 执行保存 → 写回 run.json + summary.md + artifacts.json
9. 完成 · 用户 review
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

LLM agent 触发本 SKILL 后,**按顺序读**:

1. **`parameters-defaults.md`(本目录)— 启动对话需要(§ 0.5)· α.3 起首读**
2. `safety-gates.md`(本目录)— scope + 白名单 + token + 失败矩阵
3. `decision-prompts.md`(本目录)— 3 LLM 节点 prompt + schema + decision policy
4. `runners/README.md`(本目录)— runner 接口(W3 实施 · 当前 stub)
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
