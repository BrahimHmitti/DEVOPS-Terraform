# Exercice 1 – Génération d’un nom aléatoire

## Objectif visé
Générer un nom aléatoire au format `<prefix><separator><pet>` et l’enregistrer dans un fichier local.

## Fichiers créés
- **main.tf** : configuration des providers et des ressources (`random_pet` + `local_file`).
- **variables.tf** : définition des variables `prefix` et `separator` avec valeurs par défaut.
- **outputs.tf** : publication des outputs `pet_name` et `filename`.

## Problèmes rencontrés
- Le dossier `dist/` n’existait pas : `local_file` ne crée pas automatiquement les répertoires.
- Première utilisation des providers Terraform : comprendre comment déclarer et initialiser `hashicorp/random` et `hashicorp/local`.
- Suivre le cycle Terraform (`init`, `plan`, `apply`) et bien saisir l’ordre d’exécution des ressources.

## Solution appliquée
1. Déclaration des providers dans `main.tf` :
   ```hcl
   terraform {
     required_version = ">= 1.6"
     required_providers {
       random = { source = "hashicorp/random", version = "~> 3.6" }
       local  = { source = "hashicorp/local",  version = "~> 2.5" }
     }
   }
   provider "random" {}
   provider "local" {}
   ```
2. Création du dossier `dist/` avant l’exécution :  
   ```bash
   mkdir -p dist
   ```
3. Ressource `random_pet` pour générer le nom :
   ```hcl
   resource "random_pet" "pet" {
     length    = 2
     prefix    = var.prefix
     separator = var.separator
   }
   ```
4. Ressource `local_file` pour écrire dans `dist/pet.txt` :
   ```hcl
   resource "local_file" "pet_file" {
     filename = "${path.module}/dist/pet.txt"
     content  = random_pet.pet.id
   }
   ```
5. Déclaration des variables dans `variables.tf` et des outputs dans `outputs.tf`.
6. Commandes Terraform sous WSL :
   ```bash
   terraform init
   terraform apply -auto-approve
   cat dist/pet.txt
   ```

## Apprentissage et pertinence
- **Provider vs resource** : chaque provider (ici `random` et `local`) expose un ensemble de ressources spécialisées.
- **Cycle Terraform** : `init` pour installer les plugins, `apply` pour exécuter les actions, `state` pour suivre l’infrastructure.
- **Dépendances implicites** : `local_file` attend la valeur de `random_pet` avant de s’exécuter.
- **Organisation du code** : séparation claire entre configuration (`main.tf`), variables (`variables.tf`) et outputs (`outputs.tf`).
- **Bonus :** J'ai ajouté deux ressources, `random_password` et `random_integer`, pour mieux comprendre le fonctionnement. En essayant d’ajouter le mot de passe aux outputs, j’ai découvert que Terraform le considère comme sensible, ce qui bloque l’`apply`. J’ai appris que, si l’on souhaite malgré tout exposer cet output, il faut ajouter l’attribut `sensitive = true