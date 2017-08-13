Next: [harib01a](harib01a.md), Previous: [harib00i](harib00i.md), Up: [Chapter3](chapter3.md)

----

# Chapter3

## harib00j

### 課題

OS を hlt できるようにする。

### 学習

#### hlt する関数の作成

OS 機能を実現するために C からアセンブリ言語の関数を呼び出せるようにする。

適当な C 関数を作成し、-S オプションでアセンブリ言語ソースを出力させて確認する。
それによれば gcc から呼び出す関数を gas で記述する場合、以下のようにすれば良い。

- シンボル名はそのまま（先頭に '_' を付与する必要なし）
- .globl 疑似命令でシンボルを公開する
- .type 疑似命令でシンボルが関数であることを示す
- 関数は単なるラベルで構わない

その他、今回使用しない詳細部分は呼出規約として確認できる。

#### リンカスクリプトでのワイルドカード

hrb.lds で bootpack.o, startup.o 以外に naskfunc.o もリンクする必要が生じたが、

```ldscript
    .text : {
        _btext = .;
        *(.text)
        startup.o(.text)
        . = (. + 3) & ~ 3;
        _etext = .;
    } = 0x00000000
```

とすると、startup.o, bootpack.o, naskfunc.o の順に並んでしまった。
マップファイルでもうかがえたが、objdump で直接確認した。  
\# *.hrb のヘッダは 36 バイトあるため飛ばしてから逆アセンブルしなければならない

```shell-session
$ dd bs=1 skip=36 if=bootpack.hrb of=- 2>/dev/null | objdump -D -b binary -mi386 -

-:     file format binary


Disassembly of section .data:

00000000 <.data>:
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	5d                   	pop    %ebp
   4:	e9 00 00 00 00       	jmp    0x9
   9:	55                   	push   %ebp
   a:	89 e5                	mov    %esp,%ebp
   c:	83 ec 08             	sub    $0x8,%esp
   f:	e8 02 00 00 00       	call   0x16
  14:	eb f9                	jmp    0xf
  16:	f4                   	hlt    
  17:	c3                   	ret    
```

マニュアルにある通り EXCLUDE_FILE を使うことで startup.o を除外できる。

```ldscript
    .text : { 
        _btext = .;
        EXCLUDE_FILE(startup.o) *(.text)
        startup.o(.text)
        . = (. + 3) & ~ 3;
        _etext = .;
    } = 0x00000000
```

```shell-session
$ dd bs=1 skip=36 if=bootpack.hrb of=- 2>/dev/null | objdump -D -b binary -mi386 -

-:     file format binary


Disassembly of section .data:

00000000 <.data>:
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 ec 08             	sub    $0x8,%esp
   6:	e8 02 00 00 00       	call   0xd
   b:	eb f9                	jmp    0x6
   d:	f4                   	hlt    
   e:	c3                   	ret    
   f:	55                   	push   %ebp
  10:	89 e5                	mov    %esp,%ebp
  12:	5d                   	pop    %ebp
  13:	e9 e8 ff ff ff       	jmp    0x0
```

#### bootpack.o の内容が一致しない

bootpack.hrb の内容を確認していたら bootpack.o の内容が一致しないことに気付いた。

CD-ROM 環境で作成したもの:

```shell-session
$ objdump -d bootpack.obj

bootpack.obj:     file format pe-i386


Disassembly of section .text:

00000000 <_HariMain>:
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	e8 00 00 00 00       	call   8 <_HariMain+0x8>
   8:	eb f9                	jmp    3 <_HariMain+0x3>
```

手元の環境で作成したもの:

```shell-session
$ objdump -d bootpack.o

bootpack.o:     file format elf32-i386


Disassembly of section .text:

00000000 <HariMain>:
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 ec 08             	sub    $0x8,%esp
   6:	e8 fc ff ff ff       	call   7 <HariMain+0x7>
   b:	eb f9                	jmp    6 <HariMain+0x6>
```

見比べると

```Assembly
	sub	$0x8,%esp
```

の ```83 ec 08``` が余分に出力されてしまっている。

HariMain() 内ではローカル変数を使用しないので %esp の sub は必要ないはずだが、
io_hlt() の呼び出しを行うと sub が出力されてしまう。

gcc のオプションで抑制できると思われるが見つけられなかった。  
\# -falign-jumps や -falign-loops では変わらず

すでに -Os で有効になっているから？

```shell-session
$ gcc -O0 -Q --help=optimize | grep falign
  -falign-functions           		[disabled]
  -falign-jumps               		[disabled]
  -falign-labels              		[disabled]
  -falign-loops               		[disabled]
$ gcc -Os -Q --help=optimize | grep falign
  -falign-functions           		[enabled]
  -falign-jumps               		[enabled]
  -falign-labels              		[enabled]
  -falign-loops               		[enabled]
```

gcc のバージョンによるのかもしれない。

CD-ROM 環境:

```cmd
Z:\wine\z_tools>cc1 --version
GNU C version 3.2 (mingw special 20020817-1) (i586-pc-cygwin)
        compiled by GNU C version 3.2 (mingw special 20020817-1).
GNU CPP version 3.2 (mingw special 20020817-1) (cpplib) (80386, BSD syntax)

```

手元の環境:

```shell-session
$ gcc --version
gcc (Debian 7.1.0-13) 7.1.0
Copyright (C) 2017 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

```

しかたがないので未解決のままとしておく。

##### 参考

- [x86 calling conventions - Wikipedia](https://en.wikipedia.org/wiki/X86_calling_conventions#x86-64_calling_conventions)
- [呼出規約 - Wikipedia](https://ja.wikipedia.org/wiki/%E5%91%BC%E5%87%BA%E8%A6%8F%E7%B4%84#System_V_AMD64_ABI_.E5.91.BC.E5.87.BA.E8.A6.8F.E7.B4.84)
- [C/C++ の呼び出し規約](https://www.xlsoft.com/jp/products/intel/compilers/ccl/12/ug/bldaps_cls/common/bldaps_calling_conv.htm)
- [[GDB] Linux x86-64 の呼出規約(calling convention)を gdb で確認する - th0x4c 備忘録](http://th0x4c.github.io/blog/2013/04/10/gdb-calling-convention/)

- [LD: Input Section Basics](https://sourceware.org/binutils/docs/ld/Input-Section-Basics.html)
- [tools/bim2hrb - hrb-wiki](http://hrb.osask.jp/wiki/?tools/bim2hrb)

### 成果

- [Makefile](/Makefile)
    - naskfunc.S を追加
- [bootpack.c](/bootpack.c)
    - io_hlt() を呼び出す
- [hrb.lds](/hrb.lds)
    - naskfunc.o をリンクする
- [naskfunc.S](/naskfunc.S)
    - アセンブリ言語でしか書けない関数に追加

----

Next: [harib01a](harib01a.md), Previous: [harib00i](harib00i.md), Up: [Chapter3](chapter3.md)
