# Exercice 3 – Modules & Dynamic blocks

## Objectif visé
Factoriser la configuration Terraform avec des modules réutilisables et des blocs dynamiques. Générer plusieurs artefacts en utilisant `for_each`, des modules personnalisés, et `terraform_data` avec provisioners.

## Fichiers créés/modifiés

### Structure des modules créés
```
modules/
├── pet_fleet/
│   ├── main.tf       # Ressources avec for_each pour générer N pets
│   ├── variables.tf  # Variables d'entrée du module
│   └── outputs.tf    # Outputs agrégés du module
└── script_runner/
    ├── main.tf       # terraform_data avec provisioners
    ├── variables.tf  # Variables pour les commandes et fichiers
    └── outputs.tf    # Résumé d'exécution des scripts
```

### Configuration racine modifiée
- **main.tf** : remplacement des ressources individuelles par des appels de modules
- **outputs.tf** : agrégation des outputs des modules
- **tests/modules.tftest.hcl** : nouveau fichier de tests pour valider les modules

## Problèmes rencontrés & Solutions

### 1. Conflits de configuration duplicate
**Problème** : Erreurs `"Duplicate required providers configuration"` et `"Duplicate module call"`
```bash
Error: Duplicate module call
A module call named "pet_fleet" was already defined at main.tf:14,1-19.
```

**Cause** : Présence du fichier `main_exercices1-2.tf` contenant des configurations en double.

**Solution appliquée** :
```powershell
Remove-Item main_exercices1-2.tf
```

### 2. Syntaxe des provisioners dynamiques
**Problème initial** : Tentative d'utiliser `dynamic "provisioner"` (syntaxe invalide)
```hcl
#  INCORRECT - Les provisioners ne supportent pas les blocs dynamiques
dynamic "provisioner" {
  for_each = var.files_to_process
  content {
    "local-exec" {
      command = "${var.base_command} ${provisioner.value}"
    }
  }
}
```

**Solution correcte** : Utilisation de `for_each` sur `terraform_data`
```hcl
#  CORRECT - for_each sur la ressource terraform_data
resource "terraform_data" "script_runner" {
  for_each = toset(var.files_to_process)
  
  triggers_replace = {
    file = each.value
    base_command = var.base_command
  }
  
  provisioner "local-exec" {
    command = "${var.base_command} ${each.value} && echo 'Traitement de ${each.value} terminé'"
    on_failure = continue
  }
}
```

### 3. Migration des tests pour les nouveaux outputs
**Problème** : Tests référençant les anciens outputs `output.pet_name` et `output.filename` 

**Solution** : Mise à jour pour utiliser les outputs des modules
```hcl
# Avant (Exercice 2)
condition = can(regex("^test-[a-z]+-[a-z]+$", output.pet_name))

# Après (Exercice 3)
condition = can(regex("^test_[a-z]+_[a-z]+$", output.fleet_pet_names.testing))
```

## Implémentation des modules

### Module `pet_fleet` - Génération multiple avec for_each

#### **modules/pet_fleet/main.tf**
```hcl
# Précondition au niveau du module
resource "random_pet" "fleet" {
  for_each = var.pet_configs
  
  length    = 2
  prefix    = each.value.prefix
  separator = each.value.separator

  lifecycle {
    precondition {
      condition     = length(each.value.prefix) > 0
      error_message = "Le préfixe pour l'environnement '${each.key}' ne peut pas être vide."
    }
    
    precondition {
      condition     = contains(["-", "_"], each.value.separator)
      error_message = "Le séparateur pour l'environnement '${each.key}' doit être '-' ou '_'."
    }
  }
}

# Génération des fichiers correspondants
resource "local_file" "pet_files" {
  for_each = var.pet_configs

  filename = "${var.output_directory}/pet_${each.key}.txt"
  content  = random_pet.fleet[each.key].id

  lifecycle {
    postcondition {
      condition     = self.content == random_pet.fleet[each.key].id
      error_message = "Le contenu du fichier '${self.filename}' ne correspond pas au pet généré."
    }
  }
}
```

