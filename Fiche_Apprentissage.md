# Apprentissages

## Titre

Court résumé de l’objectif visé

### Problème rencontré et pourquoi il est survenu

### Solution appliquée et pourquoi cette solution a fonctionnée

### Apprentissage et pourquoi c’est pertinent dans mon

## Valider l’écriture du pet dans le fichier

Dans le TP terraform, l’Exercice 2 demande de vérifier en post condition que j’ai bien la bonne valeur de pet-name dans le fichier

### Post-condition est insuffisant

Il ne m’est pas possible explicitement de valider l’écriture de la valeur via postcondition dans le fichier. l’utilisation du bloc post-condition dans la resource random_pet ne m’aide pas pour récupérer la valeur dans le fichier

### Je passe par un datasource local_file

Après avoir créé le fichier via une resource “local_file”, je fais une datasource local_file du même fichier pour demander à terraform d’ouvrir le fichier dans lequel il a écrit et d’afficher la valeur.

### Je peux vérifier la valeur d’une resource par postcondition ou par datasource

Je sais que je peux utiliser une postcondition https://spacelift.io/blog/terraform-precondition-postcondition#verify-the-vpc-cidr-block dans une datasource pour assert la valeur d’une resource.

L’output me donne un message d’erreur que j’ai définit. La ressource est créé mais l’utilisateur voit l’erreur et peut adapter son code.

Je pense qu’il est plus judicieux de vérifier les données d’entrées avant la création de la ressource pour gagner du temps de création de la ressource et les possibles effets de bord s’il y a des ressources qui dépendent de celle erronée.

Je préfèrerais donc toujours mettre une precondition sur la ressource et des conditions sur les variables entrées par l’utilisateur