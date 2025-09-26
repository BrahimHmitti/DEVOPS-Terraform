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