# Outputs agrégés de l'exercice 3
output "fleet_pet_names" {
  description = "Tous les noms de pets générés par le module fleet"
  value = module.pet_fleet.pet_names
}

output "fleet_pet_files" {
  description = "Tous les fichiers créés par le module fleet"
  value = module.pet_fleet.pet_files
}

output "script_execution_summary" {
  description = "Résumé de l'exécution des scripts"
  value = {
    files_processed = module.script_runner.processed_files_count
    execution_ids   = module.script_runner.execution_ids
    files_list      = module.script_runner.files_processed
    additional_scripts = module.script_runner.additional_scripts_executed
  }
}

# Outputs pour compatibilité et démonstration des boucles
output "pet_names_count" {
  description = "Nombre total de pets générés"
  value = length(module.pet_fleet.pet_names_list)
}

output "all_pet_names_formatted" {
  description = "Noms formatés pour affichage"
  value = join(", ", module.pet_fleet.pet_names_list)
}
