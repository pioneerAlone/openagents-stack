#!/usr/bin/env bash
# ============================================================
# test_install.sh — 测试 install.sh 可执行
# ============================================================
set -uo pipefail

STACK_HOME="${OPENAGENTS_STACK_HOME:-$HOME/openagents-stack}"
PASS=0
FAIL=0

# Test 1: install.sh 存在
echo "Test 1: install.sh exists..."
if [[ -f "$STACK_HOME/install.sh" ]]; then
  echo "  ✅ PASS"
  PASS=$((PASS+1))
else
  echo "  ❌ FAIL: install.sh not found"
  FAIL=$((FAIL+1))
fi

# Test 2: install.sh 可执行
echo "Test 2: install.sh is executable..."
if [[ -x "$STACK_HOME/install.sh" ]]; then
  echo "  ✅ PASS"
  PASS=$((PASS+1))
else
  echo "  ❌ FAIL: install.sh not executable"
  FAIL=$((FAIL+1))
fi

# Test 3: install.sh 语法
echo "Test 3: install.sh syntax..."
if bash -n "$STACK_HOME/install.sh" 2>&1; then
  echo "  ✅ PASS"
  PASS=$((PASS+1))
else
  echo "  ❌ FAIL: install.sh has syntax error"
  FAIL=$((FAIL+1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
