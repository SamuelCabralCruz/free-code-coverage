# free-code-coverage

GitHub Action to enforce code coverage maintenance on pull requests.
This action leverages the power of AWS S3 to persist code coverage data between runs.
In addition to add commit statuses, it can also comment pull request with provided code coverage report.
Last but not least, it will also generate a Markdown code coverage badge to be added in your README.
This action comes in two parts UPLOAD and UPDATE for convenience purposes.

## Important Facts

- This action has been developed as proof-of-concept to standardize the ideas brought in the following 
  [article](https://itnext.io/github-actions-code-coverage-without-third-parties-f1299747064d).
  - As a simple POC, I opted for a simple Docker container action which needs a lot less boilerplate,
    but also come with the downside to be hard to test.
  - Depending on the attraction it gets, some rework might be brought to it. 
- This action assumes that you are working with pull requests and that 
  you enforce branches to be up to date before merge.
  - This design choice was made to suit my personal needs.
  - These assumptions have the following impacts:
    - Enforce that the action can only be run on `pull_request` events.
    - Automatic clean up of the S3 Bucket on close of a pull request.
      > On merge of a pull request, instead of having to re-upload coverage data, 
        we simply override base branch coverage data with the pull request head.
- S3 Bucket must enable public access in order to make badges publicly available.
  - It is recommended to use a dedicated bucket for this action to avoid any conflicts and possible data loss.
  > Sole the badge files are public, all other coverage data is kept private.

## Sample Usage

In order to use this action, you will need at least two workflows.

### Upload Action

The first one probably already exists, and it is your CI workflow that will run your tests and collect coverage data.
Within this workflow you will have to add a step to the UPLOAD action as follows:
  ```
  - uses: SamuelCabralCruz/free-code-coverage/upload@vX.X.X
    with:
      bucket-name: <bucket-name> 
      project-name: <project-name> 
      coverage-metric: <coverage-metric>
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  ```

#### Environment Variables

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

#### Inputs

- bucket-name (required)
  - S3 bucket name to be used to persist code coverage data between runs.
- project-name (required)
  - Lower kebab case string (lower-kebab-case-string) allowing to store action's data from multiple 
    projects/repositories without collisions in the same bucket.
- coverage-metric (required)
  - Computed code coverage metric to be used to perform the check.
- coverage-report (optional - default: '')
  - Additional code coverage details that will be commented on the pull request if provided.
  - By default, no comment will be added.
  - To avoid pull request pollution, previous comments on the same pull request will be deleted.
- badge-color-thresholds (optional - default: '50,60,70,80,90')
  - Comma separated list of thresholds to be used to determine the color of the badge.
  - Associated colors are: brightgreen, green, yellowgreen, yellow, orange, and red.
  - Extremum boundaries (0 and 100) are implicit and corresponding intervals are right half-open.
  - Thus, default value is equivalent to:
      - [100..90[ => brightgreen
      - [ 90..80[ => green
      - [ 80..70[ => yellowgreen
      - [ 70..60[ => yellow
      - [ 60..50[ => orange
      - [ 50.. 0] => red
- bypass-label (optional - default: 'ignoreCoverage')
  - Label to be added to a pull request in order to bypass code coverage check.
  - This label might be useful to knowingly accept a decrease in coverage.
  - Make sure that if a custom value is used for the UPDATE part, it is the same value provided here.

### Update Action

The second workflow is standalone and is necessary for clean up purpose and 
synchronization after pull request labeling or closing.
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
This can easily be adapted using a matrix strategy when using the action for multiple projects inside same repository.

#### Environment Variables

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

#### Inputs

- bucket-name (required)
  - S3 bucket name to be used to persist code coverage data between runs.
- project-name (required)
  - Lower kebab case string (lower-kebab-case-string) allowing to store action's data from multiple
    projects/repositories without collisions in the same bucket.
- bypass-label (optional - default: 'ignoreCoverage')
  - Label to be added to a pull request in order to bypass code coverage check.
  - This label might be useful to knowingly accept a decrease in coverage.
  - Make sure that if a custom value is used for the UPLOAD part, it is the same value provided here.

### Badges

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

### Checks

To enforce code coverage not to decrease, you simply have to modify your branch rules and add 
`Code Coverage - <project-name>` as a required check before merge.
