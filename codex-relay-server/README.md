# Codex Relay Server

## English

Dedicated relay server deployment for Codex Remote.
Deploy this server separately from any legacy relay infrastructure.

### Responsibilities

- Create and manage 6-character sessions
- Join extension and mobile devices to a session
- Forward messages between client and extension
- Track heartbeat to release stale PC sessions
- Apply approval policy to risky `execute_command` requests
- Persist command events and approval history

### Separation checklist

- Create a dedicated deployment for this repository
- Use separate Supabase or Upstash Redis credentials
- Configure both clients to use the same relay base URL
- Do not reuse a shared production relay by default

### Configure clients

#### VS Code extension

```json
{
  "codexRemote.relayServerUrl": "https://relay.example.com"
}
```

#### Mobile app

```bash
flutter run --dart-define=RELAY_SERVER_URL=https://relay.example.com
flutter build web --dart-define=RELAY_SERVER_URL=https://relay.example.com
```

### Storage backends

- **Supabase** when `SUPABASE_URL` is present
- **Upstash Redis** otherwise

### Local development

```bash
cp .env.example .env.local
npm install
npm run dev
```

Local relay URL: `http://localhost:3000`

### Main API endpoints

- `GET /api/health`
- `GET /api/version`
- `GET /api/store`
- `POST /api/session`
- `POST /api/connect`
- `GET /api/poll`
- `POST /api/send`
- `GET /api/command-approvals`
- `POST /api/resolve-command-approval`
- `GET /api/command-events`

### Session model

- Session IDs are 6-character uppercase alphanumeric strings
- PC heartbeat timeout is 2 minutes
- Optional PIN can be attached by the extension
- Multiple mobile devices can join the same session

---

## 한국어

Codex Remote용 전용 릴레이 서버 배포 문서입니다.
기존 레거시 릴레이 인프라와는 분리해서 운영하세요.

### 역할

- 6자리 세션을 생성하고 관리합니다
- 확장과 모바일 기기를 같은 세션에 연결합니다
- 클라이언트와 확장 사이의 메시지를 전달합니다
- 오래된 PC 세션을 정리하기 위해 heartbeat를 추적합니다
- 위험한 `execute_command` 요청에 승인 정책을 적용합니다
- 명령 이벤트와 승인 이력을 저장합니다

### 분리 체크리스트

- 이 저장소 전용 배포를 만듭니다
- Supabase 또는 Upstash Redis 자격 증명을 별도로 사용합니다
- 양쪽 클라이언트가 같은 릴레이 base URL을 사용하도록 설정합니다
- 기본적으로 공유 운영 릴레이를 재사용하지 않습니다

### 클라이언트 설정

#### VS Code 확장

```json
{
  "codexRemote.relayServerUrl": "https://relay.example.com"
}
```

#### 모바일 앱

```bash
flutter run --dart-define=RELAY_SERVER_URL=https://relay.example.com
flutter build web --dart-define=RELAY_SERVER_URL=https://relay.example.com
```

### 스토리지 백엔드

- `SUPABASE_URL`이 있으면 **Supabase**
- 그렇지 않으면 **Upstash Redis**

### 로컬 개발

```bash
cp .env.example .env.local
npm install
npm run dev
```

로컬 릴레이 URL: `http://localhost:3000`

### 주요 API 엔드포인트

- `GET /api/health`
- `GET /api/version`
- `GET /api/store`
- `POST /api/session`
- `POST /api/connect`
- `GET /api/poll`
- `POST /api/send`
- `GET /api/command-approvals`
- `POST /api/resolve-command-approval`
- `GET /api/command-events`

### 세션 모델

- 세션 ID는 6자리 대문자 영숫자입니다
- PC heartbeat timeout은 2분입니다
- 확장에서 선택적 PIN을 붙일 수 있습니다
- 여러 모바일 기기가 같은 세션에 참여할 수 있습니다
