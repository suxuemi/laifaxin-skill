#!/usr/bin/env bash
# v0.2 alpha smoke test · 3 件套 · 对齐 HOW-TO-START-SPIKE.md § 2.1
# 用法: bash smoke_test.sh
# 注意: 这个脚本不是自动化测试 · 是给 Tony / 用户引导 Codex 跑 smoke 的 wrapper
#       Tony 用 codex 交互模式手动跑下面 3 个 prompt · 这个脚本帮你 echo 出来 + 记 audit

set -uo pipefail

CODEX=/Applications/Codex.app/Contents/Resources/codex
SMOKE_LOG="$HOME/.codex/runs/smoke-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$SMOKE_LOG")"

cat <<'EOF'
==========================================
Laifaxin Outreach v0.2 alpha · Smoke Test
==========================================

注意: 这个脚本是 Codex 交互引导 · 你需要在 Codex 交互模式下手动跑 3 个 prompt
脚本会帮你 echo 出来 · 复制粘贴到 Codex

EOF

read -p "确认已读完 HOW-TO-START-SPIKE.md § 2.1 ? [y/N] " -r READY
[[ "$READY" =~ ^[Yy]$ ]] || { echo "请先读完文档"; exit 1; }

set -e   # r4 #1 失败立即中止 · 不让 W3 放行门假阳性

run_smoke() {
    local idx="$1"
    local name="$2"
    local prompt="$3"

    echo ""
    echo "==========================================="
    echo "Smoke Test $idx: $name"
    echo "==========================================="
    echo ""
    echo "--- 复制以下 prompt 到 Codex 交互模式 ---"
    echo "$prompt"
    echo "--- prompt 结束 ---"
    echo ""

    read -p "Codex 报告了什么? 输 'pass' / 'stub_pass' / 'fail' / 'skip': " -r RESULT
    echo "[Smoke $idx] $name: $RESULT" >> "$SMOKE_LOG"

    # r7 必修 · stub_pass **仅 smoke 3 + W2 阶段**允许 · smoke 1/2 必须真 pass
    if [ "$RESULT" = "stub_pass" ]; then
        if [ "$idx" != "3" ]; then
            echo "❌ Smoke $idx 不允许 stub_pass(仅 smoke 3 可)· 立即中止"
            exit 1
        fi
        if [ "${V02_STAGE:-W2}" = "W2" ]; then
            echo "⚠️ Smoke 3 stub_pass(W2 阶段允许 · W3 必须真 pass)"
            return 0
        else
            echo "❌ W3 阶段 smoke 3 不接受 stub_pass · 必须真 pass · 立即中止"
            exit 1
        fi
    fi
    if [ "$RESULT" != "pass" ]; then
        echo "❌ Smoke $idx 未通过 · 立即中止 · 不要继续 W3"
        exit 1
    fi
    echo "✓ Smoke $idx pass"
    return 0
}

# --- Smoke 1: 截图 ---
run_smoke 1 "computer-use 截图" "$(cat <<'PROMPT'
你是 laifaxin-outreach-v0.2 spike 的 smoke tester.

Task: 使用 computer-use plugin 截图当前 Chrome 活跃 tab.
要求报告:
- 用了哪个 plugin (computer-use / chrome)
- 截图 path
- 截图分辨率
- 截图中文本"AI 数据库" / "AI 推演" 是否可见

不要点击 · 不要操作 · 只截图 · 报告完停.
PROMPT
)"

# --- Smoke 2: 读 a11y ---
run_smoke 2 "macOS a11y 读取按钮" "$(cat <<'PROMPT'
你是 laifaxin-outreach-v0.2 spike 的 smoke tester.

Task: 使用 computer-use plugin + macOS accessibility tree · 读取当前 Chrome 中
"AI 推演" 按钮的可见文本 + 坐标位置 + accessibility role.

要求报告:
- 用了哪个 API (computer-use a11y / OCR / vision)
- 找到的按钮坐标 (x, y)
- 按钮文本归一化结果

不要点击 · 只读取 · 报告完停.
PROMPT
)"

# --- Smoke 3: token gate runtime 验证(r4 #4 修 · 不再只读文档)---
run_smoke 3 "token gate runtime (永久 block 实际拦截)" "$(cat <<'PROMPT'
你是 laifaxin-outreach-v0.2 spike 的 smoke tester.

Task: 真的尝试调用 safety controller 的 check_click("AI 评分") · 看返回什么.
要求:
- 在 codex 交互里实例化 controller(从 safety-gates.md 加载语义白名单)
- 调用 check_click(semantic="AI 评分", page_context="/search/refine-search")
- 报告返回 disposition 值 + 异常类型(应该是 SafetyError "permanently_blocked")
- 不要真的点屏幕 · 只走 controller 内部判定

预期:
  disposition = "permanently_blocked"
  exception = SafetyError("AI 评分 in permanently_blocked list")

如果 controller 还未实现(W2 stub),则报告 stub 状态 + 输出预期值;不算 pass.

报告完停.
PROMPT
)"

echo ""
echo "==========================================="
echo "Smoke Test Summary: $SMOKE_LOG"
cat "$SMOKE_LOG"
echo "==========================================="
echo ""
echo "🎉 3 smoke 全 pass → 可进 W3 实施 (runners/prospect.py)"
echo "❌ 任一 fail → 不要继续 W3 · 见 safety-gates.md § 7 失败矩阵"
