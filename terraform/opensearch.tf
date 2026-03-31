# Bedrock Knowledge Base needs a vector store to save embeddings
resource "aws_opensearchserverless_collection" "main" {
  name = "${var.project_name}-vectors"
  type = "VECTORSEARCH"
}

resource "aws_opensearchserverless_access_policy" "main" {
  name  = "${var.project_name}-access-policy"
  type  = "data"
  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.project_name}-vectors"]
        Permission   = ["aoss:*"]
      },
      {
        ResourceType = "index"
        Resource     = ["index/${var.project_name}-vectors/*"]
        Permission   = ["aoss:*"]
      }
    ]
    Principal = [aws_iam_role.bedrock_knowledge_base.arn]
  }])
}

resource "aws_opensearchserverless_security_policy" "encryption" {
  name  = "${var.project_name}-encryption"
  type  = "encryption"
  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.project_name}-vectors"]
    }]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  name  = "${var.project_name}-network"
  type  = "network"
  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.project_name}-vectors"]
      },
      {
        ResourceType = "dashboard"
        Resource     = ["collection/${var.project_name}-vectors"]
      }
    ]
    AllowFromPublic = true
  }])
}


