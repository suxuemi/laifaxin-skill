---
name: laifaxin-outreach-v0.2 · HOW-TO-START-SPIKE
type: meta
status: active
version: 0.2.0-alpha.2
created: 2026-06-17
updated: 2026-06-17
tags: [v0.2, alpha, spike, codex, runbook, pre-flight, stop-sop]
description: v0.2 alpha 浏览器 agent 实战启动 runbook · r1 deep-review 全面重写 · 5 分钟预飞改为权威 runtime check · 启动命令改自然语言 prompt(删伪 DSL)· 紧急停降级表述去除过承诺 · 回灌 sink 对齐 spec § 6 run.json(不再撞 wiki/history)
---

# HOW-TO-START-SPIKE · v0.2 alpha 首次实战 runbook(r1 重写版)

> **r1 deep-review 反馈**:原版 🔴 大改 · 18 条硬伤
> - 启动入口 `/laifaxin-outreach-v0.2 product=...` 凭空 DSL · 不存在
> - 5 分钟预飞全是心理安慰 · 没真验 runtime
> - 紧急停"computer-use 自动暂停 / agent 立即报失效"= 过承诺
> - 回灌 sink 写到 `~/.codex/runs/.../summary.md`(应在 `raw/prospecting/...`)+ append `wiki/history`(撞治理)
>
> **重写策略**:权威 runtime check + 真启动命令 + 紧急停降级表述 + 回灌对齐 spec § 6

## § 0 · 前置条件(执行前必须满足)

| 项 | 检查 / 设置 |
|---|---|
| Codex CLI 已安装且能执行 | 绝对路径 `/Applications/Codex.app/Contents/Resources/codex`(无需 PATH 别名) |
| Codex CLI 版本 | `0.140.0-alpha.2`(精确锁定 · 不接受其他版本) |
| 3 plugin 启用(实证 `codex plugin list`)| `browser@openai-bundled` / `chrome@openai-bundled` / `computer-use@openai-bundled` 全 `installed, enabled` |
| Chrome 已登录来发信 | 打开 `https://web.laifaxin.com/search/refine-search` · 可见搜索页 · 非登录页 |
| 用户在场监控 | 全程能随时介入 / 终止 run · 不要求 Chrome 前台,但要求用户 watching |
| `~/.codex/runs/` 目录可写 | `mkdir -p ~/.codex/runs && touch ~/.codex/runs/.write-test && rm $_` |
| 来发信账户点数余额 | 心里清楚 · 单次 stop-loss 阈值(例:300 点 ≈ ¥30)· 超过立即停 |

## § 1 · 5 分钟预飞 runtime check(用脚本 · 不要复制片段)

> **r5 必修**:不要复制下面 bash 片段(可能假阳性)· **直接跑 `bash runners/preflight.sh`**(它有真 FAIL 分支 + 退出码)
>
> ```bash
> cd skills-public/laifaxin-outreach-v0.2/
> bash runners/preflight.sh
> echo "退出码: $?"   # 0 = 全过 · 非 0 = 至少一项失败 · 不要继续 spike
> ```
>
> 下方代码块仅作**说明性参考**(展示每个 check 在做什么)· **不要直接执行**:

