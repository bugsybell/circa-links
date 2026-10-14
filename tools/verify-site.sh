#!/bin/sh
# Verifies the site. Local:  tools/verify-site.sh
#                 Live:      tools/verify-site.sh https://join.ourcirca.com
# Live mode additionally checks DNS/HTTPS behaviour that Universal Links depend on.
set -u
cd "$(dirname "$0")/.."
BASE="${1:-}"
fail=0
ok()  { echo "PASS  $1"; }
bad() { echo "FAIL  $1"; fail=1; }
chk() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

echo "== files"
chk "CNAME is exactly join.ourcirca.com" '[ "$(cat CNAME | tr -d "\n")" = "join.ourcirca.com" ]'
chk ".nojekyll present (publishes .well-known)" '[ -f .nojekyll ]'
chk "AASA is valid JSON" 'python3 -c "import json;json.load(open(\".well-known/apple-app-site-association\"))"'
chk "AASA app ID is G588ZXG856.com.pinzo.circa" 'grep -q "G588ZXG856.com.pinzo.circa" .well-known/apple-app-site-association'
chk "AASA covers /join/ and /invite/" 'grep -q "\"/join/\"" .well-known/apple-app-site-association && grep -q "\"/invite/\"" .well-known/apple-app-site-association'
chk "pages are up to date with tools/ (python3 tools/build.py leaves no diff)" 'cp invite/index.html /tmp/_i && cp join/index.html /tmp/_j && python3 tools/build.py >/dev/null && cmp -s /tmp/_i invite/index.html && cmp -s /tmp/_j join/index.html'
for p in invite join; do
  chk "$p: CSP pins the inline script hash" 'h=$(python3 - <<PY
import re,hashlib,base64
t=open("'$p'/index.html").read()
s=re.search(r"<script>(.*?)</script>",t,re.S).group(1)
print(base64.b64encode(hashlib.sha256(s.encode()).digest()).decode())
PY
); grep -q "script-src '"'"'sha256-$h'"'"'" '$p'/index.html'
  chk "$p: no external URLs, trackers or remote scripts" '! grep -Eq "(src|href)=\"https?://|<link |<img |<iframe" '$p'/index.html'
  chk "$p: noindex + no-referrer" 'grep -q "noindex" '$p'/index.html && grep -q "no-referrer" '$p'/index.html'
done
chk "hand-off logic (stubbed DOM)" 'command -v bun >/dev/null && bun tools/test-handoff.mjs || node tools/test-handoff.mjs'

if [ -n "$BASE" ]; then
  echo "== live: $BASE"
  host=$(echo "$BASE" | sed 's#https://##; s#/.*##')
  chk "DNS: $host is a CNAME to bugsybell.github.io" 'dig +short CNAME '"$host"' | grep -qi "bugsybell.github.io"'
  A="$BASE/.well-known/apple-app-site-association"
  code=$(curl -sS -m 20 -o /tmp/_aasa -w "%{http_code} %{redirect_url} %{content_type}" "$A")
  chk "AASA: HTTP 200, no redirect ($code)" 'echo "'"$code"'" | grep -Eq "^200  "'
  chk "AASA: body is the same JSON as the repo file" 'cmp -s /tmp/_aasa .well-known/apple-app-site-association'
  chk "AASA: parseable JSON" 'python3 -c "import json;json.load(open(\"/tmp/_aasa\"))"'
  for p in invite join; do
    chk "/$p/ served as HTML 200" 'curl -sS -m 20 -o /dev/null -w "%{http_code} %{content_type}" '"$BASE/$p/"' | grep -Eq "^200 text/html"'
    chk "/$p/ matches the repo page" 'curl -sS -m 20 '"$BASE/$p/"' | cmp -s - '$p'/index.html'
  done
  chk "HTTPS certificate valid" 'curl -sS -m 20 -o /dev/null '"$BASE/"
  echo "== reminder: Apple's CDN copy (what iOS actually uses)"
  echo "   curl -sS https://app-site-association.cdn-apple.com/a/v1/$host"
fi
[ $fail -eq 0 ] && echo "\nALL PASSED" || echo "\nFAILURES"
exit $fail
