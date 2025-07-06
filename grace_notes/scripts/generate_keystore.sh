#!/bin/bash
# 🔐 Grace Note (그레이스노트) - Android 키스토어 생성 스크립트

echo "🔐 Grace Note Android 키스토어 생성 중..."
echo "======================================"

# 키스토어 파일명
KEYSTORE_FILE="grace-note-release.keystore"
KEY_ALIAS="grace-note-key"

# 키스토어 생성
echo "📝 키스토어 정보를 입력해주세요:"
keytool -genkey -v \
    -keystore $KEYSTORE_FILE \
    -alias $KEY_ALIAS \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000

echo ""
echo "✅ 키스토어가 생성되었습니다: $KEYSTORE_FILE"
echo ""

# Base64 인코딩
echo "🔒 GitHub Secrets용 Base64 인코딩 중..."
base64 -i $KEYSTORE_FILE | tr -d '\n' > keystore.base64

echo "✅ Base64 인코딩 완료: keystore.base64"
echo ""

# GitHub Secrets 설정 안내
echo "🔧 GitHub Secrets 설정:"
echo "======================================"
echo "SIGNING_KEY_ALIAS=$KEY_ALIAS"
echo "SIGNING_KEY_PASSWORD=[키 비밀번호]"
echo "SIGNING_STORE_PASSWORD=[키스토어 비밀번호]"
echo "SIGNING_KEY_STORE_BASE64="
cat keystore.base64
echo ""
echo ""

# 보안 경고
echo "⚠️  보안 주의사항:"
echo "======================================"
echo "1. 키스토어 파일($KEYSTORE_FILE)을 안전한 곳에 백업하세요"
echo "2. 비밀번호를 잊지 마세요 (복구 불가능)"
echo "3. keystore.base64 파일은 GitHub Secrets 설정 후 삭제하세요"
echo "4. 이 파일들을 Git에 커밋하지 마세요"

echo ""
echo "🎉 설정 완료! DEPLOYMENT.md 문서를 참고하여 배포를 진행하세요."