```bash
# ========== Check 1: Codex 版本(权威 · 走绝对路径)==========
CODEX=/Applications/Codex.app/Contents/Resources/codex
[ -x "$CODEX" ] || { echo "❌ Codex 不存在: $CODEX"; exit 1; }
VER=$($CODEX --version 2>&1)
echo "Codex version: $VER"
[[ "$VER" == *"0.140.0-alpha.2"* ]] || { echo "❌ 版本不匹配"; exit 1; }
echo "✓ Check 1 pass"

# ========== Check 2: 3 plugin 启用(走 Codex 子命令而非 grep config)==========
# 注:'codex plugin list' 是当前可用子命令(本 mac 实测有 `codex plugin` 子命令)
$CODEX plugin list 2>&1 | grep -E "browser@|chrome@|computer-use@" || \
  $CODEX doctor 2>&1 | grep -i "plugin" || \
  { echo "❌ plugin 状态未坐实"; exit 1; }
echo "✓ Check 2 pass(实证 plugin 状态 · 不是只读 config)"

# ========== Check 3: Chrome web.laifaxin.com 登录态 ==========
# 手动:浏览器打开 https://web.laifaxin.com/search/refine-search
#   - 可见搜索输入框 → ✓
#   - 跳到登录页 → ❌(重新登录后再跑)
echo "✓ Check 3:用户手动确认搜索页可见 · 非登录页"

# ========== Check 4: runs/ 可写 ==========
mkdir -p ~/.codex/runs && touch ~/.codex/runs/.write-test && rm ~/.codex/runs/.write-test
echo "✓ Check 4 pass"

# ========== Check 5: SkyComputerUseClient(从 config 读 · 不硬编码路径)==========
NOTIFY=$(grep "^notify" ~/.codex/config.toml | head -1)
echo "notify config: $NOTIFY"
# 不强制路径 · 配置存在即可
echo "✓ Check 5:config 中 notify 已配"

# ========== Check 6: 点数余额 ==========
# 手动:登录来发信 · 查看顶部点数余额 · 心里有数
# 建议:当前余额 ≥ 500 点(可应付 alpha 多次 spike · 不被余额报警打断)
echo "✓ Check 6:用户确认余额充足 · 知道 stop-loss 阈值"

echo "🎉 5 分钟预飞通过 · 可以进 § 2 启动"
```

## § 2 · 启动命令(真实 · 可复制 · 可验证)

### 2.1 W2 当前阶段:用 Codex 交互模式做 smoke test

```bash
CODEX=/Applications/Codex.app/Contents/Resources/codex
$CODEX
# 在交互中,逐条复制以下 prompt 跑 smoke test:
```

**Smoke test 1**:能不能截图 web.laifaxin.com 搜索页?

```
你是 laifaxin-outreach-v0.2 spike 的 smoke tester.

Task: 使用 computer-use plugin 截图当前 Chrome 活跃 tab.
要求报告:
- 用了哪个 plugin (computer-use / chrome)
- 截图 path
- 截图分辨率
- 截图中文本"AI 数据库" / "AI 推演" 是否可见

不要点击 · 不要操作 · 只截图 · 报告完停.
```

**预期通过**:报告 `computer-use plugin · ~/.codex/screenshots/xxx.png · 1920x1080 · 文本可见 ✓`

**Smoke test 2**:能不能从截图读出 "AI 推演" 按钮位置?

```
你是 laifaxin-outreach-v0.2 spike 的 smoke tester.

Task: 使用 computer-use plugin + macOS accessibility tree · 读取当前 Chrome 中
"AI 推演" 按钮的可见文本 + 坐标位置 + accessibility role.

要求报告:
- 用了哪个 API (computer-use a11y / OCR / vision)
- 找到的按钮坐标 (x, y)
- 按钮文本归一化结果

不要点击 · 只读取 · 报告完停.
```

**预期通过**:报告 a11y tree 找到按钮 + 坐标 + 文本"AI 推演"

