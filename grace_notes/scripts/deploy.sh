#!/bin/bash
# 🚀 Grace Note (그레이스노트) - 배포 스크립트

set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Grace Note (그레이스노트) 배포 스크립트${NC}"
echo "=================================================="

# 현재 버전 확인
CURRENT_VERSION=$(grep "version:" pubspec.yaml | cut -d ' ' -f 2)
echo -e "${YELLOW}📊 현재 버전: $CURRENT_VERSION${NC}"

# 배포 타입 선택
echo ""
echo "배포 타입을 선택하세요:"
echo "1) Patch (버그 수정)"
echo "2) Minor (새 기능)"
echo "3) Major (대규모 변경)"
echo "4) 수동 입력"
echo "5) GitHub Actions로 배포"

read -p "선택 (1-5): " choice

case $choice in
    1)
        BUMP_TYPE="patch"
        ;;
    2)
        BUMP_TYPE="minor"
        ;;
    3)
        BUMP_TYPE="major"
        ;;
    4)
        read -p "새 버전을 입력하세요 (예: 1.0.1): " NEW_VERSION
        ;;
    5)
        echo -e "${BLUE}🌐 GitHub Actions로 배포를 진행합니다...${NC}"
        
        # 현재 브랜치 확인
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        
        # 변경사항 확인
        if [[ -n $(git status --porcelain) ]]; then
            echo -e "${YELLOW}⚠️  커밋되지 않은 변경사항이 있습니다.${NC}"
            read -p "계속 진행하시겠습니까? (y/N): " confirm
            if [[ $confirm != [yY] ]]; then
                echo "배포를 취소했습니다."
                exit 1
            fi
            
            # 변경사항 커밋
            git add .
            read -p "커밋 메시지를 입력하세요: " commit_msg
            git commit -m "$commit_msg"
        fi
        
        # 태그 생성
        read -p "새 버전 태그를 입력하세요 (예: v1.0.1): " tag_version
        
        # 태그 생성 및 푸시
        git tag $tag_version
        git push origin $CURRENT_BRANCH
        git push origin $tag_version
        
        echo -e "${GREEN}✅ 태그가 생성되었습니다: $tag_version${NC}"
        echo -e "${BLUE}🔗 GitHub Actions에서 배포 상태를 확인하세요:${NC}"
        echo "https://github.com/yeonghun00/grace-notes/actions"
        
        exit 0
        ;;
    *)
        echo -e "${RED}❌ 잘못된 선택입니다.${NC}"
        exit 1
        ;;
esac

# 버전 업데이트 (선택 1-3인 경우)
if [[ -n $BUMP_TYPE ]]; then
    echo -e "${BLUE}🔄 $BUMP_TYPE 버전 업데이트 중...${NC}"
    
    # 간단한 버전 업데이트 로직
    VERSION_NUMBER=$(echo $CURRENT_VERSION | cut -d '+' -f 1)
    BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d '+' -f 2)
    
    IFS='.' read -ra VERSION_PARTS <<< "$VERSION_NUMBER"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    PATCH=${VERSION_PARTS[2]}
    
    case $BUMP_TYPE in
        "patch")
            PATCH=$((PATCH + 1))
            ;;
        "minor")
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        "major")
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
    esac
    
    NEW_VERSION="$MAJOR.$MINOR.$PATCH"
fi

# pubspec.yaml 업데이트
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_FULL_VERSION="$NEW_VERSION+$NEW_BUILD_NUMBER"

echo -e "${YELLOW}📝 버전 업데이트: $CURRENT_VERSION → $NEW_FULL_VERSION${NC}"

sed -i.bak "s/version: .*/version: $NEW_FULL_VERSION/" pubspec.yaml
rm pubspec.yaml.bak

echo -e "${GREEN}✅ pubspec.yaml 업데이트 완료${NC}"

# Git 커밋 및 태그
echo -e "${BLUE}📤 Git 커밋 및 태그 생성 중...${NC}"

git add pubspec.yaml
git commit -m "🔖 버전 업데이트: v$NEW_VERSION

- 자동 버전 증가
- 빌드 번호: $NEW_BUILD_NUMBER"

git tag "v$NEW_VERSION"

echo -e "${GREEN}✅ 로컬 태그 생성 완료: v$NEW_VERSION${NC}"

# 원격 저장소에 푸시할지 확인
read -p "원격 저장소에 푸시하여 자동 배포를 시작하시겠습니까? (y/N): " push_confirm

if [[ $push_confirm == [yY] ]]; then
    echo -e "${BLUE}🚀 원격 저장소에 푸시 중...${NC}"
    
    git push origin main
    git push origin "v$NEW_VERSION"
    
    echo -e "${GREEN}✅ 배포 시작됨!${NC}"
    echo -e "${BLUE}🔗 GitHub Actions에서 배포 상태를 확인하세요:${NC}"
    echo "https://github.com/yeonghun00/grace-notes/actions"
else
    echo -e "${YELLOW}⏸️  로컬에만 태그가 생성되었습니다.${NC}"
    echo "나중에 다음 명령어로 배포할 수 있습니다:"
    echo "git push origin main && git push origin v$NEW_VERSION"
fi

echo -e "${GREEN}🎉 배포 스크립트 완료!${NC}"