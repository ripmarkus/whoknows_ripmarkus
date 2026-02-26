# CodeRabbit & Software Quality

We use CodeRabbit as an AI code review tool, scoped to the [ruby-app](https://github.com/ripmarkus/whoknows_ripmarkus/blob/72a647d3b754339ad66e9a116f4a714b87ee6060/ruby-app/app.rb), [documentation](https://github.com/ripmarkus/whoknows_ripmarkus/blob/10b61cd7b4ad06a7bba402cfaf946139e3b91162/documentation), and .[github/](https://github.com/ripmarkus/whoknows_ripmarkus/blob/6593add60ab1f021f8077775b9468069f386e2e3/.github) directories, as well as the readme.

It is configured to focus on meaningful issues such as code smells, complex methods, bad patterns, logic errors, and security concerns — always explaining why something is a problem rather than just flagging it. 

This aligns with the educational nature of the project, framing reviews as a learning opportunity grounded in DevOps principles. 

Minor issues like linting and formatting are intentionally ignored to keep feedback focused because we have a CI check on PR's as well. 

If the number of changed files significantly exceeds the number of commits, CodeRabbit will prompt for more commits to encourage good version control hygiene. This could maybe be controlled in a better way, but it runs just fine right now.