# Configuration Terragrunt pour l'environnement PROD
# Ce fichier orchestre tous les modules de l'environnement prod

# Inclusion de la configuration racine
include "root" {
  path = find_in_parent_folders()
}

# Inputs spécifiques à l'environnement prod (surchargent la config racine)
inputs = {
  environment = "prod"
  output_directory = "./dist"
}
