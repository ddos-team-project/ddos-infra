# Layer 1 (Network) 상태 참조 - Tokyo
data "terraform_remote_state" "network_tokyo" {
  backend = "s3"

  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "tokyo/01-network/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
