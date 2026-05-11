/* Creates Azure AD security groups dynamically based on input map for role-based access control and identity management */
resource "azuread_group" "groups" {
  for_each = var.groups

  display_name     = each.value.name
  security_enabled = true
}

/* Flattens group-to-member mapping into a list format to simplify assignment of multiple users to multiple groups */
locals {
  group_members = flatten([
    for group_key, group in var.groups : [
      for member in group.members : {
        group_key = group_key
        member_id = member
      }
    ]
  ])
}

/* Assigns users/service principals as members to Azure AD groups based on the flattened mapping structure */
resource "azuread_group_member" "members" {
  for_each = {
    for gm in local.group_members :
    "${gm.group_key}-${gm.member_id}" => gm
  }

  group_object_id  = azuread_group.groups[each.value.group_key].object_id
  member_object_id = each.value.member_id
}