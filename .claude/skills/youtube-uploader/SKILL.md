---
name: youtube-uploader
description: YouTube 영상 업로드 자동화. upload-package.md를 파싱하여 메타데이터를 보강하고,
  youtubeuploader CLI로 업로드. "youtube upload", "영상 업로드", "유튜브 업로드" 등의 요청 시 자동 적용.
---

# YouTube Uploader

`07-upload-package.md`를 파싱하여 메타데이터를 보강하고 `youtubeuploader` CLI로 YouTube에 업로드하는 스킬.

## Trigger

- "youtube upload", "영상 업로드", "유튜브 업로드"
- "지난번 만든 영상 업로드해줘", "유튜브에 올려줄래?"
- `youtube-scriptwriter` Phase 7에서 자동 호출

## Invocation

**From youtube-scriptwriter**: Phase 7에서 자동 호출. `{OUTPUT_DIR}`이 자동으로 전달됨.
**Standalone**: `/youtube-uploader <project-directory>` 또는 자연어 "upload {directory}"
**No path provided**: Claude가 "어느 프로젝트 디렉토리를 업로드할까요? (경로 입력)" 질문

## Input

| 인수 | 설명 | 기본값 |
|------|------|--------|
| (positional) | 프로젝트 디렉토리 경로 | scriptwriter에서 호출 시 `{OUTPUT_DIR}`, 독립 실행 시 필수 |
| `--channel` | 채널 이름 | config.yaml의 default_channel |
| `--dry-run` | 메타데이터 생성만, 업로드 안 함 | false |

`--dry-run` 용도: 메타데이터 미리보기만 확인하고 싶을 때, 또는 metadata.json을 다른 업로더 도구로 사용하고 싶을 때.

## Prerequisites

- `youtubeuploader` CLI 설치 (`go install github.com/porjo/youtubeuploader@latest`)
- `~/.config/yt-uploader/config.yaml` 설정 (채널 인증 정보)
- 채널별 OAuth 인증 완료 (`youtubeuploader -filename dummy.mp4 -secrets <secrets.json>`)

## Contract with youtube-scriptwriter

이 스킬은 아래 디렉토리 구조를 기대한다:

```
{project-dir}/
  ├── 07-upload-package.md     (필수 - 메타데이터 원본)
  ├── 00-briefing.md           (필수 - 결과 업데이트 대상)
  ├── 01-success-analysis.md   (선택 - 참조 출처 추출)
  ├── 02-fact-check.md         (선택 - 참조 출처 추출)
  └── 06-storyboard.md         (선택 - BGM/라이센스 추출)
```

## Workflow

### Step 1: Environment Check

환경 확인. 하나라도 실패 시 안내 메시지 출력 후 중단.

```bash
which youtubeuploader || echo "ERROR: youtubeuploader not installed"
test -f ~/.config/yt-uploader/config.yaml || echo "ERROR: config.yaml not found"
```

채널 cache 파일 존재 여부도 확인:
```bash
# config.yaml에서 선택된 채널의 cache 경로를 읽어 파일 존재 확인
test -f "{CHANNEL_CACHE}" || echo "WARNING: token 파일이 없습니다. 재인증이 필요합니다."
```

토큰 유효성은 업로드 시점에만 확인 가능 (API 호출 필요). 만료 에러는 Step 6에서 처리.

### Step 2: Input Collection

**2-0. 디렉토리 검증**

`{PROJECT_DIR}`이 존재하고 디렉토리인지 확인. 아니면 에러 + 경로 재입력 요청.

**2-1. 필수 파일 확인**

`{PROJECT_DIR}/07-upload-package.md` 존재 확인 (정확한 경로, 재귀 탐색 아님).
없으면 "youtube-scriptwriter를 먼저 실행하세요" 안내 후 중단.

**2-2. 영상 파일 탐색**

Glob 도구로 `{PROJECT_DIR}/*.mp4` 탐색:
- 1개 → 자동 선택
- 복수 → 번호 목록 표시, 사용자에게 선택 요청
- 0개 → "영상 파일 경로를 입력해주세요" 질문

**2-3. 썸네일 탐색**

Glob 도구로 `{PROJECT_DIR}/*.{png,jpg}` 탐색:
- 1개 → 자동 선택
- 복수 → 번호 목록 표시, 사용자에게 선택 요청
- 0개 → "썸네일 경로를 입력해주세요 (없으면 Enter)" 질문

**2-4. 채널 선택**

