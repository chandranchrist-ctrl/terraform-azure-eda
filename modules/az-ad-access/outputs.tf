output "group_ids" {
  description = "Map of group names to object IDs"
  value = {
    for k, v in azuread_group.groups :
    k => v.object_id
  }
}