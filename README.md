# Atelier Terraform ➜ de 0 à Terragrunt (sans compte cloud)

Bienvenue ! Cet atelier est conçu pour fonctionner **sans compte chez un CSP** (pas de carte bancaire).
Nous utiliserons uniquement des providers _locaux_ : `random`, `local`, `null`, et `terraform` (pour `terraform_data`).

## Pré-requis
- Terraform ≥ 1.6 installé (pour `terraform test`).
- (Optionnel) Terragrunt ≥ 0.58 si vous faites l'étape 4.
- Bash/PowerShell disponibles pour exécuter quelques scripts locaux.

## Plan
1. **Exercice 1 — random_pet & dépendances**
2. **Exercice 2 — Tests & conditions (pre/postconditions, `terraform test`)**
3. **Exercice 3 — Modules & dynamic blocks**
4. **Exercice 4 — Basculer sur Terragrunt** (selon le modèle GCP Library)
5. **Exercice bonus — Commander une pizza Dominos… via Terraform** (simulation 😄)

> La correction complète se trouve dans `solution/`.

---

## Exercice 1 — random_pet & dépendances
Objectif : créer un nom de « pet » aléatoire puis l’écrire dans un fichier local.
- Utilisez le provider `random` et la ressource `random_pet`.
- Créez une dépendance logique pour écrire le nom dans un fichier (`local_file`) **après** la génération.
- Variables proposées : `prefix` (ex: *dev*), `separator` (ex: `-`).
- Sorties (`outputs`) : `pet_name`, `filename`.

Critères d’acceptation :
- `terraform init && terraform apply` crée un fichier `./dist/pet.txt` contenant le nom.
- Le nom respecte le pattern `<prefix><separator><pet>`.

---

## Exercice 2 — Tests & conditions
Objectif : sécuriser et valider votre config.
- Ajoutez des **preconditions** et **postconditions** :
  - `prefix` non vide, `separator` ∈ `-` ou `_`.
  - Postcondition : le contenu du fichier contient bien le nom généré.
- Ajoutez un dossier `tests/` avec un fichier `.tftest.hcl` qui :
  - appelle le module racine avec des variables de test ;
  - **assert** que `output.pet_name` matche le bon pattern.

Commandes utiles :
```bash
terraform validate
terraform test
```

---

## Exercice 3 — Modules & dynamic blocks
Objectif : factoriser et générer plusieurs artefacts.
- Créez un module `modules/pet_fleet` qui génère **N** pets et écrit **N** fichiers (un par pet).
- Utilisez `for_each` et des sorties agrégées (liste des noms, liste des fichiers).
- Ajoutez un module `modules/script_runner` utilisant `terraform_data` + un **dynamic block** pour générer autant de `provisioner "local-exec"` que nécessaire (une commande par fichier écrit).

> Remarque : les provisioners sont utilisés ici **uniquement** comme support pédagogique pour illustrer les `dynamic blocks`.

---

