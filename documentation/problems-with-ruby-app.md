# Problems

## *.db not in .gitignore

We accidentaly commited our .db file to version control, which it should not be. But, it is not as simple, as just writing *.db in the gitignore and call it a day - the .db files are still to be found in old commits.

After adding the line to gitignore, i removed all .db files from the entire git history, which also changed every SHA for every commit. 

I had to re-edit the rules for pushing to the main branch, since I needed to do a force push.

The command I needed to run are below:

```bash
echo "*.db" >> .gitignore
git add .gitignore
git commit -m "Add .db files to gitignore"

git filter-repo --path-glob '*.db' --invert-paths

git push origin --force --all
git push origin --force --tags

git branch --merged main

git branch --merged main | grep -v "\*\|main" | xargs git branch -d

git push origin --delete chore/documentation chore/move-templates-folder docs/create-readme.md+create-contributions.md docs/create-useful-links.md docs/dependency-graph feat/all-views-exist feat/init-ruby-app feat/init-ruby-app-again feat/pull-request-template feat/search-view-erb-and-view-method fix/added-gitignore fix/pull-request-template fix/remove-dot-bundle

git fetch --prune

git push origin --force main
```