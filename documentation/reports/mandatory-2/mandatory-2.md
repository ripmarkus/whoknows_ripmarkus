# How we use Version Control



# How are you DevOps?

We use CALMS as a framework to argue why we are DevOps, and where we fall short.

## Culture

No one merges their own PR. We require peer review, and we have CodeRabbit set up as an extra reviewer on every PR. The idea is that the codebase belongs to the team, not whoever wrote a given feature. In practice though, reviews are not always serious. Sometimes a PR gets approved to unblock someone rather than because it was actually reviewed. We also started with commit message conventions but stopped following them, which makes the history harder to read.

## Automation

We have tried to automate each critical part of our development cycle: Tests run on every PR, the image gets built and validated, and a passing CI on main triggers a deployment. The server pulls the new image, backs up the database, and restarts the container without anyone needing to SSH in. 

The gap is on the local side: development runs through Docker, which means rebuilding the image for every change. It is slow, we knew it was slow, and we never fixed it. That makes developers less likely to test things locally before pushing.

## Lean

Looking at the git history, we are not very lean. The CD pipeline needed four separate fix PRs. Tailwind broke and was fixed in two rounds. There are sequences of PRs from the same branch merged minutes apart, meaning we merged something, saw it was wrong, and pushed another fix immediately. 

The pattern is the same each time, we merge something before it is fully verified and let production surface the problem.

## Measurement

Although we have set up Postman monitoring and Grafana monitoring, our measurements are not very critical to the business development, we are solely monitoring the parts about how many users log in, if they CAN log in and not what they search for, or what part of the site they actually spend the most time on.

We collect data, but we do not really observe. Measurement is raw numbers, observation is understanding what they mean. We have the former and not the latter, and that gap is where useful insight about user behaviour would live.

 Observability could mean a lot more than server health, understanding user patterns and behaviour would actually tell us something useful about our product.

## Sharing

All infrastructure is in the repo as code, and anyone can reproduce the full environment from it. The documentation site publishes automatically on every push to main. Where it falls down is that documentation gets written after the fact, not during. 

We have a vast amount of documentation, served as a deployment on Github Pages, meaning that everyone can at any given time read well formatted documentation on the application and team.


# Software Quality


# Monitoring Realization 


