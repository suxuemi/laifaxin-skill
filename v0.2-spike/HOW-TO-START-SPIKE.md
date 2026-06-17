---
name: laifaxin-outreach-v0.2 · HOW-TO-START-SPIKE
type: meta
status: active
version: 0.2.0-alpha.0
created: 2026-06-17
updated: 2026-06-17
tags: [v0.2, alpha, spike, codex, how-to-start, runbook]
description: v0.2 alpha 浏览器 agent 实战启动 runbook · Tony / 用户在自己 mac 上跑首次 spike 的完整步骤 · 包含预跑前检查清单 / Codex CLI 实际启动命令 / 第一次 run 推荐参数 / 失败应对
---

# HOW-TO-START-SPIKE · v0.2 alpha 首次实战 runbook

> ⚠️ **第一次跑前必读 · 跑完后回灌 W3 实测数据**

## 0. 预跑前 5 分钟检查清单

```bash
# 1. Codex CLI 版本对齐
codex --version
# 期望: codex-cli 0.140.0-alpha.2(或更高,但 W3 用 0.140.0-alpha.2 锁定测)

# 2. 3 plugin 状态
grep -A1 "computer-use@openai-bundled\|browser-use@openai-bundled\|browser@openai-bundled" ~/.codex/config.toml
# 期望: 全 enabled = true

# 3. Chrome 已登录 web.laifaxin.com + tab 前台
# (手动检查)

# 4. ~/.codex/runs/ 目录可写
mkdir -p ~/.codex/runs && touch ~/.codex/runs/.write-test && rm ~/.codex/runs/.write-test
echo "✓ runs/ writable"

# 5. SkyComputerUseClient.app 通知通道
ls "/Users/tony/.codex/computer-use/Codex Computer Use.app/Contents/SharedSupport/SkyComputerUseClient.app/Contents/MacOS/SkyComputerUseClient"
# 期望: 文件存在

# 6. 跑前 wallpaper 截图(可选 · 用于回看比对)
screencapture ~/.codex/runs/pre-spike-$(date +%s).png

# 7. 月度营销预算心里有数(虽然 Tony §0#8 不用 AI 评分但翻页+保存仍可能误触发)
```

## 1. 第一次 spike · 推荐参数

