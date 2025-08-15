data "aws_ssoadmin_instances" "daan-se" {}

resource "aws_identitystore_user" "daan" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.daan-se.identity_store_ids)[0]

  display_name = "Daan Wendelen"
  user_name    = "daan"

  name {
    given_name  = "Daan"
    family_name = "Wendelen"
  }

  emails {
    primary = true
    type = "work"
    value = "daanwendelen@gmail.com"
  }
}

resource "aws_identitystore_group" "admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.daan-se.identity_store_ids)[0]

  display_name = "admin"
}

resource "aws_identitystore_group_membership" "admin_daan" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.daan-se.identity_store_ids)[0]
  group_id          = aws_identitystore_group.admin.group_id
  member_id         = aws_identitystore_user.daan.user_id
}

resource "aws_ssoadmin_permission_set" "admin" {
  instance_arn     = tolist(data.aws_ssoadmin_instances.daan-se.arns)[0]
  name             = "AdministratorAccess"
  session_duration = "PT1H"
  tags = { }
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.daan-se.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_account_assignment" "admin" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.daan-se.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_type = "GROUP"
  principal_id   = aws_identitystore_group.admin.group_id

  target_type = "AWS_ACCOUNT"
  target_id   = "749235773701"
}

 # principal_id, principal_type, target_id, target_type, permission_set_arn, instance_arn separated by commas (,). For example:
# terraform import --var-file=secret.tfvars aws_ssoadmin_account_assignment.admin c3f47862-50e1-70ac-e547-671c16920452,GROUP,AWS_ACCOUNT,749235773701,arn:aws:sso:::permissionSet/ssoins-6987e57886e28b18/ps-3f83ffae3786bf78,arn:aws:sso:::instance/ssoins-6987e57886e28b18
