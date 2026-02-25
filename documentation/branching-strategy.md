# Branching Strategy

## 1. Chosen Version Control Strategy

We chose to use **GitHub Flow** as our branching strategy.

GitHub Flow is a lightweight, feature-branch-based workflow centered around a stable `main` branch.

### Repository Structure

- `main` → Always stable and production-ready
- `feature/*` → Short-lived branches created from `main`
- Pull Requests (PRs) → Required before merging into `main`

All new features, bug fixes, and documentation updates are developed in separate feature branches and merged back into `main` via PRs.

---

## Enforcement of the Strategy

We enforce our branching strategy through the following rules:

- ❌ Direct pushes to `main` are not allowed  
- ❌ Developers cannot review or approve their own PRs  
- ✅ At least one team member must review and approve a PR  
- ✅ Only after approval can the PR be merged  
- ✅ Feature branches are deleted after merge  

This ensures:

- A strong code review culture
- Shared ownership of the codebase
- Higher code quality
- Reduced risk of unstable code reaching `main`

By preventing self-review, all code changes are validated by another developer, increasing accountability and collaboration.

---

## 2. Why We Chose GitHub Flow

We chose GitHub Flow because:

- We are a relatively small team
- Our project does not require complex release cycles
- We wanted a simple and efficient workflow
- It integrates naturally with PRs and GitHub

GitHub Flow supports continuous integration principles and keeps the workflow easy to understand and maintain.

### Why We Did Not Choose Git Flow

We did not choose Git Flow because:

- It introduces additional branches such as `develop`, `release`, and `hotfix`
- It adds unnecessary process overhead for our team size
- It is better suited for larger teams with structured release planning

For our project, Git Flow would have introduced complexity without clear added value.

### Why We Did Not Choose Trunk-Based Development

We did not choose Trunk-Based Development because:

- It requires very mature CI/CD pipelines
- It relies heavily on automated testing
- It demands frequent integration directly into `main`

As a student team, we preferred a more controlled approach where PRs and peer reviews act as a safety mechanism before changes reach `main`.

---

## 3. Advantages and Disadvantages

### Advantages

- Clear separation between development and stable code
- Mandatory code review improves quality
- Increased knowledge sharing across the team
- Structured and readable Git history
- Reduced risk of breaking `main`

### Disadvantages

- PRs can slow development if reviewers are unavailable
- Merge conflicts occur if branches live too long
- Requires discipline to keep branches small and focused
- Workflow depends on team responsiveness

---

## 4. Current State and Future Improvements

Since the project is still ongoing, we see our current GitHub Flow implementation as a foundation.

Our target is to evolve towards a more mature DevOps-oriented workflow by:

- Adding required CI status checks before merge
- Integrating automated testing in the pipeline
- Keeping feature branches smaller and more focused
- Improving PR descriptions and documentation standards
- Enforcing consistent branch naming conventions

This will strengthen our continuous integration process and reduce risk as the project grows.