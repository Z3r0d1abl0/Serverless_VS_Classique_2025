variable "name" { type = string }

variable "description" { type = string }

variable "scope" { type = string } # "REGIONAL" ou "CLOUDFRONT"

variable "tags" { type = map(string) }

# Configuration des règles avancées
variable "enable_bot_protection" {
  description = "Activer la protection contre les bots (coût supplémentaire)"
  type        = bool
  default     = false
}

variable "blocked_countries" {
  description = "Codes pays à bloquer (format ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.blocked_countries) == 0 || alltrue([for c in var.blocked_countries : length(c) == 2])
    error_message = "Les codes pays doivent être au format ISO 3166-1 alpha-2 (2 caractères)."
  }
}

variable "blocked_user_agents" {
  description = "User-Agents suspects à bloquer"
  type        = list(string)
  default     = ["sqlmap", "nikto", "nmap", "masscan", "nessus"]
}

variable "common_rule_exclusions" {
  description = "Règles du Common Rule Set à exclure (mode count au lieu de block)"
  type        = list(string)
  default     = []
}

# Configuration de la limitation de taille
variable "enable_size_restrictions" {
  description = "Activer les restrictions de taille"
  type        = bool
  default     = true
}

variable "max_query_string_length" {
  description = "Longueur maximale autorisée pour les query strings"
  type        = number
  default     = 2048
}

variable "max_uri_length" {
  description = "Longueur maximale autorisée pour les URIs"
  type        = number
  default     = 512
}

# Rate limiting configurable
variable "rate_limit" {
  description = "Limite de requêtes par IP sur 5 minutes"
  type        = number
  default     = 1000
}