brahim@Brahim:/mnt/c/Users/er-co/Desktop/DEVOPS-Terraform/devops-terraform$ terraform validate
╷
│ Error: Duplicate required providers configuration
│
│   on main_exercices1-2.tf line 4, in terraform:
│    4:   required_providers {
│
│ A module may have only one required providers configuration. The required  
│ providers were previously configured at main.tf:4,3-21.
╵
╷
│ Error: Duplicate provider configuration
│
│   on main_exercices1-2.tf line 10:
│   10: provider "random" {}
│
│ A default (non-aliased) provider configuration for "random" was already    
│ given at main.tf:10,1-18. If multiple configurations are required, set the 
│ "alias" argument for alternative configurations.
╵
╷
│ Error: Duplicate provider configuration
│
│   on main_exercices1-2.tf line 11:
│   11: provider "local" {}
│
│ A default (non-aliased) provider configuration for "local" was already     
│ given at main.tf:11,1-17. If multiple configurations are required, set the 
│ "alias" argument for alternative configurations.
╵
╷
│ Error: Duplicate module call
│
│   on main_exercices1-2.tf line 14:
│   14: module "pet_fleet" {
│
│ A module call named "pet_fleet" was already defined at main.tf:14,1-19.    
│ Module calls must have unique names within a module.
╵
╷
│ Error: Duplicate module call
│
│   on main_exercices1-2.tf line 28:
│   28: module "script_runner" {
│
│ A module call named "script_runner" was already defined at
│ main.tf:28,1-23. Module calls must have unique names within a module.      
╵
brahim@Brahim:/mnt/c/Users/er-co/Desktop/DEVOPS-Terraform/devops-terraform$ terraform init
Initializing the backend...
Initializing modules...
╷
│ Error: Duplicate required providers configuration
│
│   on main_exercices1-2.tf line 4, in terraform:
│    4:   required_providers {
│
│ A module may have only one required providers configuration. The required  
│ providers were previously configured at main.tf:4,3-21.
╵
╷
│ Error: Duplicate provider configuration
│
│   on main_exercices1-2.tf line 10:
│   10: provider "random" {}
│
│ A default (non-aliased) provider configuration for "random" was already    
│ given at main.tf:10,1-18. If multiple configurations are required, set the 
│ "alias" argument for alternative configurations.
╵
╷
│ Error: Duplicate provider configuration
│
│   on main_exercices1-2.tf line 11:
│   11: provider "local" {}
│
│ A default (non-aliased) provider configuration for "local" was already     
│ given at main.tf:11,1-17. If multiple configurations are required, set the 
│ "alias" argument for alternative configurations.
╵
╷
│ Error: Duplicate module call
│
│   on main_exercices1-2.tf line 14:
│   14: module "pet_fleet" {
│
│ A module call named "pet_fleet" was already defined at main.tf:14,1-19.    
│ Module calls must have unique names within a module.
╵
╷
│ Error: Duplicate module call
│
│   on main_exercices1-2.tf line 28:
│   28: module "script_runner" {
│
│ A module call named "script_runner" was already defined at
│ main.tf:28,1-23. Module calls must have unique names within a module.      
╵
brahim@Brahim:/mnt/c/Users/er-co/Desktop/DEVOPS-Terraform/devops-terraform$ terraform plan
╷
│ Error: Duplicate required providers configuration
│
│   on main_exercices1-2.tf line 4, in terraform:
│    4:   required_providers {
│
│ A module may have only one required providers configuration. The required  
│ providers were previously configured at main.tf:4,3-21.
╵
╷
│ Error: Duplicate provider configuration
│
│   on main_exercices1-2.tf line 10:
│   10: provider "random" {}
│
│ A default (non-aliased) provider configuration for "random" was already    
│ given at main.tf:10,1-18. If multiple configurations are required, set the 
│ "alias" argument for alternative configurations.
╵
╷
│ Error: Duplicate provider configuration
│
│   on main_exercices1-2.tf line 11:
│   11: provider "local" {}
│
│ A default (non-aliased) provider configuration for "local" was already     
│ given at main.tf:11,1-17. If multiple configurations are required, set the 
│ "alias" argument for alternative configurations.
╵
╷
│ Error: Duplicate module call
│
│   on main_exercices1-2.tf line 14:
│   14: module "pet_fleet" {
│
│ A module call named "pet_fleet" was already defined at main.tf:14,1-19.    
│ Module calls must have unique names within a module.
╵
╷
│ Error: Duplicate module call
│
│   on main_exercices1-2.tf line 28:
│   28: module "script_runner" {
│
│ A module call named "script_runner" was already defined at
│ main.tf:28,1-23. Module calls must have unique names within a module.      
╵
brahim@Brahim:/mnt/c/Users/er-co/Desktop/DEVOPS-Terraform/devops-terraform$# Utilisation de terraform_data avec des provisioners pour chaque fichier
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

# Ressource séparée pour les commandes additionnelles (utilisation de dynamic)
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
