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



resource "random_pet" "pet" {
  length    = 2
  prefix    = var.prefix
  separator = var.separator

  lifecycle {
    precondition {
      condition     = length(var.prefix) > 0
      error_message = "prefix ne peut pas être vide."
    }
  }
}

resource "local_file" "pet_file" {
  filename = "${path.module}/dist/pet.txt"
  content  = random_pet.pet.id

  lifecycle {
    postcondition {
      condition     = file(self.filename) == random_pet.pet.id
      error_message = "Le contenu de ${filename} n'est pas égal au nom généré."
    }
  }
}




resource "random_password" "password" {
    length =  16
}

# Écrit le nom dans un fichier dist/password.txt
resource "local_file" "password_file" {
  filename = "${path.module}/dist/password.txt"
  content  = random_password.password.result
}

resource "random_integer" "number" {
    min = 10
    max = 100
}

resource "local_file" "number_file" {
    filename = "${path.module}/dist/number.txt"
    content = random_integer.number.result
}