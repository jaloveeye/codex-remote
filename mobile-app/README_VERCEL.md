# Flutter Web on Vercel

## English

Deploy Flutter Web for Codex Remote through **Vercel** using a prebuilt output.
The Vercel build environment does not build Flutter for this project.

### Recommended flow

```bash
# 1. Build Flutter web locally
cd mobile-app
flutter pub get
flutter build web --release --base-href /

# 2. Copy the Vercel config into the build output
cp vercel-build-output.json build/web/vercel.json

# 3. Deploy from the built directory
cd build/web
vercel --prod
```

You can run `vercel link` once if the project is not linked yet.
If `mobile-app/.vercel/` is already linked, deploying from `build/web` uses the same project.

### Config files

| File | Purpose |
|------|---------|
| `vercel.json` | routing/header reference |
| `vercel-build-output.json` | copied to `build/web/vercel.json` for deployment |

### Git-based auto deploy

If you connect the repository to Vercel, do **not** rely on a Vercel-side Flutter build.
Prefer either:

- local build + `vercel --prod`
- GitHub Actions build + `vercel --prebuilt --prod`

See also [DEPLOY_INSTRUCTIONS.md](./DEPLOY_INSTRUCTIONS.md).

---

## 한국어

Codex Remote의 Flutter Web은 **Vercel**에 사전 빌드된 결과물을 배포하는 방식으로 운영합니다.
이 프로젝트에서는 Vercel 빌드 환경에서 Flutter 빌드를 수행하지 않습니다.

### 권장 절차

```bash
# 1. 로컬에서 Flutter web 빌드
cd mobile-app
flutter pub get
flutter build web --release --base-href /

# 2. 빌드 결과물에 Vercel 설정 복사
cp vercel-build-output.json build/web/vercel.json

# 3. 빌드된 디렉터리에서 배포
cd build/web
vercel --prod
```

프로젝트 연결이 안 되어 있으면 `vercel link`를 한 번 실행할 수 있습니다.
이미 `mobile-app/.vercel/`이 연결돼 있으면 `build/web`에서 배포해도 같은 프로젝트를 사용합니다.

### 설정 파일

| 파일 | 용도 |
|------|------|
| `vercel.json` | 라우팅/헤더 참고용 |
| `vercel-build-output.json` | 배포 시 `build/web/vercel.json`으로 복사되는 파일 |

### Git 연동 자동 배포

저장소를 Vercel에 연결하더라도 Vercel 내부 Flutter 빌드에 의존하지 마세요.
아래 방식 중 하나를 권장합니다:

- 로컬 빌드 + `vercel --prod`
- GitHub Actions 빌드 + `vercel --prebuilt --prod`

추가 내용은 [DEPLOY_INSTRUCTIONS.md](./DEPLOY_INSTRUCTIONS.md)를 참고하세요.
