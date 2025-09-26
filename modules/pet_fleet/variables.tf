variable "pet_configs" {
  description = "Configuration pour chaque pet à générer"
  type = map(object({
    prefix    = string
    separator = string
  }))
  default = {
    "dev"  = { prefix = "dev", separator = "-" }
    "test" = { prefix = "test", separator = "_" }
    "prod" = { prefix = "prod", separator = "-" }
  }

  validation {
    condition = alltrue([
      for config in var.pet_configs : length(config.prefix) > 0
    ])
    error_message = "Tous les prefixes doivent être non vides."
  }

  validation {
    condition = alltrue([
      for config in var.pet_configs : contains(["-", "_"], config.separator)
    ])
    error_message = "Tous les separators doivent être '-' ou '_'."
  }
}

variable "output_directory" {
  description = "Répertoire de sortie pour les fichiers"
  type        = string
  default     = "./dist"
}
