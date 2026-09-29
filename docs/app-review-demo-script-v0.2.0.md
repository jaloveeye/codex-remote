# App Store Review 데모 영상 대본 (v0.2.0)

본 문서는 App Store 심사 대응용 데모 영상 스크립트입니다.  
목표: **실기기 iPhone에서 Codex Remote 0.2.0의 전체 기능과 VS Code 연동을 명확히 입증**.

---

## 0) 촬영 체크리스트 (필수)

- [ ] 실기기 iPhone 프레임(손/베젤) 최소 1회 이상 노출
- [ ] 앱 버전 `0.2.0` 화면에 명확히 표시
- [ ] **VS Code 확장에서 세션 생성/연결을 먼저 수행**한 뒤, 모바일에서 같은 세션으로 접속
- [ ] 아래 5개 프롬프트 시나리오를 순서대로 시연
  1) `hi`
  2) `create test.txt file`
  3) `show content in test.txt`
  4) `add hello to test.txt`
  5) `show content in test.txt`
- [ ] 권한 요청이 있다면 팝업과 허용/거부 동작 포함
- [ ] 영상 링크는 로그인 없이 재생 가능(권장: Unlisted)

---

## 1) 타임라인 대본 (약 4분)

### 0:00–0:08 — 인사 + 실기기 증명

**화면**
- iPhone 실물(손/베젤) 짧게 노출

**내레이션 (EN)**
> Hello App Review Team. This demo is recorded on a physical iPhone.

---

### 0:08–0:35 — VS Code에서 Codex Remote 확장 소개

**화면**
- Mac/PC 화면으로 전환
- VS Code에서 Codex Remote 확장 패널/연결 화면 표시

**내레이션 (EN)**
> First, I will show the Codex Remote extension in Visual Studio Code.

---

### 0:35–1:00 — VS Code에서 세션 생성/연결

**화면**
- 확장에서 세션 ID/PIN 설정
- 세션 연결 성공 상태 확인

**내레이션 (EN)**
> I create and connect a relay session from the extension first.

---

### 1:00–1:25 — iPhone 앱 실행 및 동일 세션 접속

**화면**
- iPhone 앱 실행
- 버전 `0.2.0` 화면 표시
- 동일 세션 ID/PIN으로 connect

**내레이션 (EN)**
> Now I open the iPhone app, confirm version 0.2.0, and connect to the same session.

---

### 1:25–3:20 — 프롬프트 시나리오 5단계

**화면**
- 아래 프롬프트를 순서대로 입력/전송하고 각 응답 완료를 확인
  1. `hi`
  2. `create test.txt file`
  3. `show content in test.txt`
  4. `add hello to test.txt`
  5. `show content in test.txt`
- (승인 요청이 뜨면) Approvals 탭에서 승인 후 진행

**내레이션 (EN)**
> I will now run five prompts in order:
> one, hi;
> two, create test.txt file;
> three, show content in test.txt;
> four, add hello to test.txt;
> five, show content in test.txt.

---

### 3:20–3:45 — 결과 확인

**화면**
- 최종 `test.txt` 내용 확인(hello 포함)
- Chat History / Session Info / Approvals 기록 확인

**내레이션 (EN)**
> The final result shows that test.txt was created and updated successfully.

---

### 3:45–4:00 — 마무리

**화면**
- iPhone + VS Code 양쪽 연결 상태 마무리 컷

**내레이션 (EN)**
> This demonstrates full functionality and pairing between the iPhone app and the Visual Studio Code extension.

---

## 2) App Review 회신 템플릿

```text
Hello App Review Team,

Thank you for the feedback.

We have added a demo video link for version 0.2.0 in App Review Information > Notes.
Video link: <PASTE_LINK>

The video shows:
1) The app running on a physical iPhone device
2) Full app functionality
3) Pairing and interaction with Visual Studio Code extension
4) Relevant permission prompts and behavior

If you need additional test instructions, we will provide them promptly.

Best regards,
```
