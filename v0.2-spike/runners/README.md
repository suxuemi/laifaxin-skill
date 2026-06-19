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

    def __init__(self, product_input, effective_config):
        # detail 轮修(F13/F14)· effective_config 由调用方(main)构建+校验后注入 · 不在 __init__ 里现造
        #   理由:effective_config 单一所有权=runner,但"读 defaults + 跑 §0.5 启动对话 + 校验派生约束"
        #   是 main 的职责(需要和用户交互)· __init__ 只接收已校验的 dict · 实例化不依赖未定义变量
        self.product = product_input
        self.run_id = generate_run_id()    # ts + uuid
        self.audit = AuditWriter(self.run_id)
        self.run_ctx = RunContext(run_id=self.run_id, audit=self.audit)   # F13 · 统一 run_ctx · 所有 safe_click 共用
        self.effective_config = effective_config
        self.audit.write_effective_config(self.effective_config)   # 写 run.json.effective_config
        # safety-gates.md / decision-prompts.md 是文档+数据源 · from_md_sections 按 § 段分发(decision-prompts.md § 0)
        # effective_config 单一所有权=runner · 注入消费者 · 无 set_effective_config 二段装配
        self.safety = SafetyEnforcer.from_md_sections("safety-gates.md", effective_config=self.effective_config)
        self.decision = DecisionCaller.from_md_sections("decision-prompts.md", effective_config=self.effective_config)
        self.browser = ComputerUsePlugin()  # ~/.codex/computer-use/

    async def run(self):
        # detail 轮修(F11)· 顶层 fail-closed 兜底:任何 SafetyError / FailClosed / 断言失败
        #   都必须 → 写 audit failure_diagnostics + result + pause · 绝不让异常裸穿出流程
        try:
            return await self._run_inner()
        except SafetyError as e:
            await self.audit.finalize(result="aborted",
                failure_diagnostics={"error_type": "SafetyError", "detail": str(e)})
            await self.pause_and_alert(f"安全闸拦截 · 已停 · {e}")
        except FailClosed as e:
            await self.audit.finalize(result="failed",
                failure_diagnostics={"error_type": "FailClosed", "node": e.node, "detail": str(e)})
            await self.pause_and_alert(f"LLM 节点 fail-closed · 已停 · {e}")
        except AssertionError as e:
            await self.audit.finalize(result="failed",
                failure_diagnostics={"error_type": "Precondition", "detail": str(e)})
            await self.pause_and_alert(f"前置条件不满足 · 已停 · {e}")
        finally:
            await self.browser.close()       # 关 codex 连接 · 落 audit · 不留悬挂

    async def _run_inner(self):
        # 1. Session 检查(失败 → AssertionError → 顶层兜底转 result=failed)
        assert await self.session_alive(), "Chrome web.laifaxin.com 未登录"

        # 2. 输入产品 + AI 推演
        await self.safety.safe_click(semantic="搜索框", run_ctx=self.run_ctx)
        await self.browser.type(self.product)
        await self.safety.safe_click(semantic="AI 推演", run_ctx=self.run_ctx)
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
            return await self.handle_repick(reason="user_declined_audience")

        # 4. 进入搜索结果
        await self.safety.safe_click(semantic="立即查看", index=chosen, run_ctx=self.run_ctx)

        # 5. 翻页 sequential + LLM 节点 2(每页)· page_history 单一所有者=runner
        page_history = []
        prev_acc = None
        boundary_page = None        # detail 轮(F12)· 终态来源唯一 · 见下方退出后的断言
        terminal = None             # "BoundaryReached" / "Hopeless" / "NoNextPage" / "MaxPages"
        chosen_audience_id = chosen
        max_pages = self.effective_config["max_boundary_pages"]   # default 50 · range [10, 200]
        for page in range(1, max_pages + 1):
            rows = await self.read_current_page()

            # detail 轮(F12/F8)· 空页 = 真实末页 → NoNextPage 终态 · 不调 LLM
            if len(rows) == 0:
                terminal = "NoNextPage"
                break

            # ① 先 LLM eval 拿 accuracy → ② append page_history → ③ 跑 policy
            parse_result = await self.decision.eval_node(
                node="per_page_accuracy",
                inputs={
                    "page_number": page, "rows": rows,
                    "product_positioning": self.product,
                    "audience_context": {"audience_id": chosen_audience_id},
                    "cumulative_pages_read": page, "prev_page_accuracy": prev_acc,
                },
                effective_config=self.effective_config,
            )
            curr_acc = parse_result.parsed["accuracy"]
            page_history.append({"page": page, "accuracy": curr_acc})

            decision_2 = await self.decision.run_policy(
                node="per_page_accuracy", parsed=parse_result.parsed,
                inputs={"page_number": page, "prev_page_accuracy": prev_acc},
                page_history=page_history, effective_config=self.effective_config,
            )
            disp_type = decision_2.final_disposition.type
            if disp_type == "Failure":
                return await self.handle_fail_closed(decision_2)   # 内部 raise FailClosed → 顶层兜底
            prev_acc = curr_acc

            if disp_type == "BoundaryReached":
                boundary_page = decision_2.final_disposition.payload["at_page"]   # = last_high_page
                terminal = "BoundaryReached"
                break
            elif disp_type == "Hopeless":
                return await self.handle_repick(reason=decision_2.final_disposition.payload["reason"])
            else:   # Continue
                # detail 轮(F12)· 翻页前查"下一页"是否可点 · 不可点 = 真实末页 → NoNextPage 终态
                if not await self.has_enabled_next_page():
                    terminal = "NoNextPage"
                    break
                page_before = await self.current_page_number()
                await self.safety.safe_click(semantic="下一页", run_ctx=self.run_ctx)
                # 翻页后页码必须前进 · 否则视为卡死 → fail-closed
                assert await self.current_page_number() > page_before, "翻页未前进 · 疑似卡死"
        else:
            terminal = "MaxPages"   # for 循环正常跑满 max_pages 没 break

        # detail 轮(F12)· boundary_page 终态收口 · 无 BoundaryReached 时回退到 last_high_page
        if boundary_page is None:
            high_pages = [p["page"] for p in page_history if p["accuracy"] >= self.effective_config["boundary_high"]]
            if not high_pages:
                # 跑完/到末页都没出现高精页 → 没东西值得存 → 当 Hopeless 处理(不进保存)
                return await self.handle_repick(reason=f"{terminal}_no_high_accuracy_page")
            boundary_page = max(high_pages)   # 回退:保存到最后高精页(与 policy last_high_page 同义)
        assert boundary_page is not None and boundary_page >= 1, "boundary_page 非法 · 不进保存"

        # 6. 保存数量 = 安全公式求值 · 结果强校验
        # detail 轮(F15)· 不用裸 eval · 走受限 AST 解析器(只放行 boundary_page/整数/+-*//min/max)
        formula = self.effective_config["save_companies_formula"]   # default "boundary_page * 10"
        save_count = safe_arith_eval(formula, allowed_names={"boundary_page": boundary_page},
                                     allowed_funcs={"min": min, "max": max})
        save_count = min(save_count, self.effective_config["max_save_companies"])   # cap default 1000
        # 结果强校验:必须正整数且在 [1, max_save_companies] · 否则 fail-closed(不把脏值带进预算/token)
        assert isinstance(save_count, int) and 1 <= save_count <= self.effective_config["max_save_companies"], \
            f"save_count 非法: {save_count}"
        emails_per_company = self.effective_config["emails_per_company"]   # 整数 · default 5 · range 3-10

        # ① "保存联系人" allowed · 开保存弹窗
        await self.safety.safe_click(semantic="保存联系人", run_ctx=self.run_ctx)

        # detail 轮(F16)· 显式设置/校验弹窗"选择前 N 条" = save_count · 不一致 = fail-closed
        #   防止"用户审批 600 家,弹窗实际按默认 N 保存" · 预算与真实保存数必须对齐
        await self.set_save_modal_count(save_count)
        modal_n = await self.read_save_modal_count()
        assert modal_n == save_count, f"弹窗保存数 {modal_n} ≠ 审批数 {save_count} · fail-closed"

        # detail 轮(N6)· 打标签:弹窗"公司标签/联系人标签"填 label_format 渲染值(SKILL §1 in_scope · saving.tags_applied)
        #   渲染字段单一数据源(contract · decision-prompts §1.1 candidates[].audience_dims):
        #     {lang}/{country}/{role}/{industry} ← chosen_card["audience_dims"](节点 1 输入已结构化定义)
        #     {product}                          ← self.product(用户输入)
        chosen_card = next(c for c in candidates if c["audience_index"] == chosen_audience_id)
        dims = chosen_card["audience_dims"]          # canonical · 必含 lang/country/role · industry 可选
        label_fields = {
            "lang":     dims["lang"],
            "country":  dims["country"],
            "role":     dims["role"],
            "industry": dims.get("industry"),        # 仅此键可选(label_format 含 {industry} 时用 · 缺则留空+warn)
            "product":  self.product,
        }
        tags_applied = render_label(self.effective_config["label_format"], label_fields)
        await self.set_save_modal_tags(tags_applied)   # 填入弹窗标签字段 · 仍是 allowed 编辑 · 不需 token

        # ② Confirm 闸 2 · 审批单轨:guarded = 弹窗"确认转化"(action_id=confirm_save_contacts)
        #   预算预演保守上界 = save_count × emails_per_company × 2(全有效价 · 见 safety-gates § 2.2)
        pre_signed_token = await self.request_user_token(
            action_id="confirm_save_contacts",
            params={"count": save_count, "emails_per_company": emails_per_company,
                    "budget_upper_points": save_count * emails_per_company * 2},
        )
        await self.safety.safe_click(semantic="确认转化", run_ctx=self.run_ctx,
                                     pre_signed_token=pre_signed_token)

        # detail 轮(F21)· 保存是异步任务 · 点确认 ≠ 保存完成 · 轮询任务终态再判 success
        task_id = await self.read_save_task_id()
        final_state = await self.poll_save_task(task_id, timeout_s=self.effective_config["save_task_timeout_s"])   # required_key · 无 fallback
        if final_state != "done":
            # 拿不到终态 = 不能记 success · 记 partial/pending 让用户人工核对
            await self.audit.finalize(result="partial", chosen_audience=chosen,
                boundary_page=boundary_page, saved_count=save_count,
                saving={"task_id": task_id, "task_state": final_state, "tags_applied": tags_applied})
            return await self.pause_and_alert(f"保存任务未达终态({final_state})· 请人工核对")

        # 7. 写回 audit · 只有任务 done 才记 success
        await self.audit.finalize(result="success", chosen_audience=chosen,
            boundary_page=boundary_page, saved_count=save_count,
            saving={"task_id": task_id, "task_state": "done", "tags_applied": tags_applied})


