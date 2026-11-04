#!/usr/bin/env bash
# Runs every tests/lua/test_*.lua on Lua 5.2 from the repository root and prints the failures.
#   tests/run.sh
# LUA is the interpreter (default: lua from the toolchain of factorio-mod-tools), RAZI_LIB_PATH the RaziLib checkout
# (default: ../RaziLib).
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
lua="${LUA:-${FACTORIO_LUA_HOME:-$HOME/.local/share/factorio-lua}/5.2/bin/lua}"
export RAZI_LIB_PATH="${RAZI_LIB_PATH:-../RaziLib}"
export LUA_INIT=@tests/lua/razi_lib_bootstrap.lua

if [ ! -x "$lua" ]; then
  echo "error: no Lua 5.2 at $lua" >&2
  exit 2
fi
if [ ! -d "$RAZI_LIB_PATH" ]; then
  echo "error: no RaziLib at $RAZI_LIB_PATH" >&2
  exit 2
fi

passed=0
failed=0
for test in tests/lua/test_*.lua; do
  # perl for the time limit: macOS has no timeout
  if output=$(perl -e 'alarm 120; exec @ARGV' "$lua" "$test" 2>&1 </dev/null); then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
    echo "FAIL $test"
    echo "$output" | head -20
  fi
done
echo "tests: $passed passed, $failed failed"
[ "$failed" -eq 0 ] && [ "$passed" -gt 0 ]
