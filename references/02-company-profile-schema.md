# 02 · 公司资料字段化 schema

> AI 写不出有切角的开发信,常见根因是用户丢了一段散文式公司介绍。
> 本 reference 把公司资料拆成**结构化字段**,skill 必须先收齐再生成邮件。

## 必填字段(5 项)

| 字段 | 说明 | 用途 |
|---|---|---|
| `company_name` | 公司全称(英文) | 出现在签名 / 首封自报家门 |
| `website` | 官网 URL | AI 可联网时让它"看一眼"补背景 |
| `core_products` | 核心产品 1-3 个(英文 SKU 词) | 钩子 + 价值列表来源 |
| `strengths` | 用户视角的 USP(独特卖点) | 战略 4 对标 / 战略 1 价值主张 输入 |
| `target_market_country` | 本次开发的目标国家 / 地区 | 决定语气 / 时区 / 货币 |

## 强烈推荐字段(5 项)

| 字段 | 说明 | 用途 |
|---|---|---|
| `founded_year` | 成立年份 | 历史背书(`since 1987`)|
| `factory_size` | 厂房面积 / 自动化产线数 | 规模背书 |
| `certifications` | 认证(`US FDA registered` / `Halal` / `ISO 9001` / `EN13432`) | 战略 7 环保合规 钩子 |
| `export_markets` | 已出口地区列表 | 写 "we supplied partners in [LA, NY] for 30 years" 一类社证 |
| `extra_products` | 扩展产品线 | 第 2-3 轮跟进可切换角度 |

## 真实样例(参 Noodle House 案例)

```yaml
company_name: "NOODLE HOUSE FOOD (SHENZHEN) CO., LTD."
website: "https://example.com"
founded_year: 1987
factory_size: "45,000+ sq ft · multiple automated lines"
core_products:
  - "Noodles (authentic Asian)"
  - "Egg rolls"
  - "Almond / sesame biscuits"
  - "Mooncakes"
certifications:
  - "US FDA registered"
  - "Halal certified"
  - "China CNCA hygiene registration"
export_markets:
  - "Los Angeles · New York · Canada"
  - "France · Germany · Italy"
  - "Sydney · Melbourne"
  - "Singapore · Malaysia · Philippines"
strengths:
  - "37+ years heritage"
  - "Direct factory pricing (no middleman)"
  - "Multi-region compliance (FDA + Halal + CNCA)"
target_market_country: "Australia"
brands:
  - "Noodle House"
  - "Crispy Fragrance Garden"
```

## skill 行为约定

1. **缺必填字段时**,先用 `assets/company-profile-template.md` 让用户填,不要硬写
2. **散文式简介丢进来时**,先按 schema 解构 + 跟用户回确认,再写邮件
3. **找不到 USP 时**,直接问用户"你和最强竞品比,有什么是只有你有的?"(不接受"质量好"/"服务好"这种空话)
4. **认证 / 出口地区** 这两栏特别重要,**首封邮件 80% 的可信度来自这里**

## 反面教材

❌ 用户:"我做 LED 灯,帮我写一封开发信"
错的做法:直接开写
对的做法:"先按以下 5 个必填字段告诉我:公司名 / 官网 / 核心产品 / 你和最强竞品比有什么是只有你有的 / 目标国家"

❌ AI 写出"We pride ourselves on quality and service" — 0 信息量,删
对的:"FDA-registered factory supplying 30+ Asian distributors across NA since 1987" — 具体到日期 / 认证 / 地域 / 客户类型 / 历史
