# Configuration Terragrunt pour le module script_runner PROD
# Ce module dépend du module pet_fleet et traite les fichiers générés

# Inclusion de la configuration racine
include "root" {
  path = find_in_parent_folders()
}

# Source du module Terraform à utiliser
terraform {
  source = "../../../../modules/script_runner"
}

# Dépendance sur le module pet_fleet
dependency "pet_fleet" {
  config_path = "../pet"
  
  # Mock outputs pour les tests/plans avant apply
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    pet_files = {
      "production" = "./dist/pet_production.txt"
      "staging"    = "./dist/pet_staging.txt"
    }
  }
}

# Inputs spécifiques au script_runner prod
inputs = {
  files_to_process = values(dependency.pet_fleet.outputs.pet_files)
  base_command     = "echo '[PROD] Contenu du fichier pet avec Terragrunt'"
  
  additional_commands = {
    prod_validation = [
      "echo '[PROD] Validation des fichiers générés'",
      "find ./dist -name 'pet_*.txt' -exec basename {} \\;",
      "echo 'Production environment processing completed'",
      "echo 'All production checks passed successfully'"
    ]
  }
}
