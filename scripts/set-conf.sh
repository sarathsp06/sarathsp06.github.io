#!/bin/sh
# set-conf.sh KEY VALUE: replaces KEY="..." in site.conf (the key must already exist).
set -eu
cd "$(dirname "$0")/.."
key=$1 value=$2
grep -q "^$key=" site.conf || { echo "set-conf: unknown key $key" >&2; exit 1; }
case $value in *'"'* | *'\'* | *'$'* | *'`'*) echo "set-conf: $key: quotes, backslashes, \$ and \` are not allowed" >&2; exit 1 ;; esac
tmp=$(mktemp)
# A quoted value may span lines (PROJECTS): skip the old value up to its closing quote.
awk -v k="$key" -v v="$value" '
  skip { if ($0 ~ /"[[:space:]]*$/) skip = 0; next }
  index($0, k "=") == 1 {
    print k "=\"" v "\""
    rest = substr($0, length(k) + 3)
    if (rest !~ /"[[:space:]]*$/) skip = 1
    next
  }
  { print }' site.conf >"$tmp"
mv "$tmp" site.conf
echo "set-conf: $key=\"$value\""