- `--channel` 인수가 제공됨 → config에서 검증, 없으면 에러
- config에 채널 1개만 → 자동 선택
- config에 채널 복수 → 번호 목록 표시 (default 채널 표시), 사용자에게 선택 요청:
```
발견된 채널:
1. 메인 채널 (main) [기본] - Science & Technology
2. 두 번째 채널 (second) - People & Blogs

어느 채널에 업로드하시겠습니까? (1-2, Enter=기본):
```

### Step 3: Metadata Generation

`scripts/gen_metadata.py` 실행하여 `metadata.json` 생성.

```bash
python3 ~/.claude/skills/youtube-uploader/scripts/gen_metadata.py \
  "{PROJECT_DIR}/07-upload-package.md" \
  --output "{PROJECT_DIR}/metadata.json" \
  --config ~/.config/yt-uploader/config.yaml \
  --channel {CHANNEL_NAME}
```

파싱 실패 시: 스크립트가 에러 메시지와 함께 exit code 1을 반환한다.
Claude는 에러 메시지를 사용자에게 보여주고, 누락된 필드(Title/Description/Tags)를 직접 질문하여
`references/metadata-schema.md`를 참고해 수동으로 metadata.json을 Write 도구로 생성한다.

### Step 4: Metadata Enrichment

Claude가 메타데이터를 보강한다. 각 섹션은 독립적으로 시도하며, 실패한 섹션만 생략한다.

**보강 실패 기준**: 해당 섹션의 소스 파일이 없거나, 파일에서 필수 정보를 추출할 수 없는 경우.
모든 섹션이 실패하면 "메타데이터 보강을 건너뜁니다" 메시지를 표시하고 원본 description 그대로 사용.

**4-1. 트렌드 해시태그** (소스: 영상 주제 키워드)

영상 주제 키워드 기반 해시태그 생성. 형식: `#키워드2026 #관련트렌드`.
description 하단에 삽입.

**4-2. 참조 리소스 출처** (소스: `01-success-analysis.md`, `02-fact-check.md`)

출처 수집하여 포맷팅:
```
📚 참고 자료 / References
- [공식 문서] Title: URL
- [논문] Title (Author, Year)
- [영상] Title - Channel: URL
```

예: `01-success-analysis.md`에서 "참고: Kubernetes 공식 문서 (https://kubernetes.io/docs)"
→ "- [공식 문서] Kubernetes Documentation: https://kubernetes.io/docs"

**4-3. 라이센스 표기** (소스: `06-storyboard.md`)

BGM/이미지 정보 추출하여 포맷팅:
```
🎵 Music / BGM
- Track: {title} by {artist}
- License: {type}
- Source: {url}

📋 License
- Content: {license_type}
- Images: {attribution}
```

**최종 Description 구조:**
```
{2-3줄 핵심 요약}

---
⏱ 타임스탬프
00:00 {chapter}
...

---
📚 참고 자료 / References
{출처 목록}

---
🎵 Music / BGM
{BGM 정보}

📋 License
{라이센스 표기}

---
{소셜 링크}
#해시태그 #트렌드태그
```

보강된 description을 `metadata.json`에 업데이트:
Claude가 Read 도구로 `metadata.json`을 읽고, description 필드를 보강된 내용으로 교체한 뒤, Write 도구로 전체 JSON을 다시 쓴다.

### Step 5: Preview + User Approval

메타데이터를 사용자에게 미리보기로 제시. 한계에 가까운 값은 경고 표시:

```
📋 업로드 미리보기

채널: {channel_name}
제목: "{title}" {⚠️ if > 90 chars}
공개: {privacyStatus} {publishAt if scheduled}
카테고리: {category_name}
태그: {tag_count}개 ({tag_chars}/500 chars) {⚠️ if > 450}
재생목록: {playlist_name or "없음"}
영상: {video_path} ({file_size})
썸네일: {thumbnail_path or "없음"}

Description 미리보기:
─────────────────────
{first 5 lines}
... ({total_chars}/5000 chars) {⚠️ if > 4500}

계속 진행하시겠습니까? (Y/n)
```

**거부 시 수정 워크플로우:**

사용자가 거부(n/no)하면 선택지를 제시:
1. **메타데이터 직접 수정** → 사용자가 수정 내용을 텍스트로 전달, Claude가 metadata.json 업데이트 후 재미리보기
2. **07-upload-package.md 수정 후 재파싱** → Step 3부터 재실행
3. **취소** → 워크플로우 종료

### Step 6: Upload Execution

`youtubeuploader` CLI 호출. `--dry-run` 시 이 단계를 건너뛴다.

업로드 전 안내: "업로드 시작 중... (파일 크기에 따라 수 분 소요될 수 있습니다)"

