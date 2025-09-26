# Sorties agrégées - liste des noms générés
output "pet_names" {
  description = "Liste de tous les noms de pets générés"
  value = {
    for key, pet in random_pet.fleet : key => pet.id
  }
}

# Sorties agrégées - liste des fichiers créés
output "pet_files" {
  description = "Liste de tous les fichiers créés"
  value = {
    for key, file in local_file.pet_files : key => file.filename
  }
}

# Liste simple des noms (pour compatibilité)
output "pet_names_list" {
  description = "Liste simple des noms générés"
  value = [for pet in random_pet.fleet : pet.id]
}

# Liste simple des fichiers (pour le module script_runner)
output "pet_files_list" {
  description = "Liste simple des fichiers créés"
  value = [for file in local_file.pet_files : file.filename]
}
