#!/bin/bash

set -eu

DEV_VERSION_SUFFIX_MAVEN="-SNAPSHOT"
DEV_VERSION_SUFFIX_NPM="-dev"
MAIN_BRANCH="master"
DEV_BRANCH="develop"

##
## these functions are supposed to be called from other functions only
##

_is_command_available_or_fail() {
  local command="$1"

  if ! type "${command}" >/dev/null 2>&1; then
    echo_error "No '${command}' command found"
    exit 1
  else
    echo_pass "Command '${command}' found"
  fi

  return 0
}

_is_git_available_or_fail() {
  _is_command_available_or_fail "git"
  return $?
}

_is_npm_available_or_fail() {
  _is_command_available_or_fail "npm"
  return $?
}

_is_jq_available_or_fail() {
  _is_command_available_or_fail "jq"
  return $?
}

_is_maven_available_or_fail() {
  _is_command_available_or_fail "mvn"
  return $?
}

_is_npm_project() {
  test -f package.json
}

_is_maven_project() {
  test -f pom.xml
}

_validate_semantic_version() {
  local version="$1"

  echo "${version}" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' >/dev/null 2>&1
  return $?
}

_validate_development_version() {
  local version="$1"

  if _is_maven_project; then
    echo "${version}" | grep -E "^[0-9]+\\.[0-9]+\\.[0-9]+${DEV_VERSION_SUFFIX_MAVEN}\$" >/dev/null 2>&1
    return $?
  elif _is_npm_project; then
    echo "${version}" | grep -E "^[0-9]+\\.[0-9]+\\.[0-9]+${DEV_VERSION_SUFFIX_NPM}\$" >/dev/null 2>&1
    return $?
  else
    echo_error "Project is neither maven nor npm based"
    exit 1
  fi
}

_read_current_version_from_manifest() {
  if _is_maven_project; then
    mvn help:evaluate -Dexpression=project.version -B -q -DforceStdout
  elif _is_npm_project; then
    jq -r '.version' package.json
  else
    echo_error "Project is neither maven nor npm based"
    exit 1
  fi
}

_get_current_branch() {
  git branch --no-color --show-current
}

_list_all_branches() {
  git branch --no-color | sed -E 's/^[[:space:]*]+//'
}

_is_branch() {
  local expected_branch="$1"
  local current_branch

  current_branch="$(_get_current_branch)"
  if [[ "${current_branch}" == "${expected_branch}" ]]; then
    return 0
  else
    return 1
  fi
}

_is_repo_clean_or_fail() {
  local status

  status="$(git status --short)"
  if [[ -n "${status}" ]]; then
    echo_error "Pending changes in branch $(_get_current_branch)"
    echo_error "${status}"
    exit 1
  else
    echo_pass "Current branch is clean"
  fi
}

_has_git_remote_or_fail() {
  local remotes

  remotes="$(git remote)"
  if [[ -z "${remotes}" ]]
  then
    echo_error "Git repository has no remotes defined"
    exit 1
  else
    echo_pass "Git repository has remote(s) defined"
  fi
}

_detect_main_branch() {
 local all_branches

 all_branches="$(_list_all_branches)"
 for branch_name in trunk master main
 do
   if echo "${all_branches}" | grep "^${branch_name}\$" >/dev/null 2>&1
   then
     echo "${branch_name}"
     return 0
    fi
 done

 echo_error "Unable to find 'trunk', 'master', or 'main' branch in repository"
 exit 1
}

_detect_develop_branch() {
 local all_branches

 all_branches="$(_list_all_branches)"
 for branch_name in dev develop development
 do
   if echo "${all_branches}" | grep "^${branch_name}\$" >/dev/null 2>&1
   then
     echo "${branch_name}"
     return 0
    fi
 done

 echo_error "Unable to find 'dev', 'develop', or 'develop' branch in repository"
 exit 1
}

_detect_branches() {
  MAIN_BRANCH="$(_detect_main_branch)"
  echo_pass "Detected main branch '${MAIN_BRANCH}'"

  DEV_BRANCH="$(_detect_develop_branch)"
  echo_pass "Detected development branch '${DEV_BRANCH}'"
}

_check_required_commands_maven() {
  _is_git_available_or_fail
  _is_maven_available_or_fail
}

_check_required_commands_npm() {
  _is_git_available_or_fail
  _is_npm_available_or_fail
  _is_jq_available_or_fail
}

##
## these functions can be called from the main part
##

echo_error() {
  printf "\033[1;31;48m\xE2\x9C\x97 %s\033[0m\n" "$*" >&2
}

echo_pass() {
  printf "\033[0;32;48m\xE2\x9C\x94 %s\033[0m\n" "$*"
}

echo_info() {
  printf "\033[1;36;48m\xE2\x80\xA2 %s\033[0m\n" "$*"
}

echo_prompt() {
  printf "\033[1;35;48m\xE2\x86\x92 %s\033[0m" "$*" 1>&2
}

is_valid_semantic_version_or_fail() {
  local version="$1"
  if _validate_semantic_version "${version}"; then
    echo_info "Version '${version}' syntactically correct"
  else
    echo_error "Version '${version}' syntactically not correct"
    exit 1
  fi
}

read_release_version() {
  local proposed_version="$1"

  echo_prompt "New release version [${proposed_version}]: "
  read -r NEW_VERSION

  if [ -z "${NEW_VERSION}" ]; then
    NEW_VERSION="${proposed_version}"
  fi

  echo "${NEW_VERSION}"
}

