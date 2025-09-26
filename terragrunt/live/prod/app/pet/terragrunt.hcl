# Configuration Terragrunt pour l'environnement PROD
# Ce fichier définit l'instanciation du module pet_fleet pour prod

# Inclusion de la configuration racine
include "root" {
  path = find_in_parent_folders()
}

# Source du module Terraform à utiliser
terraform {
  source = "../../../../modules/pet_fleet"
}

# Inputs spécifiques à l'environnement prod
inputs = {
  pet_configs = {
    "production"  = { prefix = "prod", separator = "-" }
    "staging"     = { prefix = "stage", separator = "_" }
  }
  
  output_directory = "./dist"
}
