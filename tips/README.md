# git

## git config

```shell
git config user.email "github이메일"
git config user.name "github닉네임"
```

global 안붙이면 폴더별로 다르게 할 수 있음

## github 토큰

```shell
ls -al ~/.ssh

ssh-keygen -t ed25519 -C "이메일" // 키 생성됨
cat ~/.ssh/id_ed25519.pub
```

cat 결과를 복사해서 github 개인키에 넣으면 인증됨

## rebase

```shell
git rebase -i HEAD~3
```

상위 3개 커밋 합치기 -> 맨 위에꺼만 pick, 나머지는 s(squash) 후 저장

# Linux

```shell
grep -rin "검색어" . --include="*.java"
grep -rn "검색어" . --include="*.{java,xml,c,h}"
grep -rn "검색어" . --include="*.java" --include="*.xml"
```

- **`n`**: 단어가 발견된 **줄 번호**를 함께 출력.
- **`i`**: **대소문자를 구분하지 않고** 검색
- **`l`**: 코드는 보여주지 않고, 해당 단어가 포함된 **파일 이름만** 출력
- include로 확장자를 제한하면 검색이 더 빠름

```shell
ls -l backup/copy/ | grep ^- | wc -l // 특정 디렉터리 파일 몇개 있나 세기
```

```shell
tcpdump -i eth0 -s 0 -w ./capture1205.pcap
```

eth0를 지나가는 모든 패킷을, 내용 잘림 없이, 조건 없이 싹 다 저장

-s 0은 패킷의 **헤더(머리말)뿐만 아니라 바디(실제 데이터 내용)까지 자르지 말고 전체(Unlimited)를 저장하라는 옵션. snapshot len이다.

```bash
# 사용법: tar -zcvf [압축파일명.tar.gz] [압축할폴더/파일]
tar -zcvf archive.tar.gz my_folder/
# 사용법: tar -zxvf [압축파일명.tar.gz]
tar -zxvf archive.tar.gz
```

```kotlin
du -sh * # 현재 폴더 내 모든 파일과 폴더의 개별 용량 확인
du -h --max-depth=1 | sort -hr # 용량 큰 순서대로 정렬해서 보기
```

용량 확인하기

## WSL

```kotlin
C:\Users\chan>wsl --user root

[Root 비밀번호 변경 시]
root@PC:/mnt/c/Users/chan# passwd
New password:
Retype new password:
passwd: password updated successfully
```

wsl root 비번 초기화