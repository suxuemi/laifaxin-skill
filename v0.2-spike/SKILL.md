---
name: laifaxin-outreach-v0.2
description: Supervised browser spike (alpha) for Laifaxin (来发信) - Codex CLI orchestrated + computer-use plugin executed customer prospecting · Translates spec /Users/tony/Work/01_Data/03_laifaxin-docs/specs/active/2026-06-17-laifa-browser-agent-v0.2.md into a Codex-callable workflow · 主路径:输入产品 → AI 推演 → 翻页判精度 → 动态决定保存范围 → 保存 + 打标签 · 不用 AI 评分 · 用户必须在场监控 · session 用用户自登录账户
---

# Laifaxin Outreach v0.2 · Supervised Browser Spike (alpha)

> ⚠️ **alpha 阶段 · 高风险 · 必须用户在场监控 · 用户真账户 · 不保证 SLA**
> 设计依据:`specs/active/2026-06-17-laifa-browser-agent-v0.2.md`(本仓本地 · 同步前)
> 安全模型:`safety-gates.md`(本目录)
> 决策框架:`decision-prompts.md`(本目录)
> 执行 runners:`runners/`(本目录 · W3 实施)

## 触发场景

只在以下场景启用本 skill:
- 用户说"用来发信跑 X 产品的客户开发"
- 用户说"启动浏览器 agent 帮我开发外贸客户"
- 用户明确开启 `--mode=browser-spike` 标志

## 7 项硬铁律(违反任意一条立即停)

| # | 规则 | 出处 |
|---|---|---|
| 1 | **用户必须在场监控**(整个 run 期间 Chrome 必须前台 + 用户能介入) | spec § 2.1 |
| 2 | **不主动点击 AI 评分按钮**(Tony § 0 #8)· 主路径用翻页 | spec § 5 |
| 3 | **不点击永久 block 列表里的按钮**(发送 / 激活 / 删除 / 导出 / 黑名单 / 退订 / 拒收 / 举报 / 启用 / 启动 等)· 详见 `safety-gates.md` | spec § 4.1 |
| 4 | **危险动作(保存 / 提交)必须 one-time approval token**(用户当场签发 · 用后作废)· 详见 `safety-gates.md` § token | spec § 4.2 |
| 5 | **变量占位符 `{联系人:名称}` 必须用来发信【插入变量】按钮替换** · 严禁字面字符串发出 | v0.1 references/09 |
| 6 | **写回 audit 数据**:每个 run 必填 `~/.codex/runs/<run_id>/run.json + summary.md + artifacts.json` · screenshots / llm_logs 不入 repo | spec § 6 |
| 7 | **完成性铁律**:用户指定保存 N 公司时 · 必须逐家完成 · 严禁"...同上..."省略 | v0.1 references/04 § 6 |

## 主流程(7 步 deterministic + 3 LLM 节点)

```
1. 启动 + session 检查(Chrome 已登录 web.laifaxin.com)
2. 输入产品 → 点 AI 推演 → 读 4 客群卡片
3. LLM 节点 1:选客群(读历史 dead 档案避坑)→ Confirm 闸 1
4. 进入搜索结果 → 翻页 sequential
5. LLM 节点 2(每页):当前页 ≥ 70% 对口?→ 累积或定边界
6. 找到边界 K 页 → 保存范围 = (K-1) × 10 公司 × 5-10 邮箱/家 → Confirm 闸 2 + Token
7. 执行保存 → 写回 run.json + summary.md
```

跨 run 场景:
```
LLM 节点 3:客户回信 → 询盘 / OOO / 转介 / 拒绝 / 待定 → 打标签 → sequence 自动过滤
```

## 关联

- spec(待发):`specs/active/2026-06-17-laifa-browser-agent-v0.2.md`(本仓)
- safety-gates(本目录)
- decision-prompts(本目录)
- runners(本目录 · W3 实施)
- v0.1 包(已发):[github.com/suxuemi/laifaxin-skill](https://github.com/suxuemi/laifaxin-skill)
