# ── Lambda Deployment Package (your Python file) ──────────────
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"   # 👈 Your Python file
  output_path = "${path.module}/lambda_function.zip"
}

# ── Lambda Function ───────────────────────────────────────────
resource "aws_lambda_function" "main" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_execution.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = var.lambda_runtime
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 60
  memory_size      = 512

  # Deploy Lambda inside private subnet
  vpc_config {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.private.id]
  }

  environment {
    variables = {
      KNOWLEDGE_BASE_ID = "your-knowledge-base-id"   # 👈 Replace
      DATA_SOURCE_ID    = "your-data-source-id"       # 👈 Replace
      RAG_MODEL_ID      = "anthropic.claude-3-sonnet-20240229-v1:0"
      AWS_REGION_NAME   = var.aws_region
    }
  }

  tags = {
    Name    = var.lambda_function_name
    Project = var.project_name
  }
}

# ── Allow API Gateway to invoke Lambda ────────────────────────
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}