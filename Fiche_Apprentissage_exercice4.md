# Exercice 4 – Terragrunt (modèle GCP Library)

## Objectif visé
Réorganiser le code Terraform avec Terragrunt en adoptant une architecture DRY (Don't Repeat Yourself - ne te repète pas) inspirée du modèle GCP Library. Séparer la logique métier (modules) de l'instanciation par environnement (live configurations).

## Architecture et philosophie Terragrunt

### Principe DRY appliqué
- **Modules réutilisables** : Code Terraform défini une seule fois dans `/modules`
- **Configurations par environnement** : Instanciation spécifique dans `/live/{env}`
- **Configuration partagée** : Éléments communs définis au niveau racine
- **Generate blocks** : Génération automatique de fichiers (`provider.tf`, `backend.tf`)

### Structure implémentée
```
terragrunt/
├── terragrunt.hcl                    # Configuration racine (generate blocks, inputs communs)
├── .gitignore                        # Cache Terragrunt et fichiers générés
├── live/                             # Configurations par environnement (live configs)
│   ├── dev/
│   │   └── app/
│   │       ├── pet/terragrunt.hcl    # Instance du module pet_fleet pour dev
│   │       └── script/terragrunt.hcl # Instance du module script_runner pour dev
│   └── prod/
│       └── app/
│           ├── pet/terragrunt.hcl    # Instance du module pet_fleet pour prod
│           └── script/terragrunt.hcl # Instance du module script_runner pour prod
└── modules/                          # Modules Terraform réutilisables (copiés depuis Exercice 3)
    ├── pet_fleet/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── script_runner/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Implémentation des configurations

### Configuration racine - `terragrunt/terragrunt.hcl`
```hcl
# Configuration Terragrunt racine - Exercice 4
# Cette configuration définit les éléments communs à tous les environnements

# Génération automatique du fichier provider.tf
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
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
EOF
}

# Génération automatique du fichier backend.tf 
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "local" {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}
EOF
}

# Inputs communs partagés entre tous les environnements
inputs = {
  # Préfixes par défaut 
  output_directory = "./dist"
  
  # Commandes communes pour le script_runner
  base_command = "echo 'Processing file with Terragrunt'"
  
  additional_commands = {
    validation = [
      "echo 'Validation des fichiers générés avec Terragrunt'",
      "ls -la ./dist/pet_*.txt || echo 'No files found yet'",
      "wc -l ./dist/pet_*.txt || echo 'No files to count yet'"
    ]
  }
}
```

### Configuration Dev - `live/dev/app/pet/terragrunt.hcl`
```hcl
# Configuration Terragrunt pour l'environnement DEV
# Ce fichier définit l'instanciation du module pet_fleet pour dev

# Inclusion de la configuration racine
include "root" {
  path = find_in_parent_folders()
}

# Source du module Terraform à utiliser
terraform {
  source = "../../../../modules/pet_fleet"
}

# Inputs spécifiques à l'environnement dev
inputs = {
  pet_configs = {
    "development" = { prefix = "dev", separator = "-" }
    "testing"     = { prefix = "test", separator = "_" }
  }
  
  output_directory = "./dist"
}
```

### Configuration Prod - `live/prod/app/pet/terragrunt.hcl`
```hcl
# Configuration Terragrunt pour l'environnement PROD
# Ce fichier définit l'instanciation du module pet_fleet pour prod

# Inclusion de la configuration racine
include "root" {
  path = find_in_parent_folders()
}

# Source du module Terraform à utiliser
terraform {
  source = "../../../../modules/pet_fleet"
}

# Inputs spécifiques à l'environnement prod
inputs = {
  pet_configs = {
    "production"  = { prefix = "prod", separator = "-" }
    "staging"     = { prefix = "stage", separator = "_" }
  }
  
  output_directory = "./dist"
}
```

### Configuration avec dépendances - `live/dev/app/script/terragrunt.hcl`
```hcl
# Configuration Terragrunt pour le module script_runner DEV
# Ce module dépend du module pet_fleet et traite les fichiers générés

# Inclusion de la configuration racine
include "root" {
  path = find_in_parent_folders()
}

# Source du module Terraform à utiliser
terraform {
  source = "../../../../modules/script_runner"
}

# Dépendance sur le module pet_fleet
dependency "pet_fleet" {
  config_path = "../pet"
  
  # Mock outputs pour les tests/plans avant apply
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    pet_files = {
      "development" = "./dist/pet_development.txt"
      "testing"     = "./dist/pet_testing.txt"
    }
  }
}

