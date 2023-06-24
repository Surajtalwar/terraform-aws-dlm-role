/**
 * # terraform-aws-dlm-role
 *
 * Data Lifecycle Manager (DLM) role.
 *
 * Provides typical role with policies based on https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/snapshot-lifecycle.html
 */

data "aws_iam_policy_document" "assume_by_dlm" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  path               = var.role_path
  description        = var.role_description
  assume_role_policy = data.aws_iam_policy_document.assume_by_dlm.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "snapshot" {
  count      = var.enable_snapshot_lifecycle ? 1 : 0
  role       = aws_iam_role.this.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_iam_role_policy_attachment" "ami" {
  count      = var.enable_ami_lifecycle ? 1 : 0
  role       = aws_iam_role.this.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRoleForAMIManagement"
}

resource "aws_dlm_lifecycle_policy" "test_lifecyclerole" {
  description        = "DLM lifecycle policy"
  execution_role_arn = "${aws_iam_role.this.arn}"
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "2 weeks of daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["23:45"]
      }

      retain_rule {
        count = 5
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = false
    }

    target_tags = {
      Snapshot = "true"
    }
  }
}