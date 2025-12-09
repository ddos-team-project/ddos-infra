# Layer 1 (Network) 상태 참조
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "seoul/01-network/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