## Exercice 4 — Basculer sur Terragrunt (modèle GCP Library)
Objectif : réorganiser votre code avec [Terragrunt](https://blog.stephane-robert.info/docs/infra-as-code/provisionnement/terragrunt/) en reprenant **la structure suivante**.

Lisez le cours suivant sur terragrunt avant de commencer : [Terragrunt](https://blog.stephane-robert.info/docs/infra-as-code/provisionnement/terragrunt/)

Structure cible (exemple) :
```
terragrunt/
  terragrunt.hcl                  # config root (inputs communs, generate blocks)
  live/
    dev/
      app/
        pet/terragrunt.hcl        # pointe vers ../../../../modules/pet_fleet
    prod/
      app/
        pet/terragrunt.hcl
  modules/                         # modules terraform locaux réutilisés
```

- Le **root `terragrunt.hcl`** définit des `generate` pour créer des `provider.tf`/`backend.tf` (backend **local** dans cet atelier), et des `inputs` partagés (ex: `prefix`).
- Chaque `terragrunt.hcl` d’environnement référence le module local via `source = "../../modules/pet_fleet"` et passe ses `inputs`.
- Commandes : `cd terragrunt/live/dev/app/pet && terragrunt run-all apply`.

Si vous avez ouvert l’archive “GCP Library main.zip”, vous reconnaîtrez les conventions (arborescences **live/** & **modules/**, factorisation au root).

---

## Exercice 5 - Atelier — 3-Tier sur GCP (mocké) : LB ↔ VM ↔ DB

🎯 Objectif : modéliser une application 3-tier basique sur GCP :
réseau (VPC/Subnets/Firewall) → compute (VM/App) → DB (Cloud SQL) → Load Balancer HTTP.
✅ À chaque étape, vous écrirez au moins un test terraform test s’appuyant sur mock_provider "google", ce qui permet de tester sans créer de ressources réelles (Terraform ≥ 1.7 requis).Atelier — 3-Tier sur GCP (mocké) : LB ↔ VM ↔ DB

Étape 1 — Réseau : VPC, Subnet, Firewall

À faire :

	•	Créer un VPC custom : google_compute_network.vpc avec auto_create_subnetworks = false.
	•	Créer un Subnet régional : google_compute_subnetwork.app (ex. 10.10.0.0/20).
	•	Créer des règles firewall minimales :
	•	allow http (80) pour le trafic entrant vers l’app (via tags réseau).
	•	allow ssh (22) pour l’admin (optionnel).
	•	(Optionnel) règle pour health checks (ports/IPS des HC GCP) — vous pouvez vous limiter au port 80 côté test.

Test obligatoire tests/01-network.tftest.hcl

  Étape 2 — Compute (App) : Instance Template + MIG (1)

À faire :

	•	google_compute_instance_template.app (network+subnet, tag web).
	•	(Optionnel) startup script qui démarre un serveur HTTP simple sur :80.
	•	google_compute_region_instance_group_manager.app (target_size = 1).
	•	Définir un named port http:80 pour le backend (via MIG ou instance group selon approche).

Test obligatoire tests/02-compute.tftest.hcl

Étape 3 — DB : Cloud SQL (mocké)

À faire :

	•	google_sql_database_instance.db (ex. Postgres).
	•	database_version = "POSTGRES_13" (ou équivalent), settings.tier défini.
	•	google_sql_database.app (base applicative).
	•	google_sql_user.app (utilisateur applicatif).

Astuce : pour rester simple (et mock-friendly), ne gérez pas le Private IP ni le Serverless VPC dans un premier temps.

Test obligatoire tests/03-db.tftest.hcl

Étape 4 — Load Balancer HTTP (global)

À faire (modèle classique) :

	•	google_compute_health_check.http (HTTP sur / port 80).
	•	google_compute_backend_service.app (protocol HTTP, health_checks, port_name = “http”, backend = instance group/MIG).
	•	google_compute_url_map.default (default_service = backend).
	•	google_compute_target_http_proxy.default (url_map).
	•	google_compute_global_forwarding_rule.http (port 80, cible = proxy ; optionnel google_compute_global_address).

Test obligatoire tests/04-lb.tftest.hcl

Critères finaux (acceptation)

	•	L’architecture réseau → compute → db → lb est définie avec des ressources GCP cohérentes.
	•	Tous les tests passent localement via terraform test sans credentials GCP (car mock_provider).
	•	Les noms/labels sont paramétrables (préfixes d’environnement, région, etc.).
	•	Les outputs exposent au minimum : vpc_name, subnet_name, mig_name, db_instance_name, lb_rule_name.

```
# À la racine du projet
terraform fmt -recursive
terraform validate

# Lancer tous les tests
terraform test

# Ou étape par étape
terraform test -run network_basics
terraform test -run compute_mig_minimal
terraform test -run db_basics
terraform test -run lb_http_global
```

---

## Exercice bonus — Commander une pizza Dominos (simulation)
Pas d’API Terraform officielle pour Dominos, et pas d’achats réels ici.
But pédagogique : **modéliser** une ressource `pizza_order` et générer un **bon de commande** local (`order.json`) + une **commande shell** à lancer **manuellement** (simulation).

- Créez un module `modules/pizza_order` qui prend :
  - `store_code`, `customer`, `address`, `items` (liste d’objets `{product_code, qty}`) ;
  - génère `order.json` via `local_file` ;
  - expose un output `curl_command` (vers une URL fictive) affiché en fin d’apply.
- Ajoutez des `preconditions` (quantités > 0, items non vides).

---

## Démarrage rapide
```bash
# Dans chaque exercice :
terraform init
terraform apply -auto-approve

# Tests (ex2 & suivants) :
terraform test
```

Bon apprentissage ✨
