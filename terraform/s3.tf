# Create S3 bucket
resource "aws_s3_bucket" "demo_bucket" {
  bucket = "${var.project_name}-frontend-gouthami"
  tags = {
    Name = "${var.project_name}-frontend-gouthami"
  }
}

# Allow public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.demo_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Public read policy for static website
resource "aws_s3_bucket_policy" "newpolicy" {
  bucket = aws_s3_bucket.demo_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.demo_bucket.id}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

# Static website configuration (SPA)
resource "aws_s3_bucket_website_configuration" "static" {
  bucket = aws_s3_bucket.demo_bucket.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key="index.html"
  }
  }

