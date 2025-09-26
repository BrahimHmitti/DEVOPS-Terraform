# Génère N pets avec for_each
resource "random_pet" "fleet" {
  for_each = var.pet_configs
  
  length    = 2
  prefix    = each.value.prefix
  separator = each.value.separator
  
  lifecycle {
    precondition {
      condition     = length(each.value.prefix) > 0
      error_message = "Le prefix '${each.key}' ne peut pas être vide."
    }
  }
}

# Écrit N fichiers (un par pet)
resource "local_file" "pet_files" {
  for_each = random_pet.fleet
  
  filename = "${var.output_directory}/pet_${each.key}.txt"
  content  = each.value.id
  
  lifecycle {
    postcondition {
      condition = self.content == random_pet.fleet[each.key].id
      error_message = "Le contenu du fichier '${each.key}' ne correspond pas au nom généré."
    }
  }
}
