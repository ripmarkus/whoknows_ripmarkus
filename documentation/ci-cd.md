# CI/CD

## CI

At the time of writing, our CI checks focus on compiling the app and linting the code using RuboCop. 

Upon completion, the pipeline generates a comment in Markdown format summarizing the results, and will both fail the PR and leave a comment if any of the checks do not pass.

By enforcing these steps, we ensure that every Pull Request meets our baseline standards for code quality and maintainability, allowing us to run a tight ship throughout the development lifecycle.

## CD

To be added.