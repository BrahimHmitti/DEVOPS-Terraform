# Exercice 3 - Modules & Dynamic Blocks

## Structure créée

```
modules/
├── pet_fleet/
│   ├── main.tf      # Génération de N pets avec for_each
│   ├── variables.tf # Configuration des pets
│   └── outputs.tf   # Sorties agrégées
└── script_runner/
    ├── main.tf      # terraform_data + dynamic provisioners
    ├── variables.tf # Configuration des scripts
    └── outputs.tf   # Résultats d'exécution

main_modules.tf      # Configuration racine utilisant les modules
outputs_modules.tf   # Outputs agrégés de l'exercice 3
tests/modules.tftest.hcl # Tests des modules
```

## Commandes d'exécution

```bash
# 1. Tester avec la configuration modules
terraform init
terraform validate

# 2. Planification avec la nouvelle configuration
terraform plan -var-file="terraform.tfvars" -out="modules.tfplan"

# 3. Application
terraform apply "modules.tfplan"

# 4. Vérification des résultats
ls -la dist/pet_*.txt
terraform output

# 5. Tests automatisés
terraform test tests/modules.tftest.hcl

# 6. Alternative : utiliser directement main_modules.tf
mv main.tf main_old.tf
mv main_modules.tf main.tf
mv outputs.tf outputs_old.tf  
mv outputs_modules.tf outputs.tf

terraform plan
terraform apply -auto-approve
```

## Fonctionnalités démontrées

### Module pet_fleet
- **for_each** sur une map de configurations
- **Validations** sur collections avec `alltrue()`
- **Sorties agrégées** avec transformations
- **Lifecycle hooks** dans un module

### Module script_runner  
- **terraform_data** avec triggers
- **Dynamic blocks** pour provisioners
- **Iterator personalizado** (file)
- **Conditional creation** avec count

### Configuration racine
- **Module calls** avec dépendances
- **Output chaining** entre modules
- **Complex variable passing**

## Résultats attendus

- 4 fichiers créés : `pet_development.txt`, `pet_testing.txt`, `pet_production.txt`, `pet_staging.txt`
- Chaque fichier contient un nom au format `prefix_separator_animal_separator_animal`
- Scripts exécutés pour traiter chaque fichier
- Sorties agrégées disponibles via `terraform output`
