---
name: laifaxin-outreach-v0.2 · runners
type: meta
status: stub
version: 0.2.0-alpha.0
created: 2026-06-17
updated: 2026-06-17
tags: [v0.2, runner, codex, orchestration]
description: v0.2 alpha Codex orchestration runner 占位说明 · W3 实施时填写实际可执行脚本
---

# Runners · v0.2 alpha(stub)

> ⚠️ 本目录是**占位 stub** · W3 spike 启动时填写实际可执行脚本。
> 当前阶段只列**结构 + 接口 + 测试期望**,不写实际代码。

## 计划文件

```
runners/
├── README.md                    ← 本文(stub)
├── prospect.py                  ← W3 实施 · 主流程 orchestration
├── safety_enforcer.py           ← W3 实施 · 调用 safety-gates.md 配置
├── decision_caller.py           ← W3 实施 · 调用 decision-prompts.md 节点
├── audit_writer.py              ← W3 实施 · 写 ~/.codex/runs/<run_id>/ 三件套
└── tests/
    ├── test_safety_enforcer.py
    ├── test_decision_caller.py
    └── test_audit_writer.py
```

## 主 entry point · `prospect.py`(伪 API)

```python
"""
laifaxin-outreach-v0.2 主 runner.
启动: codex exec - < /tmp/v0.2-prompt.txt
或: python prospect.py --product "皮筏艇" --history-root ~/.codex/runs/
"""

import asyncio
from safety_enforcer import SafetyEnforcer
from decision_caller import DecisionCaller
from audit_writer import AuditWriter

class V02SpikeRunner:
    """Supervised browser spike alpha runner."""

    def __init__(self, product_input, history_root):
        self.product = product_input
        self.run_id = generate_run_id()    # ts + uuid
        self.audit = AuditWriter(self.run_id)
        # safety-gates.md / decision-prompts.md 是文档+数据源(markdown 多类内容)
        # 加载方式: from_md_sections 按 § 段标题分发 · 解析 5 类内容(详见 decision-prompts.md § 0)
        # r10 钉死 · effective_config 单一所有权 = runner · 一处构建 · 注入所有消费者
        #   ① 读 defaults → ② 合并 § 0.5 启动对话的 user_overrides → ③ 注入 decision/safety
        #   DecisionCaller / SafetyEnforcer 都不再自己加载 parameters-defaults · 无 set_effective_config 二段装配
        defaults = load_parameters_defaults("parameters-defaults.md")
        self.effective_config = build_effective_config(defaults, user_overrides)   # § 0.5 产物
        self.audit.write_effective_config(self.effective_config)   # 写 run.json.effective_config
        self.safety = SafetyEnforcer.from_md_sections("safety-gates.md", effective_config=self.effective_config)
        self.decision = DecisionCaller.from_md_sections("decision-prompts.md", effective_config=self.effective_config)
        self.browser = ComputerUsePlugin()  # ~/.codex/computer-use/

    async def run(self):
        # 1. Session 检查
        assert await self.session_alive(), "Chrome web.laifaxin.com 未登录"

        # 2. 输入产品 + AI 推演
        await self.browser.click(semantic="搜索框")
        await self.browser.type(self.product)
        await self.safety.safe_click(semantic="AI 推演")
        candidates = await self.read_inference_results()

        # 3. LLM 节点 1:选客群
        decision_1 = await self.decision.call(
            node="choose_audience",
            inputs={
                "product_positioning": self.product,
                "candidates": candidates,
                "historical_dead_audiences": await self.load_dead_audiences(),
            }
        )
        chosen = await self.confirm_with_user(decision_1)  # Confirm 闸 1
        if chosen is None:
            return await self.handle_repick()

        # 4. 进入搜索结果
        await self.safety.safe_click(semantic="立即查看", index=chosen)

        # 5. 翻页 sequential + LLM 节点 2(每页)· 对齐 decision-prompts.md § 2.4 新 contract
        # ⚠️ r7 必修 · page_history 单一所有者 = runner
        #    runner 在 self.decision.call() **之前** 先调 LLM 拿 accuracy + append · 然后 call(policy)
        #    DecisionCaller 不再内部 append · 它只跑 policy 不动 history
        page_history = []   # runner 唯一 append · 含已 decide 完的所有页(包括当前页)
        prev_acc = None
        boundary_page = None
        chosen_audience_id = chosen   # chosen 是 audience_index 整数 · LLM 节点 1 输出
        # r9 必修 · 从 effective_config 读 max_boundary_pages
        max_pages = self.effective_config["max_boundary_pages"]   # default 50 · range [10, 200]
        for page in range(1, max_pages + 1):
            rows = await self.read_current_page()

            # ⚠️ r7 必修 · runner 流程: ① 先 LLM eval 拿 accuracy → ② append page_history → ③ 跑 policy
            # 这样 page_history 在 call(policy) 之前已含当前页 · Hopeless 的 cumulative_avg 可算
            parse_result = await self.decision.eval_node(
                node="per_page_accuracy",
                inputs={
                    "page_number": page,
                    "rows": rows,
                    "product_positioning": self.product,
                    "audience_context": {"audience_id": chosen_audience_id},
                    "cumulative_pages_read": page,
                    "prev_page_accuracy": prev_acc,
                },
                effective_config=self.effective_config,   # r7 必修 · 注入参数
            )
            curr_acc = parse_result.parsed["accuracy"]    # schema 保证含 accuracy

            # ⚠️ 唯一 append 点(r7 必修):runner 在 policy 之前 append 当前页
            page_history.append({"page": page, "accuracy": curr_acc})

            # 跑 policy(注入已含本页的 page_history)
            decision_2 = await self.decision.run_policy(
                node="per_page_accuracy",
                parsed=parse_result.parsed,
                inputs={
                    "page_number": page,
                    "prev_page_accuracy": prev_acc,
                },
                page_history=page_history,
                effective_config=self.effective_config,   # r7 必修
            )

            # ⚠️ 必须先判 final_disposition.type · Failure 路径可能没 payload
            disp_type = decision_2.final_disposition.type
            if disp_type == "Failure":
                return await self.handle_fail_closed(decision_2)

            prev_acc = curr_acc

            if disp_type == "BoundaryReached":
                boundary_page = decision_2.final_disposition.payload["at_page"]   # 已是"最后准页"
                break
            elif disp_type == "Hopeless":
                return await self.handle_repick()
            else:   # Continue
                await self.safety.safe_click(semantic="下一页")

        # 6. 保存范围 = effective_config.save_companies_formula 求值
        # r9 必修 · 不再硬编码 · 公式由 parameters-defaults § 3 提供
        formula = self.effective_config["save_companies_formula"]   # default "boundary_page * 10"
        save_count = safe_eval_formula(formula, {"boundary_page": boundary_page})
        save_count = min(save_count, self.effective_config["max_save_companies"])   # default 1000
        emails_per_company = self.effective_config["emails_per_company"]            # 整数 · default 5 · range 3-10

        # ① "保存联系人" 是 allowed 按钮(safety-gates § 2.1)· 普通点击 · 开保存弹窗 · 不需 token
        await self.safety.safe_click(semantic="保存联系人", run_ctx=self.run_ctx)

        # ② Confirm 闸 2 · r10 钉死 · 审批单轨:真正 guarded 的是弹窗里的"确认转化"(action_id=confirm_save_contacts)
        #    runner 预签 token(action_id 必须 == confirm_save_contacts)→ 透传给 safe_click → gates 只 consume
        pre_signed_token = await self.request_user_token(
            action_id="confirm_save_contacts",                                       # 对齐 safety-gates § 2.2 guarded_actions
            params={"count": save_count, "emails_per_company": emails_per_company},  # 预算预演:count × emails × 单价
        )
        # 弹窗确认键走唯一审批链 · gates 校验 action_id+payload+sig 后只 consume · 缺 token = fail-closed
        await self.safety.safe_click(
            semantic="确认转化",                                                      # guarded 真实按钮文案
            run_ctx=self.run_ctx,
            pre_signed_token=pre_signed_token,
        )

        # 7. 写回 audit
        await self.audit.finalize(
            result="success",
            chosen_audience=chosen,
            boundary_page=boundary_page,
            saved_count=save_count,
        )

if __name__ == "__main__":
    import sys
    runner = V02SpikeRunner(
        product_input=sys.argv[1] if len(sys.argv) > 1 else input("产品: "),
        history_root=os.path.expanduser("~/.codex/runs/"),
    )
    asyncio.run(runner.run())
```

