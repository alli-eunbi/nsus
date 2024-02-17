# nsus

앤서스랩

### Todo

base에 있는 모듈 정리
cluster version 주석처리 해제 및 버전 수정
metric server 설치

### 실제 운영환경과 다르게 설정한 부분 (금액 및 시간 상 생략)

1. IAM 을 사용에 맞게 나누고 각각 권한을 다르게 줬을 것.
2. EKS에 대한 접근 권한을 public access로 외부에서 접근 가능하게 설정하진 않았을 것.
3. prometheus를 사용하여 metric-server로 수집된 정보들을 모니터링 했을 것.
4. namespace를 서비스마다 구분하고 권한을 따로 부여 했을 것.
5. argocd 에서 배포 시 슬랙 혹은 email 알람이 가도록 설정 했을 것.
