resource "aws_iam_role" "ec2_cloudhsm_role" {
  name = "ec2-cloudhsm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "cloudhsm_describe_policy" {
  name        = "CloudHSMDescribeOnly"
  description = "Allows EC2 to describe CloudHSM clusters"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudhsm:DescribeClusters"
        ],
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "attach_cloudhsm_policy" {
  role       = aws_iam_role.ec2_cloudhsm_role.name
  policy_arn = aws_iam_policy.cloudhsm_describe_policy.arn
}

resource "aws_iam_instance_profile" "cloudhsm_instance_profile" {
  name = "cloudhsm-instance-profile"
  role = aws_iam_role.ec2_cloudhsm_role.name
}

