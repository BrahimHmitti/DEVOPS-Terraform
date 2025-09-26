# Module script_runner - Terragrunt
# Utilisation de terraform_data avec des provisioners pour chaque fichier

resource "terraform_data" "script_runner" {
  for_each = toset(var.files_to_process)
  
  # Déclenche la recréation si le fichier ou la commande change
  triggers_replace = {
    file = each.value
    base_command = var.base_command
  }
  
  # Provisioner pour traiter chaque fichier individuellement
  provisioner "local-exec" {
    command = "${var.base_command} ${each.value} && echo 'Traitement de ${each.value} terminé'"
    
    # Gestion d'erreur pour les fichiers manquants
    on_failure = continue
  }
}

# Ressource séparée pour les commandes additionnelles
resource "terraform_data" "additional_scripts" {
  count = length(var.additional_commands) > 0 ? 1 : 0
  
  triggers_replace = {
    commands = jsonencode(var.additional_commands)
  }
  
  # Une seule commande qui exécute toutes les commandes additionnelles
  provisioner "local-exec" {
    command = join(" && ", flatten([
      for cmd_group in values(var.additional_commands) : cmd_group
    ]))
    on_failure = continue
  }
}
