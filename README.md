# Release Tools

## release.sh

What it does:

1. merges develop branch into main
2. If `.release.sh/hooks` contains files ending in `.sh`, executes them in the main branch
3. sets release version on main branch
4. pushes and tags main branch
5. merges main back into develop branch
6. sets new version on develop branch and pushes develop branch

Supports NPM and Maven projects.
