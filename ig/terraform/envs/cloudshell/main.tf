# module "network" {
#   source      = "../../modules/network"
#   name_prefix = local.name_prefix
# }
# 
# module "lambda" {
#   source            = "../../modules/lambda"
#   name_prefix       = local.name_prefix
#   account_id        = data.aws_caller_identity.current.account_id
#   vpc_id            = module.network.vpc01_id
#   subnet_id_01      = module.network.vpc01_private_subnet01_id
#   subnet_id_02      = module.network.vpc01_private_subnet02_id
#   security_group_id = module.network.vpc01_lambda_sg_id
#   backend_url       = module.backend_mock.backend_url
# }
# 
# module "apigw" {
#   source             = "../../modules/apigw"
#   name_prefix        = local.name_prefix
#   account_id         = data.aws_caller_identity.current.account_id
#   access_from_vpc_id = "vpc-0bd7ecd9bd53b4ed4"
# }
# 
# module "backend_mock" {
#   source             = "../../modules/backend_mock"
#   name_prefix        = local.name_prefix
#   account_id         = data.aws_caller_identity.current.account_id
#   access_from_vpc_id = module.network.vpc01_id
# }

module "iam" {
  source = "../../modules/iam"
}

module "route53" {
  source = "../../modules/route53"
  ig_no  = local.ig_no
}

module "dynamodb" {
  source = "../../modules/dynamodb"
  ig_no  = local.ig_no
}

module "s3" {
  source = "../../modules/s3"
  ig_no  = local.ig_no
}


