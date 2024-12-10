resource "aws_s3_bucket" "terraform" {
  bucket = "ndeguchi-${var.ig_no}-terraform"
}
