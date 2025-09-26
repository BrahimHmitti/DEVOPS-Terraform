# Configuration Terragrunt racine - Exercice 4
# Cette configuration définit les éléments communs à tous les environnements

# Génération automatique du fichier provider.tf
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "random" {}
provider "local" {}
EOF
}

# Génération automatique du fichier backend.tf (local backend pour cet atelier)
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "local" {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}
EOF
}

# Inputs communs partagés entre tous les environnements
inputs = {
  # Préfixes par défaut (peuvent être surchargés)
  output_directory = "./dist"
  
  # Commandes communes pour le script_runner
  base_command = "echo 'Processing file with Terragrunt'"
  
  additional_commands = {
    validation = [
      "echo 'Validation des fichiers générés avec Terragrunt'",
      "ls -la ./dist/pet_*.txt || echo 'No files found yet'",
      "wc -l ./dist/pet_*.txt || echo 'No files to count yet'"
    ]
  }
}