| 参数 | 推荐值 | 理由 |
|---|---|---|
| 产品 | 你最熟的一个(如"皮筏艇" / "LED 户外照明") | 已知客群对路 · 易判 agent 是否选对 |
| 目标 boundary 上限 | 50 页(500 公司)| 起步小 · 别一次跑 600 公司 |
| 单家邮箱数 | 5 | 起步取保守值 · 后续可调 10 |
| 标签 | `<lang>-<country>-<product>-<role>` | 测一次完整公式 · 见 [docs/zhinan/03-save-customers](https://www.laifa.xin/zhinan/03-save-customers) |
| 是否激活计划 | **❌ 否** | spike 只测搜+筛+保存 · 计划激活手动后做 |

## 2. 启动命令(W3 实施后填实际 prompt)

```bash
# 当前 (W2):runners/prospect.py 还是 stub · 先用 codex 交互模式手摸
# W3 实施后:
# codex exec - <<'EOF'
# /laifaxin-outreach-v0.2 product="皮筏艇" max_boundary_pages=50 emails_per_company=5
# EOF
```

**当前 W2 状态**:用 Codex 交互模式手摸 plugin 接口,先验证基础能力 · 不跑完整 orchestration。手摸 3 件事:

```bash
codex
# 在交互中:
# 1. 让 Codex 截图 web.laifaxin.com/search/refine-search
# 2. 让 Codex 描述屏幕上的 AI 推演按钮位置
# 3. 让 Codex 模拟点 AI 推演(但用户在场,准备 Ctrl-C 紧急停)
```

如果这 3 步都 work · 才进 W3 写 `prospect.py`。

## 3. 关键观察指标(W3 启动后填回灌)

每次 spike 跑完 · 用户记 1 行:

```yaml
run_id: <Codex 自动生成>
date: 2026-06-XX
product: <产品名>
boundary_page: <翻到第几页停>
saved_companies: <实际保存>
saved_emails: <实际保存>
wall_clock_minutes: <开始到结束>
user_interventions: <你介入了几次>
errors: <遇到几次错>
ocr_misreads: <OCR 识别错按钮几次>
anti_bot_trigger: <反爬响应几次>
points_spent: <扣了多少点数>
```

填回 `~/.codex/runs/<run_id>/summary.md` · W5 soak 汇总分析。

## 4. 紧急停操作

| 状况 | 怎么停 |
|---|---|
| agent 准备点了不该点的按钮(发送 / 激活 / 删除)| **关掉 Chrome tab** · agent 会立即报 session 失效 |
| agent 卡住超 5 分钟没动 | Ctrl-C 进程 + 看 `~/.codex/runs/<run_id>/llm_logs.jsonl` 最后一行 |
| 反爬验证码 | Codex `notify` 会弹 alert · 用户手动过验证码 + Codex 等 |
| 点数即将耗光 | 来发信余额监控弹窗 → 立刻 Ctrl-C |
| 计算机被别人借用 | Cmd-Tab 切走 + Chrome 失焦 → computer-use 自动暂停 |

## 5. 第一次 spike 之后(W4-W6 路径)

1. 写 `runners/prospect.py` 完整实现(参 `runners/README.md` stub 伪 API)
2. 写 `safety_enforcer.py` 实际 enforce(从 `safety-gates.md` 加载 yaml)
3. 写 `decision_caller.py` 调 LLM 节点(从 `decision-prompts.md` 加载 prompt)
4. 写 `audit_writer.py` 落 `~/.codex/runs/<run_id>/run.json + summary.md + artifacts.json`
5. 30/60 分钟 soak test
6. 跑 5 次连续 success run · 计 alpha → beta 4 条硬条件(spec § 11.1 #5)
7. promote 到 v0.2.0-beta.1

## 6. 失败应对矩阵(对应 spec § 4.4 + safety-gates.md § 4)

| 失败 | 应对 |
|---|---|
| Codex 找不到按钮 | 截图回灌 · 改 OCR / 同义词词典(`safety-gates.md` § 1) |
| 用户 token 没及时签发 → 超时 | 跑 token 流(`safety-gates.md` § 3.1) |
| 来发信 UI 大改 | 截图 + 报告 · spec 写"alpha 期可接受" |
| 反爬封号 | 立刻停 · 24h 不跑 · 换关键词 / 等 cookie 重置 |
| 模型输出非 yaml(LLM 节点回不严格) | 重跑 + confidence_threshold 提一档 |

## 7. 反馈回灌

跑完每次 spike · 在 `wiki/history/2026-06-laifa-browser-agent-v0.2-design.md` 末尾追加一段:

```markdown
## 实测日志 · YYYY-MM-DD-<run_id>

- 总耗时:X 分钟
- 用户介入:Y 次
- 误操作:Z 次(预期 0)
- 主要观察:...
- 是否进 W4:Yes / No
```

5 次实测后:汇总 → 决定是否 alpha → beta promote。

## 关联

- 主 SKILL.md(本目录)
- safety-gates.md(本目录)
- decision-prompts.md(本目录)
- runners/README.md stub(本目录)
- 完整 spec:`specs/done/2026-06-17-laifa-browser-agent-v0.2.md`(本仓)
- 关键决策回顾:`wiki/history/2026-06-laifa-browser-agent-v0.2-design.md`(本仓)
- v0.1 包(已发):[github.com/suxuemi/laifaxin-skill](https://github.com/suxuemi/laifaxin-skill)
- spike 分支:[github.com/suxuemi/laifaxin-skill/tree/spike/v0.2-alpha](https://github.com/suxuemi/laifaxin-skill/tree/spike/v0.2-alpha)
