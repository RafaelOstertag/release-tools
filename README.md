# Release Tools

## release.sh

What it does:

If you have a main branch _and_ development branch:

1. merges development branch into main
2. If `.release.sh/hooks` contains files ending in `.sh`, executes them in the main branch
3. sets release version on main branch
4. pushes and tags main branch
5. merges main back into develop branch
6. sets new version on develop branch and pushes development branch

If you only have a master branch:

1. If `.release.sh/hooks` contains files ending in `.sh`, executes them in the main branch
2. sets release version on main branch
3. pushes and tags main branch
4. sets new version on main branch and pushes main branch

Following branch names qualify as main branches:

* trunk
* master
* main

Following branch names qualify as development branches:

* dev
* develop
* development

It checks the repository for branch names in the order listed above. First
match wins, if you happen to have multiple main and/or development branches.

Supports NPM and Maven projects.
