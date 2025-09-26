variable "files_to_process" {
  description = "Liste des fichiers à traiter avec des commandes"
  type        = list(string)
  default     = []
}

variable "base_command" {
  description = "Commande de base à exécuter pour chaque fichier"
  type        = string
  default     = "echo 'Processing file:'"
}

variable "additional_commands" {
  description = "Commandes additionnelles par fichier"
  type        = map(list(string))
  default     = {}
}
