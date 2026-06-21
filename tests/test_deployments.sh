#!/usr/bin/env bash
# ============================================================
# test_deployments.sh — 测试 deployments/ 3 种部署模式
# ============================================================
set -uo pipefail

STACK_HOME="${OPENAGENTS_STACK_HOME:-$HOME/openagents-stack}"
DEPLOY_DIR="$STACK_HOME/deployments"
PASS=0
FAIL=0

# Test 1: 3 种部署模式存在
echo "Test 1: 3 种部署模式..."
for mode in local-personal lan-team enterprise; do
  if [[ ! -d "$DEPLOY_DIR/$mode" ]]; then
    echo "  ❌ FAIL: $mode missing"
    FAIL=$((FAIL+1))
  fi
done
echo "  ✅ PASS"
PASS=$((PASS+1))

# Test 2: 每个模式有 README + install.sh + verify.sh
echo "Test 2: 每个模式 3 文件..."
for mode in local-personal lan-team enterprise; do
  for f in README.md install.sh verify.sh; do
    if [[ ! -f "$DEPLOY_DIR/$mode/$f" ]]; then
      echo "  ❌ FAIL: $mode/$f missing"
      FAIL=$((FAIL+1))
    fi
  done
done
echo "  ✅ PASS"
PASS=$((PASS+1))

# Test 3: install.sh 语法
echo "Test 3: install.sh 语法..."
for mode in local-personal lan-team enterprise; do
  if ! bash -n "$DEPLOY_DIR/$mode/install.sh" 2>&1; then
    echo "  ❌ FAIL: $mode/install.sh syntax"
    FAIL=$((FAIL+1))
  fi
done
echo "  ✅ PASS"
PASS=$((PASS+1))

# Test 4: verify.sh 语法
echo "Test 4: verify.sh 语法..."
for mode in local-personal lan-team enterprise; do
  if ! bash -n "$DEPLOY_DIR/$mode/verify.sh" 2>&1; then
    echo "  ❌ FAIL: $mode/verify.sh syntax"
    FAIL=$((FAIL+1))
  fi
done
echo "  ✅ PASS"
PASS=$((PASS+1))

# Test 5: enterprise 有 nginx.conf + config.enterprise.yaml
echo "Test 5: enterprise 有 nginx + config..."
if [[ ! -f "$DEPLOY_DIR/enterprise/nginx.conf" ]] || [[ ! -f "$DEPLOY_DIR/enterprise/config.enterprise.yaml" ]]; then
  echo "  ❌ FAIL: enterprise 缺少 nginx.conf 或 config.enterprise.yaml"
  FAIL=$((FAIL+1))
else
  echo "  ✅ PASS"
  PASS=$((PASS+1))
fi

# Test 6: lan-team 有 config.lan.yaml
echo "Test 6: lan-team 有 config.lan.yaml..."
if [[ ! -f "$DEPLOY_DIR/lan-team/config.lan.yaml" ]]; then
  echo "  ❌ FAIL: lan-team 缺少 config.lan.yaml"
  FAIL=$((FAIL+1))
else
  echo "  ✅ PASS"
  PASS=$((PASS+1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
