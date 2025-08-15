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