#
# Based on https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/blob/main/azure/azure.tf
#


# Creates an application registration within Azure Active Directory, specific to the Workspace

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

data "azuread_client_config" "current" {}
resource "azuread_application" "tfc_application" {
  display_name = "tfc-${var.tfc_organization_name}-${var.tfc_workspace_name}"
  owners = distinct([
    data.azuread_client_config.current.object_id,
  ])


  dynamic "required_resource_access" {
    for_each = toset(
      length(var.azuread_graph_permissions) > 0 ?
      [
        data.azuread_service_principal.msgraph.application_id,
      ]
      :
      []
    )

    content {
      resource_app_id = required_resource_access.key

      dynamic "resource_access" {
        for_each = var.azuread_graph_permissions
        content {
          id   = data.azuread_service_principal.msgraph.app_role_ids[resource_access.key]
          type = "Role"
        }
      }

    }
  }
}


# Creates a service principal associated with the previously created
# application registration.
resource "azuread_service_principal" "tfc_service_principal" {
  application_id = azuread_application.tfc_application.application_id
  owners = distinct([
    data.azuread_client_config.current.object_id,
  ])
}

resource "azuread_app_role_assignment" "tfc_service_principal" {
  for_each = var.azuread_graph_permissions

  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids[each.key]
  principal_object_id = azuread_service_principal.tfc_service_principal.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}







# Creates a role assignment which controls the permissions the service
# principal has within the Azure subscription.
data "azurerm_subscription" "current" {}
resource "azurerm_role_assignment" "tfc_role_assignment" {
  # TODO: Make this configurable
  scope = data.azurerm_subscription.current.id

  principal_id = azuread_service_principal.tfc_service_principal.object_id

  role_definition_name = var.azure_role_definition_name
}




# Creates federated identity credentials which ensures that the given
# workspace will be able to authenticate to Azure for the "plan" and "apply" run phases
resource "azuread_application_federated_identity_credential" "tfc_federated_credential_plan" {
  application_object_id = azuread_application.tfc_application.object_id
  display_name          = "tfc-plan"
  audiences             = [var.tfc_azure_audience]
  issuer                = "https://${var.tfc_hostname}"
  subject = join(
    ":", [
      "organization:${var.tfc_organization_name}",
      "project:${var.tfc_workspace_project}",
      "workspace:${var.tfc_workspace_name}",
      "run_phase:plan"
    ]
  )
}
resource "azuread_application_federated_identity_credential" "tfc_federated_credential_apply" {
  application_object_id = azuread_application.tfc_application.object_id
  display_name          = "tfc-apply"
  audiences             = [var.tfc_azure_audience]
  issuer                = "https://${var.tfc_hostname}"
  subject = join(
    ":", [
      "organization:${var.tfc_organization_name}",
      "project:${var.tfc_workspace_project}",
      "workspace:${var.tfc_workspace_name}",
      "run_phase:apply"
    ]
  )
}