#### **modules/pet_fleet/variables.tf**
```hcl
variable "pet_configs" {
  description = "Configuration pour chaque environnement"
  type = map(object({
    prefix    = string
    separator = string
  }))
  
  validation {
    condition = alltrue([
      for config in values(var.pet_configs) : 
      contains(["-", "_"], config.separator)
    ])
    error_message = "Tous les séparateurs doivent être '-' ou '_'."
  }
}

variable "output_directory" {
  description = "Répertoire de sortie pour les fichiers"
  type        = string
  default     = "./dist"
}
```

#### **modules/pet_fleet/outputs.tf**
```hcl
# Outputs agrégés avec transformation
output "pet_names" {
  description = "Noms des pets générés par environnement"
  value       = {
    for env, pet in random_pet.fleet : env => pet.id
  }
}

output "pet_files" {
  description = "Chemins des fichiers générés"
  value       = {
    for env, file in local_file.pet_files : env => file.filename
  }
}

output "pet_count" {
  description = "Nombre total de pets générés"
  value       = length(random_pet.fleet)
}

output "pets_formatted" {
  description = "Liste formatée de tous les noms de pets"
  value       = join(", ", [
    for pet in random_pet.fleet : pet.id
  ])
}
```

### Module `script_runner` - Provisioners avec terraform_data

#### **modules/script_runner/main.tf**
```hcl
# Utilisation de terraform_data avec for_each pour chaque fichier
resource "terraform_data" "script_runner" {
  for_each = toset(var.files_to_process)
  
  triggers_replace = {
    file = each.value
    base_command = var.base_command
  }
  
  provisioner "local-exec" {
    command = "${var.base_command} ${each.value} && echo 'Traitement de ${each.value} terminé'"
    on_failure = continue
  }
}

# Ressource séparée pour les commandes additionnelles
resource "terraform_data" "additional_scripts" {
  count = length(var.additional_commands) > 0 ? 1 : 0
  
  triggers_replace = {
    commands = jsonencode(var.additional_commands)
  }
  
  provisioner "local-exec" {
    command = join(" && ", flatten([
      for cmd_group in values(var.additional_commands) : cmd_group
    ]))
    on_failure = continue
  }
}
```

#### **modules/script_runner/variables.tf**
```hcl
variable "files_to_process" {
  description = "Liste des fichiers à traiter"
  type        = list(string)
}

variable "base_command" {
  description = "Commande de base à exécuter sur chaque fichier"
  type        = string
  default     = "echo 'Processing file'"
}

variable "additional_commands" {
  description = "Commandes supplémentaires groupées par catégorie"
  type        = map(list(string))
  default     = {}
}
```

#### **modules/script_runner/outputs.tf**
```hcl
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
```

### Configuration racine - Orchestration des modules

#### **main.tf** (version finale)
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "random" {}
provider "local" {}

# Module de génération de la flotte de pets
module "pet_fleet" {
  source = "./modules/pet_fleet"
  
  pet_configs = {
    "development" = { prefix = "dev", separator = "-" }
    "testing"     = { prefix = "test", separator = "_" }
    "production"  = { prefix = "prod", separator = "-" }
    "staging"     = { prefix = "stage", separator = "_" }
  }
  
  output_directory = "./dist"
}

# Module de traitement des fichiers générés
module "script_runner" {
  source = "./modules/script_runner"
  
  files_to_process = values(module.pet_fleet.pet_files)
  base_command     = "echo 'Contenu du fichier pet'"
  
  additional_commands = {
    validation = [
      "echo 'Validation des fichiers générés'",
      "ls -la ./dist/pet_*.txt || true",
      "wc -l ./dist/pet_*.txt || true"
    ]
  }
  
