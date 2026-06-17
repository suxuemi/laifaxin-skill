---
name: laifaxin-outreach-v0.2 · safety-gates
type: meta
status: active
version: 0.2.0-alpha.2
created: 2026-06-17
updated: 2026-06-17
tags: [v0.2, safety, browser-agent, codex, scope-restricted, executor-path]
description: v0.2 alpha 浏览器 agent 安全闸 yaml 配置 · r1 deep-review 全面重写 · scope 严格收缩到"搜客+翻页+保存"· sequence/template/AI 评分整模块永久 block · primitive 区分 chrome vs computer-use 双路 · controller 级 token 原子消费(待 W3 落地)
---

# Safety Gates · v0.2 alpha(r1 + r2 deep-review 重写版)

> **机器可读规则加载说明**(r2 #2 修复):本文件**既是文档也是数据源**。runner 加载方式:
> 1. 解析本文 markdown · 提取所有 fenced ```yaml 块拼接
> 2. 验证拼接后的 yaml schema
> 3. 运行时使用 · 见 `runners/README.md` § safety_enforcer
>
> 严禁直接 `from_yaml("safety-gates.md")`(本文是 md 不是 yaml)· 改用 `from_md_sections("safety-gates.md")`

> **r1 deep-review 反馈**:原版 🔴 大改 · 21 条硬伤
> - 白名单只覆盖搜客+保存一小段 · sequence/template/AI 评分模块漏
> - `开关变蓝` 不是按钮文本(状态描述)· 无法匹配
> - `ocr_extract / current_url / page_title` 不是 computer-use 原生能力
> - token 系统假接口 · hash 可预测 · 无原子操作 · SkyComputerUseClient Y/N 回调 API 未坐实
> - 高风险动作"确认添加(active plan) / AI 评分全链路 / 激活开关" 无 controller 级硬规则
>
> **重写策略**:
> 1. **收 scope** · alpha 只做"搜客+翻页+保存" · 其他模块整体永久 block
> 2. **二分执行路** · chrome(有 URL/title/accessibility)vs computer-use(看图 + accessibility text)
> 3. **删伪 primitive** · 改"拟议实现 · W3 落地"
> 4. **controller 级原子规则** · single-controller + sqlite store + HMAC token

## § 0 · Alpha Scope(硬约束 · 不可越界)

```yaml
alpha_scope:
  in:
    - 搜客户(AI 数据库 / AI 推演 / 翻页 / 找相似)
    - 翻页判精度(LLM 节点 2)
    - 保存联系人(单家 5-10 邮箱 · 动态范围)

  out:                              # 整模块永久 block · agent 不许碰
    - 智能跟进计划(任何操作 · 创建 / 编辑 / 加客户 / 激活)
    - 邮件模板(任何操作 · 创建 / 编辑 / 测试 / 发送)
    - AI 评分(任何按钮 · 全链路)
    - 邮件群发(任何操作)
    - 邮件收发(任何操作)
    - 客户管理删除 / 导出 / 黑名单
    - 设置(账号 / 通道 / 权限 / 充值)
```

**scope 越界检测**:agent 状态机进入 out 模块的页面 url(如 `/marketing/sequences/*`) → 立即 pause + alert。

## § 1 · Executor 路二选一

> **r1 #D3.2**:`chrome` 和 `computer-use` 不是同一执行器 · 公开 API 不同。

| 路 | 实证(codex plugin list) | 使用场景 |
|---|---|---|
| **computer-use@openai-bundled** | ✅ installed, enabled · 有 `screenshot` / macOS accessibility / `action` | **主路 · 唯一执行器** · Tony § 0 #4 不加 data-test-id · 看屏幕 + macOS a11y 是唯一稳定方案 |
| **chrome@openai-bundled** | ✅ installed, enabled · Chrome tab 管理 / URL / 状态查询 | 辅助 · 仅做页面上下文判断(URL / tab 状态)· 不做点击 |
| **browser@openai-bundled** | ✅ installed, enabled · 通用浏览器原语 | 不在 alpha 主路 |
| ~~browser-use@openai-bundled~~ | 🔴 **不存在**(`~/.codex/config.toml` 旧配置 · `codex plugin list` 已无此 plugin) | 删除所有依赖 |

**关键决定(架构修正后)**:
- alpha 主路:**computer-use 单路点击 + 看图 + macOS a11y**
- `chrome` plugin 辅助:**仅查 URL / tab title** 给 scope-out 检测做上下文判断 · 不做点击
- ⚠️ 不再依赖 `browser-use` 任何能力(plugin 实证不存在)

## § 2 · 白名单(scope 内 · 按真实按钮文案)

> **r1 #D1.1-1.6**:对账 docs/zhinan/refine-search-all + 00-quickstart-10min + 03-save-customers + email-templates 真实按钮文本。

### 2.1 Allowed(scope 内 · 普通点击 · 不需 token)

```yaml
allowed_button_semantics:
  # 搜客户(AI 数据库 / 推演 / 翻页)
  - "搜索"
  - "AI 推演"
  - "AI 智能生成"         # r1 #D1.1 补 · refine-search-all L108 / 00-quickstart L69
  - "立即查看"            # 推演结果客群卡片
  - "找相似"
  - "下一页"
  - "上一页"
  - "高级"
  - "返回"
  - "取消"

  # 保存联系人(列表 → 选 → 触发保存)
  - "保存联系人"          # 列表顶部按钮 · 弹窗不算
```

### 2.2 Guarded(需 token · controller 原子消费)

```yaml
guarded_actions:
  - action_id: confirm_save_contacts
    button_semantics: ["确认转化", "确认保存"]    # r1 #D2.1 真实文案 · 不是"确定"
    page_routes:                                  # r3 #2 结构化 · 不用 OR 字符串
      - "/search/refine-search"
      - "/search/customer-list"
    modal_indicator:                                 # 多重证据 · 不靠单一 URL
      heading_contains: ["保存联系人", "确认转化"]
      form_field_present: ["公司标签", "联系人标签"]
    required_token: true
    budget_estimate:                              # r3 #2 结构化字段
      selected_count_source:
        type: read_modal_field
        field_label: "选择前 [N] 条数据"
        value_extractor: "数字"
      unit_price_source:
        type: constant
        value: 1.0                                # 1 邮箱 = 1 点
      formula: "selected_count × emails_per_company × unit_price"
```

### 2.3 Permanently Blocked(scope 外 · 任何情况不点)

```yaml
permanently_blocked:
  # 发送 / 群发(scope 外)
  - "发送"
  - "群发"
  - "发送邮件"
  - "分别发送"
  - "确认发送"
  - "立即发送"

  # 计划激活 / 启动(scope 外)
  - "激活"
  - "启用"
  - "启动"
  # ⚠️ r1 #D1.5 删除 "开关变蓝"(不是按钮文本)· 改 § 3 状态规则

  # 计划 / 步骤创建 + 编辑(scope 外 · r1 #D1.2 整模块 block)
  - "+ 计划"
  - "+ 添加第一个跟进步骤"
  - "+ 添加跟进步骤"
  - "添加联系人"          # 计划"添加联系人"按钮
  - "确认添加"            # ⚠️ r1 #D2.4 关键:active plan 上的确认添加 = 准发送触发器
  - "保存"                # 计划设置保存

  # 模板 + 签名(scope 外 · r1 #D1.3 整模块 block)
  - "+ 目录"
  - "+ 模板"
  - "创建"                # 模板创建
  - "修改"                # 模板修改
  - "插入变量"
  - "插入签名"
  - "新建签名"

  # AI 评分全链路(scope 外 · Tony § 0 #8 + r1 #D1.4 完整封堵)
  - "AI 评分"
  - "评分"
  - "开始评分"
  - "提交"                # AI 评分弹窗的提交
  - "查看详细报告"         # 评分报告(读权也 block · 引导用户错觉)

  # 删除 / 导出
  - "删除"
  - "彻底删除"
  - "导出"
  - "导出数据"
  - "导出联系人"

  # 黑名单 / 拒收 / 举报 / 退订
  - "加入黑名单"
  - "移出黑名单"
  - "添加到黑名单"
  - "拒收"
  - "举报"
  - "退订"

  # 权限 / 授权 / 充值
  - "权限"
  - "授权"
  - "确认充值"
```

## § 3 · 状态级规则(非按钮文本)· r1 #D1.5

某些危险动作不是"点按钮"而是"切换状态"或"组合操作":

```yaml
state_rules:
  # 智能跟进计划激活(开关 off → on · 视觉颜色变化 · 没文本)
  - rule_id: sequence_activation
    detection:
      page_route_match: "/marketing/sequences/*"
      control_role: "switch"
      state_transition: "off → on"
    action: permanently_blocked

  # AI 评分按钮 hover 预览(r5 必修 · 改用真可用 primitive · 不用 element_class)
  - rule_id: ai_rating_hover
    detection:
      page_url_match: "/search/refine-search"      # chrome.tab_url() 拿到
      button_text_contains_any: ["AI 评分", "评分", "开始评分"]   # OCR + a11y 拿到
    action: permanently_blocked

  # active sequence 上的 "确认添加"(r1 #D2.4 高优先)
  - rule_id: active_sequence_confirm_add
    detection:
      page_route_match: "/marketing/sequences/*/contacts"
      sequence_state: "active"           # 通过开关颜色 / accessibility state 检测
      button_text: "确认添加"
    action: permanently_blocked          # 比普通 confirm_add 更严
```

## § 4 · Controller Architecture(r1 #D3.5 + D4.1-D4.3 必修)

```
              ┌──────────────────────────┐
              │   Orchestration Loop      │
              │   (Codex CLI · LLM-driven)│
              └────────────┬─────────────┘
                           │
                           ▼
              ┌──────────────────────────┐
              │  Safety Controller        │  ← 单一 owner
              │  (single python process)  │
              │  - token store: sqlite    │
              │  - file lock              │
              │  - scope state machine    │
              └────────────┬─────────────┘
                           │
              ┌────────────┴─────────────┐
              ▼                          ▼
     ┌──────────────┐          ┌──────────────┐
     │ chrome  │          │ computer-use │
     │ executor     │          │ executor     │
     └──────────────┘          └──────────────┘
```

### 4.0 Token canonical payload(r5 必修 · issue + consume + click 三处统一)

```python
# canonical_payload 是唯一序列化函数 · 三处都用同一调用
def canonical_payload(button_target):
    """Stable serialization for HMAC signature."""
    return json.dumps({
        "selector_kind": button_target.kind,    # "a11y_node" | "coords"
        "semantic": button_target.semantic,     # 按钮文本 normalize
        "page_url": button_target.page_url,
        "page_title": button_target.page_title,
    }, sort_keys=True)

# Usage(必须保证 issue 和 consume 用同一 payload):
payload = canonical_payload(button_target)
token = controller.token_store.issue(action_id, payload)
# ... user approves ...
controller.token_store.consume(token.id, action_id, payload)   # ← 同 payload · 不用 button_target
```

### 4.1 Token store(待 W3 落地)

```python
# 拟议实现(W3 spike 实测后定稿)
class TokenStore:
    """Single-controller-owned · sqlite-backed · file lock."""
    path: str = "~/.codex/runs/<run_id>/tokens.sqlite"

    def issue(self, action_id, canonical_payload) -> Token:
        # 1. 生成不可预测的 token_id (urandom)
        token_id = secrets.token_urlsafe(32)
        # 2. HMAC(signing_key 来自 ~/.codex/keys/safety.key)
        sig = hmac_sha256(signing_key, f"{token_id}:{action_id}:{canonical_payload}")
        # 3. INSERT with file lock
        with file_lock:
            conn.execute(
                "INSERT INTO tokens(id, action_id, sig, issued_at, expires_at, consumed) "
                "VALUES (?, ?, ?, ?, ?, FALSE)",
                ...
            )
        # α.3 起从 effective_config 读 · 不再硬编码 300 秒
        expire_seconds = effective_config["token_expire_minutes"] * 60   # default 5 min
        return Token(token_id, sig, expires_at=now() + expire_seconds)

    def consume(self, token_id, action_id, canonical_payload) -> bool:
        # Atomic compare-and-swap
        with file_lock:
            row = conn.execute("SELECT sig, consumed, expires_at FROM tokens WHERE id = ?", (token_id,)).fetchone()
            if not row: return False
            if row.consumed: return False
            if datetime.now() > row.expires_at: return False
            expected_sig = hmac_sha256(signing_key, f"{token_id}:{action_id}:{canonical_payload}")
            if not constant_time_eq(row.sig, expected_sig): return False
            conn.execute("UPDATE tokens SET consumed = TRUE WHERE id = ?", (token_id,))
        return True
```

### 4.2 Token 状态机(r1 #D4.5 加 revoke / abandoned)

```
issued ─────► armed (waiting user) ─────► consumed ─► terminal
   │              │
   │              ├──► revoked (user cancelled)
   │              ├──► abandoned (user no response · timeout 5min)
   │              └──► expired (auto · 5min)
   │
   └──► (multi-issue 不允许 · 同 run_id 同 action 同 payload → 拒)
```

**Abandon flow**:
- 5 分钟内用户无响应 → token 状态 `abandoned`
- run 全局状态 → `paused`
- 不重弹 · 等用户主动 resume(`codex exec resume <SESSION_ID>` · ⚠️ SESSION_ID 是 Codex UUID · 不是 run_id timestamp slug · 见 HOW-TO-START § 4.3)

## § 5 · 7 步语义识别 SOP(r1 #D3.1-3.4 + r2 #4 必修)

```python
def safe_click(button_target, run_ctx):
    # 1. screenshot · computer-use 公开 API(主路)
    screenshot = await computer_use.screenshot()

    # 2. 主路 computer-use + macOS a11y · 看屏幕优先(对齐 § 1 主路 = computer-use)
    #    辅助路 chrome 提供 url/title(若可用)
    page_url = None
    page_title = None
    if chrome_plugin_available():                          # codex chrome@openai-bundled
        try:
            page_url = await chrome.tab_url()              # 辅助 · 仅做页面上下文
            page_title = await chrome.tab_title()
        except Exception:
            pass

    try:                                                   # r4 a11y try/except 防整段崩
        macos_a11y = await computer_use.accessibility_tree()
    except Exception:
        macos_a11y = None                                  # 截图坐标兜底走得到

    # locate_by_accessibility MUST tolerate None macos_a11y(r5 必修)
    # 实现合同:if macos_a11y is None: return None  (退到截图坐标兜底分支)
    button_node = locate_by_accessibility(macos_a11y, button_target)

    # actuation_target 记录最终点击用什么(coords or a11y node) · r3 #1 必修
    if button_node and button_node.text:
        text = button_node.text                            # 主路成功:a11y 拿到按钮文本
        confidence = 0.95
        actuation_target = ("a11y_node", button_node)      # 用 a11y node 点击(更稳)
    else:
        # 兜底:看截图 + LLM 推理按钮文本 + 推理可点击坐标
        text, confidence, coords = await llm_extract_button_text_and_coords(screenshot, button_target)
        if confidence < 0.85 or coords is None:
            return Fail("computer-use button text or coords low confidence", screenshot)
        actuation_target = ("coords", coords)              # 用屏幕坐标点击

    # 后续 page_url / page_title / macos_a11y 可为 None · matchers 必须接受 None
    a11y_tree = macos_a11y                                 # 统一变量名 · 给 § 5 后续 step 用

    # 3. normalize · curated synonym map(r1 #D3.4 不上 cosine/embedding)
    normalized = normalize_via_curated_map(text)

    # 4. state rules 优先匹配(§ 3)
    for rule in state_rules:
        if rule.detection.matches(page_url, page_title, a11y_tree, button_target):
            if rule.action == "permanently_blocked":
                return SafetyError("blocked by state rule: " + rule.rule_id, screenshot)

    # 5. context-aware demotion(§ 2.2 guarded_actions)
    matched_guarded = match_guarded_action(normalized, page_url, page_title, a11y_tree)

    # 6. 三层匹配
    if normalized in permanently_blocked:
        return SafetyError("permanently blocked: " + normalized, screenshot)
    if matched_guarded:
        # r5 必修 · issue + consume + click 三处用同一 canonical_payload
        payload = canonical_payload(button_target)
        token = await controller.await_user_token(action_id=matched_guarded.action_id, payload=payload)
        if not token: return SafetyError("no token / abandoned")
        consumed = controller.token_store.consume(token.id, matched_guarded.action_id, payload)
        if not consumed: return SafetyError("token consume failed")
        # 真实点击
        await computer_use.click(actuation_target)         # r3 #1 · 真用 actuation_target(a11y_node 或 coords)
        run_ctx.update_state(action_taken=matched_guarded.action_id)
        return
    if normalized in allowed:
        await computer_use.click(actuation_target)         # r3 #1 · 真用 actuation_target(a11y_node 或 coords)
        run_ctx.update_state(action_taken=normalized)
        return

    # 7. 白名单制 · 不在任何列表 → 拒
    return SafetyError("unknown action (whitelist mode): " + normalized)
```

## § 6 · Curated Synonym Map(W2 写完整版 · alpha 起步)

```yaml
synonym_map:
  "保存联系人":
    - "保存联系人"
    - "save contacts"
  "确认转化":
    - "确认转化"
    - "确认保存"
    - "confirm save"
  "AI 推演":
    - "AI 推演"
    - "ai inference"
  "AI 智能生成":
    - "AI 智能生成"
    - "ai generate"
  # ... (W2 实施时补全 W3 实测中补漏)
```

**严禁**:cosine similarity / embedding 模糊匹配(误放行风险) · alpha 期只用 normalize + curated map · 不命中 = deny。

## § 7 · 失败回退矩阵

| 异常 | 检测 | 回退 |
|---|---|---|
| 按钮 a11y 找不到 | 节点不存在 | 截图 + 停 + alert |
| computer-use OCR confidence < 0.85 | LLM 自报 | 不点 · 截图 + 停 |
| URL/页面意外跳到 scope out 模块(§ 0)| 状态机检测 | 立即停 + alert |
| Synonym map 不命中 | normalize 后无匹配 | deny + 截图 |
| 充值 / 权限 / 授权弹窗 | 模式匹配 page url + 标题 | 停 + 截图 + 报告"用户处理" |
| Active sequence 上的"确认添加" | state_rule 触发 | 立即停 + alert(高优先) |
| Token consume 原子失败 | sqlite 事务 conflict | 重新走 § 4.1 流程(最多 3 次) |
| Token abandoned(5min 无响应)| 计时器 | run 转 paused · 等用户 resume |
| 操作速率超阈(反爬)| 内部限速器(< 1 click/秒) | 自动 sleep + jitter(2-5s) |

## § 8 · 已知未坐实接口(W3 实测前 · 待实证)

> **r1 #D4.4 必修**:不把假接口写成既成事实

| 项 | 当前状态 | W3 实测 SOP |
|---|---|---|
| `computer-use` 是否原生 OCR | ⚠️ 公开面只有 screenshot / a11y / action · 未见 OCR primitive | W3 spike:试用 vision API · 看是否能直接读屏文本 |
| `chrome` `url() / title()` | ⚠️ 文档暗示有 · 未在本会话实证调用 | W3 spike:`codex exec` 让 Codex 调 chrome plugin 跑 hello-world |
| `SkyComputerUseClient.app` Y/N callback API | ⚠️ 二进制内有 `approvalStore / approval_requested` 字符串 · 但公开 contract 未坐实 | W3 spike:让 Codex 发起一次 approval · 看 callback 真实 schema |
| `accessibility_tree` 获取方式 | ⚠️ 推测有 · 未实证 | W3 spike:跑 hello-world |
| controller-process 与 Codex orchestration 的 IPC | ⚠️ 拟议 single-controller + sqlite + file lock | W3 写 controller stub · 跑 multi-agent 并发测 token 唯一 |

## § 9 · 一句话总结(对齐 v0.1 风格)

**Alpha scope 严格收缩到搜客+保存 · 其他全 block · 白名单制 + curated synonym + controller-owned token + state rules + computer-use 主路(macOS a11y + screenshot)+ chrome 辅助(URL/title 上下文)· 关键 primitive 待 W3 坐实**

## § 10 · 关联

- 主 SKILL.md(本目录)
- decision-prompts.md(本目录 · 决策门用可验证条件 · 不用 self-confidence)
- runners/README.md(本目录 · safety_enforcer.py 实现 § 4-7 controller)
- spec § 4(本仓 specs/done/)
- r1 deep-review:`raw/inbox/2026-06-17-codex-deep-审-safety-gates.md`
