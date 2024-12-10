provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Owner     = "ndeguchi-cloudshell"
      Terraform = "true"
    }
  }
}
