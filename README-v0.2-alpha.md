# ⚠️ Laifaxin Outreach v0.2-alpha · Supervised Browser Spike

> **alpha 阶段 · 高风险 · 必须用户在场监控 · 用户真账户 · 不保证 SLA · 勿生产用**

这个分支(`spike/v0.2-alpha`)是 v0.1.0 SOP 包的**实验性升级方向** ——
让 Codex CLI(配 `browser-use` / `computer-use` plugin)真的在浏览器里跑客户开发流程,
而不是停在"生成提示词让用户手动操作"。

## 是什么 / 不是什么

| ✅ 是 | ❌ 不是 |
|---|---|
| 设计文档(SKILL.md / safety-gates.md / decision-prompts.md) | 可直接运行的 v0.1.0 软件包 |
| Codex CLI 编排 + computer-use plugin 看屏幕点击 | 浏览器自动化 SaaS |
| 主路径不用 AI 评分 · 翻页判精度 + 动态保存范围 | 自动激活 / 自动发邮件 |
| 必须用户在场监控 · token 闸防误操作 | 无人值守 24h agent |

## 7 项硬铁律(违反任意一条立即停)

1. 用户必须在场监控
2. 不主动点 AI 评分按钮
3. 不点永久 block 按钮(发送 / 激活 / 删除 / 导出 / 黑名单 / 退订 等)
4. 危险动作必须 one-time approval token
5. `{联系人:名称}` 变量必须用编辑器【插入变量】按钮替换
6. 每个 run 必填 audit
7. 完成性铁律(不省略)

详见 `v0.2-spike/SKILL.md`。

## 启动需要

- Codex CLI ≥ 0.140.0-alpha.2 + `browser-use@openai-bundled` + `computer-use@openai-bundled` plugin
- 来发信账户已登录 + Chrome 前台
- 用户在场监控
- 已读 v0.1 SOP 包(`main` 分支)

## v0.1 vs v0.2-alpha

| 维度 | v0.1.0(main) | v0.2-alpha(本分支)|
|---|---|---|
| 形态 | SOP 文档包(用户手动配置)| 浏览器 agent(Codex 执行)|
| 风险 | 低 | 高(用户真账户)|
| SLA | 不保证(SOP 性质)| 不保证(alpha)|
| 适用 | 普通用户 | 内部 dogfood / Tony 自用 |
| 安装 | `git clone -b main` | `git clone -b spike/v0.2-alpha` |

## 设计依据

完整 spec 在主项目仓内(私有 vault):
`specs/done/2026-06-17-laifa-browser-agent-v0.2.md`

3 轮 Codex 对抗审查记录 + Tony 10 项拍板汇总。
