resource "aws_route53_zone" "ndeguchi_com" {
  name          = "${var.ig_no}.ndeguchi.com"
  comment       = "${var.ig_no}.ndeguchi.com"
  force_destroy = false
}
