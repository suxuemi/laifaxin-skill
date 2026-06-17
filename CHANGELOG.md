# Changelog

All notable changes to `laifaxin-outreach` skill package.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

待版本号定版后从 Unreleased 移到具体版本。

## [0.1.0] - 2026-06-16

初版骨架 · 提交 Codex 对抗审查 r1 → 大改回灌 → r2 验证。

### Added

- `SKILL.md` · Anthropic Claude Code skill 入口 + 触发分诊 + 产品级硬规则 vs 写作策略默认值分层 + 旧名映射表
- `README.md` · 发布说明 + 5 分钟验收引导 + 数据来源
- `references/00-workflow-overview.md` · 5 段总览(搜 → 析 → 写 → 排 → 推)
- `references/01-customer-search.md` · 来发信 AI 数据库三种搜法 + 黄金原则(客户产品词 vs 自己服务词)+ 客户类型词库
- `references/02-company-profile-schema.md` · 公司资料 5 必填 + 5 推荐 + Noodle House 示范
- `references/03-benchmark-analysis.md` · 标杆画像 6 维 + 推荐 / Fallback 两档
- `references/04-email-sequence-rules.md` · 长提示词结构化拆解(优先级 / 呼吸感公式 / 视觉层级 / 9 策略 / 3 钩子原型 + 客户端兼容性矩阵 + fallback / 极简 / 三阶段交付 / 完整性铁律)
- `references/05-first-round-rules.md` · 首轮专属(≤100 词 / 1 CTA / 1 价值点)+ Noodle House 真实样例拆解 + 与 04 默认值的差异显式表
- `references/06-reply-playbook.md` · 回复推进 6 场景 SOP(转介 / 竞品 / 样品异议 / 报价 / OEM 多行业泛化 / 算年度账)
- `references/07-laifaxin-plan-setup.md` · 来发信端落地(模板目录 / 命名 / 时间间隔 / 高级规则 7 项 / **§ 7.5 发件昵称 vs 正文签名区分** / setup YAML)
- `references/08-prompt-chain.md` · 推荐对话策略 + interrupt handlers + 优先级表
- `references/09-validation.md` · **必读** · 装好后 5 分钟验收(关 1 触发 / 关 2 变量 / 关 3 预览 / 关 4 自发测试)
- `assets/company-profile-template.md` · 公司资料 yaml 输入表
- `assets/benchmark-customer-template.md` · 标杆采集 + 零标杆两条路
- `assets/search-keywords-food-example.csv` · 搜索词池**示例**(食品行业,非通用模板)
- `assets/first-round-template.md` · 输出格式 + 自检表 + 反面 vs 正面对照
- `assets/followup-round-template.md` · 多轮输出 + 8 轮策略递进 + 主题不复读规则
- `assets/reply-recipe-template.md` · 回复推进输出格式 + 6 场景速查
- `LICENSE` · MIT
- `CHANGELOG.md` · 本文

### Adversarial Review

- **r1**(2026-06-16):Codex 4 角色对抗审查 → 🔴 大改 · Top 5 必修硬伤
- **r1 回灌**(2026-06-16):14 文件改 + 1 新建 + 1 重命名,逐条对应 r1 Top 5 + 多项 🟡
- **r2**(2026-06-16):Codex 二轮验证 → 🟡 小修后发 · ★★★☆☆ · Top 3 + 5 项 🟡
- **r2 回灌**(2026-06-16):12 处再修(fallback 残留 / 占位符防呆 / 验收兼容性 / handoff / 多行业 OEM 等)
- **r2 回灌后自检**:无残留(没标杆拒写 / csv 旧名 / 占位符无注解 三项 grep 清零)
- **r3**(2026-06-16):Codex 三轮验证 → 🟡 还要小修 · 3 必修(repo 私有引用 / A/B fallback 口径 / 公司资料拒写残留)+ partial
- **r3 回灌**(2026-06-16):9 处收尾(README 三邮箱收紧 / 发布元数据更新 / 完整旅程时间预期 / 占位符 inline 显式铺满 / 09 关 1 路由描述纠正 / 公司资料反问替代拒写 / 08 伪代码 analyzing_fallback 分支补完 / 04 § 3 实战做法去重 / 09 Outlook fallback 口径与 04 对齐)
- **审查脱离 vault 后**:CHANGELOG 不再链 `raw/inbox/...` 私有路径;skill 包独立可分发

### Knowledge Sources

- 来发信现行产品文档:https://www.laifa.xin/zhinan/
  - refine-search-all · ai-rating-guide · email-sequence-guide · email-templates · 00-quickstart-10min · 03-save-customers
- 原素材:`41_laifa_xiaping/来发信使用教程完整版/`
  - 3 个教学视频 · 智能跟进计划 PNG · 序列邮件设置文本(公司资料 / 长提示词 / 真实首轮模板 / AI 对话语句 / 邮件教程图)
- 兼容性事实源:[Gmail CSS support](https://developers.google.com/workspace/gmail/design/css)
- skill 包规范:[Claude Code Skills 官方文档](https://code.claude.com/docs/en/skills)
