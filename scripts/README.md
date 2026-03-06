# Scripts

## English

Collection of helper scripts for this repository.

### Git Flow guard hooks

To enforce Git Flow rules locally:

```bash
./scripts/install-git-flow-hooks.sh
```

Installed hooks:

- **pre-commit**: blocks commits on `main` / `develop`
- **commit-msg**: validates Conventional Commits prefixes such as `feat:` and `fix:`

Run the installer again after cloning the repository to restore the hooks.

---

## 한국어

이 저장소에서 사용하는 보조 스크립트 모음입니다.

### Git Flow 가드 훅

로컬에서 Git Flow 규칙을 강제하려면:

```bash
./scripts/install-git-flow-hooks.sh
```

설치되는 훅:

- **pre-commit**: `main` / `develop`에서의 커밋 차단
- **commit-msg**: `feat:`, `fix:` 같은 Conventional Commits 접두사 검사

저장소를 새로 클론한 뒤에는 훅을 복원하기 위해 다시 한 번 설치 스크립트를 실행하세요.