  depends_on = [module.pet_fleet]
}
```

### Tests automatisés

#### **tests/modules.tftest.hcl** - Tests spécifiques aux modules
```hcl
# Test du module pet_fleet
run "test_pet_fleet_module" {
  assert {
    condition = length(output.fleet_pet_names) == 4
    error_message = "Le module pet_fleet devrait générer 4 pets"
  }
  
  assert {
    condition = output.pet_names_count == 4
    error_message = "Le compteur de pets devrait être 4"
  }
  
  assert {
    condition = can(output.fleet_pet_files.development)
    error_message = "Le fichier pour development devrait exister"
  }
}

# Test des patterns générés par les modules
run "test_pet_patterns_from_modules" {
  assert {
    condition = can(regex("^dev-[a-z]+-[a-z]+$", output.fleet_pet_names.development))
    error_message = "Pattern development invalide: ${output.fleet_pet_names.development}"
  }
  
  assert {
    condition = can(regex("^test_[a-z]+_[a-z]+$", output.fleet_pet_names.testing))
    error_message = "Pattern testing invalide: ${output.fleet_pet_names.testing}"
  }
  
  assert {
    condition = can(regex("^prod-[a-z]+-[a-z]+$", output.fleet_pet_names.production))
    error_message = "Pattern production invalide: ${output.fleet_pet_names.production}"
  }
  
  assert {
    condition = can(regex("^stage_[a-z]+_[a-z]+$", output.fleet_pet_names.staging))
    error_message = "Pattern staging invalide: ${output.fleet_pet_names.staging}"
  }
}
```

## Commandes exécutées et résultats

### 1. Résolution des conflits
```powershell
# Suppression du fichier de conflit
PS C:\Users\er-co\Desktop\DEVOPS-Terraform\DEVOPS-Terraform> Remove-Item main_exercices1-2.tf
```

### 2. Validation et initialisation
```bash
brahim/Desktop/DEVOPS-Terraform/devops-terraform
$ terraform validate
Success! The configuration is valid.

brahim/Desktop/DEVOPS-Terraform/devops-terraform
$ terraform init
Initializing the backend...
Initializing modules...
Initializing provider plugins...
- etc ...

Terraform has been successfully initialized!
```

### 3. Planification et application
```bash
brahim/DEVOPS-Terraform/devops-terraform
$ terraform plan
# Plan: 13 to add, 0 to change, 6 to destroy.

brahim/DEVOPS-Terraform/devops-terraform
$ terraform apply -auto-approve
# Création réussie de tous les modules et ressources
Apply complete! Resources: 13 added, 0 changed, 6 destroyed.
```

### 4. Outputs générés
```bash
brahimDesktop/DEVOPS-Terraform/devops-terraform
$ terraform output
all_pet_names_formatted = "dev-discrete-moose, prod-flowing-cougar, stage_sacred_titmouse, test_enormous_monitor"
fleet_pet_files = {
  "development" = "./dist/pet_development.txt"
  "production" = "./dist/pet_production.txt"
  "staging" = "./dist/pet_staging.txt"
  "testing" = "./dist/pet_testing.txt"
}
fleet_pet_names = {
  "development" = "dev-discrete-moose"
  "production" = "prod-flowing-cougar"
  "staging" = "stage_sacred_titmouse"
  "testing" = "test_enormous_monitor"
}
pet_names_count = 4
script_execution_summary = {
  ....
  }
  "files_list" = tolist([
    "./dist/pet_development.txt",
    "./dist/pet_production.txt",
    "./dist/pet_staging.txt",
    "./dist/pet_testing.txt",
  ])
  "files_processed" = 4
}
```

### 5. Vérification des fichiers créés
```bash
brahim/Desktop/DEVOPS-Terraform/devops-terraform$ ls -la dist/
total 0
drwxrwxrwx 1 brahim brahim 4096 Sep 26 16:23 .
drwxrwxrwx 1 brahim brahim 4096 Sep 26 16:23 ..
-rwxrwxrwx 1 brahim brahim   18 Sep 26 16:23 pet_development.txt
-rwxrwxrwx 1 brahim brahim   19 Sep 26 16:23 pet_production.txt
-rwxrwxrwx 1 brahim brahim   21 Sep 26 16:23 pet_staging.txt
-rwxrwxrwx 1 brahim brahim   21 Sep 26 16:23 pet_testing.txt
```

### 6. Résultats des tests complets
```bash
brahim@Brahim:/mnt/c/Users/er-co/Desktop/DEVOPS-Terraform/devops-terraform$ terraform test

