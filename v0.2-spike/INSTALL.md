---
name: laifaxin-outreach-v0.2-install
description: 在 Claude Code / Codex CLI / 任意 markdown-aware LLM agent 上安装并启动 laifaxin-outreach v0.2 浏览器陪跑 skill 的两分钟教程
type: install-guide
status: alpha
created: 2026-06-18
updated: 2026-06-18
tags: [install, skill, claude-code, codex-cli, laifaxin, v0.2-alpha]
---

# Install · laifaxin-outreach v0.2

> 2 分钟上手 · 三种客户端任选一种 · 都用同一份 5 文件。

---

## ⚠️ 跑之前必做(三项)

1. **Chrome 已登录** [web.laifaxin.com](https://web.laifaxin.com) · cookie 有效 · 不在登录页
2. **账户里有点数**(本 skill 只 spike 段 1 + 段 2 · 保存联系人会消耗点数 · 估算后用户拍板)
3. **你本人在场**:alpha 阶段强约束 · 关键动作(保存弹窗里的"确认转化" guarded 步骤)需要你点 Y 签发 token 才会执行

---

## 一、Claude Code(自动加载 · 推荐)

```bash
# 1. 把 skill 目录扔到 Claude Code skill 路径
cp -r skills-public/laifaxin-outreach-v0.2 ~/.claude/skills/

# 2. 重启 Claude Code(或 /skills reload)
```

触发:在 Claude Code 对话框说 **"在来发信网页里帮我搜一批食品分销商 · 翻页判精度 · 保对的联系人"** —— Claude 会按 frontmatter `description` 自动加载本 skill,先按 [SKILL.md](SKILL.md) § 0.5 启动对话确认参数,然后走主流程。

---

## 二、Codex CLI(手动 @ 引用 · 同样能跑)

Codex 没有 Claude Code 的 frontmatter 自动加载机制,但本 skill 是纯 markdown,完全支持手动 `@` 引用。

**最短启动指令**(直接粘进 Codex prompt):

```
我已经在 Chrome 登录了 web.laifaxin.com · 现在帮我用 laifaxin-outreach-v0.2 skill 跑 browser spike

请按下面 5 文件顺序读完 · 然后按 SKILL.md § 0.5 先和我对话确认参数 · 再按 § 4 主流程走:

@skills-public/laifaxin-outreach-v0.2/SKILL.md
@skills-public/laifaxin-outreach-v0.2/parameters-defaults.md
@skills-public/laifaxin-outreach-v0.2/safety-gates.md
@skills-public/laifaxin-outreach-v0.2/decision-prompts.md
@skills-public/laifaxin-outreach-v0.2/HOW-TO-START-SPIKE.md

我的产品是:______ · 想找的客群方向:______
```

**Codex 需要的 plugin**(`codex plugin list` 验证 installed + enabled):

| Plugin | 用途 | 必装 |
|---|---|---|
| `computer-use@openai-bundled` | 看屏幕 + macOS a11y + 点击 / 键盘 | ✅ 主路 |
| `chrome@openai-bundled` | 读当前 tab URL / title(辅助验证) | ✅ 辅助 |

> ⚠️ `browser-use@openai-bundled` 不存在(plugin marketplace 没有 · 老 config.toml 有也忽略)· 主路用 `computer-use`。

---

## 三、其他 markdown-aware agent(通用启动指令)

任何能读 markdown + 能控制本机浏览器/桌面的 LLM agent,把下面这段贴进 system prompt 即可:

```
你是一个浏览器陪跑助手 · 你的任务由 laifaxin-outreach-v0.2 skill 定义
读完 5 文件后按 SKILL.md § 0.5 启动对话 · 然后按 § 4 主流程操作
关键约束:
- scope_out / permanently_blocked 永远不能碰(详见 safety-gates.md)
- guarded actions 必须等用户 token 才点(详见 safety-gates.md § 4)
- 所有可调参数从 run.json.effective_config 读(单一所有权 = runner)
- 失败要写 run.json.failure_diagnostics · 不要静默吞错

5 文件路径(用户提供 · 或用户上传)· 你必须全读完再开干。
```

---

## 跑起来后

- 第一次跑建议把所有参数留 default · 看完跑顺 + 看完 [run.json](runners/README.md) audit 字段 · 再考虑下次改
- 出问题先看 `~/.codex/runs/<run_id>/llm_logs.jsonl` + `screenshots/`(本地路径 · 不进 repo)
- promote alpha → beta 的 4 条硬条件见 [HOW-TO-START-SPIKE.md § 6.3](HOW-TO-START-SPIKE.md)

---

## FAQ

**Q · 我要不要给 skill 加 API key?**
A · 不要。本 skill 不调任何外部 API · 全靠你已登录的 Chrome session + Codex/Claude 自己的 LLM。

**Q · Codex 和 Claude Code 跑出的 run.json 兼容吗?**
A · 兼容 · schema 在 SKILL.md § 3.1 定义 · 与客户端无关。

**Q · 我可以无人值守跑吗?**
A · alpha 阶段不行。Tony 必须在场 · 关键动作要 Y/N。等 promote 到 beta 后再开放半监督模式。

**Q · 出错了我怎么停?**
A · 任何时候直接 Ctrl-C / 关掉 Codex/Claude Code 窗口即可。在跑的审批 token 会自动过期(`token_expire_minutes` default 5 分钟 · hard ceiling 10)。若你在中途暂停了一个 guarded 步骤,下次需要**手动 resume**(token 状态机的 resume 路径属 W3 实施层 · 当前 stub 阶段不保证自动续期)。
