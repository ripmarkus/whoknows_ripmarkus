![Contributors](https://img.shields.io/github/contributors/ripmarkus/whoknows_ripmarkus)

![Commit activity](https://img.shields.io/github/commit-activity/m/ripmarkus/whoknows_ripmarkus)

# How to Run

In order to run the application, you need to run the following commands:

```bash
cd ruby-app # make sure you are in the correct directory
make up # build the image and start the container
make help # return a list of useful commands that you can use in development
```

As a prerequisite, you need to have Docker installed since the Makefile needs it in order to build the image.

# Introduction

This is a school project for the elective 'DevOps' at Erhvervsakademi København, where we will refactor an old Python2 codebase into Ruby and Sinatra and utilize CI/CD and DevOps practices.


# How to Contribute

Read [contributions](documentation/contributions.md) first. We don't accept contributions that don't follow the guidelines.

# Documentation

All docs are in [documentation](documentation).

When you've added a new feature, please add solid documentation on what you've made.

# Found an issue?

Add it to the issues tab!

# Documentation Site (MkDocs)

The `documentation/` folder is published as a static site via [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) and automatically deployed to GitHub Pages on every push to `main`.

You can find it served [here](https://ripmarkus.github.io/whoknows_ripmarkus/)

**Run locally:**

```bash
pip install mkdocs-material
mkdocs serve          # live-reload preview at http://127.0.0.1:8000
```

**Add a new page:**

1. Drop a `.md` file into the relevant subfolder under `documentation/`.
2. Add an entry for it under the correct section in `mkdocs.yml` → `nav`.
3. Push to `main` — GitHub Actions deploys automatically.

