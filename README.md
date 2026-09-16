# chromux 설정

Claude Code 클라우드 세션에서 [chromux](https://www.npmjs.com/package/chromux)로
Chrome 탭을 자동 조작하기 위한 설정 스크립트입니다.

## 새 세션에서 쓰는 법

세션을 열고 Claude에게 이렇게 말하면 됩니다.

```
setup-chromux.sh 실행해줘
```

스크립트가 하는 일:

1. chromux 설치 (npm)
2. 화면 없는 서버용 Chromium 실행 래퍼 생성 (`~/.chromux/chrome-wrapper.sh`)
3. 프록시 인증서를 Chrome 신뢰 저장소에 등록 (없으면 HTTPS 사이트가 "Privacy error"로 막힘)
4. Chrome 재시작 후 네이버 접속 테스트

## 자주 쓰는 chromux 명령

```bash
chromux open news https://example.com   # 탭 열기
chromux snapshot news                   # 화면 요소를 번호와 함께 보기
chromux fill news @1 "검색어"           # 1번 입력창에 입력
chromux click news @2                   # 2번 버튼 클릭
chromux screenshot news shot.png        # 화면 캡처
chromux close news                      # 탭 닫기
```
