#!/bin/sh
# Renders the root files from site.conf into $OUT (default _site), then copies static/ over it.
# POSIX sh, no dependencies beyond date(1) (GNU or BSD).
set -eu

cd "$(dirname "$0")/.."
OUT=${OUT:-_site}
# shellcheck source=../site.conf
. ./site.conf

die() { echo "build: $*" >&2; exit 1; }

[ -n "${OWNER:-}" ] || die "OWNER is empty in site.conf (run: make configure OWNER=<github-user>)"
# In GitHub Actions, refuse to publish another account's settings (a fork that was not configured).
if [ -n "${GITHUB_REPOSITORY_OWNER:-}" ] && [ "$GITHUB_REPOSITORY_OWNER" != "$OWNER" ]; then
  die "site.conf belongs to '$OWNER', this repository to '$GITHUB_REPOSITORY_OWNER'. Run 'make configure' with your own details and commit site.conf."
fi
[ -n "${SECURITY_CONTACTS:-}" ] || die "SECURITY_CONTACTS is empty"

SITE_URL=${SITE_URL:-https://$OWNER.github.io}
SITE_URL=${SITE_URL%/}

# Expires: now + EXPIRES_DAYS, RFC 3339 in UTC. GNU date first, BSD date as fallback.
days=${EXPIRES_DAYS:-180}
expires=$(date -u -d "+$days days" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) ||
  expires=$(date -u -v+"$days"d +%Y-%m-%dT%H:%M:%SZ)

rm -rf "$OUT"
mkdir -p "$OUT/.well-known"

# --- security.txt (RFC 9116) ---
{
  echo "# Security contact for $SITE_URL/ and every project site under it."
  echo "# Generated from site.conf; edit that, not this file."
  if [ -n "${SECURITY_NOTES:-}" ]; then
    echo "$SECURITY_NOTES" | tr ';' '\n' | sed 's/^ *//; s/^/# /'
  fi
  for c in $SECURITY_CONTACTS; do
    case $c in
      mailto:* | https://* | tel:*) echo "Contact: $c" ;;
      *@*) echo "Contact: mailto:$c" ;;
      *) die "SECURITY_CONTACTS entry '$c' must be an email, mailto:, https:// or tel: URI" ;;
    esac
  done
  echo "Expires: $expires"
  [ -z "${SECURITY_ENCRYPTION:-}" ] || echo "Encryption: $SECURITY_ENCRYPTION"
  [ -z "${SECURITY_ACKNOWLEDGMENTS:-}" ] || echo "Acknowledgments: $SECURITY_ACKNOWLEDGMENTS"
  [ -z "${PREFERRED_LANGUAGES:-}" ] || echo "Preferred-Languages: $PREFERRED_LANGUAGES"
  echo "Canonical: $SITE_URL/.well-known/security.txt"
  [ -z "${SECURITY_POLICY:-}" ] || echo "Policy: $SECURITY_POLICY"
} >"$OUT/.well-known/security.txt"

# --- robots.txt (RFC 9309) ---
{
  echo "User-agent: *"
  echo "Allow: /"
  if [ -n "${SITEMAPS:-}" ]; then
    echo
    for s in $SITEMAPS; do echo "Sitemap: $s"; done
  fi
} >"$OUT/robots.txt"

# --- sitemap.xml: index of the project sitemaps (sitemaps.org) ---
if [ -n "${SITEMAPS:-}" ]; then
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    for s in $SITEMAPS; do echo "  <sitemap><loc>$s</loc></sitemap>"; done
    echo '</sitemapindex>'
  } >"$OUT/sitemap.xml"
fi

# --- llms.txt (llmstxt.org) ---
if [ -n "$(echo "${PROJECTS:-}" | tr -d '[:space:]')" ]; then
  {
    echo "# ${SITE_TITLE:-$OWNER}"
    [ -z "${SITE_DESCRIPTION:-}" ] || { echo; echo "> $SITE_DESCRIPTION"; }
    echo
    echo "## Projects"
    echo
    echo "$PROJECTS" | while IFS='|' read -r name url desc; do
      name=$(echo "$name" | sed 's/^ *//; s/ *$//')
      url=$(echo "$url" | sed 's/^ *//; s/ *$//')
      desc=$(echo "${desc:-}" | sed 's/^ *//; s/ *$//')
      [ -n "$name" ] || continue
      [ -n "$url" ] || die "PROJECTS: '$name' has no URL"
      if [ -n "$desc" ]; then echo "- [$name]($url): $desc"; else echo "- [$name]($url)"; fi
    done
  } >"$OUT/llms.txt"
fi

# Anything in static/ is published as-is and wins over the generated files.
cp -R static/. "$OUT/"
# Only matters when publishing from a branch instead of Actions: keeps .well-known/.
touch "$OUT/.nojekyll"

echo "build: wrote $OUT/ for $SITE_URL (security.txt expires $expires)"
