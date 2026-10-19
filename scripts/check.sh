#!/bin/sh
# Validates a built site. With no argument it checks the local build ($OUT, default _site);
# with a base URL (https://you.github.io) it checks what is actually being served.
# Uses `sectxt` (the internet.nl security.txt validator) when it is installed.
set -eu

cd "$(dirname "$0")/.."
OUT=${OUT:-_site}
BASE=${1:-}
fail=0
err() { echo "check: FAIL $*" >&2; fail=1; }
ok() { echo "check: ok   $*"; }

if [ -n "$BASE" ]; then
  BASE=${BASE%/}
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  for path in /.well-known/security.txt /robots.txt; do
    out="$tmp$path"
    mkdir -p "$(dirname "$out")"
    meta=$(curl -sS -o "$out" -w '%{http_code} %{content_type} %{num_redirects}' "$BASE$path") || { err "$path: request failed"; continue; }
    set -- $meta
    [ "$1" = 200 ] && ok "$path: HTTP 200" || err "$path: HTTP $1"
    case "${2:-} ${3:-}" in
      "text/plain; charset=utf-8"*) ok "$path: text/plain; charset=utf-8" ;;
      *) err "$path: content type '${2:-} ${3:-}'" ;;
    esac
  done
  OUT=$tmp
fi

sec=$OUT/.well-known/security.txt
[ -f "$sec" ] || { err "missing $sec"; exit 1; }

# RFC 9116 essentials, checked without any tooling.
grep -q '^Contact: ' "$sec" && ok "security.txt: Contact present" || err "security.txt: no Contact"
n=$(grep -c '^Expires: ' "$sec" || true)
[ "$n" = 1 ] && ok "security.txt: exactly one Expires" || err "security.txt: $n Expires fields (need 1)"
exp=$(sed -n 's/^Expires: //p' "$sec" | head -n1)
now=$(date -u +%s)
exp_s=$(date -u -d "$exp" +%s 2>/dev/null || date -u -j -f %Y-%m-%dT%H:%M:%SZ "$exp" +%s)
left=$(((exp_s - now) / 86400))
if [ "$left" -lt 30 ]; then err "security.txt: expires in $left days"
elif [ "$left" -gt 365 ]; then err "security.txt: expires in $left days (RFC 9116: under a year)"
else ok "security.txt: expires in $left days"; fi
if grep -q "$(printf '\r')" "$sec"; then err "security.txt: CR characters"; fi
[ -z "$(tail -c1 "$sec")" ] && ok "security.txt: ends with a newline" || err "security.txt: no final newline"
grep -q 'example\.com' "$sec" && err "security.txt: still has example.com placeholders"

if command -v sectxt >/dev/null 2>&1; then
  if [ -n "$BASE" ]; then target=$BASE/.well-known/security.txt; else target=$sec; fi
  if sectxt --show-recommendations "$target"; then ok "sectxt: valid"; else err "sectxt: invalid"; fi
else
  echo "check: skip sectxt not installed (pip install sectxt)"
fi

[ -f "$OUT/robots.txt" ] && ok "robots.txt present" || err "robots.txt missing"

exit $fail
