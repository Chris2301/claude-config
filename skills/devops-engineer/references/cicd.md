# CI/CD -- Pipeline Patterns

Check which system the project uses first. Look for `.github/workflows/` or `.gitlab-ci.yml`. Never mix both.

## GitHub Actions -- CI Workflow (ci.yml)

Runs on pull requests: lint, test, build.

```yaml
name: CI

on:
  pull_request:
    branches: [master, develop]

jobs:
  lint:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4

      - name: Lint Helm charts
        run: helm lint helm/web-configurator/

      - name: Lint Dockerfiles
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: backend/Dockerfile

      - name: Lint Dockerfiles (frontend)
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: frontend/Dockerfile

  test-backend:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
          cache: maven

      - name: Run tests
        run: cd backend && ./mvnw verify -B

  test-frontend:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        run: cd frontend && npm ci

      - name: Run tests
        run: cd frontend && npm test -- --watch=false

  build:
    runs-on: self-hosted
    needs: [lint, test-backend, test-frontend]
    steps:
      - uses: actions/checkout@v4

      - name: Build backend image
        run: docker build -t harbor.local/web-configurator/backend:${{ github.sha }} -f backend/Dockerfile backend/

      - name: Build frontend image
        run: docker build -t harbor.local/web-configurator/frontend:${{ github.sha }} -f frontend/Dockerfile frontend/
```

## GitHub Actions -- Deploy Workflow (deploy.yml)

Runs on merge to master: build, push to Harbor, deploy.

```yaml
name: Deploy

on:
  push:
    branches: [master]

env:
  REGISTRY: harbor.local
  PROJECT: web-configurator

jobs:
  build-and-push:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4

      - name: Login to Harbor
        run: echo "${{ secrets.HARBOR_PASSWORD }}" | docker login ${{ env.REGISTRY }} -u ${{ secrets.HARBOR_USERNAME }} --password-stdin

      - name: Build and push backend
        run: |
          docker build -t ${{ env.REGISTRY }}/${{ env.PROJECT }}/backend:${{ github.sha }} -f backend/Dockerfile backend/
          docker push ${{ env.REGISTRY }}/${{ env.PROJECT }}/backend:${{ github.sha }}

      - name: Build and push frontend
        run: |
          docker build -t ${{ env.REGISTRY }}/${{ env.PROJECT }}/frontend:${{ github.sha }} -f frontend/Dockerfile frontend/
          docker push ${{ env.REGISTRY }}/${{ env.PROJECT }}/frontend:${{ github.sha }}

  deploy-staging:
    runs-on: self-hosted
    needs: build-and-push
    environment: staging
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to staging
        run: |
          helm upgrade --install ${{ env.PROJECT }} helm/web-configurator/ \
            -n staging \
            -f helm/web-configurator/values-staging.yaml \
            --set backend.image.tag=${{ github.sha }} \
            --set frontend.image.tag=${{ github.sha }} \
            --wait --timeout 120s

  deploy-production:
    runs-on: self-hosted
    needs: deploy-staging
    environment:
      name: production
      # Manual approval gate -- requires reviewer approval in GitHub environment settings
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to production
        run: |
          helm upgrade --install ${{ env.PROJECT }} helm/web-configurator/ \
            -n production \
            -f helm/web-configurator/values-production.yaml \
            --set backend.image.tag=${{ github.sha }} \
            --set frontend.image.tag=${{ github.sha }} \
            --wait --timeout 120s
```

Configure the `production` environment in GitHub repository settings with required reviewers for the manual approval gate.

## GitLab CI Equivalent