tests/modules.tftest.hcl... in progress
  run "test_pet_fleet_module"... pass
  run "test_pet_patterns_from_modules"... pass
tests/modules.tftest.hcl... tearing down
tests/modules.tftest.hcl... pass

tests/pet_name.tftest.hcl... in progress
  run "validate_pet_name_pattern"... pass
tests/pet_name.tftest.hcl... tearing down
tests/pet_name.tftest.hcl... pass

tests/validation.tftest.hcl... in progress
  run "test_empty_prefix_should_fail"... pass
  run "test_invalid_separator_should_fail"... pass
  run "test_valid_config_should_pass"... pass
tests/validation.tftest.hcl... tearing down
tests/validation.tftest.hcl... pass

Success! 6 passed, 0 failed.
```

## Apprentissages et bonnes pratiques

### **Architecture modulaire**
- **Réutilisabilité** : les modules peuvent être utilisés dans d'autres projets avec des paramètres différents
- **Encapsulation** : chaque module a ses propres variables, outputs et logique interne
- **Composition** : orchestration de plusieurs modules dans la configuration racine

### **Patterns `for_each` avancés**
- **Map iteration** : `for_each = var.pet_configs` pour itérer sur une map d'objets
- **Set iteration** : `for_each = toset(var.files_to_process)` pour éviter les doublons
- **Références croisées** : `random_pet.fleet[each.key].id` pour référencer d'autres ressources

### **terraform_data et provisioners**
- **Replacement triggers** : `triggers_replace` pour forcer la recréation basée sur les inputs
- **Error handling** : `on_failure = continue` pour la robustesse
- **Provisioner limitations** : pas de support pour les blocs `dynamic`

### **Output aggregation et transformation**
- **For expressions dans outputs** : transformation et filtrage des données
- **Outputs composés** : combinaison de données de plusieurs ressources
- **Formatting** : `join()` et autres fonctions pour la présentation

### **Testing modulaire**
- **Tests par fichier** : séparation logique des tests par fonctionnalité
- **Validation de patterns** : regex pour valider les formats attendus
- **Tests d'intégration** : validation du fonctionnement inter-modules

### **Gestion des dépendances**
- **depends_on explicite** : `depends_on = [module.pet_fleet]` pour l'ordre d'exécution
- **Références implicites** : `values(module.pet_fleet.pet_files)` crée une dépendance automatique
- **Module coupling** : balance entre réutilisabilité et fonctionnalité

## Points clés retenus

1. **Modularité = Réutilisabilité** : les modules permettent de factoriser la logique et de la réutiliser
2. **for_each > count** : plus flexible pour gérer des collections d'objets complexes
3. **terraform_data** : solution moderne pour les tâches de provisioning et triggers personnalisés
4. **Outputs structurés** : facilitent l'intégration entre modules et la consommation des données
5. **Tests exhaustifs** : validation à la fois des modules individuels et de leur intégration
6. **Lifecycle hooks dans modules** : préconditions et postconditions fonctionnent aussi dans les modules
7. **Dependencies matter** : gestion explicite des dépendances pour l'ordre d'exécution correct

## Migration depuis l'Exercice 2

La transition de ressources individuelles vers une architecture modulaire démontre :
- **Scalabilité** : de 1 pet à N pets avec la même logique
- **Maintainabilité** : modification centralisée dans les modules
- **Testabilité** : tests spécifiques par module + tests d'intégration
- **Évolutivité** : ajout de nouveaux environnements par simple configuration
