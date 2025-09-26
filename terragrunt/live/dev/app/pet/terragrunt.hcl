# Configuration Terragrunt pour l'environnement DEV
# Ce fichier définit l'instanciation du module pet_fleet pour dev

# Inclusion de la configuration racine
include "root" {
  path = find_in_parent_folders()
}

# Source du module Terraform à utiliser
terraform {
  source = "../../../../modules/pet_fleet"
}

# Inputs spécifiques à l'environnement dev
inputs = {
  pet_configs = {
    "development" = { prefix = "dev", separator = "-" }
    "testing"     = { prefix = "test", separator = "_" }
  }
  
  output_directory = "./dist"
}
