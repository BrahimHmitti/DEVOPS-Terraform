terraform {
  required_version = ">= 1.6"
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
    local  = { source = "hashicorp/local",  version = "~> 2.5" }
  }
}

#provider : à l'aide des providers on peut on peut utiliser des resources comme random
#générer des mots d'animaux, mots de passe, nombres etc 

provider "random" {}
provider "local" {}



# ic on spécifie les caractéristiques du mot
resource "random_pet" "pet" {
  length    = 2
  prefix    = var.prefix
  separator = var.separator
}


resource "random_password" "password" {
    length =  16
}


resource "random_integer" "number" {
    min = 10
    max = 100
}

# Écrit le nom dans un fichier dist/pet.txt
resource "local_file" "pet_file" {
  filename = "${path.module}/dist/pet.txt"
  content  = random_pet.pet.id 
}

# Écrit le nom dans un fichier dist/password.txt
resource "local_file" "password_file" {
  filename = "${path.module}/dist/password.txt"
  content  = random_password.password.result
}


resource "local_file" "number_file" {
    filename = "${path.module}/dist/number.txt"
    content = random_integer.number.result
}