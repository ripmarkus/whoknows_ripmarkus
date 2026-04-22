
# Branching Strategy

## Github Flow

We chose this, because of how fast and lightweight it is, seeing that we want to be able to deploy fast and often.

Looking forward, we can change strategy to something more structured as our codebase scales. It wouldn't be a good fit if we were working in more/larger teams, or needed to maintain multiple released versions of the product at the same time. 

### Repository Structure

- `main`: Always stable and production-ready
- `feat/*`, `fix/*`, `documentation/*`, `chore/*`: Short-lived branches created from `main`, used for features, fixes, documentation or chores
- Pull Requests (PRs): Always required before being able to merge into `main`

All new features, bug fixes, and documentation updates are developed in separate feature branches and merged back into `main` via PRs.

---

## Enforcement of the Strategy

We enforce our branching strategy by not allowing direct pushes to `main` and developers cannot review or approve their own PR.

So the only way we can approve a merge is by having another team member approve the PR. Feature branches have to be deleted after the fact.

By preventing self-review, all code changes are validated by another team member. It increases accountability and collaboration among the team, ensuring a better understanding all together of the code, which is in alignment with C and S in CALMS.

---

## Why We Chose GitHub Flow

We chose GitHub Flow mainly because it is an easy start and doesn't require much setup or rules from the get-go. 

Seeing as we are a small team, and will continue to be so, it has been a great fit from the beginning. 

Should we get new team member(s), onboarding will be quite easy, since it is a very easy way of working and learning."

## It sounds like Trunk-Based Development

Sure, but there is a difference. We keep a strong emphasis on PRs as core part of the process and a big part of learning internally and knowledge sharing - but we do keep a higher tolerance for mistakes, this is an elective after all, and part of the learning process is making mistakes - sometimes a lot.

## Why not Git Flow?

For our small team and frankly very small codebase, it was too complicated - for now at least. When it is in production and we have a higher sense of Quality Assurance, there might be an argument in changing to this strategy, in order to schedule releases and work with more complex versioning.

## 3. Advantages and Disadvantages

### Advantages

Mandatory code reviews ensure that all changes are validated before reaching main, which improves overall code quality. The workflow itself is simple and easy to follow, and the structured use of branches results in a readable and organized Git history. Knowledge sharing increases naturally as team members review each other's work, and the risk of breaking main is reduced by never committing directly to it.

### Disadvantages

PRs can become a bottleneck if reviewers are unavailable or slow to respond, which may slow down development. The workflow also requires discipline from each team member to keep branches small and focused. Overall, the effectiveness of the strategy heavily depends on the team's responsiveness and engagement.