채널 config에서 credentials/cache 경로를 읽어서 CLI 인수로 전달:

```bash
youtubeuploader \
  -filename "{VIDEO_PATH}" \
  -metaJSON "{PROJECT_DIR}/metadata.json" \
  -thumbnail "{THUMBNAIL_PATH}" \
  -secrets "{CHANNEL_CREDENTIALS}" \
  -cache "{CHANNEL_CACHE}"
```

재생목록 지정 시 `-playlistID` 추가 (복수 재생목록은 플래그를 반복: `-playlistID PLxxx -playlistID PLyyy`).

### Step 7: Result Report

업로드 성공 시:
- Video ID, URL 표시
- YouTube Studio 수동 작업 체크리스트:
  - [ ] 카드 설정 (API 미지원) — 관련 영상 링크 추가
  - [ ] 엔드스크린 설정 (API 미지원) — 구독 버튼/다음 영상
  - [ ] 수익화 설정 (API 미지원)
  - [ ] 자막 확인/수정
  - [ ] 공개 전환 (비공개 → 공개, 예약이 아닌 경우)
- `00-briefing.md` 업데이트 (업로드 상태, Video URL 추가)

업로드 실패 시:
- 에러 메시지 표시
- 일반적 원인 안내 (할당량 초과, 토큰 만료, 파일 크기 등)
- 재시도 안내

## Error Handling

| 상황 | 처리 |
|------|------|
| youtubeuploader 미설치 | 설치 안내 출력, 중단 |
| config.yaml 없음 | 초기 설정 가이드 출력, 중단 |
| config.yaml YAML 파싱 에러 | 에러 위치 표시, 수정 안내 |
| cache 만료/갱신 실패 | 재인증 명령어 안내: `youtubeuploader -filename dummy.mp4 -secrets {secrets}` |
| 프로젝트 디렉토리 미존재 | 에러 + 경로 재입력 요청 |
| 07-upload-package.md 없음 | "youtube-scriptwriter를 먼저 실행하세요" 안내 |
| 07-upload-package.md 파싱 실패 | 누락 필드별 수동 입력 질문 |
| 영상 파일 없음 | 경로 입력 질문 |
| 메타데이터 보강 실패 | 실패 섹션만 생략, 나머지 진행 |
| 할당량 초과 | 남은 할당량 확인 안내, 내일 재시도 권장 |
| 업로드 중 네트워크 오류 | youtubeuploader 자체 재시도, 실패 시 수동 재시도 안내 |
| 파일 크기 초과 (128GB) | YouTube 제한 안내 |

scriptwriter Phase 7에서 호출 시 환경 체크 실패하면:
"업로드 준비가 안 되어 있습니다. 1) 지금 설정하기 2) 나중에 수동 업로드 3) 체크리스트만 받기"

## Multi-Channel Config

```yaml
# ~/.config/yt-uploader/config.yaml

channels:
  main:
    name: "메인 채널"
    credentials: "~/.config/yt-uploader/credentials/main_client_secrets.json"
    cache: "~/.config/yt-uploader/credentials/main_token.json"
    defaults:
      categoryId: "28"
      language: "ko"
      license: "youtube"
      privacy: "private"
      playlist: null

  second:
    name: "두 번째 채널"
    credentials: "~/.config/yt-uploader/credentials/second_client_secrets.json"
    cache: "~/.config/yt-uploader/credentials/second_token.json"
    defaults:
      categoryId: "22"
      language: "ko"
      license: "creativeCommon"
      privacy: "private"
      playlist: "PLxxxxx"

default_channel: main
```

### Initial Setup

1. GCP Console에서 OAuth 클라이언트 ID 생성 (Desktop App 유형)
2. YouTube Data API v3 활성화
3. config.yaml 생성:
   ```bash
   mkdir -p ~/.config/yt-uploader/credentials
   ```
4. 채널별 인증:
   ```bash
   youtubeuploader -filename dummy.mp4 \
     -secrets ~/.config/yt-uploader/credentials/main_client_secrets.json
   mv request.token ~/.config/yt-uploader/credentials/main_token.json
   ```

### Troubleshooting

- **OAuth 인증 화면이 안 나타나요** → GCP 프로젝트의 OAuth 동의 화면 설정 확인
- **token 파일이 생성 안 돼요** → youtubeuploader 실행 디렉토리에 `request.token`이 생성됨, config의 cache 경로와 일치시키기
- **"quota exceeded" 에러** → 일일 할당량 10,000 units, 업로드 1건 = ~1,600 units (하루 약 6건)
- **Private 업로드만 가능** → GCP API 프로젝트 인증(Audit) 신청 필요
