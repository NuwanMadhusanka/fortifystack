###############################################################################
# Instance IAM role - least privilege for the app tier.
#   - SSM core: shell access via Session Manager (no SSH keys, no bastion).
#   - Read ONLY the one DB secret this app needs.
###############################################################################

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.name}-app-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# Session Manager access (no inbound SSH needed).
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Read only the specific DB secret.
data "aws_iam_policy_document" "secret_read" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.secret_arn]
  }
}

resource "aws_iam_role_policy" "secret_read" {
  name   = "${var.name}-read-db-secret"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.secret_read.json
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-app-profile"
  role = aws_iam_role.app.name
}
