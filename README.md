# free-code-coverage

GitHub Action to enforce code coverage maintenance on pull requests.
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

## Sample Usage

In order to use this action, you will need at least two workflows.
The first workflow might already exist and corresponds to your CI workflow which runs your tests.
In this workflow, you will need to call the UPLOAD action that best suits your needs 
to persist your code coverage data and perform the code coverage validation.
The other workflow will be necessary in order to sync coverage data between branches and clean up the persistence 
whenever a pull request will be closed by calling the UPLOAD's matching UPDATE action.

The specific usage may differ on the variant you use.
Please refer to the related README for more details:
- [upload](./upload/README.md)
  - description:
    - Best suited for single project repositories 
    - Fine-grained access rights on code coverage data
    - Not entirely free due to the cost of hosting a S3 bucket
    - Will report checks using stand-alone commit statuses
  - persistence: AWS S3
  - reporter: Separate commit status
- [update](./update/README.md)
  - description:
    - To be used with `upload` action
    - Can react to pull request labeling
  - persistence: AWS S3
  - reporter: Separate commit status
- [upload-embedded](./upload-embedded/README.md)
  - description:
    - Best suited for mono-repository
    - Fine-grained access rights on code coverage data
    - Not entirely free due to the cost of hosting a S3 bucket
    - Will report checks by failing the workflow into which it is embedded 
  - persistence: AWS S3
  - reporter: Embedded workflow
- [update-embedded](./update-embedded/README.md)
  - description:
    - To be used with `upload-embedded`
    - Will only clean and sync code coverage data whenever a pull request is closed
    - Won't update checks, needs to rerun the workflow the action is embedded into
  - persistence: AWS S3
  - reporter: None
- [upload-github-repo](./upload-github-repo/README.md)
  - description:
    - Identical to `upload`, but totally free of charge
    - Uses a public GitHub repository to persist data instead of an AWS S3 bucket
    - All code coverage data will be publicly available
  - persistence: Public GitHub repository
  - reporter: Separate commit status
