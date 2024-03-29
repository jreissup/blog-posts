#####################################
# Redshift 
#####################################
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role_policy_redshift" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values = [
        "arn:aws:redshift:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.redshift_cluster_name}/${var.redshift_admin_user_name}"
      ]
    }
  }
}

data "aws_iam_policy_document" "redshift_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "glue:*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }
}

resource "aws_iam_role" "lakehouse_role" {
  name               = "${var.redshift_cluster_name}-redshift-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_redshift.json
}

resource "aws_iam_role_policy" "lakehouse_policy" {
  name   = "${var.redshift_cluster_name}-redshift-policy"
  role   = aws_iam_role.lakehouse_role.id
  policy = data.aws_iam_policy_document.redshift_role_policy.json
}

resource "aws_iam_policy_attachment" "lakehouse-attach" {
  name       = "lakehouse-attachment"
  roles      = [aws_iam_role.lakehouse_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}

#####################################
# Glue
#####################################
data "aws_iam_policy_document" "assume_role_policy_glue" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "glue_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
     "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "glue" {
  name               = "${var.redshift_cluster_name}-glue-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_glue.json
}

resource "aws_iam_role_policy" "glue_role_policy" {
  name   = "${var.redshift_cluster_name}-glue-policy"
  role   = aws_iam_role.glue.id
  policy = data.aws_iam_policy_document.glue_role_policy.json
}