```yaml
stages:
  - lint
  - test
  - build
  - deploy

variables:
  REGISTRY: harbor.local
  PROJECT: web-configurator

# --- Lint ---

lint:helm:
  stage: lint
  tags: [self-hosted]
  script:
    - helm lint helm/web-configurator/

lint:docker:
  stage: lint
  tags: [self-hosted]
  image: hadolint/hadolint:latest-alpine
  script:
    - hadolint backend/Dockerfile
    - hadolint frontend/Dockerfile

# --- Test ---

test:backend:
  stage: test
  tags: [self-hosted]
  image: eclipse-temurin:21-jdk-alpine
  script:
    - cd backend && ./mvnw verify -B
  cache:
    key: maven
    paths:
      - backend/.m2/repository

test:frontend:
  stage: test
  tags: [self-hosted]
  image: node:22-alpine
  script:
    - cd frontend && npm ci && npm test -- --watch=false
  cache:
    key: npm
    paths:
      - frontend/node_modules/

# --- Build ---

build:
  stage: build
  tags: [self-hosted]
  only:
    - master
  before_script:
    - echo "$HARBOR_PASSWORD" | docker login $REGISTRY -u "$HARBOR_USERNAME" --password-stdin
  script:
    - docker build -t $REGISTRY/$PROJECT/backend:$CI_COMMIT_SHA -f backend/Dockerfile backend/
    - docker push $REGISTRY/$PROJECT/backend:$CI_COMMIT_SHA
    - docker build -t $REGISTRY/$PROJECT/frontend:$CI_COMMIT_SHA -f frontend/Dockerfile frontend/
    - docker push $REGISTRY/$PROJECT/frontend:$CI_COMMIT_SHA

# --- Deploy ---

deploy:staging:
  stage: deploy
  tags: [self-hosted]
  only:
    - master
  environment:
    name: staging
  script:
    - helm upgrade --install $PROJECT helm/web-configurator/
        -n staging
        -f helm/web-configurator/values-staging.yaml
        --set backend.image.tag=$CI_COMMIT_SHA
        --set frontend.image.tag=$CI_COMMIT_SHA
        --wait --timeout 120s

deploy:production:
  stage: deploy
  tags: [self-hosted]
  only:
    - master
  when: manual
  environment:
    name: production
  script:
    - helm upgrade --install $PROJECT helm/web-configurator/
        -n production
        -f helm/web-configurator/values-production.yaml
        --set backend.image.tag=$CI_COMMIT_SHA
        --set frontend.image.tag=$CI_COMMIT_SHA
        --wait --timeout 120s
```

## Self-Hosted Runners

### GitHub Actions Runner

```bash
# On the VPS, register a self-hosted runner
./config.sh --url https://github.com/org/web-configurator \
  --token <REGISTRATION_TOKEN> \
  --labels self-hosted,linux,k3s \
  --work _work

# Run as systemd service
sudo ./svc.sh install
sudo ./svc.sh start
```

### GitLab Runner

```bash
gitlab-runner register \
  --url https://gitlab.example.com \
  --token <REGISTRATION_TOKEN> \
  --executor docker \
  --docker-image alpine:latest \
  --tag-list "self-hosted,k3s"
```

## ArgoCD Integration

For staging and production, ArgoCD watches git and syncs Helm releases. Pipelines update the image tag in git, and ArgoCD detects the change.

### ArgoCD Application Manifest

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-configurator-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/web-configurator.git
    targetRevision: master
    path: helm/web-configurator
    helm:
      valueFiles:
        - values-staging.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: staging
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Image Tag Update Strategy

Pipelines update the image tag in the values file and commit:

```bash
# In CI pipeline after push to Harbor
yq e ".image.tag = \"$COMMIT_SHA\"" -i helm/web-configurator/values-staging.yaml
git add helm/web-configurator/values-staging.yaml
git commit -m "chore: update staging image to $COMMIT_SHA"
git push
# ArgoCD detects the change and syncs
```

## Quick Reference

| Topic | Detail |
|-------|--------|
| CI trigger | Pull requests to master/develop |
| Deploy trigger | Push/merge to master |
| Staging deploy | Automatic on merge to master |
| Production deploy | Manual approval gate |
| Image tag | Git commit SHA (`$GITHUB_SHA` / `$CI_COMMIT_SHA`) |
| Registry login | Secrets: `HARBOR_USERNAME`, `HARBOR_PASSWORD` |
| Runner tags | `self-hosted`, `linux`, `k3s` |
| Helm deploy | `helm upgrade --install` with `--wait --timeout 120s` |
| ArgoCD | Watches git, syncs Helm releases for staging/production |
| Never mix | GitHub Actions and GitLab CI in the same project |
