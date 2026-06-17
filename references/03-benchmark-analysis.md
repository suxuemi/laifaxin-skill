# 03 · 标杆客户画像 · 反向生成切角

> 关键洞察:**不要凭空写开发信。** 选 1-2 个对口标杆客户的官网,反向提炼"采购方关心什么",再用切角写邮件给**同类客户**。

来源:`智能跟进计划.png` 教程 5 步法 + `3.AI编写邮件.mp4` 真实操作链。

## 输入

每个标杆 1 份(至少 1,推荐 2):

```yaml
website: "https://asianfoodwholesalers.com.au"
about_text: |
  (粘贴 About Us / Company Profile 全文)
```

## 提取的画像字段(6 维)

| 字段 | 提取问题 | 用途 |
|---|---|---|
| `positioning` | 这家公司怎么定位自己?(批发 / 零售 / 跨境 / 高端 / 性价比) | 决定切角 |
| `key_people` | About 页 / Team 页有具体决策人吗?(CEO / 采购总监 / 品类经理) | 收件人称呼 + LinkedIn 找邮箱 |
| `buyer_pain_points` | 站在他们采购角色,最头疼什么?(交期 / 合规 / 同质化 / 库存 / 成本) | 首封开场痛点 |
| `our_fit_points` | 我方 strengths 哪几条直击他们痛点? | 价值列表(2-3 条) |
| `entry_angles` | 适合切入的角度 3 个 | 首轮 A/B/C 模板分别用一个 |
| `signals_to_use` | 可在首封暗示的具体细节(他们家某产品线 / 某市场 / 某新闻) | 钩子上下文,提升相关性 |

## 提取方法

1. **Positioning**:扫 About 第一段 + Header tagline + 产品分类页结构
2. **Pain points**:从"我们承诺什么 / 我们怎么解决"反推他们的客户(也就是终端零售商或消费者)在乎什么 → 再推他们采购时在乎什么
3. **Key people**:翻 Team / About Us / Contact;实在没有就标"采购负责人 · 收件人变量 `{联系人:名称}`(占位示例 · 录入来发信时必用编辑器【插入变量】按钮替换 · 见 `references/09-validation.md` 关 2)"
4. **Our fit**:对照 `02-company-profile-schema.md` 里的 strengths + certifications + export_markets,逐条问"这家公司会因为这条买我吗?"
5. **Entry angles**:从 9 策略里挑最契合的 3 个(参 `04-email-sequence-rules.md` § 2 策略编号)

## 输出格式

```yaml
benchmark_profile:
  website: "https://asianfoodwholesalers.com.au"
  positioning: |
    澳洲规模较大的亚洲食品批发商 · 服务本地华人 + 越南 + 印度社区 ·
    重点品类:面食 / 速冻 / 调味 / 饮料
  key_people:
    - name: null  # About 页未具名
      title: "Procurement / Category Manager"
  buyer_pain_points:
    - "供应商断货影响 SKU 完整度"
    - "Halal / 当地食品合规风险"
    - "亚洲品牌同质化,需差异化"
  our_fit_points:
    - "37 年面食工厂背景 + FDA + Halal 双认证 → 直击合规痛点"
    - "已供 LA/NY/澳洲市场 → 社证证明能服务他们这类客户"
    - "Direct factory pricing → 切'同质化'痛点"
  entry_angles:
    - "策略 7 环保合规型 · Halal + FDA 切入"
    - "策略 8 交期优势型 · 直工厂 + 稳定产线"
    - "策略 5 降低门槛型 · Catalog + 小试单"
  signals_to_use:
    - "提到他们在 Sydney 主仓 + Melbourne 二仓"
    - "提到 Vietnamese 区域客群是他们成长最快的(若 About 写了)"
```

## skill 行为约定(两档)

### 推荐模式(`recommended`)· 有标杆

1. 用户给 1-2 个对口客户官网或 About 文本 → 按 6 维提画像
2. **About 太空 → 让用户去 LinkedIn 看 Team / 看 Posts** 补料
3. **2 个标杆差异巨大** → 拆 2 个画像,**别合并取平均**(会写出谁都不对路的邮件)
4. 标杆提炼完成 → **跟用户回确认 entry_angles 选哪 1-3 个**,再进入 reference `04` / `05` 写邮件

### Fallback 模式(`fallback`)· 零标杆

> **触发**:用户说"我只有产品,没有标杆 / 不知道找哪家" 或 "先给我通用首轮就行"。
> 第一次用 skill 的中小业务员常见 — 不要直接拒写。

1. 跳过 6 维客户画像
2. 让用户给:
   - 产品 + 目标国家 + 目标客户类型(`02-company-profile-schema.md` 必填 5 项)
   - 1 个**他们在乎什么的猜测**(交期 / 成本 / 合规 / 同质化任选 1)
3. **只出 1-2 个"通用首轮"模板**(不出 3-5 个),并在中文备注里**显著提示**:
   ```
   ⚠️ 这是 fallback 模式产出 · 没标杆画像 → 切角是通用猜测 · 回复率会比推荐模式低
   ⚠️ 下一步建议:跑 1 周拿到第一批回复后,挑 1-2 个回复客户做标杆,切回推荐模式
   ```
4. 不进入第 2 / 3 轮,等用户先验证首轮再说

> 出处依据:`docs/share/email/ai-generate-multi-round-cold-email-sequences.md` L235 类似建议(允许零画像通用模板,但显著提示弱化)
