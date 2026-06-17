# 标杆客户采集表 · skill 输入

> 1-2 个**对口的真实客户**(已成交 / 询过盘 / 网站完美匹配)。
> **没标杆?两条路**:推荐模式 → 5-10 分钟去找(详见下文"路 A");时间紧 → Fallback 模式跑通(详见下文"路 B" · 回复率较弱 · 拿到第一批回复后切回推荐)。

```yaml
benchmarks:
  - id: "benchmark-1"
    website: ""              # 必填 · 客户官网
    company_name: ""         # 必填 · 公司名
    country: ""              # 必填
    customer_type: ""        # 必填 · wholesaler / distributor / retailer / brand / OEM ...

    # 以下二选一即可:about_text(粘 About Us 全文) 或 about_url(让 AI 自取)
    about_text: |
      ...

    # 进阶
    why_target: ""           # 你为什么选这家做标杆(对口在哪)
    known_decision_maker:    # 已知决策人(若有)
      name: ""
      title: ""
      linkedin: ""
    known_pain_points:       # 你听说 / 推测他们正头疼的事
      - ""

  - id: "benchmark-2"
    website: ""
    ...
```

## 填写示范

```yaml
benchmarks:
  - id: "benchmark-1"
    website: "https://www.asianfoodwholesalers.com.au"
    company_name: "Asian Food Wholesalers Pty Ltd"
    country: "Australia"
    customer_type: "Nationwide Asian food wholesaler"
    about_text: |
      Asian Food Wholesalers is one of Australia's largest importers and distributors
      of authentic Asian groceries · supplying supermarkets, restaurants, and Asian
      grocers across Sydney, Melbourne, Brisbane and Perth · over 5,000 SKUs from
      China, Thailand, Vietnam, Korea and Japan ...
    why_target: "他们家的 SKU 覆盖正好契合我家面食 + 调味产品线"
    known_decision_maker:
      name: null
      title: "Category Manager - Dry Goods"
      linkedin: null
    known_pain_points:
      - "亚洲面食品牌同质化严重"
      - "Halal 合规对越南 / 印度社区分销很关键"
      - "圣诞 / 春节旺季备货周期紧"
```

## 没标杆怎么办 · 两条路

### 路 A · 先去找(推荐 · 5-10 分钟)

1. 在来发信 [AI 数据库](https://web.laifaxin.com/search/refine-search) 用 AI 推演 → 选客群 → 列表里挑 2-3 个**网站做得最像样**的
2. 或者 LinkedIn 搜行业 + 国家 + 角色 → 翻 Company Page → 挑有完整 About 的
3. 哪怕用 [Google 搜索](https://www.google.com) "best [产品] [国家] distributor" 也行 — 重点是有真实可分析的官网

### 路 B · Fallback 模式(零标杆 · 跑通就行)

如果你时间紧 / 这就是第一次试 skill,**告诉 skill "用 fallback 模式 / 零标杆"**:

- skill 会跳过 6 维客户画像
- 让你给:产品 + 目标国家 + 目标客户类型 + 你的 USP + 1 个 **你猜他们最在乎的痛点**
- 只出 1-2 个**通用首轮**(不出整个 3-5 模板矩阵)
- 中文备注会显著标注"⚠️ fallback 模式 · 回复率较弱 · 拿到第一批回复后挑客户做标杆切回推荐模式"

详见 `references/03-benchmark-analysis.md § Fallback 模式`

## 常见自检

- 选的标杆和你产品方向**真的对口**吗?(对路 = 他们网站上能找到你做的品类)
- About 是不是只有一句话?(太短 → 换一家或扒 LinkedIn About)
- 是不是选了**你的同行**?(同行不是标杆 · 标杆是潜在客户)