# detail 轮(F17)· 分支退出 contract(原来只有调用点 · 无定义):
#   handle_repick(reason)      → 写 audit result="repick" + reason · 回到节点 1 重选客群(或 abort · 由用户定)· 可 resume
#   handle_fail_closed(d)      → raise FailClosed(node, detail=d) · 交顶层 try 兜底写 audit + pause
#   pause_and_alert(msg)       → 状态转 paused · 通知用户(SkyComputerUseClient)· 不自动 retry · 等人工 resume
#   result 枚举: success / partial / failed / aborted / repick


if __name__ == "__main__":
    import sys
    # detail 轮(F14)· main 职责:读 defaults → 跑 §0.5 启动对话产 user_overrides → 校验派生约束 → 构建 effective_config
    product = sys.argv[1] if len(sys.argv) > 1 else input("产品: ")
    defaults = load_parameters_defaults("parameters-defaults.md")
    user_overrides = run_startup_dialog(defaults)          # SKILL §0.5 · 与用户对话产出(可为空={})
    effective_config = build_effective_config(defaults, user_overrides)   # 内部硬校验派生约束 · 失败 raise · 不启动
    runner = V02SpikeRunner(product_input=product, effective_config=effective_config)
    asyncio.run(runner.run())
```

## 测试期望

### `tests/test_safety_enforcer.py`

```python
# detail 轮(F18)· async 测试契约:safe_click 是 async · 测试用 @pytest.mark.asyncio + async def + await
# r10 · effective_config 一处构建 · 注入所有消费者(测试里 mock 一份 · 与 test_decision_caller 同源)
import pytest
EFFECTIVE_CONFIG = build_effective_config(load_parameters_defaults("parameters-defaults.md"), user_overrides={})

