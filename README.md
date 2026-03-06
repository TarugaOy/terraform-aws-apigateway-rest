# Terraform AWS API Gateway Module

This Terraform module creates an AWS API Gateway with:

- Resources
- Methods
- Integrations
- CORS
- Deployment

## Usage

module "apigateway" {
  source = "git::https://github.com/your-org/terraform-aws-apigateway-module.git?ref=v1.0.0"

  api_name   = "event-api"
  stage_name = "dev"

  routes = [
    {
      path_part        = "events"
      http_method      = "GET"
      authorization    = "NONE"
      integration_type = "AWS_PROXY"
      integration_uri  = aws_lambda_function.get_events.invoke_arn
    }
  ]
}
