output "execution_summary" {
  description = "Résumé de l'exécution des scripts"
  value = {
    files_processed    = length(var.files_to_process)
    files_list        = var.files_to_process
    execution_ids     = {
      for file, resource in terraform_data.script_runner : file => resource.id
    }
    additional_scripts = length(terraform_data.additional_scripts) > 0 ? terraform_data.additional_scripts[0].id : null
  }
}
