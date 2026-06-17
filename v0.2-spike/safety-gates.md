---
name: laifaxin-outreach-v0.2 · safety-gates
type: meta
status: active
version: 0.2.0-alpha.0
created: 2026-06-17
updated: 2026-06-17
tags: [v0.2, safety, browser-agent, codex]
description: v0.2 alpha 浏览器 agent 安全闸 yaml 配置 · 语义识别白名单 + one-time token + 永久 block 列表 + 失败回退矩阵 · 落地 spec § 4
---

# Safety Gates · v0.2 alpha

> 本文是 spec § 4 安全模型的可执行落地配置 · Codex orchestration 必须在每次点击前查这份 yaml。
> ⚠️ alpha 期内 enforce 点仍在 Orchestration prompt + Codex 状态机 · 不是 executor 级硬约束(spec § 11.2 Decision-T1 · 待 W3 实测)。

## 1 · 三层动作语义白名单

```yaml
# 允许的动作类(按按钮可见文本语义识别)
allowed_button_semantics:
  - "搜索"
  - "AI 推演"
  - "立即查看"           # 客群卡片
  - "找相似"             # 结果行
  - "下一页"             # 分页器
  - "上一页"
  - "高级"               # 结果列表顶部
  - "保存联系人"         # 列表顶部 · 弹窗不算
  - "确定"               # 一般弹窗(子白名单见 § 1.4)
  - "取消"
  - "返回"

# 危险按钮(executor 校验后 + 必须 Token 才能点)
guarded_button_semantics_requiring_token:
  - "确认转化"           # 保存联系人弹窗
  - "确认保存"
  - "提交"
  - "确认充值"
  # AI 评分相关 · Tony § 0 #8 主路径不点 · 列在 guarded 兜底
  - "提交评分"

# 永久 blocked(任何情况都不点 · 包括有 token 都不放行)
permanently_blocked_button_semantics:
  # 发送 / 群发
  - "发送"
  - "群发"
  - "发送邮件"
  - "分别发送"
  - "确认发送"
  - "立即发送"

  # 计划激活 / 启动
  - "激活"
  - "启用"
  - "启动"
  - "开关变蓝"           # 智能跟进开关激活状态

  # 删除
  - "删除"
  - "彻底删除"

  # 导出
  - "导出"
  - "导出数据"
  - "导出联系人"

  # 黑名单 / 拒收 / 举报
  - "加入黑名单"
  - "移出黑名单"
  - "添加到黑名单"
  - "拒收"
  - "举报"

  # 权限 / 授权
  - "权限"
  - "授权"

  # 邮件退订
  - "退订"
```

### 1.4 子白名单(确定 / 取消 在特定弹窗时降级)

```yaml
context_aware_demotion:
  - context_url_contains: "/contacts/save"   # 保存联系人弹窗
    button_text: "确定"
    demote_to: guarded                       # 这里"确定"实际是"确认保存" · 提升风险等级
  - context_page_title_contains: "AI 评分"
    button_text: "提交"
    demote_to: permanently_blocked           # § 0 #8 主路径不用 AI 评分 · 直接 block
  - context_page_title_contains: "智能跟进计划"
    button_text: "确定"                       # 创建计划弹窗的确定 - 安全(只是建草稿,不激活)
    demote_to: allowed
```

## 2 · 7 步语义识别 SOP(每次点击前 enforce)

```python
def safe_click(button_target, context):
    # 1. screenshot + 截取按钮区域
    screenshot = take_screenshot()
    btn_region = locate_button(screenshot, button_target)

    # 2. OCR + LLM 识别可见文本
    raw_text = ocr_extract(btn_region)
    semantic_text = llm_normalize(raw_text)   # 同义词词典 · 去空格 / 全半角 / 大小写

    # 3. 页面上下文判定
    page_ctx = {
        "url": current_url(),
        "title": page_title(),
        "modal": detect_modal(screenshot),
    }

    # 4. 子白名单 context_aware_demotion 优先匹配
    bucket = apply_context_demotion(semantic_text, page_ctx)
    if not bucket:
        bucket = match_lists(semantic_text)

    # 5. 永久 block → 报错 + 截图 + 停
    if bucket == "permanently_blocked":
        raise SafetyError(f"Blocked: {semantic_text}", screenshot)

    # 6. 危险(guarded)→ 必须 token
    if bucket == "guarded":
        token = await_user_token(action=semantic_text, page=page_ctx)
        if not token or not token.valid(action=semantic_text):
            raise SafetyError(f"No token for: {semantic_text}")
        click_and_consume_token(button_target, token)
        return

    # 7. allowed → 放行
    if bucket == "allowed":
        click(button_target)
        return

    # 兜底:不在任何列表 → 白名单制 · 默认拒
    raise SafetyError(f"Unknown action (whitelist mode): {semantic_text}")
```

## 3 · One-Time Approval Token

### 3.1 Token 生成

用户通过 SkyComputerUseClient.app 通知响应 Y → orchestration 生成:

```yaml
token:
  id: tok_<random_8>
  action_hash: sha256(run_id + button_semantic + serialized_params)
  issued_at: 2026-06-17T10:05:00+08:00
  expires_at: 2026-06-17T10:10:00+08:00   # 5 分钟
  single_use: true
  consumed: false
```

### 3.2 Token 校验(executor 层)

```python
def validate_token(token, action_semantic, params):
    if token.consumed:
        return False, "token already used"
    if datetime.now() > token.expires_at:
        return False, "token expired"
    expected_hash = sha256(run_id + action_semantic + serialize(params))
    if token.action_hash != expected_hash:
        return False, "token action mismatch"
    return True, "valid"
```

### 3.3 用户通知 UI

通过 `~/.codex/computer-use/Codex Computer Use.app/.../SkyComputerUseClient.app` 弹窗:

```
[laifaxin-outreach-v0.2 · alpha]
准备保存 600 家公司 × 5-10 邮箱/家 ≈ 3000-6000 联系人 · 标签 en-US-inflatable-boat-retailer
点 "Y" 签发 token · 5 分钟有效 · 单次使用
                                                                                                                    [Y]   [N]
```

## 4 · 失败回退矩阵(对应 spec § 4.4)

| 异常 | 检测 | 回退 |
|---|---|---|
| 按钮 OCR 识别 unknown | LLM 输出"unknown" + 低 confidence | 截图 + 停 + alert |
| 页面布局变化 | 视觉模式 + DOM mismatch | 截图 + 停 + alert |
| 验证码 / 异常页 | OCR 关键词 ("验证" / "captcha" / "异常" / "blocked") | 停 + 用户介入 |
| 网络 5xx / 重定向到登录页 | HTTP status + URL 校验 | 停 + alert |
| 充值 / 权限 / 授权弹窗 | 永久 block 列表识别 | 停 + 截图 + 报告 |
| 操作速率超阈 | 内部限速器(默认 < 1 click/秒)| 自动 sleep + jitter(2-5s) |
| Token 过期 / hash 失败 | executor 层校验 | 回到 § 3.1 重走 token 流 |

## 5 · 一句话总结

**白名单制 · 语义识别 · 一次性 token · 5 分钟有效 · 永久 block 不可绕**
