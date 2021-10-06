
variable "project_name" {
  description = "Azure Test VM Creation"
  default     = "Azure Vm Deploy"
}

variable "ssh_user" {
  description = "SSH user name to connect to your instance."
  default     = "azureuser"
}

variable "hostname" {
  description = "Virtual machine hostname. Used for local hostname, DNS, and storage-related names."
  default     = "azuretest"
}

variable "prefix" {
  default = "AzureTest"
}

variable "location" {
  default = "East US"
}

variable "client_id" {
  description = "4580cb14-b9d9-4917-9f8c-c814e5f1f65a"
}

variable "client_secret" {
  description = "nK_mDgo-HU5U~qVp_.ynKQgBvHdPVabMC4"
}

variable "subscription_id" {
  description = "4bd67a8c-b219-4e2c-b4c1-fac8710191e6"
}

variable "tenant_id" {
  description = "d2a4b3be-2406-46d8-b098-17361e38b3c6"
}


