# GitHub Actions OIDC setup

1. In AWS IAM, add an OpenID Connect identity provider:
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
2. Create a role trusted by this provider.
3. Scope the trust policy to your repository and branch `main`. Basic example (replace account/repo details):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
        "token.actions.githubusercontent.com:sub": "repo:GITHUB_OWNER/aws-terraform-devops-assessment:ref:refs/heads/main"
      }
    }
  }]
}
```

4. Add the minimum permissions required for the Terraform resources in this project. For a learning account, do not use this example as a production policy; create a project-scoped policy and review it.
5. In GitHub repository Settings -> Secrets and variables -> Actions -> Variables, add `AWS_ROLE_ARN`.
6. The workflow runs fmt/init/validate/plan on pushes. Use Actions -> Run workflow and set `apply=true` only after reviewing the plan.
7. If your repository uses GitHub's newer OIDC subject format, adjust the `sub` condition to match the token format documented for your repository.
