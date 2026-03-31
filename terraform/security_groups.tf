# ── Public Security Group (allows all inbound traffic) ────────
resource "aws_security_group" "public" {
  name        = "${var.project_name}-public-sg"
  description = "Allow all inbound traffic for public subnet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow all inbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-public-sg"
    Project = var.project_name
  }
}

# ── Private Security Group (allows traffic from public SG only)
resource "aws_security_group" "private" {
  name        = "${var.project_name}-private-sg"
  description = "Allow traffic only from public subnet resources"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow inbound from public security group"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.public.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-private-sg"
    Project = var.project_name
  }
}