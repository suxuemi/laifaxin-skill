# 07 · 来发信端操作约束

> 上面 6 篇 reference 教 AI 怎么"想"。本篇是 AI 出完邮件后,**用户在来发信 web 上怎么配**才能跑起来。

权威源:[laifa.xin/zhinan/email-sequence-guide](https://www.laifa.xin/zhinan/email-sequence-guide)

## 1 · 邮件模板目录(必先建)

入口:来发信 → 设置 → 邮件模板

**目录命名约定**(从教程视频提炼):
```
01-<产品/客群短名>     例: 01-面食-NA-distributor
02-<产品/客群短名>     例: 02-面食-EU-distributor
03-<产品/客群短名>     例: 03-面食-AU-distributor
```

**为什么编号开头**:目录会按字母 / 数字排序,加 `01 / 02 / 03` 强制顺序便于扫读。

## 2 · 模板命名约定

进每个目录后,模板按这个格式命名:

```
<轮次>-<策略号>-<模板字母>-<钩子类型>
例: R1-S8-A-Resource   = 第 1 轮 · 策略 8 交期 · 模板 A · 资源钩子
例: R2-S2-B-Insight    = 第 2 轮 · 策略 2 降本 · 模板 B · 洞察钩子
```

## 3 · 智能跟进计划结构

入口:来发信 → 邮件营销 → 智能跟进计划

**计划名**:`YYYY-Q季度-市场-客群类型`
例:`2026-Q2-NA-asian-food-distributor`

**发送通道**:**优质通道**(默认强推)。自己邮箱只做回复后的 1-on-1。

**计划时间窗口**:按目标客户所在时区的工作时间设置。

## 4 · 跟进步骤(轮次)与时间间隔

来发信 web 上每个"跟进步骤" = 你的一轮。步骤内可挂**多模板 A/B/C**(系统随机用 → 更自然)。

**时间间隔建议**:

| 间隔 | 适用 |
|---|---|
| 加入计划后立即 | 第 1 步 |
| 上一步后 3-5 天 | 第 2 步 |
| 上一步后 4-7 天 | 第 3 步 |
| 上一步后 7-10 天 | 第 4 步及之后 |

> 永远不要连续天数 < 3 天 — 看着像群发轰炸

## 5 · 高级规则(7 块必配)

来源:[laifa.xin/zhinan/email-sequence-guide § 三 · 3](https://www.laifa.xin/zhinan/email-sequence-guide)

| 块 | 推荐配置 | 为什么 |
|---|---|---|
| 邮件追踪 | ✅ 全开 | 没数据无法复盘 |
| 发信昵称 | `[Your Name] from [Company]` | 真实身份避免群发感 |
| 计划 24h 上限 | 客户总数 / 计划天数 | 别一天打光 |
| 单域名 24h 上限 | **2 或 3** | 防同公司打扰 |
| 公司触发器 | **"标记其他联系人为未发送"** | 一人回复就停同公司其他 |
| 已完成触发器(回信即停)| ❌ **不勾选** | OOO / "thanks" 误触发停整计划 |
| 未发送触发器 | ✅ 3 项全开(无效邮箱 / 黑名单 / 指定标签) | 省点数 + 不误发 |
| AI 触发器 | ✅ 开 | 风险邮件延迟 24h 重试 |

> ⚠️ 改完**一定要点右上角【保存】**(常见漏点)

## 6 · 加客户 + 激活

1. 用 `按标签` 批量添加(标签公式:`语言-国家-产品-角色`)
2. 添加后**右上角开关变蓝** = 真激活(易漏点)

## 7 · 监控 4 个 Tab

| Tab | 看什么 |
|---|---|
| 报告 | 发送 / 送达 / 阅读 / 回复 总体 |
| 邮件 | 单封状态 / 阅读时间 / 点击 |
| 记录 | 操作时间线(排查问题)|
| 列表页 | 跨计划对比 |

## 7.5 · 发件昵称 vs 正文签名 · 两个不同的东西

> 这是用户最容易混的一对设置,**单独拎出来讲**。

| 维度 | 发件昵称(系统层 · 高级规则 → 发信昵称)| 正文签名(邮件最后那行)|
|---|---|---|
| 在哪 | 来发信"高级规则 → 发信昵称"字段 | 你 HTML 正文最后一段 `<p>Alex</p>` |
| 收件人看到 | "From: **Alex from NoodleHouse**" `<noreply@xxx.com>` | 邮件正文末尾签 `Alex` |
| 推荐值 | **最低**:真实英文名(如 `Alex`)· **更自然**:`Name from Company` 形式(如 `Alex from NoodleHouse`) | **只英文名** `Alex` |
| 为什么 | 收件箱"发件人"列要显示真实身份,避免"Unknown sender"被秒删 | 正文签名极简 = 零营销感避垃圾过滤器 |
| 反例 | 写"销售部" / "Marketing Team" — 客户看到秒删 | 巨型签名(公司+电话+网址+地址) — 进垃圾 |

出处:[laifa.xin/zhinan/email-sequence-guide L257-260](https://www.laifa.xin/zhinan/email-sequence-guide) "发信昵称应写真实业务身份,例:`Tina from ABC Corp`" · 仓内另一处也允许"填你的英文名"(见 [docs/zhinan/04-email-marketing.md L212](https://www.laifa.xin/zhinan/04-email-marketing)),口径为**至少英文名,自然时加公司**。

## 8 · skill 输出对接

skill 出完邮件后,要顺带告诉用户:

```yaml
laifaxin_setup:
  template_folder: "02-面食-EU-distributor"

  templates_to_create:
    - name: "R1-S8-A-Resource"
      subject: "Kayaks in France next week? 🛶"
      html_body: "...(详见生成结果)"
    - name: "R1-S8-B-Insight"
      ...

  sequence_plan:
    plan_name: "2026-Q2-EU-asian-food-distributor"
    channel: "优质通道"
    timezone_window: "Mon-Fri 09:00-17:00 GMT+1"

    steps:
      - round: 1
        trigger: "加入计划立即"
        templates: ["R1-S8-A-Resource", "R1-S8-B-Insight", "R1-S8-C-Qualification"]
      - round: 2
        trigger: "上一步后 4 天"
        templates: ["R2-S2-A-Insight", "R2-S2-B-Insight"]
      - round: 3
        trigger: "上一步后 5 天"
        templates: ["R3-S9-A-Resource"]

    advanced_rules:
      track: true
      sender_nickname: "Alex from NoodleHouse"
      daily_limit_per_plan: 200
      daily_limit_per_domain: 3
      company_trigger: "mark_others_as_unsent"
      completion_trigger_on_reply: false   # ⚠️ 必关
      unsent_triggers: [invalid_email, blacklist, tag:已成交]
      ai_trigger: true

    contacts_to_add:
      tag: "en-FR-asian-food-distributor"
```

用户照着在 web 上点 · 全程不超过 30 分钟。

## 反面教材

❌ 模板乱命名(`Test1 / Test2 / 新模板`)→ 半年后看不懂哪个对哪个
❌ 没建目录就建模板 → 全堆在根,挑模板时翻不到
❌ "已完成触发器"默认开了 → OOO 一封就停整个客户后续 8 轮
❌ 单域名上限留默认 → 一天发同公司 10 个人 → 客户怒投诉
❌ 加完客户忘按右上角开关 → 一周后回来发现 0 发送
