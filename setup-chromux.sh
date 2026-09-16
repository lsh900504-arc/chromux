#!/usr/bin/env bash
# chromux 설치 + Claude Code 클라우드 세션용 설정 스크립트
# 새 세션에서 한 번 실행하면: chromux 설치, 헤드리스 Chromium 래퍼 생성,
# 프록시 인증서를 Chrome 신뢰 저장소에 등록까지 끝납니다.
set -euo pipefail

CHROMIUM=/opt/pw-browsers/chromium
CA_BUNDLE=/root/.ccr/ca-bundle.crt
NSSDB="$HOME/.pki/nssdb"
CHROMUX_HOME="$HOME/.chromux"

echo "[1/4] chromux 설치"
if ! command -v chromux >/dev/null 2>&1; then
  npm install -g chromux
fi
chromux --help >/dev/null 2>&1 && echo "  chromux OK"

echo "[2/4] 헤드리스 Chromium 래퍼 생성"
mkdir -p "$CHROMUX_HOME"
cat > "$CHROMUX_HOME/chrome-wrapper.sh" <<WRAP
#!/bin/sh
exec $CHROMIUM \\
  --headless=new \\
  --no-sandbox \\
  --disable-gpu \\
  --disable-dev-shm-usage \\
  --window-size=1400,1800 \\
  "\$@"
WRAP
chmod +x "$CHROMUX_HOME/chrome-wrapper.sh"
printf '{\n  "chromePath": "%s/chrome-wrapper.sh"\n}\n' "$CHROMUX_HOME" > "$CHROMUX_HOME/config.json"
echo "  wrapper OK"

echo "[3/4] 프록시 인증서를 Chrome 신뢰 저장소에 등록"
if [ -f "$CA_BUNDLE" ]; then
  if ! command -v certutil >/dev/null 2>&1; then
    apt-get update -qq >/dev/null 2>&1 || true
    apt-get install -y -qq libnss3-tools >/dev/null 2>&1
  fi
  mkdir -p "$NSSDB"
  [ -f "$NSSDB/cert9.db" ] || certutil -d "sql:$NSSDB" -N --empty-password
  TMP=$(mktemp)
  openssl crl2pkcs7 -nocrl -certfile "$CA_BUNDLE" | openssl pkcs7 -print_certs 2>/dev/null \
    | awk '/^subject=/{keep = ($0 ~ /CCR Upstream Proxy CA/)} keep{print}' > "$TMP"
  if [ -s "$TMP" ]; then
    certutil -d "sql:$NSSDB" -D -n "CCR Upstream Proxy CA" 2>/dev/null || true
    certutil -d "sql:$NSSDB" -A -n "CCR Upstream Proxy CA" -t "C,," -i "$TMP"
    echo "  certificate OK"
  else
    echo "  경고: 번들에서 프록시 인증서를 찾지 못했습니다 (프록시 없는 환경이면 정상)"
  fi
  rm -f "$TMP"
else
  echo "  프록시 없는 환경: 건너뜀"
fi

echo "[4/4] Chrome 재시작 및 동작 확인"
chromux kill default >/dev/null 2>&1 || true
chromux launch default >/dev/null
chromux open _check "https://www.naver.com" | grep -q '"title": "NAVER"' \
  && echo "  네이버 접속 OK" || echo "  경고: 네이버 접속 실패 (네트워크 정책 확인 필요)"
chromux close _check >/dev/null 2>&1 || true
echo "완료"
