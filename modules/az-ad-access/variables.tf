variable "groups" {
  description = "Map of AD groups and their members"
  type = map(object({
    name    = string
    members = list(string)
  }))
}