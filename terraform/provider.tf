terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Backend remoto: guarda el estado en Azure Storage
  # Los valores se pasan desde el pipeline con -backend-config
  backend "azurerm" {}
}

provider "azurerm" {
  # OIDC: GitHub Actions se autentica sin contraseñas almacenadas
  use_oidc = true

  features {}
}
