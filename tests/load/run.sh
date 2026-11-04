#!/usr/bin/env bash
# Loads razi-protocol and the mods it needs in a real headless game, as a player gets it: a new map, then some ticks,
# for each difficulty. A prototype error, a Lua error at start or a bad number in the data (see check-mod/) fails it.
# Optional dependencies ("?") stay off. Needs bash, python3 and curl; downloading the game needs Linux x64.
#
#   FACTORIO_USERNAME=<account> FACTORIO_TOKEN=<player token> tests/load/run.sh
#   tests/load/run.sh --factorio-bin /path/to/factorio --pool ../razi-latest-mods     # no account, mods from a folder
#
#   --game VERSION        Factorio version; default the version of --factorio-bin, else the stable headless build
#   --factorio-bin PATH   use this game instead of downloading the headless build
#   --difficulty LIST     values of razi-difficulty-preset to load, default "normal nightmare"
#   --pool DIR            take the mods from the zips in DIR (newest of each), repeatable; no portal, no account
#   --ticks N             ticks to run after the new map, default 60
#   --work DIR            working folder, default .load in the repository
#   --resolved            <work>/mods.lock was made by the caller (mods.py resolve): do not resolve again
#   --tree                load the working tree; by default the committed tree as `git archive` packs it, like a release
#
# The mods are resolved with tests/load/mods.py (portal API, newest release for the game version), cached in
# <work>/mods-cache and linked into one folder per difficulty. Exit code 0 means every difficulty loaded.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
work="$root/.load"
game=""
bin=""
levels="normal nightmare"
ticks=60
tree=0
resolved=0
pools=()
while [ $# -gt 0 ]; do
  case "$1" in
    --game) game="$2"; shift 2 ;;
    --factorio-bin) bin="$2"; shift 2 ;;
    --difficulty) levels="$2"; shift 2 ;;
    --pool) pools+=(--pool "$2"); shift 2 ;;
    --ticks) ticks="$2"; shift 2 ;;
    --work) work="$2"; shift 2 ;;
    --resolved) resolved=1; shift ;;
    --tree) tree=1; shift ;;
    -h|--help) sed -n '2,/^set -uo/p' "$0" | sed '$d' | cut -c3-; exit 0 ;;
    *) echo "error: unknown argument $1" >&2; exit 2 ;;
  esac
done
mkdir -p "$work" || exit 2
work="$(cd "$work" && pwd)"

py() { python3 -I "$here/$1" "${@:2}"; }
# limit <seconds> <command...>: macOS has no timeout
limit() { local seconds="$1"; shift; perl -e 'alarm shift; exec @ARGV' "$seconds" "$@"; }

# --- the game ---------------------------------------------------------------------------------------------------
if [ -z "$bin" ]; then
  if [ -z "$game" ]; then
    game="$(curl -fsS --retry 3 https://factorio.com/api/latest-releases | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["stable"]["headless"])')" || exit 1
  fi
  bin="$work/factorio-$game/factorio/bin/x64/factorio"
  if [ ! -x "$bin" ]; then
    if [ "$(uname -s)-$(uname -m)" != "Linux-x86_64" ]; then
      echo "error: the headless build is for Linux x64; pass --factorio-bin" >&2; exit 2
    fi
    echo "downloading Factorio $game (headless)"
    mkdir -p "$work/factorio-$game" || exit 1
    curl -fsSL --retry 3 -o "$work/factorio-$game.tar.xz" "https://factorio.com/get-download/$game/headless/linux64" || { echo "error: cannot download Factorio $game" >&2; exit 1; }
    tar -xJf "$work/factorio-$game.tar.xz" -C "$work/factorio-$game" || exit 1
    rm -f "$work/factorio-$game.tar.xz"
  fi
fi
[ -x "$bin" ] || { echo "error: no game at $bin" >&2; exit 2; }
built="$("$bin" --version < /dev/null | sed -n 's/^Version: \([0-9.]*\).*/\1/p' | head -1)"
[ -n "$built" ] || { echo "error: cannot read the version of $bin" >&2; exit 2; }
if [ -n "$game" ] && [ "$game" != "$built" ]; then
  echo "error: $bin is Factorio $built, not $game" >&2; exit 2
