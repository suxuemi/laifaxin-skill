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
        # safety-gates.md / decision-prompts.md 是文档+数据源(markdown 内嵌 yaml 块)
        # 加载方式:提取 fenced ```yaml 块 → 拼接 → schema validate
        self.safety = SafetyEnforcer.from_md_sections("safety-gates.md")
        self.decision = DecisionCaller.from_md_sections("decision-prompts.md")
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
        #    page_history 时机:DecisionCaller **内部**先 append 当前页 + accuracy,再跑 decision policy
        #    所以 stub 内 page_history 反映"截至上一页"· DecisionCaller 入参也含 prev_page_accuracy
        page_history = []   # 累积"已 decide 完"的历史(不含正在 decide 的当前页)
        prev_acc = None
        boundary_page = None
        chosen_audience_id = chosen   # chosen 是 audience_index 整数 · LLM 节点 1 输出
        for page in range(1, 1000):
            rows = await self.read_current_page()
            decision_2 = await self.decision.call(
                node="per_page_accuracy",
                inputs={
                    "page_number": page,
                    "rows": rows,
                    "product_positioning": self.product,
                    "audience_context": {"audience_id": chosen_audience_id},   # 结构化 · 不传整数
                    "cumulative_pages_read": page,
                    "prev_page_accuracy": prev_acc,   # None on first page
                },
                page_history=page_history,             # DecisionCaller 内部会 append 当前页再判 policy
            )

            # ⚠️ 必须先判 final_disposition.type · Failure 路径可能没 payload
            disp_type = decision_2.final_disposition.type
            if disp_type == "Failure":
                return await self.handle_fail_closed(decision_2)   # 先于 payload 读取

            # 此处保证 final_disposition.payload 有 accuracy(Continue / BoundaryReached / Hopeless 都填)
            curr_acc = decision_2.final_disposition.payload.get("accuracy")
            page_history.append({"page": page, "accuracy": curr_acc})
            prev_acc = curr_acc

            if disp_type == "BoundaryReached":
                boundary_page = decision_2.final_disposition.payload["at_page"]   # 已是"最后准页"
                break
            elif disp_type == "Hopeless":
                return await self.handle_repick()
            else:   # Continue
                await self.safety.safe_click(semantic="下一页")

        # 6. 保存范围 = boundary_page × 10(boundary_page 已是最后准页 · 不再 -1)
        save_count = boundary_page * 10
        token = await self.request_user_token(
            action="保存",
            params={"count": save_count, "emails_per_company": "5-10"}
        )   # Confirm 闸 2
        await self.execute_save(save_count, token)

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
def test_blocked_action_raises():
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md")
    with pytest.raises(SafetyError):
        enforcer.check_click(semantic="发送")   # 永久 block

def test_guarded_action_requires_token():
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md")
    with pytest.raises(SafetyError, match="No token"):
        enforcer.check_click(semantic="确认转化", token=None)

def test_allowed_action_passes():
    enforcer = SafetyEnforcer.from_md_sections("safety-gates.md")
    enforcer.check_click(semantic="搜索")   # no exception
```

### `tests/test_decision_caller.py`

```python
def test_llm_node_1_returns_one_audience():
    # contract 对齐 decision-prompts.md § 1.3 新 schema
    caller = DecisionCaller.from_md_sections("decision-prompts.md")
    result = caller.call("choose_audience", inputs={...})
    assert result.chosen in [1, 2, 3, 4, None]
    assert len(result.evidence_snippets) >= 1
    assert len(result.applied_rules) >= 1
    assert result.why_not_top_alt.audience_index in [0, 1, 2, 3, 4]
    # ⚠️ 不再 assert confidence / reasoning · r1/r2 已降级为 audit 字段(不参与决策门)

def test_llm_node_2_boundary_detection():
    # contract 对齐 § 2.4 新 disposition · 不是 verdict enum 字符串
    caller = DecisionCaller.from_md_sections("decision-prompts.md")
    rows_high_match = [{"description": "We import LED outdoor lighting from China"} for _ in range(10)]
    result = caller.call("per_page_accuracy", inputs={"rows": rows_high_match, "prev_page_accuracy": 0.85, ...})
    assert result.final_disposition.type in ["Continue", "BoundaryReached", "Hopeless", "Failure"]
    # r5 #1 修 · accuracy 在 final_disposition.payload · 不是 result.payload
    assert 0.0 <= result.final_disposition.payload["accuracy"] <= 1.0

def test_llm_node_2_two_page_boundary_calculation():
    # r2 #2 必修 · 双页连续 < 0.6 · boundary_page = page - 2(最后准页)
    caller = DecisionCaller.from_md_sections("decision-prompts.md")
    # 模拟第 62 页 · 当前 0.5 / 上一页(第 61) 0.5
    result = caller.call(
        "per_page_accuracy",
        inputs={"page_number": 62, "rows": [...], "prev_page_accuracy": 0.5, ...},
        page_history=[{"page": p, "accuracy": 0.85} for p in range(1, 61)] + [{"page": 61, "accuracy": 0.5}],
    )
    assert result.final_disposition.type == "BoundaryReached"
    assert result.final_disposition.payload["at_page"] == 60   # page - 2 · 最后准页是第 60 页
    assert result.final_disposition.payload["save_companies"] == 600
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
