# CodeRabbit & Software Quality

We use CodeRabbit as an AI code review tool, scoped to the ruby-app/`, documentation/, and .github/ directories, as well as the root readme.

It is configured to focus on meaningful issues such as code smells, complex methods, bad patterns, logic errors, and security concerns — always explaining why something is a problem rather than just flagging it. 

This aligns with the educational nature of the project, framing reviews as a learning opportunity grounded in DevOps principles. 

Minor issues like linting and formatting are intentionally ignored to keep feedback focused because we have a CI check on PR's as well. 

If the number of changed files significantly exceeds the number of commits, CodeRabbit will prompt for more commits to encourage good version control hygiene. This could maybe be controlled in a better way, but it runs just fine right now.