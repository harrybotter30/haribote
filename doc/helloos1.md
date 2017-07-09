Next: [helloos2](helloos2.md), Previous: [helloos0](helloos0.md), Up: [Chapter1](chapter1.md)

----

# Chapter1

## helloos1

### 課題

gas を使って helloos.img を生成する。

### 学習

#### nask（nasm）と gas の文法の相違

nask | gas
---- | ----
DB | .byte
RESB _length_ | .lcomm _symbol_ _length_

[Linux のアセンブラー: GAS と NASM を比較する](https://www.ibm.com/developerworks/jp/linux/library/l-gas-nasm.html)

#### リスティングオプション

gas で生成したオブジェクトは明らかに小さい。

```shell-session
$ as -o helloos.o helloos.S
$ wc -c helloos.o
684 helloos.o
```

gas コマンドラインオプションの [-a で各種リスト出力が有効](http://ftp.gnu.org/old-gnu/Manuals/gas/html_node/as_10.html)になる。
今回は単純に出力されるバイナリを確認したいため -al を使用する。

- \-al
    - requests an output-program assembly listing

```shell-session
$ as -o helloos.o -al helloos.S
GAS LISTING helloos.S 			page 1


   1 0000 EB4E9048 		.byte	0xeb, 0x4e, 0x90, 0x48, 0x45, 0x4c, 0x4c, 0x4f
   1      454C4C4F 
   2 0008 49504C00 		.byte	0x49, 0x50, 0x4c, 0x00, 0x02, 0x01, 0x01, 0x00
   2      02010100 
   3 0010 02E00040 		.byte	0x02, 0xe0, 0x00, 0x40, 0x0b, 0xf0, 0x09, 0x00
   3      0BF00900 
   4 0018 12000200 		.byte	0x12, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00
   4      00000000 
   5 0020 400B0000 		.byte	0x40, 0x0b, 0x00, 0x00, 0x00, 0x00, 0x29, 0xff
   5      000029FF 
   6 0028 FFFFFF48 		.byte	0xff, 0xff, 0xff, 0x48, 0x45, 0x4c, 0x4c, 0x4f
   6      454C4C4F 
   7 0030 2D4F5320 		.byte	0x2d, 0x4f, 0x53, 0x20, 0x20, 0x20, 0x46, 0x41
   7      20204641 
   8 0038 54313220 		.byte	0x54, 0x31, 0x32, 0x20, 0x20, 0x20, 0x00, 0x00
   8      20200000 
   9              		.lcomm	brank1	16
  10 0040 B800008E 		.byte	0xb8, 0x00, 0x00, 0x8e, 0xd0, 0xbc, 0x00, 0x7c
  10      D0BC007C 
  11 0048 8ED88EC0 		.byte	0x8e, 0xd8, 0x8e, 0xc0, 0xbe, 0x74, 0x7c, 0x8a
  11      BE747C8A 
  12 0050 0483C601 		.byte	0x04, 0x83, 0xc6, 0x01, 0x3c, 0x00, 0x74, 0x09
  12      3C007409 
  13 0058 B40EBB0F 		.byte	0xb4, 0x0e, 0xbb, 0x0f, 0x00, 0xcd, 0x10, 0xeb
  13      00CD10EB 
  14 0060 EEF4EBFD 		.byte	0xee, 0xf4, 0xeb, 0xfd, 0x0a, 0x0a, 0x68, 0x65
  14      0A0A6865 
  15 0068 6C6C6F2C 		.byte	0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x77, 0x6f, 0x72
  15      20776F72 
  16 0070 6C640A00 		.byte	0x6c, 0x64, 0x0a, 0x00, 0x00, 0x00, 0x00, 0x00
  16      00000000 
  17              		.lcomm	brank2  368
  18 0078 00000000 		.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0xaa
  18      000055AA 
  19 0080 F0FFFF00 		.byte	0xf0, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00
  19      00000000 
  20              		.lcomm	brank3  4600
  21 0088 F0FFFF00 		.byte	0xf0, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00
  21      00000000 
  22              		.lcomm	brank4  1469432
```

単純に DB-> .byte, RESB-> .lcomm の置き換えをしただけでは .lcomm の部分が全く出力されない。
マニュアルによれば .lcomm は bss セクションに配置される。

```shell-session
$ readelf -S helloos.o
There are 7 section headers, starting at offset 0x194:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000034 000090 00  AX  0   0  1
  [ 2] .data             PROGBITS        00000000 0000c4 000000 00  WA  0   0  1
  [ 3] .bss              NOBITS          00000000 0000c8 167f70 00  WA  0   0  8
  [ 4] .symtab           SYMTAB          00000000 0000c8 000080 10      5   8  4
  [ 5] .strtab           STRTAB          00000000 000148 00001d 00      0   0  1
  [ 6] .shstrtab         STRTAB          00000000 000165 00002c 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  p (processor specific)
```

.bss セクションに 1439.86KB ほど出力されていることが判る。

#### .space ディレクティブ

調べてみたところ [.space ディレクティブ](http://ftp.gnu.org/old-gnu/Manuals/gas/html_node/as_124.html)が使えそうなので試す。

```shell-session
$ as -o helloos.o -al helloos.S
GAS LISTING helloos.S 			page 1


   1 0000 EB4E9048 		.byte	0xeb, 0x4e, 0x90, 0x48, 0x45, 0x4c, 0x4c, 0x4f
   1      454C4C4F 
   2 0008 49504C00 		.byte	0x49, 0x50, 0x4c, 0x00, 0x02, 0x01, 0x01, 0x00
   2      02010100 
   3 0010 02E00040 		.byte	0x02, 0xe0, 0x00, 0x40, 0x0b, 0xf0, 0x09, 0x00
   3      0BF00900 
   4 0018 12000200 		.byte	0x12, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00
   4      00000000 
   5 0020 400B0000 		.byte	0x40, 0x0b, 0x00, 0x00, 0x00, 0x00, 0x29, 0xff
   5      000029FF 
   6 0028 FFFFFF48 		.byte	0xff, 0xff, 0xff, 0x48, 0x45, 0x4c, 0x4c, 0x4f
   6      454C4C4F 
   7 0030 2D4F5320 		.byte	0x2d, 0x4f, 0x53, 0x20, 0x20, 0x20, 0x46, 0x41
   7      20204641 
   8 0038 54313220 		.byte	0x54, 0x31, 0x32, 0x20, 0x20, 0x20, 0x00, 0x00
   8      20200000 
   9 0040 00000000 		.space	16
   9      00000000 
   9      00000000 
   9      00000000 
  10 0050 B800008E 		.byte	0xb8, 0x00, 0x00, 0x8e, 0xd0, 0xbc, 0x00, 0x7c
  10      D0BC007C 
  11 0058 8ED88EC0 		.byte	0x8e, 0xd8, 0x8e, 0xc0, 0xbe, 0x74, 0x7c, 0x8a
  11      BE747C8A 
  12 0060 0483C601 		.byte	0x04, 0x83, 0xc6, 0x01, 0x3c, 0x00, 0x74, 0x09
  12      3C007409 
  13 0068 B40EBB0F 		.byte	0xb4, 0x0e, 0xbb, 0x0f, 0x00, 0xcd, 0x10, 0xeb
  13      00CD10EB 
  14 0070 EEF4EBFD 		.byte	0xee, 0xf4, 0xeb, 0xfd, 0x0a, 0x0a, 0x68, 0x65
  14      0A0A6865 
  15 0078 6C6C6F2C 		.byte	0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x77, 0x6f, 0x72
  15      20776F72 
  16 0080 6C640A00 		.byte	0x6c, 0x64, 0x0a, 0x00, 0x00, 0x00, 0x00, 0x00
  16      00000000 
  17 0088 00000000 		.space  368
  17      00000000 
  17      00000000 
  17      00000000 
  17      00000000 
  18 01f8 00000000 		.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0xaa
  18      000055AA 
  19 0200 F0FFFF00 		.byte	0xf0, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00
  19      00000000 
  20 0208 00000000 		.space  4600
  20      00000000 
  20      00000000 
  20      00000000 
  20      00000000 
  21 1400 F0FFFF00 		.byte	0xf0, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00
  21      00000000 
  22 1408 00000000 		.space  1469432
  22      00000000 
  22      00000000 
  22      00000000 
  22      00000000 
$ wc -c helloos.o
1475004 helloos.o
```

ちゃんと 1440KB+444B 出力された。

#### リンカスクリプト

```shell-session
$ file helloos.o
helloos.o: ELF 32-bit LSB relocatable, Intel 80386, version 1 (SYSV), not stripped
$ readelf -S helloos.o
There are 7 section headers, starting at offset 0x1680a4:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000034 168000 00  AX  0   0  1
  [ 2] .data             PROGBITS        00000000 168034 000000 00  WA  0   0  1
  [ 3] .bss              NOBITS          00000000 168034 000000 00  WA  0   0  1
  [ 4] .symtab           SYMTAB          00000000 168034 000040 10      5   4  4
  [ 5] .strtab           STRTAB          00000000 168074 000001 00      0   0  1
  [ 6] .shstrtab         STRTAB          00000000 168075 00002c 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  p (processor specific)
```

helloos.o は ELF であり、テキストセクションのサイズがちょうど 1440KB なので、この内容のみ取り出せば helloos.img として利用できるはず。

#### リンカスクリプト（失敗）

マニュアルを参照して .text のみのファイルを作成しようと以下のスクリプトを書いた。

```
SECTIONS
{
  .text : { *(.text) }
}
```

```shell-session
$ ld -o helloos.img -T helloos.lds helloos.o
$ wc -c helloos.img
1478924 helloos.img
```

！ 1474560 より大きい？

```shell-session
$ file helloos.img
helloos.img: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), statically linked, not stripped
$ readelf -S helloos.img
There are 5 section headers, starting at offset 0x169044:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 001000 168000 00  AX  0   0  1
  [ 2] .symtab           SYMTAB          00000000 169000 000020 10      3   2  4
  [ 3] .strtab           STRTAB          00000000 169020 000001 00      0   0  1
  [ 4] .shstrtab         STRTAB          00000000 169021 000021 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  p (processor specific)
```

ELF が生成されてしまった。しかし .text はちょうど 1440KB になっている。
ELF 用の ld だから明示的に出力ファイル書式を指定しなければならないのだろう。

#### リンカスクリプト（成功）

```objdump -i``` の出力からすると、```OUTPUT_FORMAT(binary)``` を指定すれば良さそう。

```
OUTPUT_FORMAT(binary)
SECTIONS
{
  .text : { *(.text) }
}
```

```shell-session
$ ld -o helloos.img -T helloos.lds helloos.o
$ wc -c helloos.img
1474560 helloos.img
```

ちょうど 1440KB になった。

```shell-session
$ file helloos.img
helloos.img: DOS/MBR boot sector, code offset 0x4e+2, OEM-ID "HELLOIPL", root entries 224, sectors 2880 (volumes <=32 MB) , sectors/FAT 9, sectors/track 18, sectors 2880 (volumes > 32 MB) , serial number 0xffffffff, label: "HELLO-OS   ", FAT (12 bit), followed by FAT
$ git show 01/helloos0:helloos.img | cmp - helloos.img
$
```

01/helloos0 タグの helloos.img と比較しても完全に一致した。 :+1:

### 成果

- [helloos.S](/helloos.S)
    - helloos.nas を gas 用に書き換えたソース
- [helloos.lds](/helloos.lds)
    - helloos.o から helloos.img を作るためのリンカスクリプト
- [asm](/asm)
    - helloos.img を作るためのシェルスクリプト

----

Next: [helloos2](helloos2.md), Previous: [helloos0](helloos0.md), Up: [Chapter1](chapter1.md)
