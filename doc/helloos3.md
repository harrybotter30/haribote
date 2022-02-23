Next: [helloos4](helloos4.md), Previous: [helloos2](helloos2.md), Up: [Chapter2](chapter2.md)

----

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

- [Using as - Org](http://ftp.gnu.org/old-gnu/Manuals/gas/html_node/as_110.html)
- [assembly - Is there something like org for nasm in gas? - Stack Overflow](https://stackoverflow.com/questions/31479054/is-there-something-like-org-for-nasm-in-gas)

### 成果

- [helloos.S](/helloos.S)
    - helloos.nas を参考に gas 用に書き換えたソース
- [helloos.lds](/helloos.lds)
    - helloos.o から helloos.img を作るためのリンカスクリプト

----

Next: [helloos4](helloos4.md), Previous: [helloos2](helloos2.md), Up: [Chapter2](chapter2.md)
