#!/bin/sh
set -eu
if [ "$#" -gt 1 ]; then echo 'usage: git mr [title]' >&2; exit 2; fi
branch=$(git symbolic-ref --quiet --short HEAD) || exit 1
head=$(git rev-parse HEAD)
remote_head=$(git ls-remote --heads origin "refs/heads/$branch") || exit 1
if [ "${remote_head%%[[:space:]]*}" = "$head" ]; then echo 'git mr: branch is already pushed' >&2; exit 1; fi
title=${1-}
set -- -o merge_request.create -o merge_request.target="${GIT_MR_TARGET:-main}" -o merge_request.remove_source_branch
if [ -n "${GIT_MR_ASSIGNEE:-}" ]; then set -- "$@" -o "merge_request.assign=$GIT_MR_ASSIGNEE"; fi
if [ -n "$title" ]; then set -- "$@" -o "merge_request.title=$title"; fi
git push origin "HEAD:refs/heads/$branch" "$@"
