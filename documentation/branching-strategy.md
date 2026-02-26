# Branching Strategy

## 1. Chosen Version Control Strategy

We chose to use **GitHub Flow** as our branching strategy.

GitHub Flow is a lightweight, feature-branch-based workflow centered around a stable `main` branch.

### Repository Structure

- `main` → Always stable and production-ready
- `feat/*`, `fix/*`, `documentation/*`, `chore/*` → Short-lived branches created from `main`, and used for features, fixes documentation or chores
- Pull Requests (PRs) → Required before merging into `main`

All new features, bug fixes, and documentation updates are developed in separate feature branches and merged back into `main` via PRs.

---

## Enforcement of the Strategy

We enforce our branching strategy through the following rules:

- Direct pushes to `main` are NOT allowed  
- Developers CANNOT review or approve their own PR  
- At least one team member must review and approve a PR  
- Only after approval can the PR be merged  
- Feature branches are deleted after merge  

This ensures:

- A strong code review culture
- Shared ownership of the codebase
- Higher code quality
- Fast and continuous delivery of features
- Reduced risk of unstable or unwanted code reaching `main`

By preventing self-review, all code changes are validated by another team member. This increases accountability and collaboration among the team.

---

## 2. Why We Chose GitHub Flow

We chose GitHub Flow because:

- We are a small team
- Our project does not require complex release cycles
- We wanted a simple and efficient workflow

GitHub Flow supports continuous integration principles and keeps the workflow very easy to understand and maintain.

### Why We Did Not Choose Git Flow

We did not choose Git Flow because:

- It introduces additional branches such as `develop`, `release`, and `hotfix`
- It adds unnecessary process overhead for our team size
- It is better suited for larger teams with structured release planning

For our project, Git Flow would have introduced more complexity without any clear added value. 

### Why We Did Not Choose Trunk-Based Development

We did not choose Trunk-Based Development because:

- It requires very mature CI/CD pipelines
- It relies heavily on automated testing
- It demands small frequent code changes directly into `main`

As a student team, we preferred a more controlled approach where PRs and code-reviews act as a safety mechanism before changes reach `main`.

---

## 3. Advantages and Disadvantages

(Feel free to add to 'Advantages' or 'Disadvantages' if new insight is gained or you feel like something is missing)

### Advantages

- Mandatory code review improves quality
- Simple workflow
- Increased knowledge sharing across the team
- Structured and readable Git history
- Reduced risk of breaking `main`

### Disadvantages

- PRs can slow development if reviewers are unavailable/not looking for new PRs to merge
- Requires discipline to keep branches small and focused
- Workflow heavily depends on the team's responsiveness and level of activeness