data "aws_caller_identity" "current" {}

locals {
  current_account_id = data.aws_caller_identity.current.account_id
}
