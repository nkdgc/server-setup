resource "aws_dynamodb_table" "terraform" {
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "LockID"
  name                        = "ndeguchi-${var.ig_no}-terraform"
  read_capacity               = 0
  stream_enabled              = false
  table_class                 = "STANDARD"
  write_capacity              = 0

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = false
  }
}