## 测试期望

### `tests/test_safety_enforcer.py`

```python
# r10 · effective_config 一处构建 · 注入所有消费者(测试里 mock 一份 · 与 test_decision_caller 同源)
EFFECTIVE_CONFIG = build_effective_config(load_parameters_defaults("parameters-defaults.md"), user_overrides={})

def test_blocked_action_raises():
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md", effective_config=EFFECTIVE_CONFIG)
    with pytest.raises(SafetyError):
        await enforcer.safe_click(semantic="发送", run_ctx=CTX)   # 永久 block · 任何 token 都不放行

def test_guarded_action_without_token_fail_closed():
    # r10 审批单轨:guarded 动作缺 pre_signed_token = fail-closed(gates 绝不自签)
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md", effective_config=EFFECTIVE_CONFIG)
    with pytest.raises(SafetyError, match="requires pre_signed_token"):
        await enforcer.safe_click(semantic="确认转化", run_ctx=CTX, pre_signed_token=None)

def test_guarded_action_with_pre_signed_token_consumes():
    # r10 · guarded = 弹窗"确认转化"(action_id=confirm_save_contacts)· 带 runner 预签 token → gates 只 consume
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md", effective_config=EFFECTIVE_CONFIG)
    token = make_valid_token(action_id="confirm_save_contacts")   # runner 预签 mock
    await enforcer.safe_click(semantic="确认转化", run_ctx=CTX, pre_signed_token=token)   # no exception

def test_allowed_action_passes():
    # "保存联系人" 与 "搜索" 都是 allowed(§ 2.1)· 普通点击 · 无需 token
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md", effective_config=EFFECTIVE_CONFIG)
    await enforcer.safe_click(semantic="搜索", run_ctx=CTX)         # no exception
    await enforcer.safe_click(semantic="保存联系人", run_ctx=CTX)   # allowed · 开弹窗 · 无需 token
```