@pytest.mark.asyncio
async def test_blocked_action_raises():
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md", effective_config=EFFECTIVE_CONFIG)
    with pytest.raises(SafetyError):
        await enforcer.safe_click(semantic="发送", run_ctx=CTX)   # 永久 block · 任何 token 都不放行

@pytest.mark.asyncio
async def test_blocked_action_records_audit_hit():
    # detail 轮(F2)· 永久 block 命中必须递增 audit.permanently_blocked_hits(promote 误操作率靠它)
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md", effective_config=EFFECTIVE_CONFIG)
    ctx = make_run_ctx()
    with pytest.raises(SafetyError):
        await enforcer.safe_click(semantic="AI 评分", run_ctx=ctx)
    assert ctx.audit.permanently_blocked_hits == 1

@pytest.mark.asyncio
async def test_guarded_action_without_token_fail_closed():
    # r10 审批单轨:guarded 动作缺 pre_signed_token = fail-closed(gates 绝不自签)
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md", effective_config=EFFECTIVE_CONFIG)
    with pytest.raises(SafetyError, match="requires pre_signed_token"):
        await enforcer.safe_click(semantic="确认转化", run_ctx=CTX, pre_signed_token=None)

@pytest.mark.asyncio
async def test_guarded_action_with_pre_signed_token_consumes():
    # r10 · guarded = 弹窗"确认转化"(action_id=confirm_save_contacts)· 带 runner 预签 token → gates 只 consume
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md", effective_config=EFFECTIVE_CONFIG)
    token = make_valid_token(action_id="confirm_save_contacts")   # runner 预签 mock
    await enforcer.safe_click(semantic="确认转化", run_ctx=CTX, pre_signed_token=token)   # no exception

