resource "aws_iam_role" "admin_for_ig01" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action    = "sts:AssumeRole"
          Condition = {}
          Effect    = "Allow"
          Principal = {
            AWS = "arn:aws:iam::345594571106:root"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  description           = "Admin Role for Ig01"
  force_detach_policies = false
  max_session_duration  = 43200
  name                  = "AdminRoleForIg01"
  path                  = "/"
}

resource "aws_iam_role_policy_attachments_exclusive" "admin_for_ig01" {
  role_name = aws_iam_role.admin_for_ig01.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}
