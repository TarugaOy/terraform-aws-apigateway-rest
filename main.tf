data "aws_region" "current" {}

##################################
# API Gateway
##################################

resource "aws_api_gateway_rest_api" "api" {
  name = var.api_name
}

##################################
# Resources
##################################

resource "aws_api_gateway_resource" "resource" {

  for_each = {
    for r in var.routes :
    r.path => r
  }

  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = replace(each.value.path, "/", "")
}

##################################
# Methods
##################################

resource "aws_api_gateway_method" "method" {

  for_each = local.route_map

  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource[each.value.path].id
  http_method   = upper(each.value.method)
  authorization = each.value.authorization
}

##################################
# Integrations
##################################

resource "aws_api_gateway_integration" "integration" {

  for_each = local.route_map

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[each.value.path].id
  http_method = aws_api_gateway_method.method[each.key].http_method

  integration_http_method = "POST"
  type                    = each.value.integration_type
  uri                     = each.value.integration_uri
}

##################################
# CORS
##################################

resource "aws_api_gateway_method" "cors" {

  count = var.enable_cors ? length(var.routes) : 0

  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = element(values(aws_api_gateway_resource.resource)[*].id, count.index)
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors" {

  count = var.enable_cors ? length(var.routes) : 0

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = element(values(aws_api_gateway_resource.resource)[*].id, count.index)
  http_method = "OPTIONS"
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\":200}"
  }
}

##################################
# Deployment
##################################

resource "aws_api_gateway_deployment" "deployment" {

  depends_on = [
    aws_api_gateway_integration.integration
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
}

##################################
# CloudWatch Logs
##################################

resource "aws_cloudwatch_log_group" "apigw_logs" {

  count = var.enable_logging ? 1 : 0

  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = var.log_retention_days
}

##################################
# API Gateway Stage
##################################

resource "aws_api_gateway_stage" "stage" {

  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = var.stage_name

  access_log_settings {

    destination_arn = aws_cloudwatch_log_group.apigw_logs[0].arn

    format = jsonencode({
      requestId    = "$context.requestId"
      ip           = "$context.identity.sourceIp"
      requestTime  = "$context.requestTime"
      httpMethod   = "$context.httpMethod"
      resourcePath = "$context.resourcePath"
      status       = "$context.status"
    })
  }
}

resource "aws_api_gateway_domain_name" "domain" {

  count = var.custom_domain_enabled ? 1 : 0

  domain_name = var.domain_name

  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "mapping" {

  count = var.custom_domain_enabled ? 1 : 0

  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  domain_name = aws_api_gateway_domain_name.domain[0].domain_name
  base_path   = var.base_path
}

resource "aws_api_gateway_api_key" "api_key" {

  count = var.enable_api_key ? 1 : 0

  name    = var.api_key_name
  enabled = true
}

resource "aws_api_gateway_usage_plan" "usage_plan" {

  count = var.enable_api_key ? 1 : 0

  name = var.usage_plan_name

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }

  throttle_settings {
    rate_limit  = var.throttle_rate_limit
    burst_limit = var.throttle_burst_limit
  }

  quota_settings {
    limit  = var.quota_limit
    period = var.quota_period
  }
}

resource "aws_api_gateway_usage_plan_key" "plan_key" {

  count = var.enable_api_key ? 1 : 0

  key_id        = aws_api_gateway_api_key.api_key[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan[0].id
}

resource "aws_wafv2_web_acl_association" "apigw_waf" {

  count = var.waf_acl_arn != null ? 1 : 0

  resource_arn = aws_api_gateway_stage.stage.arn
  web_acl_arn  = var.waf_acl_arn
}