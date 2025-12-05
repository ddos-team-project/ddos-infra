data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"         # 🔥 수정필요
    key    = "seoul/01-network/terraform.tfstate" # 🔥 수정필요
    region = "ap-northeast-2"
  }
}
