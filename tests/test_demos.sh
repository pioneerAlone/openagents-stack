#!/usr/bin/env bash
# ============================================================
# test_demos.sh — 测试 examples/demos/ 6 个 Demo 结构
# ============================================================
set -uo pipefail

STACK_HOME="${OPENAGENTS_STACK_HOME:-$HOME/openagents-stack}"
DEMOS_DIR="$STACK_HOME/examples/demos"
PASS=0
FAIL=0

EXPECTED_DEMOS=(
  "hello_world"
  "pitch_room"
  "tech_news"
  "research_team"
  "grammar_check"
  "agentworld"
)

assert_eq() {
  local expected="$1" actual="$2" name="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  ✅ PASS: $name"
    PASS=$((PASS+1))
  else
    echo "  ❌ FAIL: $name (expected $expected, got $actual)"
    FAIL=$((FAIL+1))
  fi
}

# Test 1: 6 个 Demo 都存在
echo "Test 1: 6 个 Demo 目录存在..."
EXIST=0
for demo in "${EXPECTED_DEMOS[@]}"; do
  if [[ -d "$DEMOS_DIR/$demo" ]]; then
    EXIST=$((EXIST+1))
  fi
done
assert_eq 6 $EXIST "6 demos exist"

# Test 2: 每个 Demo 有 3 个文件
echo "Test 2: 每个 Demo 有 README + network.yaml + run.sh..."
ALL_HAVE=0
for demo in "${EXPECTED_DEMOS[@]}"; do
  if [[ -f "$DEMOS_DIR/$demo/README.md" ]] && \
     [[ -f "$DEMOS_DIR/$demo/network.yaml" ]] && \
     [[ -f "$DEMOS_DIR/$demo/run.sh" ]]; then
    ALL_HAVE=$((ALL_HAVE+1))
  fi
done
assert_eq 6 $ALL_HAVE "6 demos have all 3 files"

# Test 3: 每个 run.sh 语法 OK
echo "Test 3: run.sh 语法..."
SYNTAX_OK=0
for demo in "${EXPECTED_DEMOS[@]}"; do
  if bash -n "$DEMOS_DIR/$demo/run.sh" 2>/dev/null; then
    SYNTAX_OK=$((SYNTAX_OK+1))
  fi
done
assert_eq 6 $SYNTAX_OK "6 demos have valid run.sh syntax"

# Test 4: 至少 5 个 demo 有 agents/
echo "Test 4: 5+ demos 有 agents/..."
WITH_AGENTS=0
for demo in "${EXPECTED_DEMOS[@]}"; do
  if [[ -d "$DEMOS_DIR/$demo/agents" ]]; then
    WITH_AGENTS=$((WITH_AGENTS+1))
  fi
done
if [[ $WITH_AGENTS -ge 5 ]]; then
  echo "  ✅ PASS: $WITH_AGENTS demos have agents/"
  PASS=$((PASS+1))
else
  echo "  ❌ FAIL: only $WITH_AGENTS demos have agents/"
  FAIL=$((FAIL+1))
fi

# Test 5: network.yaml 包含 port
echo "Test 5: network.yaml 包含 port..."
PORT_OK=0
for demo in "${EXPECTED_DEMOS[@]}"; do
  if grep -q "port" "$DEMOS_DIR/$demo/network.yaml" 2>/dev/null; then
    PORT_OK=$((PORT_OK+1))
  fi
done
assert_eq 6 $PORT_OK "6 demos have port in network.yaml"

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