fi
game="$built"
echo "Factorio $game"

# --- the mods ---------------------------------------------------------------------------------------------------
if [ "$resolved" -eq 0 ]; then
  py mods.py resolve --info "$root/info.json" --game "$game" --out "$work/mods.lock" ${pools[@]+"${pools[@]}"} || exit 1
fi
if [ ${#pools[@]} -eq 0 ]; then
  py mods.py fetch --lock "$work/mods.lock" --dir "$work/mods-cache" || exit 1
fi

# the mod as a release packs it (files marked export-ignore left out), or the working tree
version="$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$root/info.json")"
razi=()
if [ "$tree" -eq 1 ]; then
  razi=(--razi-dir "$root")
else
  git -C "$root" diff --quiet HEAD -- . 2> /dev/null || echo "note: uncommitted changes are not loaded (--tree loads them)"
  rm -f "$work"/razi-protocol_*.zip
  git -C "$root" archive --format=zip --prefix="razi-protocol_$version/" -o "$work/razi-protocol_$version.zip" HEAD || exit 1
  razi=(--razi-zip "$work/razi-protocol_$version.zip")
fi

# --- one difficulty -----------------------------------------------------------------------------------------------
failed=0
summary=""
run_level() {
  local level="$1" dir="$work/run-$1" step started
  rm -rf "$dir"; mkdir -p "$dir/config" || return 1
  py mods.py link --lock "$work/mods.lock" --dir "$work/mods-cache" --out "$dir/mods" ${razi[@]+"${razi[@]}"} --extra "$here/check-mod" > /dev/null || return 1
  py mod_settings.py write "$dir/mods/mod-settings.dat" --game "$game" "razi-difficulty-preset=$level" || return 1
  local readdata="__PATH__system-read-data__"
  [ -d "$(dirname "$bin")/../../data/base" ] && readdata="__PATH__executable__/../../data"
  printf '[path]\nread-data=%s\nwrite-data=%s\n[other]\nenable-new-mods=false\n' "$readdata" "$dir" > "$dir/config.ini"

  for step in create ticks; do
    started=$(date +%s)
    if [ "$step" = create ]; then
      limit 1500 "$bin" -c "$dir/config.ini" --create "$dir/map.zip" < /dev/null > "$dir/$step.txt" 2>&1
    else
      limit 1500 "$bin" -c "$dir/config.ini" --benchmark "$dir/map.zip" --benchmark-ticks "$ticks" --benchmark-runs 1 < /dev/null > "$dir/$step.txt" 2>&1
    fi
    local code=$?
    if [ $code -ne 0 ]; then
      echo "::error title=razi-protocol does not load ($level, $step)::exit code $code; the game's error is below"
      # a prototype error is in the log; the stack trace of a Lua error is at the end of the game's output
      { grep -hE -A3 " Error |Failed to load" "$dir/factorio-current.log" || tail -20 "$dir/$step.txt"; } | cut -c1-700
      summary="$summary| $level | $step | FAILED, exit code $code |  |"$'\n'
      return 1
    fi
    echo "ok   $level $step ($(( $(date +%s) - started )) s)"
    summary="$summary| $level | $step | ok | $(( $(date +%s) - started )) s |"$'\n'
  done
  grep -h "razi-load-check:" "$dir/create.txt" | sed 's/^ *[0-9.]* Script @[^ ]* //' | head -1
}

for level in $levels; do
  echo "== razi-difficulty-preset = $level"
  run_level "$level" || failed=1
done

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Game load, Factorio $game"
    echo
    echo "| difficulty | step | result | time |"
    echo "| --- | --- | --- | --- |"
    printf '%s' "$summary"
    echo
    echo "$(python3 -I -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["mods"]))' "$work/mods.lock") mods besides razi-protocol."
  } >> "$GITHUB_STEP_SUMMARY"
fi
[ $failed -eq 0 ] && echo "loaded: $levels" || echo "FAILED" >&2
exit $failed
