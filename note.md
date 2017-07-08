# Chapter2

## helloos3

### 課題

ソース内のプログラム部分を理解しやすい形に書き換える。

### 学習

#### AT&T 文法（Intel 文法と比べて）

- ソースオペランドとデスティネーションオペランドの順序が逆
- immediate operand には '$' を前置する
- レジスタオペランドには '%' を前置する
- 命令ニモニック末尾の 'b', 'w', 'l', 'q' でメモリオペランドサイズを示す
- 間接アドレッシングでは '(', ')' を使う

##### 参考

- [Linux のアセンブラー: GAS と NASM を比較する](https://www.ibm.com/developerworks/jp/linux/library/l-gas-nasm.html)

#### gas で 16 ビット命令を生成させる

- 16 ビット命令を生成するには .code16 ディレクティブを使う

##### 参考

- [Using as - i386-16bit](http://ftp.gnu.org/old-gnu/Manuals/gas/html_node/as_203.html)

#### nask（nasm）と gas の org は異なる

- nask で "ORG 0x7c00" とされていたので単純に ".org 0x7c00" とした
- しかし .text セクションのサイズが 1506304 になってしまい 1474560（1440KB）より 31744（0x7c00）バイト大きくなってしまう

```shell-session
$ readelf -S helloos.o
There are 8 section headers, starting at offset 0x16fd04:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000034 16fc00 00  AX  0   0  1
  [ 2] .rel.text         REL             00000000 16fccc 000008 08   I  5   1  4
  [ 3] .data             PROGBITS        00000000 16fc34 000000 00  WA  0   0  1
  [ 4] .bss              NOBITS          00000000 16fc34 000000 00  WA  0   0  1
  [ 5] .symtab           SYMTAB          00000000 16fc34 000080 10      6   8  4
  [ 6] .strtab           STRTAB          00000000 16fcb4 000017 00      0   0  1
  [ 7] .shstrtab         STRTAB          00000000 16fcd4 000030 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  p (processor specific)
```

- objdump -d helloos.o を実行してみると先頭に 0x7c00 バイトの '\x00' が付与されている

```shell-session
$ objdump -d -mi8086 helloos.o

helloos.o:     file format elf32-i386


Disassembly of section .text:

00000000 <entry-0x7c50>:
	...
    7c00:	eb 4e                	jmp    7c50 <entry>
    7c02:	90                   	nop
    7c03:	48                   	dec    %ax
    7c04:	45                   	inc    %bp
    7c05:	4c                   	dec    %sp
    7c06:	4c                   	dec    %sp
    7c07:	4f                   	dec    %di
    7c08:	49                   	dec    %cx
    7c09:	50                   	push   %ax
    7c0a:	4c                   	dec    %sp
    7c0b:	00 02                	add    %al,(%bp,%si)
    7c0d:	01 01                	add    %ax,(%bx,%di)
    7c0f:	00 02                	add    %al,(%bp,%si)
    7c11:	e0 00                	loopne 7c13 <entry-0x3d>
    7c13:	40                   	inc    %ax
    7c14:	0b f0                	or     %ax,%si
    7c16:	09 00                	or     %ax,(%bx,%si)
    7c18:	12 00                	adc    (%bx,%si),%al
    7c1a:	02 00                	add    (%bx,%si),%al
    7c1c:	00 00                	add    %al,(%bx,%si)
    7c1e:	00 00                	add    %al,(%bx,%si)
    7c20:	40                   	inc    %ax
    7c21:	0b 00                	or     (%bx,%si),%ax
    7c23:	00 00                	add    %al,(%bx,%si)
    7c25:	00 29                	add    %ch,(%bx,%di)
    7c27:	ff                   	(bad)  
    7c28:	ff                   	(bad)  
    7c29:	ff                   	(bad)  
    7c2a:	ff 48 45             	decw   0x45(%bx,%si)
    7c2d:	4c                   	dec    %sp
    7c2e:	4c                   	dec    %sp
    7c2f:	4f                   	dec    %di
    7c30:	2d 4f 53             	sub    $0x534f,%ax
    7c33:	20 20                	and    %ah,(%bx,%si)
    7c35:	20 46 41             	and    %al,0x41(%bp)
    7c38:	54                   	push   %sp
    7c39:	31 32                	xor    %si,(%bp,%si)
    7c3b:	20 20                	and    %ah,(%bx,%si)
    7c3d:	20 00                	and    %al,(%bx,%si)
	...

00007c50 <entry>:
    7c50:	b8 00 00             	mov    $0x0,%ax
    7c53:	8e d0                	mov    %ax,%ss
    7c55:	bc 00 7c             	mov    $0x7c00,%sp
    7c58:	8e d8                	mov    %ax,%ds
    7c5a:	8e c0                	mov    %ax,%es
    7c5c:	be 74 7c             	mov    $0x7c74,%si

00007c5f <putloop>:
    7c5f:	8a 04                	mov    (%si),%al
    7c61:	83 c6 01             	add    $0x1,%si
    7c64:	3c 00                	cmp    $0x0,%al
    7c66:	74 09                	je     7c71 <fin>
    7c68:	b4 0e                	mov    $0xe,%ah
    7c6a:	bb 0f 00             	mov    $0xf,%bx
    7c6d:	cd 10                	int    $0x10
    7c6f:	eb ee                	jmp    7c5f <putloop>

00007c71 <fin>:
    7c71:	f4                   	hlt    
    7c72:	eb fd                	jmp    7c71 <fin>

00007c74 <msg>:
    7c74:	0a 0a                	or     (%bp,%si),%cl
    7c76:	68 65 6c             	push   $0x6c65
    7c79:	6c                   	insb   (%dx),%es:(%di)
    7c7a:	6f                   	outsw  %ds:(%si),(%dx)
    7c7b:	2c 20                	sub    $0x20,%al
    7c7d:	77 6f                	ja     7cee <msg+0x7a>
    7c7f:	72 6c                	jb     7ced <msg+0x79>
    7c81:	64 0a 00             	or     %fs:(%bx,%si),%al
	...
    7dfc:	00 00                	add    %al,(%bx,%si)
    7dfe:	55                   	push   %bp
    7dff:	aa                   	stos   %al,%es:(%di)
    7e00:	f0 ff                	lock (bad) 
    7e02:	ff 00                	incw   (%bx,%si)
	...
    9000:	f0 ff                	lock (bad) 
    9002:	ff 00                	incw   (%bx,%si)
	...
```

- リンカスクリプトでこの null bytes を削除しようとしたが方法見つからず
- また、0x7c00 以降のみを出力する方法も見つけられず

- 一方、".org 0x7c00" により entry, putloop, fin, msg は正しく 0x7c50, 0x7c5f, 0x7c71, 0x7c74 に解決されてはいる
- ".org 0" だと上記の各ラベルは 0x0050, 0x005f, 0x0071, 0x0074 となってしまう

```shell-session
$ objdump -d -mi8086 helloos.o

helloos.o:     file format elf32-i386


Disassembly of section .text:

00000000 <entry-0x50>:
       0:	eb 4e                	jmp    50 <entry>
       2:	90                   	nop
       3:	48                   	dec    %ax
       4:	45                   	inc    %bp
       5:	4c                   	dec    %sp
       6:	4c                   	dec    %sp
       7:	4f                   	dec    %di
       8:	49                   	dec    %cx
       9:	50                   	push   %ax
       a:	4c                   	dec    %sp
       b:	00 02                	add    %al,(%bp,%si)
       d:	01 01                	add    %ax,(%bx,%di)
       f:	00 02                	add    %al,(%bp,%si)
      11:	e0 00                	loopne 13 <entry-0x3d>
      13:	40                   	inc    %ax
      14:	0b f0                	or     %ax,%si
      16:	09 00                	or     %ax,(%bx,%si)
      18:	12 00                	adc    (%bx,%si),%al
      1a:	02 00                	add    (%bx,%si),%al
      1c:	00 00                	add    %al,(%bx,%si)
      1e:	00 00                	add    %al,(%bx,%si)
      20:	40                   	inc    %ax
      21:	0b 00                	or     (%bx,%si),%ax
      23:	00 00                	add    %al,(%bx,%si)
      25:	00 29                	add    %ch,(%bx,%di)
      27:	ff                   	(bad)  
      28:	ff                   	(bad)  
      29:	ff                   	(bad)  
      2a:	ff 48 45             	decw   0x45(%bx,%si)
      2d:	4c                   	dec    %sp
      2e:	4c                   	dec    %sp
      2f:	4f                   	dec    %di
      30:	2d 4f 53             	sub    $0x534f,%ax
      33:	20 20                	and    %ah,(%bx,%si)
      35:	20 46 41             	and    %al,0x41(%bp)
      38:	54                   	push   %sp
      39:	31 32                	xor    %si,(%bp,%si)
      3b:	20 20                	and    %ah,(%bx,%si)
      3d:	20 00                	and    %al,(%bx,%si)
	...

00000050 <entry>:
      50:	b8 00 00             	mov    $0x0,%ax
      53:	8e d0                	mov    %ax,%ss
      55:	bc 00 7c             	mov    $0x7c00,%sp
      58:	8e d8                	mov    %ax,%ds
      5a:	8e c0                	mov    %ax,%es
      5c:	be 74 00             	mov    $0x74,%si

0000005f <putloop>:
      5f:	8a 04                	mov    (%si),%al
      61:	83 c6 01             	add    $0x1,%si
      64:	3c 00                	cmp    $0x0,%al
      66:	74 09                	je     71 <fin>
      68:	b4 0e                	mov    $0xe,%ah
      6a:	bb 0f 00             	mov    $0xf,%bx
      6d:	cd 10                	int    $0x10
      6f:	eb ee                	jmp    5f <putloop>

00000071 <fin>:
      71:	f4                   	hlt    
      72:	eb fd                	jmp    71 <fin>

00000074 <msg>:
      74:	0a 0a                	or     (%bp,%si),%cl
      76:	68 65 6c             	push   $0x6c65
      79:	6c                   	insb   (%dx),%es:(%di)
      7a:	6f                   	outsw  %ds:(%si),(%dx)
      7b:	2c 20                	sub    $0x20,%al
      7d:	77 6f                	ja     ee <msg+0x7a>
      7f:	72 6c                	jb     ed <msg+0x79>
      81:	64 0a 00             	or     %fs:(%bx,%si),%al
	...
     1fc:	00 00                	add    %al,(%bx,%si)
     1fe:	55                   	push   %bp
     1ff:	aa                   	stos   %al,%es:(%di)
     200:	f0 ff                	lock (bad) 
     202:	ff 00                	incw   (%bx,%si)
	...
    1400:	f0 ff                	lock (bad) 
    1402:	ff 00                	incw   (%bx,%si)
	...
$ readelf -S helloos.o
There are 8 section headers, starting at offset 0x168104:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000034 168000 00  AX  0   0  1
  [ 2] .rel.text         REL             00000000 1680cc 000008 08   I  5   1  4
  [ 3] .data             PROGBITS        00000000 168034 000000 00  WA  0   0  1
  [ 4] .bss              NOBITS          00000000 168034 000000 00  WA  0   0  1
  [ 5] .symtab           SYMTAB          00000000 168034 000080 10      6   8  4
  [ 6] .strtab           STRTAB          00000000 1680b4 000017 00      0   0  1
  [ 7] .shstrtab         STRTAB          00000000 1680d4 000030 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  p (processor specific)
```

- しかし、逆に先頭の null bytes は取り除かれている

- 結局 nasm と gas の org は異なる命令であり gas の .org はオブジェクト内にスペースを作ってしまう
- ".org 0" でアセンブルし、リンカスクリプトでロケーションカウンタを 0x7c00 に設定することで、各ラベルのアドレスも +0x7c00 され正しい helloos.img を生成することができた。

```
OUTPUT_FORMAT(binary)
SECTIONS
{
  . = 0x7c00;
  .text : { *(.text) }
}
```

```shell-session
$ ./asm
$ git show 01/helloos0:helloos.img | cmp - helloos.img
$
```

##### 参考

- [Using as - Org](http://ftp.gnu.org/old-gnu/Manuals/gas/html_node/as_110.htm)
- [assembly - Is there something like org for nasm in gas? - Stack Overflow](https://stackoverflow.com/questions/31479054/is-there-something-like-org-for-nasm-in-gas)

### 成果

- [helloos.S](/helloos.S)
    - helloos.nas を参考に gas 用に書き換えたソース
- [helloos.lds](/helloos.lds)
    - helloos.o から helloos.img を作るためのリンカスクリプト

# Chapter1

## helloos2

### 課題

ソース内のデータ部分を理解しやすい形に書き換える。

### 学習

#### ディレクティブ

- .short
    - 普通は .word と同じ（多分 16 ビット整数）
- .long
    - 普通は .int と同じ（多分 32 ビット整数）
- .ascii
    - 文字列リテラル（\0 で終わるのは .asciz）
- .org
    - 指定した値までロケーションカウンタを進める

オリジナルの ```RESB 0x1fe-$``` を ```.space 0x1fe-$``` に置き換えたところエラーになった。

```shell-session
$ ./asm
helloos.S: Assembler messages:
helloos.S:37: Error: .space specifies non-absolute value
```

そのため、```.org 0x1fe``` を使用した。

### 成果

- [helloos.S](/helloos.S)
    - helloos.nas を参考に gas 用に書き換えたソース

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

## helloos0

### 課題

バイナリエディタで、起動後特定のメッセージを表示するだけのフロッピーディ
スクイメージを作る。

### 学習

ただ入力するだけでは学習にならないように思えたので、16進ダンプ入力をバ
イナリに変換するツールを作成した。

### 成果

- support/hex2bin
    - hexdump -C の出力から入力を生成するフィルタ
