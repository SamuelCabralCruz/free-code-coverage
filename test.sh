#!/bin/bash

BRANCH_NAME="test"
git stash save
git checkout main
git branch -D $BRANCH_NAME
git stash apply
git add -A && git commit --no-edit --amend && git push -f
git checkout -b $BRANCH_NAME
touch $BRANCH_NAME.txt
git add -A
git commit -m "$BRANCH_NAME"
git push origin -uf $BRANCH_NAME
git checkout main
