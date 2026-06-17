# 08 · 推荐对话策略 + interrupt handlers

> 来自 `6.AI对话语句.txt` 真实操作链 + 教程视频还原。
>
> ⚠️ **澄清**:本文给的是**推荐对话流 + 跳问处理建议**,不是确定性状态机。
> Claude / Codex 是提示词驱动,不会按代码逐分支跑;用户也常常跳着问。本文教 skill 怎么**优先级处理**这些跳问,不是教模型按 if/else 严格执行。

## 为什么用对话状态机,而不是大 prompt 一锤子

| 问题 | 大 prompt 一锤子 | 对话状态机 |
|---|---|---|
| 模型偷懒 | 30+ 模板后期开始"...同上结构..." | 一轮一审,不偷懒 |
| 模板趋同 | 一气呵成易复用句式 | 每轮可重置策略 |
| 用户消化 | 30 封一起看不过来 | 一轮一审一录入 |
| 中途调整 | 错了重跑整套 | 错了只重跑当前轮 |

## 标准 6 阶段(skill 默认按此跑)

### 阶段 0 · 学习

用户消息:
> "先学习这份教程 / 这两个模板范式"

skill 动作:
- 读 `references/04-email-sequence-rules.md` § 1-3(创作准则 / 策略编号 / 钩子)
- 读 `references/05-first-round-rules.md`
- **不输出邮件**,只输出"我已经学习了 X / Y / Z 规则,准备进入下一步"

### 阶段 1 · 收公司资料

skill 主动让用户填 `assets/company-profile-template.md`,缺必填字段反复回问。

### 阶段 2 · 收标杆客户

skill 主动让用户填 `assets/benchmark-customer-template.md`(1-2 个)。
没标杆 → **询问**用户:"想用推荐模式(先去找 1-2 个标杆,5-10 分钟)还是 Fallback 模式(零标杆通用首轮,回复率较弱)?"
两档均可,切到 `references/03 § Fallback 模式` 或 `assets/benchmark-customer-template.md § 没标杆怎么办`。

### 阶段 3 · 标杆分析 + 战略蓝图

按 `references/03-benchmark-analysis.md` 输出 6 维画像 + 推荐 3 个 entry angle。
按 `references/04-email-sequence-rules.md § 5` 输出战略蓝图(引用块):
```markdown
> **战略蓝图确认**
> *   核心洞察: ...
> *   破局点: ...
> *   序列逻辑: ...
```

**等用户确认**再下一步。

### 阶段 4 · 生成第 1 轮(3-5 个模板)

用户消息:
> "生成第一轮邮件 3 种不同模板,简短一些,生成 HTML 格式"

skill 动作:按 `04 § 5` 三阶段输出 · 严守 `05 首轮规则` · 含主题 + HTML 正文 + 中文对照。

### 阶段 5 · 等用户回灌反馈

可能信号:
- "重新生成第一轮" → 改方向重出
- "继续" / "生成第二轮" → 进阶段 6
- "把第 1 轮 A 模板再短一点" → 局部修改
- "改成热情友好语气" → 重定 tone

### 阶段 6 · 逐轮生成第 2 / 3 / N 轮

每次只生成**一轮**,等用户说"继续"。

每轮:
1. 选 1 个策略编号(避免和前轮重复)
2. 选钩子原型(参 `04 § 3`)
3. 出 3-5 个模板(用户可在阶段 4 已指定 templates_per_round)
4. **绝不省略** · **绝不"...同上..."**

### 阶段 7 · 输出来发信对接清单

序列完成后,按 `references/07-laifaxin-plan-setup.md § 8` 输出 `laifaxin_setup` YAML 块。

## Interrupt handlers · 用户跳问怎么办

用户实际不会按 6 阶段顺序问。常见跳跃:

| 跳跃情况 | skill 应怎么处理 |
|---|---|
| 在阶段 4(刚出第 1 轮)用户说"客户回复了" | **暂停序列生成**,优先切到回复推进(`references/06`),处理完回复后问"要继续序列吗" |
| 在阶段 6(生成第 3 轮)用户说"前两轮重写一下" | **倒退到阶段 4-5**,告知"重写会丢失原版,要保留吗",拿确认后重出 |
| 用户跳过阶段 1-3 直接问"写一封开发信" | 反问"先给我:你的产品 / 目标国家 / 一个标杆客户官网" — 不要凭空写 |
| 用户说"零标杆我没标杆" | 切到 `references/03 § Fallback 模式` |
| 用户最后说"给我 setup YAML 我去录入来发信" | 立刻按 `references/07 § 8` 出 YAML · 不再追问 |
| 用户在任意阶段问"客户回复了怎么处理" | **回复推进总是最高优先级** · 序列生成可暂停 |

