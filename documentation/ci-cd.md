# CI/CD

## CI (OLD)

At the time of writing, our CI checks focus on compiling the app and linting the code using RuboCop, configured via a .rubocop.yml in the project root. This file defines our code style and complexity rules, ensuring consistent standards are enforced on every PR created.

Once linting is complete, the results are automatically posted as a comment on the Pull Request. If a report already exists from a previous run, it is overwritten rather than duplicated. 

This ensures every PR has an up-to-date summary of code quality issues directly on the Pull Request for review.

By enforcing these steps, we ensure that every Pull Request meets our baseline standards for code quality and maintainability, allowing us to run a tight ship throughout the development lifecycle.

**Why not locally?**

Running Ruboco locally is definitely a possibility, however running it in our CI flow, allows all developers to see what can be done better with our code quality, before they can submit the code - This nudges our team to fix issues instead of only fixing issues when they become a bigger problem.

## CI (NEW)

The CI-pipeline runs on every push and pull request to `main`, and can also be triggered manually via `workflow_dispatch`.

The first job (**Docker Build**) builds the Docker image from `ruby-app/Dockerfile`. Once built, a container is spun up and a health check is performed. The database is initialized and a request is made to the app to verify it's running correctly. If any of this fails, the pipeline stops, ensuring broken code won't make it further.

If the build and health check pass, and the trigger was not a pull request, the next job (**Docker Push**) pushes the image to GHCR. This ensures only verified images are published, ready for the CD-pipeline to deploy. 

## CD

The CD-pipeline triggers automatically when the CI workflow completes successfully on `main`, or can be triggered manually via `workflow_dispatch`.

Deployment steps:

1. An SSH key is added to the runner from repository secrets
2. The runner SSH's into the production server
3. The server logs into GHCR and pulls the latest Docker image
4. The running container is stopped, and restarted with the new image via Docker Compose
