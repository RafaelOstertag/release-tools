# Release Tools

## release.sh

What it does:

1. merges develop branch into main
2. sets release version on main branch
3. pushes and tags main branch
4. merges main back into develop branch
5. sets new version on develop branch and pushes develop branch

Supports NPM and Maven projects.
