# ⚠️ Laifaxin Outreach v0.2-alpha · Supervised Browser Spike

> **alpha 阶段 · 高风险 · 用户必须在场监控 · 用户真账户 · 不保证 SLA · 勿生产用**

这个分支(`spike/v0.2-alpha`)是 v0.1.0 SOP 包的**实验性升级方向** ——
让 Codex CLI(配 `browser-use` / `computer-use` plugin)真的在浏览器里跑客户开发流程,
而不是停在"生成提示词让用户手动操作"。

## 是什么 / 不是什么

| ✅ 是 | ❌ 不是 |
|---|---|
| 设计文档(SKILL / safety-gates / decision-prompts / runners stub / HOW-TO-START)| 可直接运行的 v0.1.0 软件包 |
| Codex CLI 编排 + computer-use plugin 看屏幕(macOS a11y + screenshot)+ browser-use 辅助(URL/title 上下文)| 浏览器自动化 SaaS / 无人值守 24h agent |
| **主路径不用 AI 评分 · 翻页判精度 + 动态保存范围**(Tony § 0 #8 #9)| AI 评分 / 自动激活 / 自动发邮件 |
| Scope 严格限定:段 1 客群推演 + 段 2 翻页保存 | 邮件模板 / 智能跟进 / 邮件群发 / 回信处理(scope out) |
| 必须用户在场监控 · token 闸防误操作 | 端到端无人值守 |

## 5 项入口硬铁律(违反任意 = 立即 stop · 详见 `v0.2-spike/SKILL.md` § 2)

1. 用户必须在场监控
2. scope 越界 = 立即 stop + alert(进入 sequence / template / AI 评分 / 发送等 out_of_scope 模块)
3. 永久 block 列表的按钮任何情况不点(发送 / 激活 / 删除 / 导出 / 黑名单 / 退订 等)
4. Guarded 动作必须 one-time approval token(5 分钟有效 · 单次使用)
5. 登录失效 / 验证码 / 反爬 / 权限弹窗 = pause + alert(不得自恢复)

## 主流程(对齐 `v0.2-spike/decision-prompts.md` 最新 canonical)

```
1. 用户启动 → 输入产品 → 点 AI 推演
2. LLM 节点 1 选客群 → Confirm 闸 1
3. 翻页 sequential · 每翻一页调用 LLM 节点 2:
   - 当前页 ≥ 0.80 → 翻下一页
   - 0.60-0.80 中间 → 翻下一页(不停)
   - 单页 < 0.60 → 翻下一页确认
   - 双页连续 < 0.60 → boundary 确认 · 保存范围 = (boundary_page) × 10 公司
4. Confirm 闸 2 + token → 保存 + 打标签(5-10 邮箱/家)
5. 写回 run.json + summary.md + artifacts.json
```

## 启动需要

- Codex CLI ≥ 0.140.0-alpha.2 + `browser@openai-bundled` + `browser-use@openai-bundled` + `computer-use@openai-bundled` 全 enabled
- 来发信账户已登录(`https://web.laifaxin.com`)+ Chrome 不必前台,但用户 watching
- 已读 v0.1 SOP 包(`main` 分支)
- 已读本目录 `v0.2-spike/HOW-TO-START-SPIKE.md` 完整 runbook

## v0.1 vs v0.2-alpha

| 维度 | v0.1.0(main 分支)| v0.2-alpha(本分支)|
|---|---|---|
| 形态 | SOP 文档包(用户手动配置)| 浏览器 agent 设计(W3+ 实施)|
| 风险 | 低 | 高(用户真账户)|
| SLA | 不保证(SOP 性质)| 不保证(alpha)|
| 适用 | 普通用户 | 内部 dogfood / Tony 自用 |
| 安装 | `git clone -b main` | `git clone -b spike/v0.2-alpha` |
| 触发优先级 | 大多数场景 | 仅用户明确说"在来发信网页里实际操作搜客 / 翻页 / 保存" |

## 文件清单

```
v0.2-spike/
├── SKILL.md                    ← Skill 入口 · 5 铁律 + trigger precedence + 主流程
├── safety-gates.md             ← 三层语义白名单 + token 流(待 W3 落地)+ 失败矩阵
├── decision-prompts.md         ← 3 LLM 节点 · output contract + repair retry + 统一 audit
├── HOW-TO-START-SPIKE.md       ← 实战启动 runbook(预飞 + smoke test + 紧急停 + 回灌)
└── runners/
    └── README.md               ← prospect.py 伪 API(stub · W3 实施)
```

## 设计依据

完整 spec(已归档):主仓 `specs/done/2026-06-17-laifa-browser-agent-v0.2.md`
关键决策回顾:主仓 `wiki/history/2026-06-laifa-browser-agent-v0.2-design.md`

经历:r1 🔴 大改 → v2 重写 → r2 🟡 → v3 重写 → r3 🟡 + Tony 10 项拍板 → r4 deep-review 逐文件(safety + decision + SKILL + HOW-TO-START 各 r1/r2 全部回灌)

## 不要做

- ❌ 不要直接照本分支文件实施 · 这是 design + stub · W3 才落地 runners/prospect.py
- ❌ 不要在 main 分支用 v0.2 · 它们是两条 release channel
- ❌ 不要把 spike runs 数据 push 到本仓(screenshots / llm_logs 已 gitignore)
- ❌ 不要承诺 24h 无人值守 / 端到端 agent 任何对外表述
