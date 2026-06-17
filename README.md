---
name: laifaxin-outreach
title: Laifaxin Outreach · 外贸开发信 + 来发信跟进计划 · skill 包
type: meta
status: draft
version: 0.1.0
created: 2026-06-16
updated: 2026-06-16
tags: [skill-package, outreach, b2b, foreign-trade, laifaxin, public-release]
description: 对外发布版 skill 包 · 覆盖外贸主动开发完整链路(搜客户 → 标杆分析 → 首轮邮件 → 多轮序列 → 回复推进)· 输出直对接来发信 AI 数据库 + 智能跟进计划 + 邮件模板系统
---

# Laifaxin Outreach · AI-assisted outreach SOP 包

> 外贸主动开发 + 来发信跟进计划 一体化 Claude Code / Anthropic Skill 包。
> **目标用户**:做外贸主动开发的业务员 / 创始人 / 团队;已在使用来发信(www.laifa.xin)做客户搜索 + 智能跟进。

## ⚠️ 是什么 / 不是什么(请先读)

| ✅ 这个 skill **是** | ❌ 这个 skill **不是** |
|---|---|
| AI 军师 + 文档生成器 — 帮你出搜索词 / 客户画像 / 邮件模板 / 跟进计划配置清单 / 回复脚本 | 端到端 agent — 不会自动登录 / 点击 / 录入来发信网页 |
| 配合 [来发信](https://www.laifa.xin) 使用的 SOP 包,降低你写 prompt + 配模板 + 排序列的认知成本 | 来发信本身的替代品 |
| 9 篇 references + 6 个 assets + 5 段工作流 + 3 轮 Codex 对抗审查过的 SOP | 浏览器自动化 / 客户邮件代收发系统 |
| 你拿 skill 输出去**在来发信网页上手动配置**(模板录入 / 计划激活 / 加客户)| 让客户回信自动转换成询盘的魔法 — 回信后 skill 帮你写回复稿,**点发送的是你** |

**为什么这样设计**:来发信是纯 web · 无对外 API · 因此 skill 在"打前"(出搜索词 / 出邮件模板 / 出跟进配置清单)和"打后"(吃客户回信 / 出推进策略)两端做事,中间所有网页操作由用户手动完成。这是当前架构的真实边界。

## 这个 skill 解决什么

主动开发外贸客户的实际痛点不是"写一封邮件",而是这整条链:

```
搜客户 → 分析客户 → 写首轮 → 排多轮序列 → 推回复
```

本 skill 把每一段沉淀成可执行 SOP,**不需要用户再去拼超长 prompt** · 不需要每次都重新设计跟进节奏 · 不需要在多个客群上手动复制黏贴。

## 文件结构

```
laifaxin-outreach/
├── README.md             ← 本文
├── SKILL.md              ← 触发分诊 + 执行约束(skill 引擎读这个)
├── references/           ← 9 篇规则 / SOP / 知识
│   ├── 00-workflow-overview.md
│   ├── 01-customer-search.md
│   ├── 02-company-profile-schema.md
│   ├── 03-benchmark-analysis.md
│   ├── 04-email-sequence-rules.md
│   ├── 05-first-round-rules.md
│   ├── 06-reply-playbook.md
│   ├── 07-laifaxin-plan-setup.md
│   └── 08-prompt-chain.md
├── references/
│   └── 09-validation.md           ← 5 分钟验收 SOP(必跑)
└── assets/               ← 模板 / 输入表 / 输出格式
    ├── company-profile-template.md
    ├── benchmark-customer-template.md
    ├── search-keywords-food-example.csv
    ├── first-round-template.md
    ├── followup-round-template.md
    └── reply-recipe-template.md
```

## 怎么用

### 1. 安装(2 分钟)

把 `laifaxin-outreach/` 整个目录放进项目 `.claude/skills/` 或全局 `~/.claude/skills/`。重启 Claude Code。

> Claude Code skill body 与 supporting files 都是**按需加载**(不是全量塞上下文),9 reference + 6 asset 不会拖慢 token 消耗。
> 出处:[Claude Code Skills 官方文档](https://code.claude.com/docs/en/skills)

### 2. 5 分钟验收(必跑 · 否则不要批量发邮件)

完整 SOP 见 `references/09-validation.md`。简版 4 步:

1. **触发**:在 Claude Code 说"帮我用来发信找北美亚洲食品分销商,我做手工面" — 应自动加载本 skill,**路由到 `references/01-customer-search.md` 出客户类型词池 + 中英对照**(不是先填公司资料 · 公司资料是写邮件时才要)
2. **变量**:skill 出的邮件里 `{联系人:名称}` 是 **占位符**(不是真变量),必须在来发信编辑器顶部点 **【插入变量】** 选真实字段替换 — **手打无效**
3. **预览**:在来发信邮件模板编辑器点【预览】,看 HTML 渲染对不对(钩子黄底红字 / bullet / 段落空隙)
4. **测试**:给自己邮箱发一封测试(最低 1 个主用客户端 + 1 个非 Gmail 客户端如有,看真实渲染),确认无误再批量发 · 详见 `references/09-validation.md` 关 4

出处:[laifa.xin/zhinan/email-templates](https://www.laifa.xin/zhinan/email-templates) L63 / L68 官方建议。

### 3. 兼容性

本 skill 按 [Claude Code Skills 官方 frontmatter reference](https://code.claude.com/docs/en/skills) 最小集编写(`name` + `description`)。
其他 AI agent runtime 接入需自行测试。

### 4. 单独发布

本目录设计为**可独立复制成 GitHub repo 发布**,内部链接均为相对路径,无外部依赖
(除链接到 [laifa.xin](https://www.laifa.xin) 现行产品文档 + [Claude Code 官方](https://code.claude.com/docs/en/skills) + [Gmail CSS 文档](https://developers.google.com/workspace/gmail/design/css))。

**发布步骤**(0.1.0 → public):

1. 复制本目录(`laifaxin-outreach/`)到新 git repo([github.com/suxuemi/laifaxin-skill](https://github.com/suxuemi/laifaxin-skill))
2. 顶层加 `.github/` 工作流 + issue/PR 模板(本仓不带 · 按目标 repo 风格)
3. `CHANGELOG.md` 的 `[Unreleased]` 段移到具体版本号(参 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/))
4. 创建 git tag `v0.1.0` + GitHub Release
5. 在 README 顶部加发布徽章(可选)

**版本号约定**:[Semantic Versioning](https://semver.org/spec/v2.0.0.html)
- MAJOR · 改 `SKILL.md` 主流程 / 改 references 编号
- MINOR · 加 reference / asset · 加新场景
- PATCH · 修文案 / 修字数 / 改 fallback

**License**:`LICENSE` · MIT

## 数据来源 / 知识库

本 skill 的规则全部基于以下真实素材结构化提取:

| 素材类型 | 出处 |
|---|---|
| AI 数据库 + 智能跟进 + AI 编写邮件 操作流程 | `41_laifa_xiaping/来发信使用教程完整版/` 3 个视频 + 关键帧 OCR |
| 长提示词 + 9 策略 + 钩子原型 | `序列邮件设置/3.提示词.txt` |
| 真实首轮模板 | `序列邮件设置/4.模板1.txt` `5.模板2.txt`(Noodle House 案例)|
| 公司资料字段 | `序列邮件设置/1.公司资料.txt` + `公司简介英文.txt` |
| AI 对话状态机 | `序列邮件设置/6.AI对话语句.txt` |
| 回复推进 playbook | `序列邮件设置/2.邮件教程.jpeg` OCR |
| 来发信产品事实 | [laifa.xin/zhinan/*](https://www.laifa.xin/zhinan/) 现行文档(避开已下线页)|

## 完整旅程时间预期

| 阶段 | 时间 |
|---|---|
| 安装 skill | 2 分钟 |
| 5 分钟验收 | 5 分钟 |
| 收集公司资料 + 标杆客户 | 15-30 分钟(取决于资料是否齐) |
| skill 推搜索词 + 出首轮 3-5 模板 | 5-10 分钟 |
| 在来发信建模板目录 + 录模板 + 配跟进计划 + 高级规则 | 30 分钟(参 `references/07 § 8`)|
| 加客户 + 激活 | 5 分钟 |
| **首次跑通全链路** | **≈ 1-1.5 小时** |
| 后续每个新产品 / 新客群 | 30-45 分钟(复用模板目录)|

## 版本

- `0.1.0` (2026-06-16) — 初版骨架 + Codex 3 轮对抗审查(r1 🔴 大改 / r2 🟡 小修 / r3 🟡 公开发版口径收尾)+ 全部回灌完毕

## 反馈

- 来发信:https://www.laifa.xin
- Issue / PR:(发布时填仓库地址)
