Next: [harib00a](harib00a.md), Previous: [helloos4](helloos4.md), Up: [Chapter2](chapter2.md)

----

# Chapter2

## helloos5

### 課題

Makefile を使用して開発環境を管理する。

### 学習

Makefile は大体知っていた。

オリジナルの Makefile があまり普通ではないように思えたので、普通の
Makefile にした。互換のためオリジナルのターゲットも残してある。

リスティングファイルを出力したかったので %.o: %.S を上書きした。

いままで run.bat 用の実行環境は用意していなかったが、run ターゲットの
動作確認のために qemu 環境も用意してみた。  
\# install ターゲットの確認はできていない

不要になった asm スクリプトは削除した。

```shell-session
$ make realclean
rm -f ipl.s ipl.o ipl.lst *~
rm -f helloos.img
$ make
cc -E   ipl.S -o ipl.s
as -al  ipl.s -o ipl.o >ipl.lst
ld -T helloos.lds -o helloos.img ipl.o
$ git show 01/helloos0:helloos.img | cmp - helloos.img
$ make
make: Nothing to be done for 'all'.
```

### 成果

- [Makefile](/Makefile)
    - 開発環境管理用 Makefile

----

Next: [harib00a](harib00a.md), Previous: [helloos4](helloos4.md), Up: [Chapter2](chapter2.md)
