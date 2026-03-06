variable "api_name" {
  type = string
}

variable "stage_name" {
  type    = string
  default = "dev"
}

variable "routes" {
  description = "API route definitions"

  type = list(object({
    path              = string
    method            = string
    authorization     = string
    integration_type  = string
    integration_uri   = string
  }))
}

variable "enable_cors" {
  type    = bool
  default = true
}

variable "enable_logging" {
  type    = bool
  default = true
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "custom_domain_enabled" {
  type    = bool
  default = false
}

variable "domain_name" {
  type    = string
  default = null
}

variable "certificate_arn" {
  type    = string
  default = null
}

variable "base_path" {
  type    = string
  default = ""
}

variable "enable_api_key" {
  type    = bool
  default = false
}

variable "api_key_name" {
  type    = string
  default = null
}

variable "usage_plan_name" {
  type    = string
  default = "default-usage-plan"
}

variable "throttle_rate_limit" {
  type    = number
  default = 100
}

variable "throttle_burst_limit" {
  type    = number
  default = 200
}

variable "quota_limit" {
  type    = number
  default = 10000
}

variable "quota_period" {
  type    = string
  default = "MONTH"
}

variable "waf_acl_arn" {
  type    = string
  default = null
}