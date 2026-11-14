#!/bin/bash
# Run Infinite DJ check scripts with a hard timeout (sclang never exits after an error).
# Usage: run-checks.sh [name ...]   e.g. run-checks.sh check pop-check   (default: check.scd and every *-check.scd)
#        TIMEOUT=300 run-checks.sh   (seconds per check, default 240)
SCLANG=/Applications/SuperCollider.app/Contents/MacOS/sclang
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
DJ="$ROOT/infinite/experiments/dj"
TIMEOUT="${TIMEOUT:-240}"
LOGDIR="${TMPDIR:-/tmp}/infinite-dj-checks"; mkdir -p "$LOGDIR"
if [ $# -eq 0 ]; then set -- $(cd "$DJ" && ls check.scd *-check.scd | sed 's/\.scd$//'); fi
pass=0; fail=0
for name in "$@"; do
  name="${name%.scd}"; file="$DJ/$name.scd"; log="$LOGDIR/$name.log"
  [ -f "$file" ] || { printf '%-28s MISSING\n' "$name"; fail=$((fail+1)); continue; }
  start=$SECONDS
  perl -e "alarm $TIMEOUT; exec @ARGV" "$SCLANG" -D "$file" >"$log" 2>&1
  code=$?; secs=$((SECONDS-start))
  if [ $code -eq 0 ]; then
    printf '%-28s PASS  %3ss\n' "$name" "$secs"; pass=$((pass+1))
  else
    [ $code -eq 142 ] && why="TIMEOUT" || why="exit $code"
    # Prefer the thrown error (sclang's "preceding error dump" line); skip UDP-port noise.
    err=$(grep -E '^\^\^ The preceding error dump is for ERROR:' "$log" | grep -v 'UDP port' | head -1 | sed 's/^.*dump is for //')
    [ -n "$err" ] || err=$(grep -m1 -E 'ERROR|FAIL' "$log")
    err=$(printf '%s' "$err" | cut -c1-110)
    printf '%-28s FAIL  %3ss (%s) %s\n' "$name" "$secs" "$why" "$err"; fail=$((fail+1))
  fi
done
echo "pass=$pass fail=$fail  logs: $LOGDIR"
[ $fail -eq 0 ]
