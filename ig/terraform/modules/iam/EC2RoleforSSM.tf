resource "aws_iam_role" "ec2_for_ssm" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
          Sid = ""
        },
      ]
      Version = "2012-10-17"
    }
  )
  description           = "Allows EC2 instances to call AWS services like CloudWatch and Systems Manager on your behalf."
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "EC2RoleforSSM"
  name_prefix           = null
  path                  = "/"
}

resource "aws_iam_role_policy_attachments_exclusive" "ec2_for_ssm" {
  role_name = aws_iam_role.ec2_for_ssm.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}
