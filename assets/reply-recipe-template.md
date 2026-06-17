# 回复推进 · 输出模板

> 用户给一段客户回复 → skill 按本模板输出。严守 `references/06-reply-playbook.md` 6 场景分类。

## 输出格式(逐回复一份)

````markdown
## 回复推进 · 收件 [日期]

```yaml
classification: scenario_3       # 1 转介 / 2 竞品 / 3 样品异议 / 4 报价 / 5 OEM / 6 算账
confidence: high                 # high / medium / low(只够标 1 个场景吗?)
mixed_scenarios: []              # 若混合,把次要场景列出
next_goal: "锁年采购量 + 出对路样品清单"
required_internal_info:          # 操作者发出前要准备的内部数据
  - "查样品成本表"
  - "确认到付物流商账号"
risks:
  - "客户可能借机要更多样品 → 锁 SKU ≤ 5"
  - "如果客户不在亚太,运费可能 > 样品价 → 用试订单切换"
```

### 英文回复稿

```html
<p>Hi [客户名],</p>

<p>[场景对应应对 - 见 06-reply-playbook]</p>

<p>[CTA - 1 个,最多 yes/no 二选一]</p>

<p>Alex</p>
```

### 中文备注(不发给客户 · 给操作者看)

- 策略意图: [你这封回信想达成什么]
- 关键句解读: [对方哪句话暴露了什么信号]
- 如对方继续 push: [下一步怎么应对]
- 如对方不回: [何时 / 怎么追]
````

## 6 场景模板速查

| 场景 | 何时用 | 关键句结构 |
|---|---|---|
| 1 转介 | "I'm not the right person, please contact X" | "X kindly referred me to you" |
| 2 竞品 | "We currently use [品牌]" | 反问 2 个 qualifier · 不当场对比 |
| 3 样品异议 | "Can you send free samples? Who pays shipping?" | 锁 5 题问卷 · 或切试订单 |
| 4 报价 | "Send your price list" | 反问 2 个 qualifier · 只报相关 SKU |
| 5 OEM/定制 | "We need our own brand" | 3 阶段路径(现成 → 贴牌 → 定制)· 按品类调:食品=库存 SKU / CNC=标准件 / LED=现成型号 / 化工=现成配方 · 从 Stage 1/2 起手 |
| 6 算账 | 多次提价格 | 算年度节省 $Z · 试 1 柜验证 |

## 自检表

```yaml
self_check:
  scenario_classified: true
  next_goal_explicit: true       # next_goal 不能写"继续跟进"
  cta_count: 1                   # 严格 1(yes/no 算 1)
  word_count_reply: ___          # ≤ 150
  has_pricelist_dump: false      # 不要直接发完整 price list
  has_data_objectivity: ___      # 涉及数字必须可解释
  has_chinese_notes: true
  has_risks: true                # 必须列至少 1 个风险
```

## 反面教材

❌ 用户回 "I'm not the buyer, contact procurement@..." → skill 写一封长信给原回信人感谢他们的"宝贵反馈" — **浪费机会**,直接给 procurement@ 写新 thread
❌ 用户回 "Send price list" → skill 把全 SKU 报价表照 dump — **直接发完整 price list 就没了 thread**
❌ 用户回 "We need OEM" → skill 直接说"我们可以做" — **没锁 MOQ 等于没说**
❌ 用户回竞品对比 → skill 当场写 10 维度大表 — **客户不会看**
