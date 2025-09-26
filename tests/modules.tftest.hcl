variables {
  # Test avec configuration par défaut
}

run "test_pet_fleet_module" {
  command = apply
  
  # Utilise la configuration main_modules.tf
  
  assert {
    condition = length(output.fleet_pet_names) == 4
    error_message = "Le module pet_fleet devrait générer 4 pets, mais a généré ${length(output.fleet_pet_names)}"
  }
  
  assert {
    condition = length(output.fleet_pet_files) == 4
    error_message = "Le module pet_fleet devrait créer 4 fichiers, mais en a créé ${length(output.fleet_pet_files)}"
  }
  
  assert {
    condition = output.script_execution_summary.files_processed == 4
    error_message = "Le module script_runner devrait traiter 4 fichiers, mais en a traité ${output.script_execution_summary.files_processed}"
  }
}

run "test_pet_patterns_from_modules" {
  command = apply
  
  assert {
    condition = alltrue([
      for name in values(output.fleet_pet_names) :
      can(regex("^[a-z]+([-_])[a-z]+([-_])[a-z]+$", name))
    ])
    error_message = "Tous les noms de pets doivent respecter le pattern avec prefix-separator-word-separator-word"
  }
  
  assert {
    condition = alltrue([
      for filename in values(output.fleet_pet_files) :
      can(regex("^\\./dist/pet_[a-z]+\\.txt$", filename))
    ])
    error_message = "Tous les fichiers doivent être dans ./dist/ avec le format pet_[env].txt"
  }
}
