# Layer 1 (Network) 상태 참조 - Tokyo
data "terraform_remote_state" "network_tokyo" {
  backend = "s3"

  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "tokyo/01-network/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# Layer 2 (Data) 상태 참조 - Seoul (Global Cluster ID를 가져오기 위함)
data "terraform_remote_state" "data_seoul" {
  backend = "s3"

  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "seoul/02-data/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
