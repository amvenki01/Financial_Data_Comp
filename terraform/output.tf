output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private Subnet ID"
  value       = aws_subnet.private.id
}

output "public_security_group_id" {
  description = "Public Security Group ID"
  value       = aws_security_group.public.id
}

output "private_security_group_id" {
  description = "Private Security Group ID"
  value       = aws_security_group.private.id
}

output "bedrock_kb_role_arn" {
  description = "Bedrock Knowledge Base IAM Role ARN"
  value       = aws_iam_role.bedrock_knowledge_base.arn
}

output "bedrock_invoke_role_arn" {
  description = "Bedrock Model Invoke IAM Role ARN"
  value       = aws_iam_role.bedrock_model_invoke.arn
}

output "lambda_role_arn" {
  description = "Lambda Execution IAM Role ARN"
  value       = aws_iam_role.lambda_execution.arn
}

output "lambda_function_arn" {
  description = "Lambda Function ARN"
  value       = aws_lambda_function.main.arn
}

output "api_gateway_url" {
  description = "API Gateway Endpoint URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/prod/query"
}
```

---

