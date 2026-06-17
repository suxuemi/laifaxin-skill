# 01 · 搜客户 · 三种搜法 + 词池扩展

## 黄金原则(必守)

> 自己**服务词**(如 `CNC Machining`)→ 找到的是 **同行**
> 客户**产品词**(如 `Drone Frame`)→ 找到的是 **金主**

来源:[laifa.xin/zhinan/refine-search-all](https://www.laifa.xin/zhinan/refine-search-all) "二、AI 推演"

## 三种搜法(全部在来发信 AI 数据库内)

入口:登录 [web.laifaxin.com](https://web.laifaxin.com) → 搜客引擎 → AI 数据库

### 搜法 A · 英文产品词搜索 + 词池扩展

1. 用 **客户卖的产品**(不是你做的)的英文词搜
2. 看搜索结果里高匹配公司的简介,提取**客户类型词**(如 `Nationwide Asian Food Wholesaler`)
3. 把类型词再翻成英文继续搜 → 滚雪球扩词

### 搜法 B · 客户网址直搜

输入已知客户域名(如 `www.asianfoodwholesalers.com.au`)→ 系统返回**相似或同类客户**。

适用场景:
- 展会名录 / 客户名片有客户官网
- 询盘客户官网(用一个真实询盘客户扩出一批)

### 搜法 C · AI 推演

不知道客户类型时:点搜索框右侧 **AI 推演** → 输入产品名 → 系统列出客群卡片(含推荐理由)→ 选最匹配的进入。

推得不准时 → 去 **方案库** 编辑产品方案,填:产品名 / 用途 / 客户类型 / 应用场景 → 重新推演。

来源:[laifa.xin/zhinan/refine-search-all L101-138](https://www.laifa.xin/zhinan/refine-search-all)

## 客户类型词库(skill 内置启发,按产品行业扩)

通用维度:

| 维度 | 候选词 |
|---|---|
| 供应链角色 | wholesaler / distributor / retailer / importer / brand / OEM / contractor / installer / e-commerce-seller / designer / system-integrator / agent |
| 地域+规模 | Nationwide / Regional / Local / Online |
| 渠道 | Online supermarket / E-commerce platform / Brick-and-mortar |
| 业务垂直 | 行业前缀,如 `Asian Food` / `LED Outdoor` / `Premium Pet` |

组合模板:`[地域]` + `[业务垂直]` + `[供应链角色]`
例:`Nationwide Asian Food Wholesaler` / `Regional LED Outdoor Distributor` / `Online Premium Pet Retailer`

## skill 输出格式

收到用户产品 + 目标地区后,skill 应输出:

```yaml
search_keywords:
  english:
    - "Nationwide Asian Food Wholesaler"
    - "Regional Asian Food Distributor"
    - "Online Asian Grocery Importer"
  chinese:                       # 给用户中文确认 / 沉淀到 csv
    - "全国性亚洲食品批发商"
    - "区域性亚洲食品分销商"
    - "亚洲食品在线进口商"
  derived_terms:                 # 二级扩展(看了搜索结果再加)
    - "ethnic food wholesaler"
    - "specialty Asian food importer"
  reverse_url_examples:          # 若用户已知 1-2 个客户网址,放这里供搜法 B
    - "https://www.asianfoodwholesalers.com.au"

next_actions:
  - "去 https://web.laifaxin.com/search/refine-search 把英文词逐个跑"
  - "高匹配公司用'找相似'裂变"
  - "把结果导出后用 AI 评分 60+ 筛"
```

## 来发信操作衔接(给用户的下一步指令)

1. 登录 https://web.laifaxin.com/search/refine-search
2. 用上述英文词逐个搜 · 或开 AI 推演直接输产品名
3. 抽样判精度:跳到第 500 页 / 997 页,前者 70%+ 对口就保存(参 [laifa.xin/zhinan/quick-start-laifaxin-10min](https://www.laifa.xin/zhinan/quick-start-laifaxin-10min))
4. 设产品档案 → 列表 AI 评分 60+ → 打标签保存(标签公式:`语言-国家-产品-角色`)
5. 进入 reference `03-benchmark-analysis.md` 选 1-2 个对口客户做画像
