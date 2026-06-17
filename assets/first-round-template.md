# 首轮邮件 · 输出模板

> skill 写完首轮后,**逐封**按此格式输出 · 严守 `references/05-first-round-rules.md`。

## 输出格式(每个模板独立块)

````markdown
### 模板 A · 策略 8 交期优势型 · 资源钩子

```邮件主题 (第1轮 - 模板 A)
Asian noodles in Melbourne next week? 🍜
```

```邮件正文 HTML (第1轮 - 模板 A)
<p>Hi {联系人:名称}   <!-- ⚠️ 占位示例,不是真变量 · 录入来发信后必用编辑器顶部【插入变量】按钮替换,见 references/09-validation.md 关 2 · 这行注释生产时可删 -->,</p>

<p>I noticed Asian Food Wholesalers carries 5,000+ Asian SKUs across AU—impressive coverage.</p>

<p>I'm Alex from Noodle House, a noodle factory <i>FDA-registered and Halal-certified</i> since 1987.</p>

<ul>
  <li>Direct factory pricing — <b><u>15-25% lower</u></b> than middlemen</li>
  <li>Stable supply for Lunar New Year & Christmas peaks</li>
</ul>

<p>Would you be interested in a tailored catalog for AU distributors?</p>

<p>Reply with <span style='background-color:yellow; color:red; padding:2px 4px; font-weight:bold;'>Catalog</span> and I'll send it within 24h.</p>

<p>Alex</p>
```

```中文对照 (第1轮 - 模板 A)
切角: 交期优势 + 已供澳洲(社证) + Halal(对越南/印度社区分销关键)
钩子: Resource Hook · 给具体回报(catalog within 24h)
风险: 客户可能问"15-25% 怎么算的" → 准备一份对标 sheet
字数: 64 词(英文实词 · 不含 HTML 标签 / 空白 / 标点 · 含签名 1 个名)
```
````

## 自检表(skill 生成后逐封跑)

每个模板生成后,skill 自检:

```yaml
self_check:
  word_count: ___           # ≤ 100
  has_Dear: false           # 必须 false
  signature_only_name: true # 严禁公司/电话/链接
  bullet_count: ___         # 2-3 (含 bullet 时)
  emphasis_total: ___       # ≤ 4 (不含钩子)
  hook_html_present: true        # A 模板 span 黄底红字 (Gmail 优)
  hook_fallback_present: true    # B 模板 <b> 加粗 (Outlook 桌面兜底) · 见 04 § 3
  both_templates_attached: true  # 来发信"步骤"内 A/B 双挂载
  cta_count: 1              # 严格 1
  has_one_pain_point: true  # 严格 1 个痛点
  has_one_value_point: true # 严格 1 个主价值
  language: english         # 默认
  has_chinese_brief: true   # 中文对照(给操作者)
```

任何一项不通过 → 重写,不要交付。

## 真实样例(Noodle House 案例 · 已验证的最短可发)

参 `references/05-first-round-rules.md` 模板 A / B(70-78 词版)。
那两版**没用 HTML 钩子**(早期教程素材),新输出**必须**升级为 HTML 钩子格式。

## 反面教材 vs 正面对照(精简版)

### ❌ 不要这样

```
Subject: Hello, would you be interested in our products?

Dear Sir/Madam,
Hope this email finds you well. We are a leading manufacturer of high quality products...
Please find attached our complete product catalog for your review.

Best regards,
John Smith | CEO | XYZ Trading Co., Ltd. | Tel: +86-xxx | Web: www.xyz.com | Address: ...
```

问题:废标题 / Dear / 自我中心 / 空话 / 多 CTA / 巨型签名

### ✅ 应该这样(同信息量 · 64 词)

```
Subject: Asian noodles in Melbourne next week? 🍜

Hi Tom,

I noticed Asian Food Wholesalers carries 5,000+ Asian SKUs across AU.

I'm Alex from Noodle House — FDA-registered + Halal-certified noodle factory since 1987.

Would a tailored catalog for AU distributors help? Reply Catalog and I'll send within 24h.

Alex
```

要点:具体钩 / 真实背书 / 单 CTA / 极简签名
