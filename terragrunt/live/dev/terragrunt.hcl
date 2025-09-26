# Configuration Terragrunt pour l'environnement DEV
# Ce fichier orchestre tous les modules de l'environnement dev

# Inclusion de la configuration racine
include "root" {
  path = find_in_parent_folders()
}

# Inputs spécifiques à l'environnement dev (surchargent la config racine)
inputs = {
  environment = "dev"
  output_directory = "./dist"
}
