# 公司资料采集表 · skill 输入

> 把下面 yaml 填好,贴给 skill。
> 必填 5 项不齐 → skill 会先**反问**补齐(不是硬拒),写出来的邮件没有可信背书,回复率必然弱。建议尽量填全。
> 字段说明见 `references/02-company-profile-schema.md`。

```yaml
# === 必填 ===
company_name: ""             # 英文全称 · 出现在签名 / 自报家门
website: ""                  # 官网 URL
core_products:               # 1-3 个核心产品 · 用客户产品词,不是你的服务词
  - ""
  - ""
strengths:                   # USP · 数字化 / 具体化 · 不接受"质量好"
  - ""
  - ""
target_market_country: ""    # 本次开发的目标国家 / 地区

# === 强烈推荐 ===
founded_year: null           # 1987
factory_size: ""             # "45,000 sq ft · 多自动化产线"
certifications:              # FDA / Halal / ISO 9001 / EN13432 / CE / RoHS ...
  - ""
export_markets:              # 已出口的真实地区(社证用)
  - ""
extra_products:              # 扩展产品(用于第 2-3 轮跟进切换角度)
  - ""

# === 可选 ===
brands:                      # 自有品牌名
  - ""
team_signature_name: "Alex"  # 邮件签名用的英文名 · 不接受 Mr./Ms./Dr.
contact_role: ""             # 你在公司的角色(决定语气)
languages_we_handle:         # 内部能处理的客户语种
  - "English"
```

## 填写示范(参 Noodle House 案例)

```yaml
company_name: "NOODLE HOUSE FOOD (SHENZHEN) CO., LTD."
website: "https://example.com"
core_products:
  - "Authentic Asian noodles"
  - "Egg rolls"
  - "Almond / sesame biscuits"
strengths:
  - "37+ years heritage (since 1987)"
  - "FDA-registered + Halal-certified · multi-region compliant"
  - "Direct factory pricing · no middleman"
target_market_country: "Australia"
founded_year: 1987
factory_size: "45,000+ sq ft · multiple automated lines"
certifications:
  - "US FDA registered"
  - "Halal certified"
  - "China CNCA hygiene registration"
export_markets:
  - "USA: Los Angeles · New York"
  - "Europe: France · Germany · Italy"
  - "Oceania: Sydney · Melbourne"
  - "SEA: Singapore · Malaysia · Philippines"
brands:
  - "Noodle House"
  - "Crispy Fragrance Garden"
team_signature_name: "Alex"
```

## 常见自检

- `strengths` 写了 "high quality / good service / competitive price"? → **删,这是 0 信息**
- `core_products` 写了你的"服务词"(如 CNC machining)? → **改成客户产品词**(如 Drone Frame)
- `certifications` 空? → 至少把行业最基础认证查清(国内 / 出口必备)
- `export_markets` 写了"全球" / "100+ 国家"? → **改成 3-5 个具体城市**,空话失信
