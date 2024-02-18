### 파일구조

Nest Js 프레임 워크를 사용하였습니다.

<img width="216" alt="스크린샷 2022-09-08 오후 2 44 09" src="https://user-images.githubusercontent.com/95579358/189049265-29aef875-4774-4508-9abf-f81b1421ce98.png">

Backend api를 위한 src 디렉토리의 구조는 아래와 같습니다.

auth는 로그인, 로그인 여부 확인과 같은 인증을 위한 디렉토리 입니다.

cart는 장바구니 / order는 주문 / purchase는 결제를 위한 디렉토리입니다.

<img width="317" alt="스크린샷 2022-09-08 오후 2 46 57" src="https://user-images.githubusercontent.com/95579358/189049290-7e88f657-caab-431d-ad23-6f79fff286ec.png">

### DB 설계 구조

<img width="838" alt="스크린샷 2022-09-08 오전 3 27 44" src="https://user-images.githubusercontent.com/95579358/189049355-e05be174-4e7e-48ec-9ddf-d03f6fd55cb5.png">

DB는 위와 같이 설계 하였습니다.

order_has_menu 는 주문과 메뉴 id를 매핑하는 테이블 입니다.

purchase_has_menu는 결제와 주문 id, 메뉴 id를 매핑하는 테이블 입니다.

order과 같은 경우 if_purchased 칼럼을 추가해 결제가 진행될 시, db에서 주문을 아예 삭제하지 않고 결제 여부를 확인하는 방향으로 설계 했습니다.

### 실행 화면

1. 회원 가입

   <img width="758" alt="스크린샷 2022-09-08 오후 2 03 54" src="https://user-images.githubusercontent.com/95579358/189049461-37f68de5-a87e-42aa-89ab-dd93b9d65e24.png">

   위와 같이 인풋 창에 회원 정보를 입력하고 가입을 클릭하면 db에 아래와 같이 저장 됩니다.

   <img width="425" alt="스크린샷 2022-09-08 오후 2 04 59" src="https://user-images.githubusercontent.com/95579358/189049499-1efaf226-b1eb-4bd7-a2de-d709d4a53bff.png">

   비밀번호는 bcrypt를 사용하여 암호화 하였습니다.

2. 로그인
   로그인을 클릭 하면 아래와 같이 쿠키에 토큰이 저장 됩니다.
   Jwt 토큰 및 passport를 활용하여 진행하였습니다.

<img width="806" alt="스크린샷 2022-09-08 오후 2 06 38" src="https://user-images.githubusercontent.com/95579358/189049637-e6ced6bb-4de7-45ac-957d-e23f6d19e96f.png">

3. 장바구니
   메뉴를 10개 보여줄 수 있는 화면을 구성하였습니다.
   CRUD api도 구현하였으나 시간상 화면 구현은 Create만 진행하였습니다.

   <img width="730" alt="스크린샷 2022-09-08 오후 2 07 30" src="https://user-images.githubusercontent.com/95579358/189049690-948382da-a670-4edf-b2c0-f508e9dd4b61.png">

   장바구니에 김치찌개를 3개 추가하기 버튼을 클릭하면 carts.json에 해당 내용이 저장됩니다. 실제 서비스라면 Redis를 사용하여 캐싱하겠지만 빠르게 만들기 위하여 json을 사용하였습니다.

   <img width="735" alt="스크린샷 2022-09-08 오후 2 08 26" src="https://user-images.githubusercontent.com/95579358/189049875-6f800ff9-8f58-405b-9ea1-88eae4b62de4.png">

   <img width="609" alt="스크린샷 2022-09-08 오후 2 08 52" src="https://user-images.githubusercontent.com/95579358/189050558-66df12c1-f290-4dba-8c06-7883d0d88691.png">

4. 주문하기

   <img width="730" alt="스크린샷 2022-09-08 오후 2 09 29" src="https://user-images.githubusercontent.com/95579358/189049970-1f13333d-5446-4d70-8b52-5500b662a5dd.png">

   주문하기를 클릭하면 아래와 같이 사용자의 id와 최종 가격을 포함한 내용이 저장 됩니다.

   <img width="554" alt="스크린샷 2022-09-08 오후 2 10 16" src="https://user-images.githubusercontent.com/95579358/189050026-15ffbc05-b446-44cc-910a-3e5b5516aa04.png">

   order_has_menu 테이블에 주문 id 및 메뉴 id 가 저장 됩니다.

   <img width="193" alt="스크린샷 2022-09-08 오후 2 10 45" src="https://user-images.githubusercontent.com/95579358/189050152-16d9048c-3491-4e11-9643-6e8333f1398f.png">

5. 결제하기

   <img width="727" alt="스크린샷 2022-09-08 오후 2 31 11" src="https://user-images.githubusercontent.com/95579358/189050213-ecbbe53c-0042-4b30-8e3e-448828996a0b.png">

   결제하기 버튼을 클릭하면 아래와 같이 저장 됩니다.

   canceled_at은 결제가 취소가 됐을 경우를 대비하여 추가하였습니다.

   <img width="459" alt="스크린샷 2022-09-08 오후 2 31 46" src="https://user-images.githubusercontent.com/95579358/189050276-5afcbb76-d1e0-4c25-b09c-b5efc16550b2.png">
