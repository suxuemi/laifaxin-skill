#!/usr/bin/env bash
# v0.2 alpha preflight check · 真实可执行 · 对齐 HOW-TO-START-SPIKE.md § 1
# 用法: bash preflight.sh
# 退出码: 0 = 全过 · 非 0 = 某项失败 · 不要继续 spike

set -uo pipefail

CODEX=/Applications/Codex.app/Contents/Resources/codex
EXPECTED_VERSION="0.140.0-alpha.2"
EXPECTED_PLUGINS=("browser@openai-bundled" "chrome@openai-bundled" "computer-use@openai-bundled")

PASS=0
FAIL=0

check() {
    local name="$1"
    local cmd="$2"
    echo -n "  $name ... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo "✓"
        PASS=$((PASS+1))
        return 0
    else
        echo "✗"
        FAIL=$((FAIL+1))
        return 1
    fi
}

echo "==========================================="
echo "Laifaxin Outreach v0.2 alpha · Pre-flight"
echo "==========================================="

echo ""
echo "## Check 1: Codex CLI 可执行"
check "Codex 二进制存在" "[ -x \"$CODEX\" ]"

echo ""
echo "## Check 2: Codex 版本"
ACTUAL_VERSION=$($CODEX --version 2>&1 || echo "unknown")
echo "  expected: $EXPECTED_VERSION"
echo "  actual:   $ACTUAL_VERSION"
check "版本匹配" "[[ '$ACTUAL_VERSION' == *'$EXPECTED_VERSION'* ]]"

echo ""
echo "## Check 3: 3 plugin 启用(从 config 实证)"
for plugin in "${EXPECTED_PLUGINS[@]}"; do
    check "  plugin $plugin" "grep -q '\"$plugin\"' ~/.codex/config.toml"
done

echo ""
echo "## Check 4: ~/.codex/runs/ 可写"
check "目录创建 + 写测试" "mkdir -p ~/.codex/runs && touch ~/.codex/runs/.preflight && rm ~/.codex/runs/.preflight"

echo ""
echo "## Check 5: SkyComputerUseClient 通知通道"
NOTIFY=$(grep "^notify" ~/.codex/config.toml 2>/dev/null | head -1)
echo "  notify 配置: ${NOTIFY:-(未设)}"
check "notify 配置存在" "[ -n '$NOTIFY' ]"

echo ""
echo "## Check 6: Chrome web.laifaxin.com 登录态(手动确认)"
echo "  ❓ 浏览器打开 https://web.laifaxin.com/search/refine-search"
echo "     • 可见搜索输入框 + AI 推演按钮 → 输 'y' 通过"
echo "     • 跳转登录页 → 输 'n' 失败"
read -p "  Chrome 已登录搜索页? [y/N] " -r LOGIN_OK
if [[ "$LOGIN_OK" =~ ^[Yy]$ ]]; then
    echo "  ✓"
    PASS=$((PASS+1))
else
    echo "  ✗ 请重新登录后再跑 preflight"
    FAIL=$((FAIL+1))
fi

echo ""
echo "## Check 7: 点数余额(手动确认)"
echo "  ❓ 登录来发信查看顶部点数余额"
echo "     • ≥ 500 点 → 输 'y' 通过(spike 推荐起步余额)"
echo "     • < 500 点 → 输 'n' 失败"
read -p "  余额充足? [y/N] " -r POINTS_OK
if [[ "$POINTS_OK" =~ ^[Yy]$ ]]; then
    echo "  ✓"
    PASS=$((PASS+1))
else
    echo "  ✗ 充值后再跑 spike"
    FAIL=$((FAIL+1))
fi

echo ""
echo "==========================================="
echo "结果: 通过 $PASS · 失败 $FAIL"
if [ $FAIL -eq 0 ]; then
    echo "🎉 全部通过 · 可以进 smoke test(bash smoke_test.sh)"
    exit 0
else
    echo "❌ 有失败项 · 解决后重跑 preflight"
    exit 1
fi
