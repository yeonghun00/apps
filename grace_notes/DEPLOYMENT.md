# 🚀 Grace Note (그레이스노트) - Google Play Store 자동 배포 가이드

이 문서는 GitHub Actions을 통한 자동 배포 설정 방법을 설명합니다.

## 📋 사전 준비사항

### 1. Google Play Console 설정
1. [Google Play Console](https://play.google.com/console)에 로그인
2. 앱 생성 (Application ID: `com.thousandemfla.grace_notes`)
3. API 액세스 설정:
   - Google Cloud Console에서 새 서비스 계정 생성
   - Play Console에서 서비스 계정 권한 부여
   - JSON 키 파일 다운로드

### 2. Android 앱 서명 키 생성
```bash
# 새 키스토어 생성
keytool -genkey -v -keystore release.keystore -alias grace-note-key -keyalg RSA -keysize 2048 -validity 10000

# 키스토어를 Base64로 인코딩 (GitHub Secrets용)
base64 -i release.keystore | tr -d '\n' > keystore.base64
```

## 🔐 GitHub Secrets 설정

GitHub 저장소의 Settings > Secrets and variables > Actions에서 다음 시크릿들을 추가하세요:

### 필수 시크릿들:
```
SIGNING_KEY_ALIAS=grace-note-key
SIGNING_KEY_PASSWORD=키_비밀번호
SIGNING_STORE_PASSWORD=키스토어_비밀번호
SIGNING_KEY_STORE_BASE64=base64로_인코딩된_키스토어_내용
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=서비스_계정_JSON_파일_내용
```

## 🚀 배포 방법

### 자동 배포 (권장)
```bash
# 1. 버전 태그 생성 및 푸시
git tag v1.0.1
git push origin v1.0.1

# GitHub Actions이 자동으로 빌드 및 배포 실행
```

### 수동 배포
1. GitHub Actions 탭으로 이동
2. "🚀 Deploy Grace Note to Google Play Store" 워크플로 선택
3. "Run workflow" 클릭
4. 배포 트랙 선택 (internal/alpha/beta/production)

## 📊 배포 트랙 설명

- **internal**: 내부 테스트 (최대 100명)
- **alpha**: 알파 테스트 (비공개 테스터)
- **beta**: 베타 테스트 (공개 베타)
- **production**: 정식 출시

## 🔧 워크플로 기능

### ✅ 자동화 기능:
- 📦 의존성 설치
- 🧪 테스트 실행
- 🔍 코드 분석
- 🔢 버전 자동 증가
- 🏗️ AAB 빌드
- 📤 Play Store 업로드
- 📊 릴리스 노트 생성

### 🛡️ 보안 기능:
- 🔐 키스토어 안전한 처리
- 🧹 빌드 후 민감 파일 자동 삭제
- 🔒 코드 난독화 및 최적화

## 📱 앱 정보

- **앱 이름**: 그레이스노트
- **패키지 이름**: com.thousandemfla.grace_notes
- **현재 버전**: 1.0.0+1

## 🐛 문제 해결

### 빌드 실패 시:
1. GitHub Actions 로그 확인
2. Secrets 설정 재확인
3. 키스토어 파일 유효성 검증

### 업로드 실패 시:
1. Play Console API 권한 확인
2. 서비스 계정 JSON 파일 재확인
3. 앱 버전 중복 여부 확인

## 🔄 버전 관리

- **major.minor.patch+buildNumber** 형식 사용
- 빌드 번호는 자동으로 증가
- 태그 형식: `v1.0.1`

## 📞 지원

문제가 발생하면 GitHub Issues에 등록하거나 개발팀에 문의하세요.

---
💜 Grace Note (그레이스노트) 개발팀