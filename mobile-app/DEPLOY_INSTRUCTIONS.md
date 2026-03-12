# Mobile App Deployment Instructions

## English

## Why build locally?

The Vercel build environment does not include Flutter for this project.
Build the Flutter web app locally or in GitHub Actions, then upload only the generated output.

## Recommended deployment flow

### 1. Build locally and deploy with Vercel CLI

```bash
cd mobile-app
flutter pub get
flutter build web --release --base-href / --dart-define=RELAY_SERVER_URL=https://codex-relay.jaloveeye.com
cp vercel-build-output.json build/web/vercel.json
cd build/web
vercel --prod
```

Replace `RELAY_SERVER_URL` with the dedicated relay server URL for this project.

If the project is not linked yet:

```bash
cd mobile-app/build/web
vercel link
vercel --prod
```

### 2. Vercel dashboard settings

When you are not using Git-triggered auto deployment:

- **Build Command**: leave empty
- **Install Command**: leave empty
- **Output Directory**: leave empty

### 3. GitHub Actions deployment (optional)

You can automate deployment by installing Flutter in GitHub Actions, building web output, and then running `vercel --prebuilt --prod`.
Store the Vercel token in GitHub Secrets.

## Vercel config files

Use only `vercel-build-output.json` as the deployment config source.
Copy it to `build/web/vercel.json` before deploying.

## Project structure

- `mobile-app/` — Flutter project root
- `mobile-app/web/` — Flutter web source
- `mobile-app/build/web/` — built output deployed to Vercel
- `mobile-app/vercel.json` — reference config
- `mobile-app/vercel-build-output.json` — deployment config copied into the build output

---

## 한국어

## 왜 로컬에서 빌드하나요?

이 프로젝트에서는 Vercel 빌드 환경에 Flutter가 포함되어 있지 않습니다.
Flutter web 앱은 로컬 또는 GitHub Actions에서 빌드한 뒤, 생성된 결과물만 업로드해야 합니다.

## 권장 배포 절차

### 1. 로컬 빌드 후 Vercel CLI로 배포

```bash
cd mobile-app
flutter pub get
flutter build web --release --base-href / --dart-define=RELAY_SERVER_URL=https://codex-relay.jaloveeye.com
cp vercel-build-output.json build/web/vercel.json
cd build/web
vercel --prod
```

`RELAY_SERVER_URL`은 이 프로젝트 전용 릴레이 서버 주소로 바꾸세요.

프로젝트 연결이 아직 없다면:

```bash
cd mobile-app/build/web
vercel link
vercel --prod
```

### 2. Vercel 대시보드 설정

Git 푸시 기반 자동 배포를 사용하지 않을 때는:

- **Build Command**: 비워 둡니다
- **Install Command**: 비워 둡니다
- **Output Directory**: 비워 둡니다

### 3. GitHub Actions 배포 (선택)

GitHub Actions에서 Flutter를 설치하고 web 빌드 후 `vercel --prebuilt --prod`를 실행하면 자동 배포할 수 있습니다.
Vercel 토큰은 GitHub Secrets에 저장하세요.

## Vercel 설정 파일

배포 설정 원본으로는 `vercel-build-output.json`만 사용하세요.
배포 전에 이 파일을 `build/web/vercel.json`으로 복사합니다.

## 프로젝트 구조

- `mobile-app/` — Flutter 프로젝트 루트
- `mobile-app/web/` — Flutter web 소스
- `mobile-app/build/web/` — Vercel에 배포할 빌드 결과물
- `mobile-app/vercel.json` — 참고용 설정 파일
- `mobile-app/vercel-build-output.json` — 빌드 결과물로 복사하는 배포 설정 파일
