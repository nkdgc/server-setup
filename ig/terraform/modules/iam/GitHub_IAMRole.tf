resource "aws_iam_role" "admin_for_github" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            }
            StringLike = {
              "token.actions.githubusercontent.com:sub" = "repo:nkdgc/*"
            }
          }
          Effect = "Allow"
          Principal = {
            Federated = "arn:aws:iam::850995561710:oidc-provider/token.actions.githubusercontent.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "GitHubActionsRole"
  path                  = "/"
}

resource "aws_iam_role_policy_attachments_exclusive" "admin_for_github" {
  role_name = aws_iam_role.admin_for_github.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}
