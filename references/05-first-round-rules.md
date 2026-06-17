# 05 · 首轮邮件专属规则

> 首轮不是"卖产品",是"拿到回复"。本 reference 比 `04-email-sequence-rules.md` 更窄,**专门约束首轮**。
> ⚠️ **优先级**:本文规则 **覆盖 04 § 1.2 的 bullet 强制**。首轮可极简,不强制 bullet / 不强制完整 5 步流。
> 04 是第 2 轮起的默认套路;05 是首轮特例,两者不冲突而是分工。

## 首轮的真实目标

不是成交 · 不是询盘 · 是 **让客户回复"OK 给我看看 catalog"** 或类似低门槛信号。

每多一行字、每多一个 CTA、每多一段背景介绍,都在**降低**回复率。

## 三个不能违反的红线

1. **≤ 100 个英文单词**(含签名)
2. **只有一个 CTA 钩子**(不要给客户多选)
3. **只讲一个最容易被接受的价值点**(不要拼盘 USP)

## 真实样例(参 Noodle House 案例 · 已验证短而有效)

> 字数标注按英文实词数(空白 / 标点不算)· 含称呼 + 签名行
> 字数仅供参考,30 词差距内对回复率影响不显著

### 模板 A(74 词)

```
Hello,

I'm {名字} from {公司}, a professional noodle manufacturer since 1987.

I noticed you are a key distributor of Asian foods.
As we have successfully supplied partners in Los Angeles and New York for over 30 years, I believe we can bring value to your portfolio.

As a direct manufacturer, we provide market-proven products at competitive factory-direct pricing.

Would you like me to send over our product catalog for your review?

Best Regards,
{名字}
{公司}
```

### 模板 B(57 词)

```
Hello,

I'm {名字} from {公司}, a manufacturer of authentic noodles since 1987.

As a US FDA-registered and Halal-certified factory, we supply high-quality, compliant products to distributors across North America, Europe, and Asia.
We help our partners succeed by providing market-proven noodles at excellent direct pricing.

Would you be interested in our product catalog?

Best Regards,
{名字}
{公司}
```

## 拆解 · 为什么这俩有效

| 元素 | 模板 A | 模板 B |
|---|---|---|
| 开场 | 自报身份 + 历史背书(`since 1987`) | 同 |
| 相关性 | "I noticed you are a key distributor" — 暗示做过功课 | 直接列认证(合规切角)|
| 社证 | 已供 LA + NY 30 年 | 已供 NA + 欧洲 + 亚洲 |
| USP | Direct manufacturer · factory-direct pricing | FDA + Halal + 同上 pricing |
| CTA | 唯一钩子:catalog | 唯一钩子:catalog |
| 签名 | 名字 + 公司(无电话 / 网址) | 同 |

### 关于这俩样例与"04 默认套路"的差异(显式说明,不再让用户自己推)

Noodle House 真实样例**没有**bullet 列表、**没有**HTML 钩子、签名**带公司名** — 这与 `04 § 1.2 / 1.3` 的默认值都不同。

| 维度 | Noodle House 真实样例(05)| 04 默认值 | 现在用哪个 |
|---|---|---|---|
| Bullet | ❌ 没用 | ✅ 第 2 轮起默认 | **首轮用 05(可不上 bullet)**;第 2 轮起用 04 |
| HTML 钩子 | ❌ 纯文本 CTA(`product catalog`) | ✅ 默认 `<span>` 黄底红字 | **新写邮件用 04 默认 + 给 fallback**;Noodle House 是历史样例,展示"短 + 单 CTA"骨架 |
| 签名 | 带公司名 | 只英文名 | **新写邮件用 04 严规**(只名);Noodle House 的"带公司签名"现在不再推荐 |
| 称呼 | `Hello,` 无名 | `Hi {联系人:名称}` 个性化(⚠️ 占位示例 · 必用【插入变量】按钮替换) | 优先**真实变量个性化**(参 `references/09-validation.md` 变量替换 SOP)|

> 一句话:**05 是历史已验证的"短骨架"样例,不是对 04 的逐项复刻**。新写邮件参考 05 的"骨架长度 + 单 CTA + 一个价值点",其余按 04 默认值出。

## 首轮 vs 第 2+ 轮的差异

| 维度 | 首轮 | 第 2 轮 | 第 3+ 轮 |
|---|---|---|---|
| 字数 | ≤ 100 | ≤ 120 | ≤ 100 |
| 任务 | 拿回复 | 价值展示 | 信任 / 差异化 |
| 价值点数量 | 1 个 | 2-3 个 (bullet) | 1-2 个特化角度 |
| CTA | catalog / 1 问 | 看数据 / 案例 | yes/no qualifier |
| 视觉 | 极简(可不上 bullet) | 上 bullet | 上 bullet + 强调 |

## skill 行为约定

1. 用户首次让写时,**只出首轮 3-5 个模板**,不要附带第 2/3 轮("我帮你也写好了"是坏习惯)
2. 用户没给 USP / 痛点 → 回到 `02-company-profile-schema.md` 收集
3. 用户没给标杆 → 回到 `03-benchmark-analysis.md`(没标杆写不出来切角邮件)
4. 跑完首轮 → 提示用户:
   - "在来发信 https://web.laifaxin.com 把这几封录入模板"
   - "想出第 2 轮,告诉我'继续'"

## 反面教材

❌ `Dear Sir/Madam, Hope this email finds you well. My name is XXX from YYY, we are a leading manufacturer of...` — 第一句就废,第二句更废
❌ `We offer high quality products at competitive prices with excellent service` — 0 信息量
❌ `Could you please let me know if you would be interested in our products, our pricing, our samples, or our factory visit?` — 多 CTA = 0 CTA
❌ 签名带 `Best regards, John Smith | CEO | ABC Trading Co., Ltd. | Tel: +86 xxx | Fax: +86 xxx | Web: www.xxx.com | Address: ...` — 进垃圾箱
