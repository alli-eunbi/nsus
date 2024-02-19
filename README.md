### 애플리케이션 관련 설명

1. Nest JS를 사용한 이유는 빠르게 개발하기 위해 사용하였습니다.
2. 애플리케이션과 Dockerfile은 app 디렉토리에 정의되어 있습니다.

### CI Workflow 구성

1. .github 디렉토리에 workflow를 정의 하였습니다.
2. argocd/order-values.yaml에 태그를 업데이트 하는 스크립트가 포함되어 있습니다.

### ArgoCD 설정

1. App of Apps 패턴을 사용하여 클러스터 생성시 필요한 앱들이 한꺼번에 배포되도록 설정하였습니다.
2. argocd/app-of-apps.yaml 은 apps 디렉토리에 있는 app들을 배포 하도록 합니다.
3. 배포되는 앱들은 아래와 같습니다.
   - metric-server
   - alb-controller
   - 애플리케이션(order)

### Terraform 설정

1. ap-northeast-2a, ap-northeast-2c 에 각각 public 및 private 서브넷을 구성하였습니다.
2. 클러스터는 "t3.medium" 인스턴스를 최소 2개, 최대 3개까지 배포되도록 설정하였습니다.
3. 이외의 RDS나 보안그룹등을 설정 하였습니다.
4. main.tf에 있는 모듈들을 분리하고 보안적 측면을 높이려 하였으나 시간이 부족하여 생략하였습니다.

### Helm Chart 설정

1. 생성한 Helm chart는 /base 디렉토리에 있습니다.
2. HTTPS Ingress는 alb로 연결하여 설정하였습니다.
3. EBS 볼륨은 /manifest 디렉토리에 storage-class와 pvc.yaml로 정의 하고 order-values.yaml에 mount 했습니다.

#### 실제 운영환경과 다르게 설정한 부분 (금액 및 시간 상 생략)

1. IAM 을 사용에 맞게 나누고 각각 권한을 다르게 줬을 것.
2. EKS에 대한 접근 권한을 public access로 외부에서 접근 가능하게 설정하진 않았을 것.
3. prometheus를 사용하여 metric-server로 수집된 정보들을 모니터링 했을 것.
4. namespace를 서비스마다 구분하고 권한을 따로 부여 했을 것.
5. argocd 에서 배포 시 슬랙 혹은 email 알람이 가도록 설정 했을 것.
6. affinity, toleration/taint 설정으로 서비스마다 노드 그룹 설정을 다르게 했을 것.
