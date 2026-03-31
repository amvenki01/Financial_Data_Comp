# You said this runs as a daily job — needs a scheduler!
resource "aws_cloudwatch_event_rule" "daily_rag_job" {
  name                = "${var.project_name}-daily-trigger"
  description         = "Triggers RAG Lambda daily"
  schedule_expression = "cron(0 8 * * ? *)"  # Every day at 8:00 AM UTC
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_rag_job.name
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.main.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_rag_job.arn
}