#!/usr/bin/env bash
# Self-contained test suite for bqn-hist. Requires the BQN.jar toolchain (JDK).
set -uo pipefail
cd "$(dirname "$0")"
TC="${TC:-$HOME/.local/toolchains}"
export PATH="$TC/jdk/bin:$TC/bqn:$PATH"
[ -x "$TC/bqn/bqn" ] || { echo "FAIL: BQN not found at $TC/bqn/bqn (set TC)"; exit 1; }
command -v java >/dev/null 2>&1 || { echo "FAIL: java not found on PATH"; exit 1; }
./build.sh >/dev/null
HIST="./bin/bqn-hist"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok(){ pass=$((pass+1)); }
bad(){ fail=$((fail+1)); echo "FAIL: $1"; }
# assert exit code and an output substring
check(){ # name expected_exit expected_substring actual_exit actual_out
  local name="$1" want_rc="$2" want="$3" rc="$4" out="$5"
  if [ "$rc" != "$want_rc" ]; then bad "$name (exit $rc, want $want_rc)"; return; fi
  if [ -n "$want" ] && ! printf '%s' "$out" | grep -qF -- "$want"; then
    bad "$name (output missing '$want')"; return
  fi
  ok
}
# assert exact full output (command substitution strips the trailing newline)
exact(){ # name expected actual
  if [ "$3" = "$2" ]; then ok; else bad "$1 (got '$3', want '$2')"; fi
}

printf 'the cat and the dog and the bird\nThe CAT sat on the mat\n' > "$TMP/text.txt"
out=$($HIST "$TMP/text.txt" 3); rc=$?
check "top-3 runs" 0 "5 the" "$rc" "$out"
exact "top-3 order + tie-break" "$(printf '5 the\n2 and\n2 cat')" "$out"

out=$($HIST "$TMP/text.txt"); rc=$?
check "default topN runs" 0 "1 bird" "$rc" "$out"
[ "$(printf '%s\n' "$out" | wc -l)" -eq 8 ] && ok || bad "default shows all 8 unique words"

out=$($HIST "$TMP/text.txt" 1); rc=$?
check "top-1 runs" 0 "5 the" "$rc" "$out"
exact "top-1 is one line" "5 the" "$out"

printf 'b a b a c\n' > "$TMP/tie.txt"
out=$($HIST "$TMP/tie.txt"); rc=$?
check "tie fixture runs" 0 "2 a" "$rc" "$out"
exact "ties break word-asc" "$(printf '2 a\n2 b\n1 c')" "$out"

printf 'Hello, hello! HELLO world.\n' > "$TMP/punct.txt"
out=$($HIST "$TMP/punct.txt"); rc=$?
check "punctuation/case runs" 0 "3 hello" "$rc" "$out"
line_world=$(printf '%s\n' "$out" | grep -c '^1 world$')
[ "$line_world" -eq 1 ] && ok || bad "punctuation stripped from world"

printf 'a\tb  a\n' > "$TMP/tabs.txt"
out=$($HIST "$TMP/tabs.txt"); rc=$?
check "tabs/multi-space run" 0 "2 a" "$rc" "$out"
exact "tab split" "$(printf '2 a\n1 b')" "$out"

: > "$TMP/empty.txt"
out=$($HIST "$TMP/empty.txt"); rc=$?
check "empty file ok" 0 "" "$rc" "$out"
exact "empty file silent" "" "$out"

out=$($HIST "$TMP/text.txt" 0); rc=$?
check "topN=0 ok" 0 "" "$rc" "$out"
exact "topN=0 silent" "" "$out"

out=$($HIST "$TMP/tie.txt" 99); rc=$?
check "topN clamps" 0 "1 c" "$rc" "$out"
[ "$(printf '%s\n' "$out" | wc -l)" -eq 3 ] && ok || bad "clamped to 3 unique words"

out=$($HIST 2>&1); rc=$?
check "no args errors" 1 "usage: bqn-hist" "$rc" "$out"

out=$($HIST "$TMP/text.txt" abc 2>&1); rc=$?
check "bad topN errors" 1 "topN must be" "$rc" "$out"

out=$($HIST "$TMP/text.txt" -1 2>&1); rc=$?
check "negative topN errors" 1 "" "$rc" "$out"

out=$($HIST "$TMP/nonexistent.txt" 2>&1); rc=$?
check "missing file errors" 1 "" "$rc" "$out"

echo "----------------------------------------"
echo "bqn-hist: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && echo "ALL CHECKS PASSED" || exit 1