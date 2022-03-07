variable "subscription_id" {}
variable "tenant_id" {}
variable "admin_password" {}
variable "admin_username" {}
variable "resource_group_name" {

  default = "henrikinrg"
}

variable "storage_account_name" {
  default = "henrikinstorageaccount"

}
variable  "resource_group_location" {
    default = "eastus"
}