@pytest.mark.asyncio
async def test_guarded_token_payload_mismatch_fail_closed():
    # detail 轮(F18)· token 错配负例:action_id / payload / sig 任一不符 → consume 失败 → raise
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md", effective_config=EFFECTIVE_CONFIG)
    wrong = make_valid_token(action_id="some_other_action")        # action_id 不匹配 confirm_save_contacts
    with pytest.raises(SafetyError, match="consume failed"):
        await enforcer.safe_click(semantic="确认转化", run_ctx=CTX, pre_signed_token=wrong)
    tampered = make_token_with_bad_sig(action_id="confirm_save_contacts")   # sig 被篡改
    with pytest.raises(SafetyError, match="consume failed"):
        await enforcer.safe_click(semantic="确认转化", run_ctx=CTX, pre_signed_token=tampered)

@pytest.mark.asyncio
async def test_allowed_action_passes():
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
    # detail 轮 · 双页连续 < 0.6 · boundary_page = last_high_page(最后一个 >=0.80 页 · 不是 page-2)
    caller = DecisionCaller.from_md_sections("decision-prompts.md", effective_config=EFFECTIVE_CONFIG)
    # 1-60 高精(0.85)· 61/62 双低(0.5)· last_high_page = 60
    page_history = [{"page": p, "accuracy": 0.85} for p in range(1, 61)] + \
                   [{"page": 61, "accuracy": 0.5}, {"page": 62, "accuracy": 0.5}]
    parsed = {"accuracy": 0.5, ...}
    result = caller.run_policy("per_page_accuracy", parsed=parsed,
        inputs={"page_number": 62, "prev_page_accuracy": 0.5},
        page_history=page_history, effective_config=caller.effective_config)
    assert result.final_disposition.type == "BoundaryReached"
    assert result.final_disposition.payload["at_page"] == 60   # last_high_page
    assert "save_companies" not in result.final_disposition.payload   # runner 用 formula(at_page) 求
    assert result.final_disposition.payload["note"] == "two_consecutive_low_pages_confirm"

def test_boundary_excludes_middle_zone_pages():
    # detail 轮(F7 · Tony 决策)· 中间区(0.60-0.79)页不纳入保存 · at_page 只到最后高精页
    caller = DecisionCaller.from_md_sections("decision-prompts.md", effective_config=EFFECTIVE_CONFIG)
    # 1-50 高精(0.85)· 51-55 中间区(0.70)· 56/57 双低(0.5)· last_high_page = 50(不是 55)
    page_history = [{"page": p, "accuracy": 0.85} for p in range(1, 51)] + \
                   [{"page": p, "accuracy": 0.70} for p in range(51, 56)] + \
                   [{"page": 56, "accuracy": 0.5}, {"page": 57, "accuracy": 0.5}]
    result = caller.run_policy("per_page_accuracy", parsed={"accuracy": 0.5, ...},
        inputs={"page_number": 57, "prev_page_accuracy": 0.5},
        page_history=page_history, effective_config=caller.effective_config)
    assert result.final_disposition.type == "BoundaryReached"
    assert result.final_disposition.payload["at_page"] == 50   # 中间区 51-55 被排除

