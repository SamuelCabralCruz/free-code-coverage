git stash save
git checkout main
git branch -D test
git stash apply
git add -A && git commit --no-edit --amend && git push -f
git checkout -b test
touch test.txt
git add -A
git commit -m "test"
git push origin -uf test
git checkout main
