# free-code-coverage (UPDATE)

- This action leverages the power of AWS S3 to persist code coverage data between runs.
- S3 Bucket must enable public access in order to make badges publicly available.
  - It is recommended to use a dedicated bucket for this action to avoid any conflicts and possible data loss.
  > Sole the badge files are public, all other coverage data is kept private.

## Sample Usage

```
on:
  pull_request:
    types: [labeled, unlabeled, closed]

jobs:
  update:
    runs-on: ubuntu-latest

    steps:
      - uses: SamuelCabralCruz/free-code-coverage/update@vX.X.X
        with:
          bucket-name: <bucket-name> 
          project-name: <project-name>
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```
> This can easily be adapted using a matrix strategy when using the action for multiple projects inside same repository.

### Environment Variables

- GITHUB_TOKEN
  - Would normally be `${{ secrets.GITHUB_TOKEN }}`
  - Needed permissions:
    - `pull_requests: write`
- AWS_ACCESS_KEY_ID
  - AWS IAM User Access Key ID with S3 admin rights
  - Should be exposed via your repository secrets
- AWS_SECRET_ACCESS_KEY
  - AWS IAM User Secret Access Key with S3 admin rights
  - Should be exposed via your repository secrets
- AWS_REGION (optional - default: 'us-east-1')

### Inputs

- bucket-name
  - S3 bucket name to be used to persist code coverage data between runs.
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
  ![](https://<bucket-name>.s3.amazonaws.com/badge-<project-name>-<branch-name>.svg)
  ```
  - You will need to provide values for:
    - bucket-name
    - project-name
    - branch-name
      - For encoding reasons, need to replace any `/` by `-` in the branch name
      - Would normally be the name of your repository's default branch name `main` or `master`.
      - Could also be the name of a branch that is never destined to be closed (ex: `develop` if you use 
        [Gitflow workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)).

## Checks

To enforce code coverage not to decrease, you simply have to modify your branch rules and add 
`Code Coverage - <project-name>` as a required check before merge.