def test_hopeless_requires_min_pages():
    # detail 轮(F6 · Tony 决策)· Hopeless 至少看满 hopeless_min_pages(default 3)页才触发 · 第1页低不立刻放弃
    caller = DecisionCaller.from_md_sections("decision-prompts.md", effective_config=EFFECTIVE_CONFIG)
    # 第 1 页低(0.3)· 只有 1 页历史 → 不该 Hopeless(应 Continue 翻下页确认)
    r1 = caller.run_policy("per_page_accuracy", parsed={"accuracy": 0.3, ...},
        inputs={"page_number": 1, "prev_page_accuracy": None},
        page_history=[{"page": 1, "accuracy": 0.3}], effective_config=caller.effective_config)
    assert r1.final_disposition.type == "Continue"   # 不是 Hopeless
    # 满 3 页都低 → Hopeless
    r3 = caller.run_policy("per_page_accuracy", parsed={"accuracy": 0.3, ...},
        inputs={"page_number": 3, "prev_page_accuracy": 0.3},
        page_history=[{"page": 1, "accuracy": 0.3}, {"page": 2, "accuracy": 0.3}, {"page": 3, "accuracy": 0.3}],
        effective_config=caller.effective_config)
    assert r3.final_disposition.type == "Hopeless"

def test_save_count_from_formula():
    # r10 · 保存数量唯一来源 = runner 用 effective_config 公式求值(不读 policy payload)
    save_count = safe_arith_eval(EFFECTIVE_CONFIG["save_companies_formula"], allowed_names={"boundary_page": 60}, allowed_funcs={"min": min, "max": max})
    save_count = min(save_count, EFFECTIVE_CONFIG["max_save_companies"])
    assert save_count == 600   # default 公式 boundary_page * 10 · cap 1000
```

## W3 启动前需补全

- [ ] Codex `computer-use` / `chrome` plugin 实际 API 文档(spike 时查 · `browser-use` 已确认不存在 · 删除)
- [ ] OCR 工具选型(Codex 已含还是外接 tesseract?)
- [ ] 同义词词典初版(`safety-gates.md` § 1 已列 · 但归一化逻辑要实现)
- [ ] 用户 token 通知 UI 接入(SkyComputerUseClient.app 接口)
- [ ] 跨设备 artifacts.json hash 校验脚本
- [ ] **`safe_arith_eval(formula, allowed_names, allowed_funcs)`**(detail 轮 F15)· 受限 AST 求值器:`ast.parse(mode="eval")` 只放行 `Num/Constant/Name(白名单)/BinOp(+-*/)/Call(min/max)` · 拒 `import/attr/lambda/下标` · 防 `save_companies_formula` 代码注入 · 结果非 int 或越 [1, max_save_companies] → raise
- [ ] **`RunContext`**(detail 轮 F13)· 含 `record_blocked(reason, screenshot)` 递增 `audit.permanently_blocked_hits` · `update_state(...)` · 所有 `safe_click` 共用一个实例
- [ ] **异步保存轮询**(detail 轮 F21)· `read_save_task_id()` + `poll_save_task(task_id, timeout_s)` 查保存任务终态 · done 才记 success
- [ ] **弹窗保存数对账**(detail 轮 F16)· `set_save_modal_count(n)` + `read_save_modal_count()` · 不一致 fail-closed
- [ ] **末页检测**(detail 轮 F12)· `has_enabled_next_page()` + `current_page_number()` · 翻页后页码必前进
- [ ] **分支 contract**(detail 轮 F17)· `handle_repick(reason)` / `handle_fail_closed(d)` / `pause_and_alert(msg)` 落 audit + result 枚举
- [ ] **`build_effective_config(defaults, user_overrides)`**(detail 轮 F14)· 合并 + **硬校验派生约束**(boundary_low<high-0.10 / hopeless_min<=window / flag<auto / token<=ceiling)· 任一违约 raise · 不生成 config · 不启动
- [ ] **`run_startup_dialog(defaults)`**(detail 轮 F14)· SKILL §0.5 启动对话 · 产 user_overrides(active 组必问 · inactive 折叠)
- [ ] **客群卡片维度解析**(detail 轮 N6)· `read_inference_results()` 解析推演卡片 → 填 candidates[].audience_dims{lang,country,role,industry}(decision-prompts §1.1 canonical · render_label 的单一数据源)
- [ ] **`render_label(label_format, label_fields)`** + **`set_save_modal_tags(tags)`**(detail 轮 N6)· label_fields 取自 chosen_card["audience_dims"] + product · 仅 {industry} 可缺(留空+warn)· 渲染 → 填保存弹窗"公司/联系人标签" → saving.tags_applied

## 关联

- 主 SKILL.md(本目录上一级)
- safety-gates.md(本目录上一级)
- decision-prompts.md(本目录上一级)
- spec(已归档):`specs/done/2026-06-17-laifa-browser-agent-v0.2.md`(本仓)
- 关键决策:`wiki/history/2026-06-laifa-browser-agent-v0.2-design.md`(本仓)
