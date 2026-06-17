# 多轮跟进 · 输出模板

> 第 2 轮起每轮的输出模板。严守 `references/04-email-sequence-rules.md` § 5 三阶段交付。

## 每轮 header(进入正文前必出)

```markdown
**第 N 轮:策略 [#] [策略名]**

策略意图: [一句话讲这轮目标是什么 · 不是"再问一遍 catalog"]
间隔: 上一轮后 [X] 天
钩子原型: [Resource / Insight / Qualification]
```

## 每个模板(独立块 · 严格分离)

````markdown
**【模板 [N]/[M]】**

```邮件主题 (第N轮 - 模板 N/M)
[5-7 词 · 不复读前轮主题 · 含 1 个 emoji]
```

```邮件正文 HTML (第N轮 - 模板 N/M)
<p>Hi {联系人:名称}   <!-- ⚠️ 占位示例,不是真变量 · 录入来发信后必用编辑器顶部【插入变量】按钮替换,见 references/09-validation.md 关 2 · 这行注释生产时可删 -->,</p>

<p>[开场痛点 - 1 句]</p>

<p>[解决方案桥梁 - 1 句]</p>

<ul>
  <li>[核心价值 1 · 含 <b><u>第一层强调</u></b>]</li>
  <li>[核心价值 2 · 含 <i>第二层强调</i>]</li>
</ul>

<p>[引导式提问 - 1 句]</p>

<p>[CTA 钩子 - 含 HTML 黄底红字 span]</p>

<p>Alex</p>
```

```中文对照 (第N轮 - 模板 N/M)
策略: ...
切角: ...
跟前轮区别: ...
风险: ...
字数: ___词
```
````

## 多轮策略递进示范(8 轮)

| 轮次 | 策略 | 钩子 | 模板数 | 跟前轮区别 |
|---|---|---|---|---|
| 1 | 8 交期 | Qualification | 3 | 首封 · 拿回复 |
| 2 | 2 降本 | Insight | 3 | 不再讲身份 · 给数字证据 |
| 3 | 9 服务 | Resource | 3 | 给案例 · 建立信任 |
| 4 | 4 对标 | Insight | 3 | 隐性对标竞品 · 显性差异 |
| 5 | 7 合规 | Qualification | 3 | 切合规痛点 · 拿 yes/no |
| 6 | 6 趋势 | Resource | 3 | 行业趋势卡位 |
| 7 | 5 门槛 | Resource | 3 | 降低尝试门槛 |
| 8 | 1 价值 | Resource | 3 | 总结性 · 最后窗口 |

## 主题不复读规则(强制)

| 轮次 | 主题示范 |
|---|---|
| 1 | `Asian noodles in Melbourne next week? 🍜` |
| 2 | `Quick numbers on 2024 noodle margins 📊` |
| 3 | `How [SimilarCo] doubled their margin 💡` |
| 4 | `Why our noodles vs imports 🔍` |
| 5 | `Halal compliance for AU distributors ✅` |
| 6 | `Asian food trends Q3 2026 🌏` |
| 7 | `One pallet trial — no MOQ 📦` |
| 8 | `Last thought before Q4 🎯` |

> 同一个 thread 内主题保持一致是发件礼仪;但每轮**独立 thread**(每轮新 subject)→ 收件箱里像不同邮件,绕过审美疲劳。
> 来发信"智能跟进"每轮一个 step,各 step 主题独立 — 符合此模型。

## 完整性铁律检查(每轮收尾)

```yaml
completeness:
  rounds_requested: 8
  current_round: 3
  templates_per_round_requested: 4
  templates_emitted_this_round: ___       # 必须 == 4
  any_omission_phrase: false              # 不能出现 "...同上..." "...后续遵循..."
  formatting:
    blank_line_between_blocks: true       # 每个 code block 之间空行
    code_block_lang_tag_present: true     # 含上下文标识
```