**通用优先级**(从高到低):

1. 客户回信处理(钱在这一步)
2. 用户明确说"暂停 / 重写 / 不要了"
3. 当前进行中的轮次完成
4. 下一阶段(默认推进)

## 推荐对话流伪代码(参考用 · 非严格执行)

```python
state = "learning"

while True:
    user_msg = await user.message()

    if state == "learning":
        if "学习" in user_msg or "继续学习" in user_msg:
            await load_references([4, 5])
            state = "collecting_profile"
            await reply("已学习 · 请告诉我你的公司资料(按 company-profile-template)")

    elif state == "collecting_profile":
        if profile_complete(user_msg):
            state = "collecting_benchmarks"
            await reply("公司资料完整 · 请给 1-2 个标杆客户官网或 About 文本")
        else:
            await reply_missing_fields()

    elif state == "collecting_benchmarks":
        if benchmarks_complete(user_msg):
            state = "analyzing"
        else:
            # 没标杆:不拒写,问用户走哪档
            mode = await ask_user_mode(
                prompt_text="没看到标杆客户。选一档:\n"
                            "  A · 推荐模式(5-10 分钟去找 1-2 个对口客户官网,回复率更稳)\n"
                            "  B · Fallback 模式(零标杆,只出 1-2 个通用首轮,回复率较弱)",
                options=["recommended", "fallback"]
            )
            if mode == "fallback":
                state = "analyzing_fallback"
            else:
                await prompt("请给至少 1 个对口客户官网 / About 文本")

    elif state == "analyzing":
        await produce_benchmark_profile()
        await produce_strategic_blueprint()
        state = "wait_blueprint_confirm"

    elif state == "analyzing_fallback":
        # Fallback 分支:不做 6 维画像,直接出 1-2 个通用首轮
        await produce_generic_first_round_with_weak_warning(
            templates=1 or 2,
            warning="⚠️ fallback 模式 · 无标杆画像 · 回复率较弱 · 拿到第一批回复后挑客户切回推荐模式"
        )
        state = "wait_fallback_feedback"

    elif state == "wait_blueprint_confirm":
        if user_confirms(user_msg):
            state = "round_1"

    elif state.startswith("round_"):
        n = int(state.split("_")[1])
        if "生成第" in user_msg or "继续" in user_msg or n == 1:
            await produce_round(n, templates_per_round)
            if n >= total_rounds:
                state = "delivering_laifaxin_setup"
            else:
                state = f"wait_round_{n}_feedback"

    elif state.startswith("wait_round_"):
        if "继续" in user_msg or "下一轮" in user_msg:
            n = int(state.split("_")[2])
            state = f"round_{n+1}"
        elif "重新生成" in user_msg:
            n = int(state.split("_")[2])
            state = f"round_{n}"  # 重跑当前轮
        elif "改" in user_msg or "修改" in user_msg:
            await produce_revision(user_msg)
            # 状态不变,等下一指令

    elif state == "delivering_laifaxin_setup":
        await produce_laifaxin_setup_yaml()
        await reply("序列完成 · 配置已就绪 · 复制到来发信即可")
        break
```

## 真实对话示例(原素材)

```
用户: 继续学习,理解
AI:   (吸收 references/04-05)

用户: 学习这两个模板方式,并生成第一轮邮件3种不同模板,
      邮件要求简短一些,生成html格式
AI:   (产出第 1 轮 3 模板 + HTML + 中文对照)

用户: 重新生成第一轮邮件
AI:   (重新产出第 1 轮)

用户: 生成第二轮邮件
AI:   (产出第 2 轮)

用户: 生成第三轮邮件
AI:   (产出第 3 轮)
```

## 反面教材

❌ 用户首条问"写 8 轮 × 4 模板" → AI 一次性吐 32 个模板 → 第 20 个开始重复
❌ 没收公司资料就开始写 → 空洞
❌ 没分析标杆就开始写 → 没切角
❌ 用户说"重新生成第一轮" → AI 又把所有轮全重出 → 浪费用户上下文
