output "processed_files_count" {
  description = "Nombre de fichiers traités"
  value = length(var.files_to_process)
}

output "execution_ids" {
  description = "IDs des exécutions des scripts par fichier"
  value = {
    for file in var.files_to_process : file => terraform_data.script_runner[file].id
  }
}

output "files_processed" {
  description = "Liste des fichiers qui ont été traités"
  value = var.files_to_process
}

output "additional_scripts_executed" {
  description = "Indique si les scripts additionnels ont été exécutés"
  value = length(terraform_data.additional_scripts) > 0 ? terraform_data.additional_scripts[0].id : "no-additional-scripts"
}
