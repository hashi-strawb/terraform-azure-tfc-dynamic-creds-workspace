variable "tfc_azure_audience" {
  type        = string
  default     = "api://AzureADTokenExchange"
  description = "The audience value to use in run identity tokens"
}

variable "azure_role_definition_name" {
  type        = string
  default     = "Contributor"
  description = "The audience value to use in run identity tokens"
}

variable "azuread_graph_permissions" {
  type        = set(string)
  default     = []
  description = "Should we grant any Azure Graph permissions to the Azure AD App? Use names, like Application.ReadWrite.OwnedBy"
}

variable "tfc_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the TFC or TFE instance you'd like to use with Azure"
}

variable "tfc_organization_name" {
  type        = string
  description = "The name of your Terraform Cloud organization"
}

variable "tfc_workspace_name" {
  type        = string
  description = "The name of the workspace"
}

variable "tfc_workspace_id" {
  type        = string
  description = "The ID of the workspace"
}

variable "tfc_workspace_project" {
  type        = string
  description = "The name of the project the workspace lives in"
}