print_current_version() {
  local current_version

  current_version="$(_read_current_version_from_manifest)"
  current_branch="$(_get_current_branch)"

  echo_info "Current version ${current_version} on branch '${current_branch}'"
}

read_development_version() {
  local proposed_version="$1"
  local message

  if _is_maven_project; then
    message="Next development version (must end in '${DEV_VERSION_SUFFIX_MAVEN}') [${proposed_version}]: "
  else
    message="Next development version (must end in '${DEV_VERSION_SUFFIX_NPM}') [${proposed_version}]: "
  fi
  echo_prompt "${message}"
  read -r NEW_VERSION

  if [ -z "${NEW_VERSION}" ]; then
    NEW_VERSION="${proposed_version}"
  fi

  echo "${NEW_VERSION}"
}

is_valid_development_version_or_fail() {
  local version="$1"
  if _validate_development_version "${version}"; then
    echo_info "Development version '${version}' syntactically correct"
  else
    echo_error "Development version '${version}' syntactically not correct"
    if _is_maven_project; then
      echo_error "maven development versions must end in '${DEV_VERSION_SUFFIX_MAVEN}'"
    else
      echo_error "npm development versions must end in '${DEV_VERSION_SUFFIX_NPM}'"
    fi
    exit 1
  fi
}

merge_develop_into_main() {
  if ! _is_branch "${DEV_BRANCH}"; then
    echo_error "Not on branch '${DEV_BRANCH}'"
    exit 1
  fi

  _is_repo_clean_or_fail

  echo_info "Merge ${DEV_BRANCH} into ${MAIN_BRANCH}"

  git checkout "${MAIN_BRANCH}" >/dev/null
  git merge --no-ff "${DEV_BRANCH}" </dev/null >/dev/null
}

merge_main_into_develop() {
  if ! _is_branch "${MAIN_BRANCH}"; then
    echo_error "not on branch '${MAIN_BRANCH}'"
    exit 1
  fi

  _is_repo_clean_or_fail

  echo_info "Merge ${MAIN_BRANCH} into ${DEV_BRANCH}"

  git checkout "${DEV_BRANCH}" >/dev/null
  git merge --no-ff "${MAIN_BRANCH}" </dev/null >/dev/null
}

set_manifest_version() {
  local new_version="$1"

  if _is_maven_project; then
    mvn -q -B versions:set -DnewVersion=${new_version}
    mvn -q -B versions:commit
  elif _is_npm_project; then
    npm version --git-tag-version=false "${new_version}" >/dev/null
  else
    echo_error "Project is neither maven nor npm based"
    exit 1
  fi
}

commit_and_push_release_version() {
  local version="$1"

  echo_info "Commit version ${version}"
  git commit -a -m "Bump to version ${version}" >/dev/null
  echo_info "Push ${MAIN_BRANCH}"
  git push origin "${MAIN_BRANCH}" >/dev/null

  echo_info "Tag version ${version}"
  git tag -a -m "Version ${version}" "v${version}" >/dev/null
  echo_info "Push tag"
  git push origin "v${version}" >/dev/null
}

commit_and_push_development_version() {
  echo_info "Commit ${DEV_BRANCH} branch"
  git commit -a -m "Prepare next development cycle" >/dev/null
  echo_info "Push ${DEV_BRANCH} branch"
  git push origin "${DEV_BRANCH}"
}

version_to_next_development_version() {
  local version="$1"
  local new_version

  new_version=$(echo "${version}" | awk 'BEGIN { FS="."; OFS="."} { print $1, $2, ++$3 }')
  if _is_maven_project; then
    echo "${new_version}${DEV_VERSION_SUFFIX_MAVEN}"
  else
    echo "${new_version}${DEV_VERSION_SUFFIX_NPM}"
  fi

  return 0
}

current_version_to_release_version() {
  local current_version

  current_version="$(_read_current_version_from_manifest)"
  echo "${current_version}" | sed -E "s/${DEV_VERSION_SUFFIX_NPM}|${DEV_VERSION_SUFFIX_MAVEN}//"
}

preflight_checks() {
  if _is_maven_project
  then
    echo_pass "$(pwd) is a maven project"
    _check_required_commands_maven
  elif _is_npm_project
  then
    echo_pass "$(pwd) is a npm project"
    _check_required_commands_npm
  else
    echo_error "$(pwd) is neither a maven nor a npm project"
    exit 1
  fi

  _detect_branches
  _has_git_remote_or_fail
}


##
## main
##

preflight_checks

# Get versions
print_current_version
PROPOSED_RELEASE_VERSION="$(current_version_to_release_version)"
RELEASE_VERSION="$(read_release_version "${PROPOSED_RELEASE_VERSION}")"
is_valid_semantic_version_or_fail "${RELEASE_VERSION}"

PROPOSED_DEV_VERSION="$(version_to_next_development_version "${RELEASE_VERSION}")"
DEVELOPMENT_VERSION="$(read_development_version "${PROPOSED_DEV_VERSION}")"
is_valid_development_version_or_fail "${DEVELOPMENT_VERSION}"

# Roll release
merge_develop_into_main
set_manifest_version "${RELEASE_VERSION}"
commit_and_push_release_version "${RELEASE_VERSION}"

# Prepare next development cycle
merge_main_into_develop
set_manifest_version "${DEVELOPMENT_VERSION}"
commit_and_push_development_version
