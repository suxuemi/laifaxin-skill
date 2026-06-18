# Laifaxin Outreach v0.2-alpha · 浏览器陪跑

> **一句话**:你打开 [web.laifaxin.com](https://web.laifaxin.com) 登录好,AI 帮你做 ① 输产品选客群 + ② 翻页判精度保对的联系人 —— 你坐旁边看,关键动作要你点 Y。
>
> 配 [Claude Code](https://claude.com/claude-code) 或 [Codex CLI](https://github.com/openai/codex) 都能跑 · 同一份 5 文件。

## 适合谁

| ✅ 你应该用 | ❌ 走 [v0.1 main 分支](https://github.com/suxuemi/laifaxin-skill) |
|---|---|
| "在来发信网页里搜一批食品分销商 · 翻页判对不对 · 保对的" | "帮我写一封开发信 / 排 sequence / 处理回信" |
| 你在场 + 你自己 [来发信](https://www.laifa.xin) 账户 + 接受半监督 | 想要无人值守的 24h 自动化 |
| 想看 AI 怎么在真浏览器里替你干活 | 第一次用来发信 · 还在学 SOP |

> ⚠️ **alpha · 高风险 · 用户必须在场 · 用户真账户 · 不保证 SLA · 勿生产用**

## 2 分钟跑起来

**Claude Code(自动加载)**
```bash
cp -r v0.2-spike ~/.claude/skills/laifaxin-outreach-v0.2
# 重启 Claude Code · 然后说:
# "在来发信网页里帮我搜一批食品分销商 · 翻页判精度 · 保对的联系人"
```

**Codex CLI(手动 @ 引用)**
```
我已登录 web.laifaxin.com · 跑 laifaxin-outreach-v0.2 spike
@v0.2-spike/SKILL.md @v0.2-spike/parameters-defaults.md @v0.2-spike/safety-gates.md
@v0.2-spike/decision-prompts.md @v0.2-spike/HOW-TO-START-SPIKE.md
产品:______ · 客群方向:______
```

完整 install + FAQ → [v0.2-spike/INSTALL.md](v0.2-spike/INSTALL.md)

## 5 项铁律(违反 = 立即 stop · 详见 [SKILL.md § 2](v0.2-spike/SKILL.md))

1. 用户必须在场监控
2. Scope 越界 = stop(进入 sequence / template / AI 评分 / 发送等 out_of_scope 模块)
3. 永久 block 列表的按钮任何情况不点(发送 / 激活 / 删除 / 导出 / 黑名单 / 退订 / AI 评分)
4. Guarded 动作必须 one-time approval token(default 10 分钟有效 · 单次使用)
5. 登录失效 / 验证码 / 反爬 / 权限弹窗 = pause + alert(不自恢复)

## 主流程

```
1. 启动对话确认参数(boundary 阈值 / 保存公式 / token 时长 等 · 详见 parameters-defaults)
2. 输产品 → AI 推演 → 4 客群卡片 → 用户拍板选一个
3. 翻页 sequential · 每页 LLM 节点判精度
   - ≥ boundary_high(default 0.80) → 继续
   - < boundary_low(default 0.60) 连两页 → 停 · 锁 boundary_page
4. 保存范围 = boundary_page × N 公司 × 5-10 邮箱(N 可调)
5. 用户签 token → 真点保存 → 写 run.json + summary.md
```

## Canonical 5 文件

| 文件 | 干嘛 |
|---|---|
| [v0.2-spike/SKILL.md](v0.2-spike/SKILL.md) | 入口 · 触发 + scope + 主流程 + run.json schema |
| [v0.2-spike/parameters-defaults.md](v0.2-spike/parameters-defaults.md) | 所有可调参数 + default + range + frozen |
| [v0.2-spike/safety-gates.md](v0.2-spike/safety-gates.md) | 三层白名单 + token store + safe_click |
| [v0.2-spike/decision-prompts.md](v0.2-spike/decision-prompts.md) | 3 个 LLM 节点 prompt + schema + 修复重试 |
| [v0.2-spike/HOW-TO-START-SPIKE.md](v0.2-spike/HOW-TO-START-SPIKE.md) | preflight + smoke + promote(alpha→beta) |

## 状态

- α.3.4(当前):5 文件互引一致 · runner stub-only · 等 W3 真接 computer-use
- 待 promote 到 beta:见 [HOW-TO-START-SPIKE.md § 6.3](v0.2-spike/HOW-TO-START-SPIKE.md) 4 条硬条件(全部从 `effective_config` 读 · 不硬编码)

## License

MIT · 同 v0.1 main 分支
