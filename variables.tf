
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
  description = "client_id"
}

variable "client_secret" {
  description = "client_secret"
}

variable "subscription_id" {
  description = "client_id"
}

variable "tenant_id" {
  description = "tenant_id"
}


