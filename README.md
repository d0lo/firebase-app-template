# Firebase App Template

An opinionated starter for **Firebase web apps** with CI/CD and conventions baked in, designed so
an **AI agent can stand up a new project from it with almost no prompting**. The agent reads
[`AGENT_SETUP.md`](AGENT_SETUP.md) and executes the whole setup, asking you only for the handful
of steps a machine genuinely can't do (creating the Google project, billing, the service-account
key, and adding secrets).

## What you get

- **Vite web app** (`app/`) with a reusable, lazy Firebase init module (Firestore + Auth +
  Functions, anonymous sign-in, dev-emulator wiring).
- **Firebase backend** (`firebase/`): `firebase.json`, a safe default ruleset, a hello-world
  Cloud Function, and emulator rules tests.
- **CI/CD** (`.github/workflows/`): lint + format + typecheck + unit + emulator tests on every
  push/PR, plus rules / functions / hosting deploys driven by a **single secret** (the project id
  is derived from the service-account key — nothing to hardcode).
- **Tooling**: ESLint (flat) + Prettier, strict TypeScript, `.editorconfig`, `.nvmrc`, PR
  template, conventional-commit + `dev`/`feature` branch flow.

## Two ways to use it

**With an agent (intended):** point your agent at the new repo and say *"set up Firebase from the
template."* It follows [`AGENT_SETUP.md`](AGENT_SETUP.md) and prompts you only for 🔴 human steps.

**By hand:** follow [`AGENT_SETUP.md`](AGENT_SETUP.md) yourself — it doubles as a human checklist.

## Local development

```bash
npm install
npm run dev                # app at localhost (set app/.env from app/.env.example first)
npm test                   # unit tests
npm run test:integration   # emulator rules tests (needs JDK 21)
npm run lint && npm run typecheck
```

## Conventions

- **Branches:** `dev` is the working branch; features go `feature/* → PR → dev`; `main` is live.
- **Commits:** conventional (`feat:` / `fix:` / `chore:` / `feat!:`).
- **Secrets:** never committed. The service-account key lives only as a GitHub Actions secret; the
  public web config comes from `VITE_FIREBASE_*` secrets (or commit it — it's public).