# Inputs spécifiques au script_runner dev
inputs = {
  files_to_process = values(dependency.pet_fleet.outputs.pet_files)
  base_command     = "echo '[DEV] Contenu du fichier pet avec Terragrunt'"
  
  additional_commands = {
    dev_validation = [
      "echo '[DEV] Validation des fichiers générés'",
      "find ./dist -name 'pet_*.txt' -exec basename {} \\;",
      "echo 'Dev environment processing completed'"
    ]
  }
}
```

## Installation et commandes

### Installation de Terragrunt dans WSL
```bash
# Télécharger Terragrunt v0.88.0
curl -L -o terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v0.88.0/terragrunt_linux_amd64

# Rendre exécutable et installer
chmod +x terragrunt
sudo mv terragrunt /usr/local/bin/

# Vérifier l'installation
terragrunt --version
```

### Commandes Terragrunt exécutées

#### 1. Test de validation par environnement
```bash
# Environnement dev
cd terragrunt/live/dev/app/pet
wsl terragrunt validate
wsl terragrunt plan

# Environnement prod  
cd terragrunt/live/prod/app/pet
wsl terragrunt validate
wsl terragrunt plan
```

#### 2. Déploiement par module
```bash
# Déploiement du pet_fleet prod
cd terragrunt/live/prod/app/pet
wsl terragrunt apply -auto-approve

# Déploiement du script_runner prod (avec dépendance)
cd ../script
wsl terragrunt plan
wsl terragrunt apply -auto-approve
```

#### 3. Déploiement par stack (run-all)
```bash
# Planification complète de l'environnement
cd terragrunt/live/dev
wsl terragrunt run-all plan

# Déploiement complet avec dépendances
wsl terragrunt run-all apply --terragrunt-non-interactive
```

## Résultats obtenus

### Déploiement complet PROD avec dépendances
```bash
# Résolution automatique des dépendances par Terragrunt
The stack at /mnt/c/Users/er-co/Desktop/DEVOPS-Terraform/DEVOPS-Terraform/terragrunt/live/prod/app will be processed in the following order for command 'terragrunt run-all apply':
  Group 1
  - Module /mnt/c/Users/er-co/Desktop/DEVOPS-Terraform/DEVOPS-Terraform/terragrunt/live/prod/app/pet
  
  Group 2
  - Module /mnt/c/Users/er-co/Desktop/DEVOPS-Terraform/DEVOPS-Terraform/terragrunt/live/prod/app/script

# Résultats pet_fleet PROD
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
pet_files = {
  "production" = "./dist/pet_production.txt"
  "staging" = "./dist/pet_staging.txt"
}
pet_files_list = [
  "./dist/pet_production.txt",
  "./dist/pet_staging.txt",
]
pet_names = {
  "production" = "prod-balanced-ocelot"
  "staging" = "stage_composed_emu"
}
pet_names_list = [
  "prod-balanced-ocelot",
  "stage_composed_emu",
]

