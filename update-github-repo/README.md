# free-code-coverage (UPDATE-GITHUB-REPO)

- This action uses a public GitHub repository to persist code coverage data between runs.
- This is a truly free of charge alternative to the default one using an AWS S3 bucket.
- Downside is that all code coverage data must be public to allow badges to be read.

## Sample Usage

```
on:
  pull_request:
    types: [labeled, unlabeled, closed]

jobs:
  update:
    runs-on: ubuntu-latest

    steps:
      - uses: SamuelCabralCruz/free-code-coverage/update-github-repo@vX.X.X
        with:
          github-repo: <github-repo> 
          project-name: <project-name>
        env:
          GITHUB_TOKEN: ${{ secrets.PAT }}
```
> This can easily be adapted using a matrix strategy when using the action for multiple projects inside same repository.

### Environment Variables

- GITHUB_TOKEN
  - Personal Access Token (PAT) which has read/write access to both repository this action is used in and
    the public repository used to persist code coverage data.
    > Need to enable all repo rights

### Inputs

- github-repo
  - Public GitHub repository name following the following format {owner}/{repo}
    used to persist code coverage data between runs.
- project-name
  - Lower kebab case string (lower-kebab-case-string) allowing to store action's data from multiple
    projects/repositories without collisions in the same bucket.
- bypass-label (optional - default: 'ignoreCoverage')
  - Label to be added to a pull request in order to bypass code coverage check.
  - This label might be useful to knowingly accept a decrease in coverage.
  - Make sure that if a custom value is used for the UPLOAD part, it is the same value provided here.

## Badges

To add badges to your `README` or any other Markdown file, you can simply copy/paste and fill in the template below:
  ```md
  ![](https://raw.githubusercontent.com/<github-repo>/<branch-name>/badge-<project-name>-<escaped-branch-name>.svg)
  ```
  - You will need to provide values for:
    - github-repo
    - project-name
    - branch-name
    - escaped-branch-name
      - For encoding reasons, need to replace any `/` by `-` in the branch name
      - Would normally be the name of your repository's default branch name `main` or `master`.
      - Could also be the name of a branch that is never destined to be closed (ex: `develop` if you use 
        [Gitflow workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)).

## Checks

To enforce code coverage not to decrease, you simply have to modify your branch rules and add 
`Code Coverage - <project-name>` as a required check before merge.
