# Security Tooling

## OWASP ZAP - Dynamic Application Security Testing

The `owasp_zap.yml` workflow runs on every push and pull request to `main`. It spins up the full application stack via Docker Compose, waits for the app to be healthy, then runs a **ZAP baseline scan** - a passive scan that spiders the app and flags common vulnerabilities without actively attacking it.

**What it checks for:**
- Missing security headers (CSP, X-Frame-Options, HSTS, etc.)
- Information disclosure (server banners, stack traces)
- Insecure cookie flags (missing `HttpOnly`, `Secure`, `SameSite`)
- Clickjacking exposure
- Other OWASP Top 10 passive indicators

**Report:** The HTML report is uploaded as a workflow artifact (`zap-security-report`) on every run, including failed runs. Download it from the Actions summary page to see the full findings broken down by risk level (High / Medium / Low / Informational).

**Why `-I`:** The scan uses the `-I` flag so warnings do not fail the build - the goal is visibility, not blocking PRs on informational findings. Promote issues to failures selectively by using a ZAP rules config file if needed in future.

## RuboCop - Code Quality

RuboCop enforces style and complexity rules via `.rubocop.yml`. While primarily a linter, it catches patterns that can lead to security issues (e.g., overly complex methods, unsafe string handling). Configured in `rubocop.yaml` and runs on every PR.

## Dependency Scanning

Dependency vulnerabilities are tracked via Dependabot and reviewed periodically. See the `security/dependency-upgrades` PRs in the git history for examples of routine upgrades.
