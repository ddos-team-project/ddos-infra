# 📘 Terraform 개발 가이드

## 개요 (Overview)

Terraform 표준 절차를 정의 해 운영 안정성과 협업 효율성을 보장

- 단일 State 파일(Monolithic) 방식 지양
- S3 Remote Backend 기반의 계층(Layer) 분리 구조를 채택

## 아키텍처 핵심 전략

### ① S3 Remote Backend (중앙 집중형 State)

---

로컬(`local`) 저장을 금지하고, 모든 인프라 상태(`tfstate`)를 AWS S3에서 암호화하여 관리함.

- **Storage:** S3 버킷 내 환경/레이어별 격리 저장 (Versioning 활성화).
- **Locking:** DynamoDB를 통한 State Locking 수행 (동시 실행 충돌 방지).

### ② Layered Architecture (계층 분리)

---

인프라를 변경 빈도와 의존성에 따라 4단계로 분리하여 운영 리스크 최소화.

- **폭발 반경 최소화 :** 상위 레이어(App) 배포 중 문제가 생겨도 하위 레이어(Network)에 영향을 미치지 않음.
- **배포 속도 향상 :** 전체 리소스 스캔 대신 해당 레이어만 스캔하여 속도 최적화.

---

## 프로젝트 구조 (Directory Structure)

```bash
terraform/
├── global/ 
├── modules/ 
└── environments/ 
    ├── seoul/              # Primary Region
    │   ├── 01-network/     # [Layer 1] VPC, TGW, VPN (Base Infra)
    │   ├── 02-data/        # [Layer 2] RDS, ElastiCache, MSK
    │   ├── 03-app/         # [Layer 3] EKS, API Gateway
    │   └── 04-front/       # [Layer 4] CloudFront, WAF
    └── tokyo/              # DR Region (서울과 동일 구조)
        ├── 01-network/     
        ├── 02-data/       
        ├── 03-app/      
        └── 04-front/ 
```

- **global :** S3 Backend, IAM과 같은 최초 1회 설정 후 전역 사용되는 리소스 위치
- **modules :** VPC, EKS, RDS와 같은 재사용 가능한 리소스 모듈 위치
- **environments :** 각 환경 State별로 실제 배포 환경 위치
    - 각 환경은 레이어를 4개층으로 분리
        - network : 리소스가 올라갈 기반환경, IDC와 Cloud간의 통로
        - data : 데이터 저장
        - app : 비즈니스 처리
        - front : 실제 사용자와의 접점

## State 관리 상세 (Backend Config)

모든 환경 디렉토리(`environments/*/*`)의 `backend.tf`는 아래 규칙을 준수해야 함.

- **Bucket:** `diehard-ddos-tf-state-lock`
- **DynamoDB:** `terraform-lock-table`
- **Key Pattern:** `{region}/{layer}/terraform.tfstate`

**작성 예시 (`environments/seoul/01-network/backend.tf`):**

```hcl
terraform {
  backend "s3" {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "seoul/01-network/terraform.tfstate" # ⚠️ 폴더 위치에 맞게 수정 필수
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
```

## 레이어 의존성 및 데이터 참조 (`remote_state`)

⚠ 상위 레이어는 하위 레이어의 outputs를 참조하는 단방향 의존성 구조로 반드시 **순차적으로 배포(01 → 04)**가 진행되어야 함.

### 구현 가이드 (Step-by-Step)

레이어 1에서 저장한 데이터를 레이어 3에서 사용하는 예시

---

#### Step 1. 데이터 제공자 (Layer 1: Network)

리소스를 생성하고 `outputs.tf`를 통해 값을 S3 State에 기록함.

- **File:** `environments/seoul/01-network/outputs.tf`
    
    ```hcl
    # VPC ID 내보내기
    output "vpc_id" {
      value = aws_vpc.main.id
    }
    
    # Subnet ID 리스트 내보내기
    output "private_subnet_ids" {
      value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    }
    ```
    
    > ⚠️ 중요: 코드 작성 후 반드시 `terraform apply`를 실행해야 S3에 값이 저장됨.
    > 

#### Step 2. 데이터 소비자 (Layer 3: App)

`terraform_remote_state`를 사용하여 Layer 1의 State 파일을 읽어옴.

- **File:** `environments/seoul/03-app/data.tf` (Backend 참조 설정)
    
    ```hcl
    data "terraform_remote_state" "network" {
      backend = "s3"
      config = {
        bucket = "diehard-ddos-tf-state-lock"
        key    = "seoul/01-network/terraform.tfstate" # Layer 1의 Key 경로와 일치해야 함
        region = "ap-northeast-2"
      }
    }
    ```
    
- **File:** `environments/seoul/03-app/main.tf` (실제 사용)
    
    ```hcl
    resource "aws_security_group" "app_sg" {
      name        = "finance-app-sg"
      
      # Remote State에서 VPC ID 가져와서 사용
      vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
    }
    ```
    

## 개발 워크플로우 (Workflow)

#### ✅ 기본 원칙

1. **Root 실행 금지:** 반드시 작업하려는 `environments/{region}/{layer}` 폴더로 이동 후 실행.
2. **State 커밋 금지:** `.tfstate`, `.terraform/` 폴더는 `.gitignore` 처리 (Git 업로드 금지).

#### 🚀 작업 순서

1. **작업 위치 이동:** `cd environments/seoul/02-data`
2. **초기화 (Init):** S3 Backend 연결 및 모듈 다운로드. `terraform init`
3. **계획 확인 (Plan):** 변경 사항 검토. `terraform plan`
4. **적용 (Apply):** 인프라 반영 및 State 업데이트. `terraform apply`

---

### 7. 트러블슈팅 (Troubleshooting)

#### Q. `Error acquiring the state lock`

- **상황:** 다른 팀원이 작업 중이거나 이전 작업이 비정상 종료되어 Lock이 걸림.
- **해결:**
    1. 팀 채널에 작업 중인 사람 확인.
    2. 확실히 작업자가 없다면 `terraform force-unlock <LockID>` 수행.

#### Q. `Unsupported attribute` (참조 에러)

- **상황:** `data.terraform_remote_state.network.outputs.vpc_id`를 찾을 수 없음.
- **원인:**
    1. 하위 레이어(`01-network`)의 `outputs.tf`에 `vpc_id`가 정의되지 않음.
    2. 정의는 했으나 `01-network`에서 `terraform apply`를 안 해서 S3에 값이 없음.
- **해결:** 하위 레이어 `outputs` 확인 및 `apply` 실행 후 재시도.

---

### 8. 명명 규칙 (Naming Convention)

리소스 식별 용이성을 위해 아래 규칙 준수 권장.

- **Format:** `{project}-{env}-{region}-{resource}-{usage}`
- **Example:**
    - `finance-prod-apn2-vpc-main` (서울 메인 VPC)
    - `finance-dev-apn2-rds-ledger` (서울 개발용 원장 DB)