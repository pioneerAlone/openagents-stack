#!/usr/bin/env bash
# ============================================================
# test_all.sh — 运行所有单元测试
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_TESTS=()

for test_file in "$SCRIPT_DIR"/test_*.sh; do
  echo ""
  echo "=========================================="
  echo "Running: $(basename "$test_file")"
  echo "=========================================="

  if bash "$test_file" 2>&1; then
    : # passed
  else
    FAILED_TESTS+=("$(basename "$test_file")")
  fi
done

echo ""
echo "=========================================="
echo "All tests complete"
echo "=========================================="

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
  echo "❌ Failed tests:"
  for t in "${FAILED_TESTS[@]}"; do
    echo "  - $t"
  done
  exit 1
else
  echo "✅ All tests passed!"
  exit 0
fi
