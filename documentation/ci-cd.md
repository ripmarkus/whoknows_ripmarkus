# CI/CD

## CI

At the time of writing, our CI checks focus on compiling the app and linting the code using RuboCop. 

Once linting is complete, the results are automatically posted as a comment on the Pull Request. If a report already exists from a previous run, it is overwritten rather than duplicated. 

This ensures every PR has an up-to-date summary of code quality issues directly on the Pull Request for review.

By enforcing these steps, we ensure that every Pull Request meets our baseline standards for code quality and maintainability, allowing us to run a tight ship throughout the development lifecycle.

## CD

To be added.