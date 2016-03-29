provider "aws" {
    profile = "${var.aws_profile}"
    region = "${var.aws_region}"
}

output "account_name" {
    value = "${var.account_name}"
}

output "technical_contact" {
    value = "${var.technical_contact}"
}

output "ssh_key_name" {
    value = "${var.ssh_key_name}"
}

resource "aws_iam_user" "admin" {
  count = "${length(split(",",var.admin_users))}"
  path = "/nubis/admin/"
  name = "${element(split(",",var.admin_users), count.index)}"
}

resource "aws_iam_access_key" "admins" {
  count = "${length(split(",",var.admin_users))}"
  user = "${element(aws_iam_user.admin.*.name, count.index)}"
}

resource "aws_iam_group" "admins" {
    name = "Administrators"
    path = "/nubis/admin/"
}

resource "aws_iam_group" "nacl_admins" {
    name = "NACLAdministrators"
    path = "/nubis/"
}

resource "aws_iam_group" "read_only_users" {
    name = "ReadOnlyUsers"
    path = "/nubis/"
}

resource "aws_iam_policy_attachment" "read_only" {
    name = "read-only-attachments"
    groups = ["${aws_iam_group.read_only_users.name}"]
    policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_group_policy" "nacl_admins" {
    name = "nacl_admins_policy"
    group = "${aws_iam_group.nacl_admins.id}"
    policy = <<POLICY
{
              "Version": "2012-10-17",
              "Statement": [
                {
                  "Action": [
                    "ec2:CreateNetworkAclEntry",
                    "ec2:DeleteNetworkAclEntry",
                    "ec2:DescribeNetworkAcls",
                    "ec2:ReplaceNetworkAclEntry",
                    "ec2:DescribeVpcAttribute",
                    "ec2:DescribeVpcs"
                  ],
                  "Effect": "Allow",
                  "Resource": "*"
                }
              ]
            }
POLICY
}

resource "aws_iam_group_membership" "admins" {
    name = "admins-group-membership"

    users = [
        "${aws_iam_user.admin.*.name}"
    ]

    group = "${aws_iam_group.admins.name}"
}
