# Exercice 2 – Tests & Conditions

## Objectif visé
Sécuriser et valider la configuration Terraform avec des preconditions, postconditions, validations sur variables et tests automatisés.

## Fichiers créés/modifiés
- **main.tf** : ajout de `lifecycle` avec `precondition` et `postcondition`.
- **variables.tf** : ajout de blocs `validation` sur les variables.
- **tests/pet_name.tftest.hcl** : test de validation du pattern de sortie.
- **tests/validation.tftest.hcl** : tests d'échec des validations et test de succès.

## Problèmes rencontrés
- **Syntaxe des fichiers .tftest.hcl** : première utilisation des tests Terraform avec des erreurs de syntaxe initiales (`terraform` block non autorisé, `variables = {}` au lieu de `variables {}`).
- **Postcondition avec fonction `file()`** : erreur "function returned an inconsistent result" car la fonction `file()` ne peut pas lire un fichier qui sera créé par une ressource dans la même configuration.
- **Référence aux attributs dans les conditions** : confusion entre `filename` et `self.filename` dans les messages d'erreur.

## Solutions appliquées

### 1. Preconditions dans `random_pet`
```hcl
resource "random_pet" "pet" {
  length    = 2
  prefix    = var.prefix
  separator = var.separator

  lifecycle {
    precondition {
      condition     = length(var.prefix) > 0
      error_message = "prefix ne peut pas être vide."
    }
  }
}
```

### 2. Postconditions dans `local_file` (version corrigée)
```hcl
resource "local_file" "pet_file" {
  filename = "${path.module}/dist/pet.txt"
  content  = random_pet.pet.id

  lifecycle {
    postcondition {
      condition     = self.content == random_pet.pet.id
      error_message = "Le contenu écrit '${self.content}' n'est pas égal au nom généré '${random_pet.pet.id}'."
    }
  }
}
```

### 3. Validations sur variables dans `variables.tf`
```hcl
variable "prefix" {
  type        = string
  description = "Préfixe du nom"
  default     = "dev"

  validation {
    condition     = length(var.prefix) > 0
    error_message = "Le préfixe ne doit pas être vide."
  }
}

variable "separator" {
  type        = string
  description = "Séparateur"
  default     = "-"

  validation {
    condition     = contains(["-", "_"], var.separator)
    error_message = "Le séparateur doit être '-' ou '_'."
  }
}
```

### 4. Tests automatisés
#### **tests/pet_name.tftest.hcl** - Test de pattern
```hcl
variables {
  prefix    = "test"
  separator = "-"
}

run "validate_pet_name_pattern" {
  assert {
    condition = can(regex("^test-[a-z]+-[a-z]+$", output.pet_name))
    error_message = "Le pet_name '${output.pet_name}' ne respecte pas le pattern '^test-[a-z]+-[a-z]+$'"
  }

  assert {
    condition = output.filename != null
    error_message = "Le filename ne doit pas être null"
  }
}
```

#### **tests/validation.tftest.hcl** - Tests d'échec et succès
```hcl
variables {
  prefix    = ""
  separator = "-"
}

run "test_empty_prefix_should_fail" {
  command = plan
  expect_failures = [
    var.prefix,
  ]
}

run "test_invalid_separator_should_fail" {
  command = plan
  
  variables {
    prefix    = "test"
    separator = "|"
  }
  
  expect_failures = [
    var.separator,
  ]
}

run "test_valid_config_should_pass" {
  command = apply

  variables {
    prefix    = "prod"
    separator = "_"
  }

  assert {
    condition = can(regex("^prod_[a-z]+_[a-z]+$", output.pet_name))
    error_message = "Pattern invalide pour prod_: ${output.pet_name}"
  }
}
```

### 5. Commandes de validation exécutées
```bash
# Validation de la syntaxe
terraform validate

# Tests automatisés
terraform test

# Tests manuels des validations
terraform plan -var="prefix="              # ✅ Échec attendu
terraform plan -var="separator=|"          # ✅ Échec attendu
terraform apply -var="prefix=test" -auto-approve
cat dist/pet.txt | grep -E "^test-[a-z]+-[a-z]+$"  # ✅ Pattern respecté
```

## Apprentissages et pertinence

### **Lifecycle Management**
- **Preconditions** : valident les inputs avant l'exécution de la ressource. Pratique pour vérifier que les paramètres respectent des contraintes métier.
- **Postconditions** : valident les outputs après création de la ressource. Attention aux limitations de la fonction `file()` qui ne peut pas lire les fichiers créés par la même configuration.

### **Variable Validation**
- Bloc `validation` dans les variables : permet de définir des règles métier au niveau des inputs.
- Fonctions utiles : `length()`, `contains()`, `can()`, `regex()`.
- Messages d'erreur explicites pour guider l'utilisateur.

### **Tests Terraform **
- Syntaxe `run` avec `command = plan|apply`.
- `expect_failures` pour tester que les validations échouent correctement.
- `assert` pour vérifier les outputs avec des conditions logiques.
- `variables` block pour surcharger les valeurs par défaut.

### **Debugging et résolution de problèmes**
- **Erreur postcondition** : `file()` vs `self.content` - utiliser les attributs de la ressource plutôt que lire le fichier.
- **Syntaxe tests** : différence entre l'ancienne syntaxe `test` et la nouvelle `run`.
- **Messages d'erreur** : utiliser `self.attribute` dans les lifecycle rules.

## Résultats des tests

```bash
Success! 4 passed, 0 failed.
```

- ✅ **validate_pet_name_pattern** - Pattern du nom généré respecté
- ✅ **test_empty_prefix_should_fail** - Validation prefix vide fonctionne
- ✅ **test_invalid_separator_should_fail** - Validation separator invalide fonctionne  
- ✅ **test_valid_config_should_pass** - Configuration valide appliquée avec succès

## Points clés retenus
1. **Sécurité par design** : les validations empêchent les erreurs dès la phase de planification.
2. **Tests automatisés** : permettent de valider les comportements attendus et les cas d'erreur.
3. **Lifecycle hooks** : préconditions et postconditions renforcent la robustesse des ressources.
4. **Fonction `file()` limitée** : ne peut lire que les fichiers présents dans la configuration source, pas ceux créés dynamiquement.
5. **Terraform Test** : fonctionnalité puissante pour la validation continue des configurations.
