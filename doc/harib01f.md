Next: [harib01g](harib01g.md), Previous: [harib01e](harib01e.md), Up: [Chapter4](chapter4.md)

----

# Chapter4

## harib01f

### 課題

カラーパレットを設定する。

### 学習

#### Video DAC レジスタ操作

set_palette() で呼び出している I/O 命令の内容を調べる。

ポート | データ | 機能
------ | ------ | ----
0x03c8 | 0-0xff | [DAC Address Write Mode Register](http://www.osdever.net/FreeVGA/vga/colorreg.htm#3C8)
0x03c9 | 0-0x3f | [DAC Data Register](http://www.osdever.net/FreeVGA/vga/colorreg.htm#3C9)

- ポート 0x3c8 でパレット番号を指定してから R, G, B の順に色の強さをポート 0x3c9 に指定する。
- データは 6bit で指定するので、8bit の数値を 4 で割って設定している。（下位 2bit は使用しない）
- 今回はビデオモードとして 320x200x8bit カラーを設定しているので、パレット番号は 0 から 7 まで指定可能。
- パレットを連続して設定する場合は最初に一度だけパレット番号を指定すればよい。
- 処理中に割り込みが発生しないよう ```sti``` してから設定する。

#### bootpack.hrb のヘッダ修正

table_rgb の初期化データ追加により bootpack.o に .data セクションが追加になった。
C ソースの内容や readelf が示すように 16 * 3（== 0x30）バイトのサイズを持っている。

```shell-session
$ readelf -S bootpack.o
There are 12 section headers, starting at offset 0x440:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000034 0000cd 00  AX  0   0  1
  [ 2] .rel.text         REL             00000000 000378 000058 08   I  9   1  4
  [ 3] .data             PROGBITS        00000000 000120 000030 00  WA  0   0 32
  [ 4] .bss              NOBITS          00000000 000150 000000 00  WA  0   0  1
  [ 5] .comment          PROGBITS        00000000 000150 00001e 01  MS  0   0  1
  [ 6] .note.GNU-stack   PROGBITS        00000000 00016e 000000 00      0   0  1
  [ 7] .eh_frame         PROGBITS        00000000 000170 000084 00   A  0   0  4
  [ 8] .rel.eh_frame     REL             00000000 0003d0 000018 08   I  9   7  4
  [ 9] .symtab           SYMTAB          00000000 0001f4 000110 10     10   9  4
  [10] .strtab           STRTAB          00000000 000304 000072 00      0   0  1
  [11] .shstrtab         STRTAB          00000000 0003e8 000057 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  p (processor specific)
```

これの影響か bootpack.hrb のヘッダが変更になった。

オフセット | wine 作成版 | 手元版 | 意味
---------- | ----------- | ------------ | ----
+0         | 0x00311000  | 0x00310000   | stack+.data+heap の大きさ（4KB単位）
+32        | 0x00310030  | 0x00310000   | heap領域（malloc領域）開始アドレス

- オフセット +0 は .data セクションの長さが 0x30、よって 0x1000 以下なので 4KB 単位にして +0x1000 に、
- オフセット +32 は .data セクションの長さが 0x30 なので heap 開始アドレスが +0x30 繰り下がった

ためと思われる。

また、コンパイラが生成するコードの相違により以下の値が変わっている。

オフセット | wine 作成版 | 手元版 | 意味
---------- | ----------- | ------------ | ----
+20        | 0x0000013c  | 0x0000014c   | .dataの初期値列がファイルのどこにあるか
+28        | 0x00000113  | 0x00000120   | エントリアドレス-0x20

.data セクションの内容は ```00 00 00``` で始まり ```84 84 84``` で終わる 0x30 バイトの領域であることから場所が推定できるが、オリジナルをコンパイルしたものでは 0x0000013c から、手元の環境では 0x0000014c から始まっていることが確認できた。

また、HariStartup の場所はマップファイルからそれぞれ 0x133, 0x140 であり 0x20 を引いて 0x113, 0x120 になることが確認できた。

#### haribote.sys のサイズが 512 バイトを超えた

haribote.sys のファイルサイズが 1 セクタを超えたので FAT で 2 セクタ分使うように修正した。

FAT の先頭部分 ```f0 ff ff ff 0f 00 00 00 00 ...``` すなわち ```ff0 fff fff 000 000 000 ...``` を
```f0 ff ff 03 f0 ff 00 00 00 ...``` すなわち ```ff0 fff 003 fff 000 000 ...``` に修正した。

これは第 2 クラスタがデータの本体かつ最後のクラスタであった状態から、
第 2 クラスタの次が第 3 クラスタで、それが最終クラスタになったことを示す。

haribote.sys はディスクイメージの先頭から 0x4200 バイト（33 セクタ）目の場所に配置し、
0x4400 バイト（34 セクタ）目から 00 で埋めていたものを 0x4600 バイト（35 セクタ）目からに変更。

#### gcc の最適化で関数の出現順が変わる

オリジナルに合わせて -Os を設定しているが、bootpack.o 内の関数出現順が set_palette -> init_palette -> HariMain に変更される。
バージョンによる（オリジナルは 3.2）のだろうが、おそらく前方参照を解決するためではないかと思われる。
-O0 に変更すればソース記述順に戻るが -O1 の段階で上記の順になる。
マニュアルによると -Os は -O2 のうちサイズが大きくなる可能性のある最適化が除外されたもの。

個別の最適化オプションでそのものと思える -freorder-functions というものがあるが -O1 では無効化されている。
実際に -Os に -fno-reorder-functions を追加して disabled にしても先頭の関数は set_palette のまま。

```shell-session
$ cc --version
cc (Debian 7.1.0-13) 7.1.0
Copyright (C) 2017 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

$ cc -fno-pic -Os -Wall -Q --help=optimize | grep reorder-functions
  -freorder-functions         		[enabled]
$ cc -fno-pic -O0 -Wall -Q --help=optimize | grep reorder-functions
  -freorder-functions         		[disabled]
$ cc -fno-pic -O1 -Wall -Q --help=optimize | grep reorder-functions
  -freorder-functions         		[disabled]
$ cc -fno-pic -Os -fno-reorder-functions -Wall -Q --help=optimize | grep reorder-function
  -freorder-functions         		[disabled]
$ cc -fno-pic -Os -fno-reorder-functions -Wall -S -o - bootpack.c | head
	.file	"bootpack.c"
	.text
	.globl	set_palette
	.type	set_palette, @function
set_palette:
.LFB2:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
```

-O0 と -O1 で異なる最適化オプションを個別に無効化しても並び順は変わらなかった。
おそらく複数のオプションの効果により有効になっていると思われる。

ソース記述順に戻す方法が見つからず、順序が変わっていても動作するようなのでそのままにする。

#### 参考

- [VGA/SVGA Video Programming--Color Regsters](http://www.osdever.net/FreeVGA/vga/colorreg.htm)
- [Tips　VGAその４の６　ビデオDACレジスター](http://softwaretechnique.jp/OS_Development/Tips/VGA/vga04-06.html)
- [VGA - os-wiki](http://oswiki.osask.jp/?VGA#o2d4bfd3)
- [tools/bim2hrb - hrb-wiki](http://hrb.osask.jp/wiki/?tools/bim2hrb)

### 成果

- [bootpack.c](/bootpack.c)
    - カラーパレットを設定
- [haribote.lds](/haribote.lds)
    - FAT で 2 セクタを使用するように修正
- [hrb.lds](/hrb.lds)
    - .data セクションにデータが追加になったため対応
- [naskfunc.S](/naskfunc.S)
    - I/O とフラグ操作を行う関数群を追加

----

Next: [harib01g](harib01g.md), Previous: [harib01e](harib01e.md), Up: [Chapter4](chapter4.md)