### `tests/test_decision_caller.py`

```python
# r10 钉死 · effective_config 一处构建 · 注入 DecisionCaller · 无 set_effective_config 二段装配
EFFECTIVE_CONFIG = build_effective_config(load_parameters_defaults("parameters-defaults.md"), user_overrides={})

def test_llm_node_1_returns_one_audience():
    # contract 对齐 decision-prompts.md § 1.3 新 schema · r10 result 全 dict 下标访问
    caller = DecisionCaller.from_md_sections("decision-prompts.md", effective_config=EFFECTIVE_CONFIG)
    result = caller.call("choose_audience", inputs={...})
    assert result["chosen"] in [1, 2, 3, 4, None]
    assert len(result["evidence_snippets"]) >= 1
    assert len(result["applied_rules"]) >= 1
    assert result["why_not_top_alt"]["audience_index"] in [0, 1, 2, 3, 4]
    # ⚠️ 不再 assert confidence / reasoning · r1/r2 已降级为 audit 字段(不参与决策门)

def test_llm_node_2_boundary_detection():
    # r8 必修 · 分两步:eval_node 拿 accuracy → append history → run_policy
    # r10 · effective_config 注入构造 · 不再 set_effective_config
    caller = DecisionCaller.from_md_sections("decision-prompts.md", effective_config=EFFECTIVE_CONFIG)
    rows_high_match = [{"description": "We import LED outdoor lighting from China"} for _ in range(10)]

    parse = caller.eval_node("per_page_accuracy", inputs={"rows": rows_high_match, ...}, effective_config=caller.effective_config)
    assert 0.0 <= parse.parsed["accuracy"] <= 1.0

    page_history = [{"page": 1, "accuracy": parse.parsed["accuracy"]}]
    result = caller.run_policy("per_page_accuracy", parsed=parse.parsed,
                                inputs={"page_number": 1, "prev_page_accuracy": None},
                                page_history=page_history, effective_config=caller.effective_config)
    assert result.final_disposition.type in ["Continue", "BoundaryReached", "Hopeless", "Failure"]
    # Failure.payload 可能 null · 必须先判 type
    if result.final_disposition.type != "Failure":
        assert 0.0 <= result.final_disposition.payload["accuracy"] <= 1.0

def test_llm_node_2_two_page_boundary_calculation():
    # r2 #2 必修 · 双页连续 < 0.6 · boundary_page = page - 2(最后准页)
    caller = DecisionCaller.from_md_sections("decision-prompts.md", effective_config=EFFECTIVE_CONFIG)
    # 模拟第 62 页 · 当前 0.5 / 上一页(第 61) 0.5
    page_history = [{"page": p, "accuracy": 0.85} for p in range(1, 61)] + \
                   [{"page": 61, "accuracy": 0.5}, {"page": 62, "accuracy": 0.5}]
    # parse 已 mock · 直接跑 policy
    parsed = {"accuracy": 0.5, ...}
    result = caller.run_policy(
        "per_page_accuracy",
        parsed=parsed,
        inputs={"page_number": 62, "prev_page_accuracy": 0.5},
        page_history=page_history,
        effective_config=caller.effective_config,
    )
    assert result.final_disposition.type == "BoundaryReached"
    assert result.final_disposition.payload["at_page"] == 60
    # r10 · policy 不再带 save_companies · 保存数量由 runner 用 effective_config.save_companies_formula(at_page) 求
    assert "save_companies" not in result.final_disposition.payload
    assert result.final_disposition.payload["note"] == "two_consecutive_low_pages_confirm"

def test_save_count_from_formula():
    # r10 · 保存数量唯一来源 = runner 用 effective_config 公式求值(不读 policy payload)
    save_count = safe_eval_formula(EFFECTIVE_CONFIG["save_companies_formula"], {"boundary_page": 60})
    save_count = min(save_count, EFFECTIVE_CONFIG["max_save_companies"])
    assert save_count == 600   # default 公式 boundary_page * 10 · cap 1000
```

## W3 启动前需补全

- [ ] Codex `computer-use` / `chrome` plugin 实际 API 文档(spike 时查 · `browser-use` 已确认不存在 · 删除)
- [ ] OCR 工具选型(Codex 已含还是外接 tesseract?)
- [ ] 同义词词典初版(`safety-gates.md` § 1 已列 · 但归一化逻辑要实现)
- [ ] 用户 token 通知 UI 接入(SkyComputerUseClient.app 接口)
- [ ] 跨设备 artifacts.json hash 校验脚本

## 关联

- 主 SKILL.md(本目录上一级)
- safety-gates.md(本目录上一级)
- decision-prompts.md(本目录上一级)
- spec(已归档):`specs/done/2026-06-17-laifa-browser-agent-v0.2.md`(本仓)
- 关键决策:`wiki/history/2026-06-laifa-browser-agent-v0.2-design.md`(本仓)
