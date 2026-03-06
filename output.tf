output "api_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "invoke_url" {
  value = aws_api_gateway_stage.stage.invoke_url
}

output "custom_domain" {
  value = try(aws_api_gateway_domain_name.domain[0].domain_name, null)
}

output "api_key_value" {
  value     = try(aws_api_gateway_api_key.api_key[0].value, null)
  sensitive = true
}