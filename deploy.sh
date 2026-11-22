#!/usr/bin/env bash
# e편한세상시티 원페이지 → GitHub Pages 재배포(수정 반영)
# 사용: bash deploy.sh
#
# 2026-11-23 첫 배포 상태:
#   - 리포: https://github.com/00up88/epyeonhan-cheonan-asan (Public)
#   - 라이브: https://00up88.github.io/epyeonhan-cheonan-asan/
#   - Pages 소스: gh-pages 브랜치 / (root), build_type legacy, https 강제
#   - Pickle GitHub 앱 토큰은 리포 생성·Pages 설정 변경(POST/PUT /pages) 권한이 없다(403).
#     그래서 Pages 는 최초에 gh-pages 브랜치 푸시로 자동 활성화됐고,
#     이후 수정은 main 과 gh-pages 두 브랜치에 모두 푸시해야 사이트에 반영된다.
set -uo pipefail

OWNER=00up88
REPO=epyeonhan-cheonan-asan
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "== 1. 리포지토리 확인 =="
gh api "repos/$OWNER/$REPO" >/dev/null 2>&1 || { echo "BLOCKED: repos/$OWNER/$REPO 접근 불가"; exit 2; }

echo "== 2. 커밋 =="
git add -A
git diff --cached --quiet || git commit -m "원페이지 내용 수정 $(date +%Y-%m-%d\ %H:%M)"

echo "== 3. 푸시 (main + gh-pages = Pages 배포 브랜치) =="
git remote remove origin 2>/dev/null
git remote add origin "https://github.com/$OWNER/$REPO.git"
git push -u origin main || { echo "BLOCKED: main 푸시 실패"; exit 3; }
git push -f origin main:gh-pages || { echo "BLOCKED: gh-pages 푸시 실패"; exit 3; }

echo "== 4. Pages 빌드 대기 =="
URL="https://$OWNER.github.io/$REPO/"
for i in $(seq 1 30); do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$URL")
  echo "  [$i] http=$code  $(gh api "repos/$OWNER/$REPO/pages" --jq '.status' 2>/dev/null)"
  [ "$code" = "200" ] && break
  sleep 10
done

echo "== 5. 자산 확인 =="
for p in "" hero.jpg view.jpg PretendardVariable.woff2; do
  echo "  $(curl -s -o /dev/null -w '%{http_code}' "$URL$p")  $URL$p"
done
echo "== 완료: $URL =="