**Smoke test 3**:token gate **runtime** 验证(r4 #4 修 · 不再只读文档)?

```
你是 laifaxin-outreach-v0.2 spike 的 smoke tester.

Task: 真的尝试调用 safety controller 的 check_click("AI 评分") · 看返回什么.
要求:
- 在 codex 交互里实例化 controller(从 safety-gates.md 加载语义白名单 + permanently_blocked list)
- 调用 check_click(semantic="AI 评分", page_context="/search/refine-search")
- 报告返回 disposition 值 + 异常类型(应该是 SafetyError "permanently_blocked")
- 不要真的点屏幕 · 只走 controller 内部判定

预期:
  disposition = "permanently_blocked"
  exception = SafetyError("AI 评分 in permanently_blocked list")

如果 controller 还未实现(W2 stub) · 报告 stub 状态 + 输出预期值;**W2 阶段输 `stub_pass` 通过**(脚本接受 stub_pass=W2 only).

报告完停.
```

**W2 预期**:报告"controller 未实现 · 预期 disposition=permanently_blocked" → 输 `stub_pass`
**W3 预期**:报告"disposition = permanently_blocked · 抛 SafetyError" → 输 `pass`

**3 smoke 全 pass 才能进 § 2.2 W3 实施**

> ⚠️ **W2 → W3 启动门**(r4 反馈修正 · 防 W3 自锁):
> - W2 阶段:smoke 1 + 2(截图 + a11y 读取)是必须 pass · smoke 3(controller runtime)**W2 阶段允许 stub pass**(报告"controller 未实现 · 期望 disposition='permanently_blocked'")
> - W3 阶段:必须 smoke 3 真实 pass(controller 实例化 · `check_click()` 真返回 SafetyError)· 这时 `runners/safety_enforcer.py` 已写完

### 2.2 W3 实施后:真 prospect.py 启动(目前 prospect.py 仍是 stub)

> ⚠️ **当前状态(W2)**:`runners/prospect.py` 还**不存在** · 仅有 `runners/README.md` 伪 API + `preflight.sh` + `smoke_test.sh`。
> W3 必须先实施 prospect.py · 才能照本节启动。

W3 完成 prospect.py 后,启动方式(规划 · 未坐实):

```bash
# 选项 A(W3 后规划):python 直跑(前台 · 用户在场监控 · 推荐 alpha)
python skills-public/laifaxin-outreach-v0.2/runners/prospect.py \
  --product "皮筏艇" \
  --max-boundary-pages 50 \
  --emails-per-company 5 \
  --tag "en-US-inflatable-boat-retailer"

# 选项 B(W3 后规划):Codex 自然语言触发
$CODEX << 'EOF'
启动 laifaxin-outreach-v0.2 spike · 跑产品"皮筏艇" ·
最大翻页 50 · 单家 5 邮箱 · 标签 en-US-inflatable-boat-retailer ·
保存到 raw/prospecting/inflatable-boat/runs/
EOF
```

⚠️ 不要用 `/laifaxin-outreach-v0.2 product=...` 这种伪 DSL · Codex 不支持。

## § 3 · 推荐参数(第一次跑)

| 参数 | 推荐值 | 理由 |
|---|---|---|
| 产品 | 你最熟的一个(如"皮筏艇")| 已知客群对路 · 易判 agent 是否选对 |
| 目标 boundary 上限 | 50 页(500 公司)| 起步小 · 别一次跑 600 |
| 单家邮箱数 | 5 | 起步保守 · 后续可调 10 |
| 标签 | 完整公式 `<lang>-<country>-<product>-<role>` | 见 [docs/zhinan/03-save-customers](https://www.laifa.xin/zhinan/03-save-customers) |
| 是否激活计划 | **❌ 否** | scope out · 永久 block · spike 只测搜+保存 |

## § 4 · 紧急停 SOP(降级表述 · 删除过承诺)

> r1 反馈:"computer-use 自动暂停 / agent 立即报失效"都是过承诺 · 当前工具面没保证。

### 4.1 主路径:前台 Ctrl-C(推荐 alpha)

| 运行模式 | Kill 方式 |
|---|---|
| 前台 `python prospect.py ...` | **同终端 Ctrl-C**(SIGINT)→ runner 应触发 finally block 写 audit + close codex 连接 |
| 前台 `codex` 交互 | 同终端 Ctrl-C |
| 后台(W3 之后):`codex exec` + run_id | `ps aux \| grep codex` 找 PID → `kill -SIGTERM <PID>` → controller 应触发 graceful shutdown |

### 4.2 兜底:关闭 Chrome tab

**降级表述**:关掉 Chrome tab → 后续 computer-use 操作会失败(无法定位按钮)→ runner 应在错误处理中停 + 写 audit · **不承诺 immediate session invalid**

### 4.3 验证码 / 登录失效 / 反爬

当 agent 遇到这些场景:

```yaml
状态机:
  detected: ["验证码页面", "登录跳转", "5xx 错误", "anti-bot challenge"]
  action: paused_for_human
  user_action: 手动过码 / 重新登录 / 等冷却
  resume: ⚠️ Codex `codex exec resume [SESSION_ID]` 是 Codex session uuid · 不是我们的 run_id(timestamp slug)· 两套 id 体系
  resume_actual: 用户跑 `codex exec resume <session_uuid>`(从 `~/.codex/sessions/` 找最近 session)+ 提示"继续 laifaxin-outreach-v0.2 run <run_id>"
  resume_W3_alternative: W3 后 prospect.py 加 `--resume <run_id>` 自定义路径 · 自己读 `~/.codex/runs/<run_id>/` 恢复状态
  no_auto_retry: true   # agent 不得自动 retry · 必须人工 resume
```

### 4.4 余额 / 点数报警

**当前 docs 没坐实"即将耗光监控弹窗"**(原文承诺过头 · 已删)。

实际:
- 来发信网页顶部点数余额是可见的(用户监控)
- agent 在每次保存提交前(token 流)预演消费量 · 大于 stop-loss 阈值就拒绝出 token
- 真扣到点数不足时 · 来发信会回弹"点数不足"提示 · agent 应停 + 报告

### 4.5 Cmd-Tab / 窗口切换

**降级表述**:用户 Cmd-Tab 切走 → Chrome 失焦 → computer-use **行为未定义**(可能继续 / 可能失败)· **不承诺 auto-pause**

**正确做法**:不要用 Cmd-Tab 当 kill switch · 用 Ctrl-C 或关 tab。

## § 5 · 关键观察指标(对齐 spec § 6.2 run.json)

每次 spike 自动 audit · run.json 字段(参 spec § 6.2):

**run.json schema canonical 见 SKILL.md § 3.1**(不是 spec § 6.2 · 已 freeze)

| 字段 | auto / manual | 说明 |
|---|---|---|
| `started_at / finished_at / duration_seconds` | auto | runner 自动写 |
| `inference.chosen_audience` | auto | LLM 节点 1 输出 |
| `sampling.pages_read / boundary_page / per_page_accuracy[]` | auto | LLM 节点 2 输出 |
| `saving.saved_companies / saved_emails / tags_applied` | auto | runner 自动读保存结果 |
| `audit.user_interventions` | auto | controller 记录每次 token 签发 |
| `audit.warnings` | auto | LLM 低 confidence / OCR 兜底 / 反爬触发 |
| `audit.anti_bot_trigger_count` | auto | reqstats / 5xx 计数 |
| **`audit.permanently_blocked_hits`** | auto | 永久 block 按钮被尝试点击的次数 · promote 必填 = 0 |
| `failure_diagnostics`(if failed)| auto | error_type / invalid_fragment / repair_attempts / taken_over_by_human |

**用户手填**(W3 后可选 · 用 `python prospect.py --add-manual-note <run_id>`):
- 主观满意度评分(1-5)
- 你认为 agent 做错了什么 / 该改什么
- 是否要进 W4 实测下一轮

⚠️ 不再有"用户肉眼数 ocr_misreads"(原文凭空 · 删)。OCR 低 confidence 由 controller 自动 audit。

## § 6 · 反馈回灌(对齐 spec § 6.1 · 不撞 wiki/history)

### 6.1 每次 spike 自动落点(r1 #D4.3 #D4.5 必修)

```
raw/prospecting/<product>/runs/<run_id>/
  ├── run.json                # 入 repo · 跨设备审计
  ├── summary.md              # 入 repo · 人读摘要(从 run.json 派生 · 不另发明字段)
  └── artifacts.json          # 入 repo · 指针 + hash list
~/.codex/runs/<run_id>/
  ├── tokens.sqlite           # 不入 repo
  ├── screenshots/            # 不入 repo
  └── llm_logs.jsonl          # 不入 repo
```

`summary.md` 字段**严格从 `run.json` 派生** · 不发明第二套字段。

### 6.2 跨 spike 决策回灌(对齐 wiki/history 治理)

**只在重大决策变化时**抽 wiki/history 一篇 · 不是每次 run 都写:

| 触发 wiki/history 新篇 | 触发 raw/prospecting/runs/ |
|---|---|
| 阈值改了(如 0.6 → 0.55)| 每次 run |
| 主路换了(computer-use → browser-use)| 每次 run |
| Token 流改了 | 每次 run |
| Tony 拍板新 scope | 每次 run |
| **每次普通 run**(常态)| 仅 raw/prospecting/runs/ · 不撞 history |

> 现行 `wiki/history/2026-06-laifa-browser-agent-v0.2-design.md` 是设计阶段总结 · 不是 run log。

### 6.3 N 次连续 success run · alpha → beta promote(N 从 effective_config 读)

每周汇总 `raw/prospecting/*/runs/*/run.json`(自动脚本可选):

```bash
# alpha → beta 4 条硬条件(α.3.3 完全 effective_config 化):
#   ① N 次连续 result=success(N = effective_config.promote_consecutive_successes)
#   ② 最近 N 次**平均** user_interventions ≤ M(M = promote_max_user_interventions_per_run)
#   ③ 误操作率 = 0(permanently_blocked_hits == 0 · per-run · frozen)
#   ④ 客户开发耗时减少 ≥ P% vs v0.1 baseline(P = promote_duration_reduction_pct)

# 从最近一次 run 的 effective_config 读全部阈值 · 无硬编码
LATEST=$(ls -t raw/prospecting/*/runs/*/run.json 2>/dev/null | head -1)
[ -z "$LATEST" ] && echo "no runs yet" && exit 1

N=$(jq -r '.effective_config.promote_consecutive_successes // 5' "$LATEST")
M=$(jq -r '.effective_config.promote_max_user_interventions_per_run // 1' "$LATEST")
P=$(jq -r '.effective_config.promote_duration_reduction_pct // 40' "$LATEST")
BASELINE=$(jq -r '.effective_config.v01_baseline_minutes // 45' "$LATEST")

# 条件 ① + ③ 合并:从尾扫连续 success 且 permanently_blocked_hits == 0
STREAK=$(jq -s --argjson NN "$N" '
  sort_by(.started_at) | reverse |
  reduce .[] as $r ({streak: 0, broken: false};
    if .broken then .
    elif $r.result == "success" and
         (($r.audit.permanently_blocked_hits // 0) == 0)
    then .streak = .streak + 1
    else .broken = true
    end
  ) | .streak
' raw/prospecting/*/runs/*/run.json)

# 条件 ② 最近 N 次的**平均** user_interventions
AVG_INTERV=$(jq -s --argjson NN "$N" '
  sort_by(.started_at) | reverse | .[:$NN] |
  map(.audit.user_interventions | length) | if length == 0 then 999 else add / length end
' raw/prospecting/*/runs/*/run.json)

# 条件 ④ 最近 N 次平均耗时 vs baseline
AVG_DUR_MIN=$(jq -s --argjson NN "$N" '
  sort_by(.started_at) | reverse | .[:$NN] |
  map(.duration_seconds) | if length == 0 then 999 else add / length / 60 end
' raw/prospecting/*/runs/*/run.json)

REDUCTION=$(echo "scale=2; ($BASELINE - $AVG_DUR_MIN) / $BASELINE * 100" | bc)

# 4 条 AND verdict
C1=$([ "$STREAK" -ge "$N" ] && echo 1 || echo 0)
C2=$([ "$(echo "$AVG_INTERV <= $M" | bc)" = "1" ] && echo 1 || echo 0)
C4=$([ "$(echo "$REDUCTION >= $P" | bc)" = "1" ] && echo 1 || echo 0)

if [ "$C1" = "1" ] && [ "$C2" = "1" ] && [ "$C4" = "1" ]; then
  echo "✅ 4 条全过 · 可 promote alpha→beta"
  echo "   streak=$STREAK/$N · avg_interv=$AVG_INTERV/$M · reduction=$REDUCTION%/$P%"
else
  echo "❌ 未达标"
  echo "   ①streak=$STREAK/$N (pass=$C1) · ②avg_interv=$AVG_INTERV/$M (pass=$C2) · ③included in streak · ④reduction=$REDUCTION%/$P% (pass=$C4)"
fi
```

## § 7 · 关联

- 主 SKILL.md(本目录)
- safety-gates.md(本目录)
- decision-prompts.md(本目录)
- runners/README.md(本目录 · W3 实施 stub)
- spec(已归档):`specs/done/2026-06-17-laifa-browser-agent-v0.2.md`
- r1 deep-review:`raw/inbox/2026-06-17-codex-deep-审-HOW-TO-START.md`

## § 8 · 一句话总结

**权威 runtime check + smoke test 3 件套(截图 / 读 a11y / 验 token gate)+ W3 启动命令(W3 后实施 `python prospect.py` · W2 仍 stub)+ 紧急停 Ctrl-C 主路 + 回灌到 raw/prospecting/runs/(不撞 wiki/history)**
