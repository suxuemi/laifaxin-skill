---
name: laifaxin-outreach-v0.2 · safety-gates
type: meta
status: active
version: 0.2.0-alpha.2
created: 2026-06-17
updated: 2026-06-17
tags: [v0.2, safety, browser-agent, codex, scope-restricted, executor-path]
description: v0.2 alpha 浏览器 agent 安全闸 yaml 配置 · r1 deep-review 全面重写 · scope 严格收缩到"搜客+翻页+保存"· sequence/template/AI 评分整模块永久 block · primitive 区分 browser-use vs computer-use 双路 · controller 级 token 原子消费(待 W3 落地)
---

# Safety Gates · v0.2 alpha(r1 deep-review 重写版)

> **r1 deep-review 反馈**:原版 🔴 大改 · 21 条硬伤
> - 白名单只覆盖搜客+保存一小段 · sequence/template/AI 评分模块漏
> - `开关变蓝` 不是按钮文本(状态描述)· 无法匹配
> - `ocr_extract / current_url / page_title` 不是 computer-use 原生能力
> - token 系统假接口 · hash 可预测 · 无原子操作 · SkyComputerUseClient Y/N 回调 API 未坐实
> - 高风险动作"确认添加(active plan) / AI 评分全链路 / 激活开关" 无 controller 级硬规则
>
> **重写策略**:
> 1. **收 scope** · alpha 只做"搜客+翻页+保存" · 其他模块整体永久 block
> 2. **二分执行路** · browser-use(有 URL/title/accessibility)vs computer-use(看图 + accessibility text)
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

> **r1 #D3.2**:`browser-use` 和 `computer-use` 不是同一执行器 · 公开 API 不同。

| 路 | API 真实可用性 | 使用场景 |
|---|---|---|
| **browser-use** | ✅ 有 `url()` / `title()` / `accessibility_tree` / `click` / `type` | 主路 · 任何能拿 DOM 的页面 |
| **computer-use** | ⚠️ 有 `screenshot` / `accessibility` / `action` · 没有 `url()` / `title()` 直接 API | 兜底 · 仅当 browser-use 失败时降级使用 |

**关键决定**:
- alpha 主路用 **browser-use**(URL/title 都有)
- computer-use 仅做兜底 · 用时不能依赖 URL/title · 改用 page heading / breadcrumb / accessibility tree(置信度低就拒绝)

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
    page_route: "/search/refine-search OR /search/customer-list"
    modal_indicator:                                 # 多重证据 · 不靠单一 URL
      heading_contains: ["保存联系人", "确认转化"]
      form_field_present: ["公司标签", "联系人标签"]
    required_token: true
    pre_action_budget_check:                        # 提交前预算预演
      - sample_estimate_via: read_modal "选择前 [N] 条数据" + 邮箱单价
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

  # AI 评分按钮 hover 预览(避免 OCR 漏 fp)
  - rule_id: ai_rating_hover
    detection:
      page_route_match: "/search/refine-search"
      element_class_contains: ["ai-rating-button", "rating-trigger"]
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
     │ browser-use  │          │ computer-use │
     │ executor     │          │ executor     │
     └──────────────┘          └──────────────┘
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
        return Token(token_id, sig, expires_at=now()+300)   # 5 min

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
- 不重弹 · 等用户主动 resume(`codex exec --resume <run_id>`)

## § 5 · 7 步语义识别 SOP(r1 #D3.1-3.4 必修 · 改 primitive)

```python
def safe_click(button_target, run_ctx):
    # 1. screenshot · computer-use 公开 API
    screenshot = await computer_use.screenshot()

    # 2. r1 #D3.1 改 · 优先 accessibility tree(原生)· OCR 是兜底(W3 实测后定)
    if browser_use_available():
        a11y_tree = await browser_use.accessibility_tree()
        page_url = await browser_use.url()           # r1 #D3.2 仅 browser-use 路有
        page_title = await browser_use.title()
        button_node = locate_by_accessibility(a11y_tree, button_target)
        if button_node:
            text = button_node.text
        else:
            return Fail("button not found in a11y tree")
    else:
        # computer-use 兜底:无 url/title · 只能看图 + 已知导航状态
        text = await llm_extract_button_text(screenshot, button_target)
        page_url = run_ctx.last_known_url            # state machine 维护 · 不实时拿
        page_title = run_ctx.last_known_heading
        if confidence < 0.85:
            return Fail("computer-use button text low confidence")

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
        token = await controller.await_user_token(action_id=matched_guarded.action_id, payload=button_target)
        if not token: return SafetyError("no token / abandoned")
        consumed = controller.token_store.consume(token.id, matched_guarded.action_id, canonical_payload(button_target))
        if not consumed: return SafetyError("token consume failed")
        # 真实点击
        await executor.click(button_target)
        run_ctx.update_state(action_taken=matched_guarded.action_id)
        return
    if normalized in allowed:
        await executor.click(button_target)
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
| `browser-use` `url() / title()` | ⚠️ 文档暗示有 · 未在本会话实证调用 | W3 spike:`codex exec` 让 Codex 调 browser-use plugin 跑 hello-world |
| `SkyComputerUseClient.app` Y/N callback API | ⚠️ 二进制内有 `approvalStore / approval_requested` 字符串 · 但公开 contract 未坐实 | W3 spike:让 Codex 发起一次 approval · 看 callback 真实 schema |
| `accessibility_tree` 获取方式 | ⚠️ 推测有 · 未实证 | W3 spike:跑 hello-world |
| controller-process 与 Codex orchestration 的 IPC | ⚠️ 拟议 single-controller + sqlite + file lock | W3 写 controller stub · 跑 multi-agent 并发测 token 唯一 |

## § 9 · 一句话总结(对齐 v0.1 风格)

**Alpha scope 严格收缩到搜客+保存 · 其他全 block · 白名单制 + curated synonym + controller-owned token + state rules + browser-use 主路 + computer-use 兜底 · 关键 primitive 待 W3 坐实**

## § 10 · 关联

- 主 SKILL.md(本目录)
- decision-prompts.md(本目录 · 决策门用可验证条件 · 不用 self-confidence)
- runners/README.md(本目录 · safety_enforcer.py 实现 § 4-7 controller)
- spec § 4(本仓 specs/done/)
- r1 deep-review:`raw/inbox/2026-06-17-codex-deep-审-safety-gates.md`
