# Your daily sales file needs a bucket defined in Terraform
resource "aws_s3_bucket" "rag_data" {
  bucket = "${var.project_name}-rag-data"
}

resource "aws_s3_bucket_versioning" "rag_data" {
  bucket = aws_s3_bucket.rag_data.id
  versioning_configuration {
    status = "Enabled"   # Keeps history of daily file updates
  }
}