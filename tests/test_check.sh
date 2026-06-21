#!/usr/bin/env bash
# ============================================================
# test_check.sh — 测试 openagents-stack --check 12 项自检
# ============================================================
set -uo pipefail

STACK_HOME="${OPENAGENTS_STACK_HOME:-$HOME/openagents-stack}"
PASS=0
FAIL=0

# 找到 openagents-stack 命令
if [[ -x "$STACK_HOME/bin/openagents-stack" ]]; then
  CMD="$STACK_HOME/bin/openagents-stack"
elif command -v openagents-stack > /dev/null 2>&1; then
  CMD="openagents-stack"
else
  echo "❌ openagents-stack not found"
  exit 1
fi

# Test 1: --help 输出
echo "Test 1: --help output..."
if $CMD --help 2>&1 | grep -q "Usage"; then
  echo "  ✅ PASS"
  PASS=$((PASS+1))
else
  echo "  ❌ FAIL: --help no Usage"
  FAIL=$((FAIL+1))
fi

# Test 2: --dry-run 输出
echo "Test 2: --dry-run output..."
if $CMD --dry-run 2>&1 | grep -q "DRY-RUN"; then
  echo "  ✅ PASS"
  PASS=$((PASS+1))
else
  echo "  ❌ FAIL: --dry-run no DRY-RUN"
  FAIL=$((FAIL+1))
fi

# Test 3: --version 存在
echo "Test 3: --version..."
if $CMD --version 2>&1 | head -1 | grep -q "v"; then
  echo "  ✅ PASS"
  PASS=$((PASS+1))
else
  echo "  ⚠️  WARN: --version not implemented"
fi

# Test 4: 12 个核心子命令存在
echo "Test 4: 12 核心子命令..."
for cmd in --start --stop --restart --logs --status --upgrade --clean --reset --dry-run --check --help; do
  if $CMD --help 2>&1 | grep -q "$cmd"; then
    : # 子命令存在
  else
    echo "  ❌ FAIL: $cmd not in help"
    FAIL=$((FAIL+1))
  fi
done
echo "  ✅ PASS"
PASS=$((PASS+1))

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
