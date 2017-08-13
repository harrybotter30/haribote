Next: [harib00j](harib00j.md), Previous: [harib00h](harib00h.md), Up: [Chapter3](chapter3.md)

----

# Chapter3

## harib00i

### 課題

C 言語で OS を記述できるようにする。

今回から内部でプロテクトモードに切り替えるようになったが、それについては今回は学ばない。

### 学習

今回は何をするのか判らないローカルツールが大量に登場し手こずった。

#### Wine 導入

何をするのか判らないツールのソースを読み解ききれなかったため、ツールを [WineHQ](https://www.winehq.org/) で動かし、生成物とバイナリ比較して進めた。

[Debian unstable](https://www.debian.org/releases/sid/) の場合、[wine-development](https://packages.debian.org/sid/wine-development) を使うことで特に問題なく make.bat を動かすことができ、中間ファイルも含めすべてのファイルを入手できた。

#### asmhead.bin の作成

- ipl10 によりディスクイメージは 0x8000 にロードされている
- FAT12 の構造から先頭ファイルはディスク先頭から 0x4200 の位置に存在する
- メモリ上の 0x8000+0x4200==0xc200 に最初のファイルが存在する

よって asmhead.bin は 0xc200 にロードされることを想定して作成する。

asmhead.nas では ```ORG 0xc200``` としているが、[helloos3](helloos3.md#nasknasm%E3%81%A8-gas-%E3%81%AE-org-%E3%81%AF%E7%95%B0%E3%81%AA%E3%82%8B) で学んだようにこれは GAS の ```.org 0xc200``` に対応するわけではないので、asmhead.lds を作成して設定した。

#### haribote.hrb の作成

bootpack.o が ```_GLOBAL_OFFSET_TABLE_``` というシンボルを参照してしまう。  
-> [PIC のためのシンボル](https://stackoverflow.com/questions/9685699/what-is-global-offset-table)とのことだが、今回は不要なので CFLAGS に ```-fno-pic``` を追加して回避した。

```shell-session
$ make
cc -E   ipl10.S -o ipl10.s
as -al  ipl10.s -o ipl10.o >ipl10.lst
cc -E   asmhead.S -o asmhead.s
as -al  asmhead.s -o asmhead.o >asmhead.lst
cc    -c -o bootpack.o bootpack.c
ld  -T haribote.lds -o haribote.img ipl10.o
ld  -T asmhead.lds -o haribote.sys haribote.o bootpack.o
bootpack.o: In function `HariMain':
bootpack.c:(.text+0x9): undefined reference to `_GLOBAL_OFFSET_TABLE_'
Makefile:25: recipe for target 'haribote.sys' failed
make: *** [haribote.sys] Error 1
$ nm bootpack.o
00000000 T HariMain
         U _GLOBAL_OFFSET_TABLE_
00000000 T __x86.get_pc_thunk.ax
```

```shell-session
$ make
cc -E -fno-pic  ipl10.S -o ipl10.s
as -al  ipl10.s -o ipl10.o >ipl10.lst
cc -E -fno-pic  asmhead.S -o asmhead.s
as -al  asmhead.s -o asmhead.o >asmhead.lst
cc -fno-pic   -c -o bootpack.o bootpack.c
ld  -T haribote.lds -o haribote.img ipl10.o
ld  -T asmhead.lds -o haribote.sys haribote.o bootpack.o
$ nm bootpack.o
00000000 T HariMain
```

ローカルツールの利用により、暗黙に startup.o がリンクされていたので追加した。  
-> 当初生成されたコードが一致しなかったが CFLAGS に ```-Os``` を追加することで同一になった。

[『30日でできる！OS自作入門』のメモ](http://vanya.jp.net/os/haribote.html#gcchrb)を参考に、同一の haribote.hrb が生成できるよう、かなりアドホックに hrb.lds を作成した。

#### haribote.sys の作成

オリジナルに従い単純に連結した。

#### haribote.img の作成

Makefile によれば

- haribote.img の作成方法自体は harib00h から変わっていない。
- haribote.img の材料である ipl10.bin も変わっていない。
- もう一つの haribote.img の材料である haribote.sys の作成方法が変更された。

前述のようにここまでで ipl10.bin, haribote.sys は作成できているが、どちらも ELF ではなくなっている。
そのため、いままでのようにリンカスクリプトでディスクイメージの haribote.img を作ることができない。

[データファイルをバイナリに埋め込みたい - Linux関係メモ＠宇治屋電子](https://www.ujiya.net/linux/0107)によれば、objcopy コマンドを用いることで、任意のバイナリを ELF オブジェクトに変換することができる。

```shell-session
$ objcopy -Ibinary -Bi386 -Oelf32-i386 ipl10.bin boot.o
$ readelf -S boot.o
There are 5 section headers, starting at offset 0x2ec:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .data             PROGBITS        00000000 000034 000200 00  WA  0   0  1
  [ 2] .symtab           SYMTAB          00000000 000234 000050 10      3   2  4
  [ 3] .strtab           STRTAB          00000000 000284 000046 00      0   0  1
  [ 4] .shstrtab         STRTAB          00000000 0002ca 000021 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  p (processor specific)
```

Size == 0x200 というところからも ipl10.bin の内容は .data セクションに出力されているようだ。
同様に haribote.sys も ELF オブジェクトに変換して haribote.img を作成する。

オリジナルの haribote.img と比較したところ二ヶ所の相違が発生している。

##### 相違点1

ファイルオフセット 0x87 からの 3 バイト

- ```05 20 00```
- ```83 c0 20```

アセンブルリストファイルの段階で異なっている。

```Assembly
    64 00007C87 05 0020                         		ADD		AX,0x0020
```

```Assembly
  62 0087 83C020   		addw	$0x0020, %ax
```

しかし、どちらも AX に 0x0020 を加える命令なので挙動としては同一。

##### 相違点2

ファイルオフセット 0x2616 からの 4 バイト

- ```76 6d 05 4b```
- ```00 00 21 2a```

haribote.lds にあるようにタイムスタンプフィールドなので問題なし。
（haribote.lds では 2001/01/01 00:00:00 で固定）

### binutils のバグ？

2017/07/29 にインストールした binutils_2.29-1_i386.deb の ld ではクラッシュするようになった。

```shell-session
$ make
cc -E -fno-pic  ipl10.S -o ipl10.s
as -al  ipl10.s -o ipl10.o >ipl10.lst
cc -E -fno-pic  asmhead.S -o asmhead.s
as -al  asmhead.s -o asmhead.o >asmhead.lst
cc -fno-pic   -c -o bootpack.o bootpack.c
ld  -T haribote.lds -o haribote.img ipl10.o
Makefile:23: recipe for target 'haribote.img' failed
make: *** [haribote.img] Segmentation fault
make: *** Deleting file 'haribote.img'
$ dpkg -l binutils
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name                      Version           Architecture      Description
+++-=========================-=================-=================-=======================================================
ii  binutils                  2.29-1            i386              GNU assembler, linker and binary utilities
```

coredump 入手

```shell-session
$ ulimit -c unlimited
$ make
ld  -T haribote.lds -o haribote.img ipl10.o
Makefile:23: recipe for target 'haribote.img' failed
make: *** [haribote.img] Segmentation fault (core dumped)
make: *** Deleting file 'haribote.img'
```

どこでクラッシュしているか見る。

```shell-session
$ gdb /usr/bin/ld core
GNU gdb (Debian 7.12-6) 7.12.0.20161007-git
Copyright (C) 2016 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "i686-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from /usr/bin/ld...(no debugging symbols found)...done.

warning: core file may not match specified executable file.
[New LWP 959]
Core was generated by `ld -T haribote.lds -o haribote.img ipl10.o asmhead.o'.
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x004f2f34 in ?? ()
(gdb) where
#0  0x004f2f34 in ?? ()
#1  0x004e2c52 in ?? ()
#2  0x004cf463 in main ()
(gdb) quit
$ dpkg -l libc6-dbg
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name                      Version           Architecture      Description
+++-=========================-=================-=================-=======================================================
ii  libc6-dbg:i386            2.24-12           i386              GNU C Library: detached debugging symbols
```

libc6-dbg は入っているので ld の中でクラッシュしているらしい。
binutils-dbg はないので確認できない。

これ以上は追求困難なので以前に使用していた binutils_2.28-6_i386.deb にダウングレードして回避。

```shell-session
$ dpkg -l binutils
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name                      Version           Architecture      Description
+++-=========================-=================-=================-=======================================================
ii  binutils                  2.28-6            i386              GNU assembler, linker and binary utilities
$ make
ld  -T haribote.lds -o haribote.img ipl10.o
$ wc -c haribote.img
1474560 haribote.img
```

その後 binutils_2.29-3_i386.deb がリリースされていたのでアップデートで解決。

##### 参考

- [tools/obj2bim - hrb-wiki](http://hrb.osask.jp/wiki/?tools/obj2bim)
- [tools/bim2hrb - hrb-wiki](http://hrb.osask.jp/wiki/?tools/bim2hrb)
- [『30日でできる！OS自作入門』のメモ](http://vanya.jp.net/os/haribote.html#gcchrb)
- [データファイルをバイナリに埋め込みたい - Linux関係メモ＠宇治屋電子](https://www.ujiya.net/linux/0107)

### 成果

- [Makefile](/Makefile)
    - 新しいソースファイル追加: bootpack.c, startup.c
    - haribote.img 作成のルールを変更
    - haribote.sys 作成のルールを変更
    - 追加した一時ファイルを clean ターゲットで削除
- [asmhead.S](/asmhead.S)
    - haribote.S の名前を変えたもの
    - A20 line を有効化
    - プロテクトモードに切り替え
    - ipl10 で読み込んだ haribote.sys とディスクイメージを 0x00280000, 0x00100000 にコピー
- [asmhead.lds](/asmhead.lds)
    - binary.lds の名前を変えたもの
- [bootpack.c](/bootpack.c)
    - ループするだけでないもしない OS
- [haribote.lds](/haribote.lds)
    - FAT12 ディスクイメージを作成することのみを目的とする
- [hrb.lds](/hrb.lds)
    - bootpack.hrb を作成するためのリンカスクリプト
- [ipl10.S](/ipl10.S)
    - 誤ったボリュームラベルを訂正
- [ipl10.lds](/ipl10.lds)
    - ブートセクタを作成するためのリンカスクリプト
- [startup.c](/startup.c)
    - すべての実行形式で共通に関数を実行するためのエントリポイント

----

Next: [harib00j](harib00j.md), Previous: [harib00h](harib00h.md), Up: [Chapter3](chapter3.md)
