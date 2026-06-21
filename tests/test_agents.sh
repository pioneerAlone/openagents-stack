#!/usr/bin/env bash
# ============================================================
# test_agents.sh — 测试 examples/agents/ 3 个 Agent 示例
# ============================================================
set -uo pipefail

STACK_HOME="${OPENAGENTS_STACK_HOME:-$HOME/openagents-stack}"
AGENTS_DIR="$STACK_HOME/examples/agents"
PASS=0
FAIL=0

# Test 1: 3 个 agent 文件存在
echo "Test 1: 3 个 agent 文件..."
for f in echo_agent.py calculator.py timer.py; do
  if [[ ! -f "$AGENTS_DIR/$f" ]]; then
    echo "  ❌ FAIL: $f missing"
    FAIL=$((FAIL+1))
  fi
done
echo "  ✅ PASS"
PASS=$((PASS+1))

# Test 2: 每个 agent 继承 WorkerAgent
echo "Test 2: 继承 WorkerAgent..."
for f in echo_agent.py calculator.py timer.py; do
  if ! grep -q "WorkerAgent" "$AGENTS_DIR/$f"; then
    echo "  ❌ FAIL: $f not extending WorkerAgent"
    FAIL=$((FAIL+1))
  fi
done
echo "  ✅ PASS"
PASS=$((PASS+1))

# Test 3: 每个 agent 有 react() 方法
echo "Test 3: 每个 agent 有 react() 方法..."
for f in echo_agent.py calculator.py timer.py; do
  if ! grep -q "async def react" "$AGENTS_DIR/$f"; then
    echo "  ❌ FAIL: $f missing react()"
    FAIL=$((FAIL+1))
  fi
done
echo "  ✅ PASS"
PASS=$((PASS+1))

# Test 4: README.md 存在
echo "Test 4: README.md..."
if [[ -f "$AGENTS_DIR/README.md" ]]; then
  echo "  ✅ PASS"
  PASS=$((PASS+1))
else
  echo "  ❌ FAIL"
  FAIL=$((FAIL+1))
fi

# Test 5: 通用 — 任人都能理解
echo "Test 5: 通用（echo/calculator/timer 任人都懂）..."
if grep -q "Echo" "$AGENTS_DIR/echo_agent.py" && \
   grep -q "Calculate" "$AGENTS_DIR/calculator.py" && \
   grep -q "Timer" "$AGENTS_DIR/timer.py"; then
  echo "  ✅ PASS"
  PASS=$((PASS+1))
else
  echo "  ❌ FAIL"
  FAIL=$((FAIL+1))
fi

# Test 6: Python 语法（如果 python3 可用）
echo "Test 6: Python 语法..."
if command -v python3 > /dev/null 2>&1; then
  for f in echo_agent.py calculator.py timer.py; do
    if ! python3 -c "import ast; ast.parse(open('$AGENTS_DIR/$f').read())" 2>&1; then
      echo "  ❌ FAIL: $f syntax error"
      FAIL=$((FAIL+1))
    fi
  done
  echo "  ✅ PASS"
  PASS=$((PASS+1))
else
  echo "  ⚠️  SKIP: python3 not available"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
