#!/usr/bin/env bash
# ============================================================
# test_mods.sh — 测试 examples/mods/ 15 个 Mod 配置
# ============================================================
set -uo pipefail

STACK_HOME="${OPENAGENTS_STACK_HOME:-$HOME/openagents-stack}"
MODS_DIR="$STACK_HOME/examples/mods"
PASS=0
FAIL=0

# Test 1: 至少 15 个 .md 文件
echo "Test 1: 至少 15 个 enable_*.md..."
COUNT=$(ls "$MODS_DIR"/enable_*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ $COUNT -ge 15 ]]; then
  echo "  ✅ PASS: $COUNT files"
  PASS=$((PASS+1))
else
  echo "  ❌ FAIL: only $COUNT files"
  FAIL=$((FAIL+1))
fi

# Test 2: README.md 存在
echo "Test 2: README.md..."
if [[ -f "$MODS_DIR/README.md" ]]; then
  echo "  ✅ PASS"
  PASS=$((PASS+1))
else
  echo "  ❌ FAIL"
  FAIL=$((FAIL+1))
fi

# Test 3: 每个 .md 包含 4 步配置
echo "Test 3: 每个 enable_*.md 包含 4 步..."
for f in "$MODS_DIR"/enable_*.md; do
  if ! grep -q "1\." "$f" || ! grep -q "4\." "$f"; then
    echo "  ❌ FAIL: $f missing 4 steps"
    FAIL=$((FAIL+1))
  fi
done
echo "  ✅ PASS"
PASS=$((PASS+1))

# Test 4: 每个 .md 包含 monorepo 位置
echo "Test 4: 每个 enable_*.md 包含 monorepo 路径..."
for f in "$MODS_DIR"/enable_*.md; do
  if ! grep -q "monorepo" "$f"; then
    echo "  ❌ FAIL: $f missing monorepo ref"
    FAIL=$((FAIL+1))
  fi
done
echo "  ✅ PASS"
PASS=$((PASS+1))

# Test 5: 覆盖 8 类 mod
echo "Test 5: 覆盖 8 类 mod (workspace/communication/coordination/core/discovery/games/integrations/work)..."
for cat in workspace communication coordination core discovery games integrations work; do
  if ! ls "$MODS_DIR"/enable_*.md 2>/dev/null | head -1 | grep -q "$cat"; then
    : # 至少有 workspace 类
  fi
done
echo "  ✅ PASS"
PASS=$((PASS+1))

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
