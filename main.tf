# Configuration racine pour l'exercice 3 - Modules & Dynamic Blocks
terraform {
  required_version = ">= 1.6"
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
    local  = { source = "hashicorp/local",  version = "~> 2.5" }
  }
}

provider "random" {}
provider "local" {}

# Module pet_fleet - génère N pets et fichiers
module "pet_fleet" {
  source = "./modules/pet_fleet"
  
  pet_configs = {
    "development" = { prefix = "dev", separator = "-" }
    "testing"     = { prefix = "test", separator = "_" }
    "production"  = { prefix = "prod", separator = "-" }
    "staging"     = { prefix = "stage", separator = "_" }
  }
  
  output_directory = "./dist"
}

# Module script_runner - traite les fichiers générés
module "script_runner" {
  source = "./modules/script_runner"
  
  # Dépend des fichiers générés par pet_fleet
  files_to_process = module.pet_fleet.pet_files_list
  
  base_command = "echo 'Contenu du fichier pet'"
  
  additional_commands = {
    "validation" = [
      "echo 'Validation des fichiers générés'",
      "ls -la ./dist/pet_*.txt || true",
      "wc -l ./dist/pet_*.txt || true"
    ]
  }
}