# Résultats script_runner PROD (avec dépendance)
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
execution_summary = {
  "additional_scripts" = "fbfae965-bcbd-5bab-de0d-4eb4f79b042a"
  "execution_ids" = {
    "./dist/pet_production.txt" = "ad81a76b-afda-eeee-2c5f-896fffa8cd54"
    "./dist/pet_staging.txt" = "2b835e47-9010-3dc9-770f-5a32803d4349"
  }
  "files_list" = [
    "./dist/pet_production.txt",
    "./dist/pet_staging.txt",
  ]
  "files_processed" = 2
}
```

### Environnement DEV déployé avec succès
```bash
# Déploiement run-all dev également fonctionnel
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs similaires avec les noms spécifiques dev:
- "dev-cunning-whale"
- "test_live_cheetah"
```

## Avantages de Terragrunt démontrés

### 1. DRY (Don't Repeat Yourself)
- **Code unique** : Modules définis une seule fois dans `/modules`
- **Configuration partagée** : Providers et backends générés automatiquement
- **Inputs communs** : Variables partagées au niveau racine

### 2. Gestion des environnements
- **Séparation claire** : `/live/dev` vs `/live/prod`
- **Configuration spécifique** : Paramètres différents par environnement
- **Promotions d'infrastructure** : Même module, paramètres différents

### 3. Gestion des dépendances
- **Dependencies explicites** : `dependency "pet_fleet"` dans script_runner
- **Mock outputs** : Tests possibles avant déploiement des dépendances
- **Order résolution** : Terragrunt détermine l'ordre d'exécution automatiquement

### 4. Opérations à grande échelle
- **run-all** : Déploiement de stacks complètes
- **Parallel execution** : Modules indépendants exécutés en parallèle
- **State isolation** : Chaque module a son propre state

## Comparaison avec l'Exercice 3

Structure : L'Exercice 3 utilise une approche monolithique où tout le code est centralisé dans un fichier main.tf, tandis que l'Exercice 4 adopte une structure modulaire organisée par environnement avec des dossiers séparés pour chaque contexte de déploiement.

Réutilisabilité : Dans l'Exercice 3, les modules sont appelés une seule fois dans la configuration principale, alors qu'avec Terragrunt dans l'Exercice 4, les mêmes modules peuvent être instanciés plusieurs fois pour différents environnements sans duplication de code.



## Points clés retenus

1. **Architecture scalable** : Terragrunt facilite la gestion de multiples environnements
2. **DRY réel** : Plus de duplication de code entre environnements
3. **Dependencies intelligentes** : Résolution automatique de l'ordre d'exécution
4. **Generate blocks** : Injection de configuration sans modification des modules
5. **Workflow GitOps** : Structure idéale pour les pipelines CI/CD
6. **State management** : Isolation et sécurité renforcées
7. **Learning curve** : Concepts supplémentaires mais ROI élevé à grande échelle

## Problèmes rencontrés et résolution

### 1. Corruption de fichiers lors de la migration
**Problème** : Le fichier `terragrunt/modules/script_runner/main.tf` s'est retrouvé corrompu avec des logs d'erreur Terraform au lieu du code HCL.

**Symptômes** :
```bash
Error: Invalid character
│   on main.tf line 1, character 1:
│   1: ╷
│     
│ This character is not used within the language.
```

**Cause** : Copie accidentelle des messages d'erreur Terraform (avec caractères │, ╷, ╵) dans le fichier source.

**Solution** :
```bash
# Nettoyage du cache Terragrunt
wsl rm -rf terragrunt/live/prod/app/script/.terragrunt-cache
wsl rm -rf terragrunt/modules/script_runner/.terragrunt-cache

# Recréation complète du fichier main.tf
# Validation après correction
wsl terragrunt validate
wsl terragrunt plan
```

### 2. Gestion du cache Terragrunt
**Leçon** : Terragrunt maintient des caches locaux (`.terragrunt-cache/`) qui peuvent causer des incohérences.

**Bonnes pratiques** :
- Nettoyer le cache après des modifications manuelles : `rm -rf .terragrunt-cache/`
- Utiliser `terragrunt validate` systématiquement après édition
- Le cache est spécifique à chaque environnement (`live/dev/`, `live/prod/`)

### 3. Références entre modules
**Attention** : Les outputs dans `outputs.tf` doivent correspondre exactement aux ressources dans `main.tf`.

**Exemple de correction** :
```hcl
# outputs.tf - Référence correcte
output "execution_summary" {
  value = {
    files_processed = length(var.files_to_process)
    files_list = var.files_to_process
    execution_ids = { for k, v in terraform_data.script_runner : k => v.id }
    additional_scripts = try(terraform_data.additional_scripts[0].id, null)
  }
}
```

## Migration réussie

✅ **From Terraform → Terragrunt** : Modules préservés, architecture repensée
✅ **Multi-environment** : dev et prod séparés et fonctionnels
✅ **Dependencies** : script_runner dépend correctement de pet_fleet
✅ **DRY achieved** : Zéro duplication de code Terraform
✅ **Operations** : validate, plan, apply, run-all fonctionnent
✅ **Enterprise ready** : Structure adaptée aux grandes organisations
✅ **Troubleshooting** : Problèmes de corruption résolus avec méthodes reproductibles
✅ **Stack deployment** : Déploiement complet des 2 environnements (4 modules total)

## Commandes de dépannage utiles

### Diagnostics Terragrunt
```bash
# Vérification de la structure des dépendances
terragrunt run-all plan --terragrunt-non-interactive

# Nettoyage complet des caches
find . -name ".terragrunt-cache" -type d -exec rm -rf {} +

# Validation de tous les modules
terragrunt run-all validate

# État des déploiements
terragrunt run-all output
```

### Gestion des erreurs communes
```bash
# "Invalid character" → Fichier corrompu
1. Vérifier le contenu avec cat/type
2. Nettoyer le cache : rm -rf .terragrunt-cache/  
3. Revalider : terragrunt validate

# "Mock outputs" manquants → Dépendances
1. Vérifier dependency block dans terragrunt.hcl
2. Ajouter mock_outputs si nécessaire
3. Tester avec : terragrunt plan

# "Module not found" → Chemins source  
1. Vérifier terraform.source relatif
2. Confirmer structure modules/ vs live/
3. Re-init si nécessaire : terragrunt init
```
