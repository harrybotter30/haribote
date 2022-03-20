Next: [harib06a](harib06a.md), Previous: [harib05d](harib05d.md), Up: [Chapter8](chapter8.md)

----

# Chapter8

## protected mode

今回実装はなくソースの確認のみ。

### 課題

32 ビットモードに切り替える。

### 学習

asmhead.S の未確認部分を確認する。

#### 割り込み禁止

CPU モード切り替え中、PIC の初期化前に割り込みが発生することを禁止する。

```Assembly
	movb	$0xff, %al
	out	%al, $0x21
	nop                     /* OUT命令を連続させるとうまくいかない機種があるらしいので */
	out	%al, $0xa1

	cli                     /* さらにCPUレベルでも割り込み禁止 */
```

8259 PIC の Master PIC Data ($0x21), Slave PIC Data ($0xa1) に $0xff を出力することで無効化し、cli で割り込み許可フラグをクリアする。

#### A20 ゲート

A20 以降の信号線を有効にする。

キーボードコントローラを使用する以外にも

- System Control Port A
- BIOS (INT 15H)

で制御する方法もある。

```Assembly
	call	waitkbdout
	movb	$0xd1, %al
	out	%al, $0x64
	call	waitkbdout
	movb	$0xdf, %al      /* enable A20 */
	out	%al, $0x60
	call	waitkbdout
```

キーボードコントローラの `Read Status Register` で `Input Buffer Full` フラグが 0 になる（コマンド送信可能）のを待ち、
`Send Command` で `Write output port`（`$0xd1`）、`Write Output Buffer` で `$0xdf` を送信する。

なぜ `$0xdf` なのかは不明。[OSDev](https://wiki.osdev.org/A20_Line) では `$0xae` を使用している。

#### 32 ビットプロテクトモード移行

[harib02i](harib02i.md) で学習したが忘れてしまっているので復習する。

```Assembly
	.arch	i486            /* 486の命令まで使いたいという記述 */

	lgdt	(GDTR0)         /* 暫定GDTを設定 */
	movl	%cr0, %eax
	andl	$0x7fffffff, %eax /* bit31を0にする（ページング禁止のため） */
	orl	$0x00000001, %eax /* bit0を1にする（プロテクトモード移行のため） */
	movl	%eax, %cr0
	jmp	pipelineflush
```

GAS 出力は以下のとおり。

|アセンブリ言語 | 機械語|
|-------------- | ------|
|```lgdt	(GDTR0)``` | ```0F 01 16 2A 01```|
|```movl	%cr0, %eax``` | ```0F 20 C0```|
|```andl	$0x7fffffff, %eax``` | ```66 25 FF FF FF 7F```|
|```orl	$0x00000001, %eax``` | ```66 83 C8 01```|
|```movl	%eax, %cr0``` | ```0F 22 C0```|
|```jmp	pipelineflush``` | ```EB 00```|

##### LGDT

ModR/M バイト `16` は `mod: 00, reg/opcode: 010, r/m: 110` となる。  
`.code16` により 16 bit モードでアセンブルしているので `disp16, opcode: 2` から
`LGDT $0x012a` であることが判る。さらに以下のリスティングファイルから `$0x012a` は `GDTR0` であり、
ラベル `GDT0`（`$0x00000110`）からオフセット `23` までを GDT として設定している。

```
 136 0105 00000000 	 .balign 16, 0
 136      00000000 
 136      000000
 137              	GDT0:
 138 0110 00000000 	 .space 8
 138      00000000 
 139 0118 FFFF0000 	 .short 0xffff,0x0000,0x9200,0x00cf
 139      0092CF00 
 140 0120 FFFF0000 	 .short 0xffff,0x0000,0x9a28,0x0047
 140      289A4700 
 141              	
 142 0128 0000     	 .short 0
 143              	GDTR0:
 144 012a 1700     	 .short 8*3-1
 145 012c 10010000 	 .long GDT0
```

`GDTR` の下位 16 bit の limit を「サイズ」と呼ぶことがあるが、実際には GDT の最終バイトのオフセットを設定する仕様のようだ。  
おそらくこの種の値をサイズとしてしまうと、セグメントのように、必要なサイズが 1 単位入らなくなることがあるからではないか？

グローバルディスクリプタは三つ登録している。先頭は「ヌル・セグメント・セレクタ」として使用しないことになっている。  
[harib02i](harib02i.md) のセグメントディスクリプタの構造を参照すると以下のようなセグメントを定義していることが判る。

|#|limit|base|type|system|privilege level|present|system software|64bit code|32bit operation|granularity|
|-:|---:|---:|----|-----:|--------------:|------:|--------------:|---------:|--------------:|----------:|
|0|$0|$0|Read-Only Data|0|0|0|0|0|0|0|
|1|$0xfffff|$0x00000000|Read/Write Data|1|0|1|0|0|1|1|
|2|$0x7ffff|$0x00280000|Execute/Read Code|1|0|1|0|0|1|0|

##### MOV

`0F 20` または `0F 22` は `Move to/from Control Registers` を表し通常の MOV とは異なる。  
この場合、reg/opcode が制御レジスタを、r/m がレジスタを表す。  
今回の ModR/M バイト `C0` は `mod: 11, reg/opcode: 000, r/m: 000` から %cr0, %eax となる。

##### AND/OR

`66` はオペランド・サイズ・オーバーライド・プリフィックスなので、`.code16` 中の `25` で `andl $imm32, %eax` を表す。  
同様に `.code16` 中の `83` は ModR/M バイト `C8`（`mod: 11` `reg/opcode: 001: r/m: 000`）から `orl $imm8, %eax` を表す。

制御レジスタ %cr0 は以下のようになっている。

```
 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
+--+--+--+-----------------------------+--+--+--+-----------------------------+--+--+--+--+--+--+
|PG|CD|NW|                             |AM|  |WP|                             |NE|ET|TS|EM|MP|PE|
+--+--+--+-----------------------------+--+--+--+-----------------------------+--+--+--+--+--+--+
```

よって、上記の操作は PG を解除して PE を設定したことを意味する。

##### JMP

次の `jmp	pipelineflush` は `EB 00` すなわち相対アドレス `00` へのジャンプであり無意味のように見えるが、
フェッチまたはデコード済みの命令を空にするためにジャンプすることが必要とマニュアルに示されている。

#### セグメントセレクタ

プロテクトモードではセグメントレジスタにはセグメントセレクタを設定する。

```
 15                                   3  2  1  0
+--------------------------------------+--+-----+
|                INDEX                 |TI| RPL |
+--------------------------------------+--+-----+
```

セレクタの下位 3 bit は `Requested Privilege Level` と `Table Indicator`（0: GDT, 1: LDT） に使用されるため、
ディスクリプタテーブルのインデックスは 3-15 ビットで表現する。8 倍しているのはディスクリプタのサイズを掛けているのではない。  
ディスクリプタの数は最大 4096 個なので、インデックスに 12 bit 必要であることと整合している。

```Assembly
pipelineflush:
	movw	$1*8, %ax      /* 読み書き可能セグメント32bit */
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %fs
	movw	%ax, %gs
	movw	%ax, %ss
```

GAS 出力は以下のとおり。

|アセンブリ言語 | 機械語|
|-------------- | ------|
|```movw	$1*8, %ax``` | ```B8 08 00```|
|```movw	%ax, %ds``` | ```8E D8```|
|```movw	%ax, %es``` | ```8E C0```|
|```movw	%ax, %fs``` | ```8E E0```|
|```movw	%ax, %gs``` | ```8E E8```|
|```movw	%ax, %ss``` | ```8E D0```|

`B8` は `B8 (+000)` かつ `.code16` なので `movw $imm16, %ax` を表す。また、 imm16 は `$0x0008` になる。

`8E` は `movw r/m16, Sreg` を表す。  
各 ModR/M バイトは以下の通りで r/m はいずれも `000` から %ax であることが判る。
Sreg は reg/opcode で示される。

|ModR/M|mod|reg/opcode|r/m|Sreg|
|------|--:|----------:|--:|----|
|`D8`|11|011|000|%ds|
|`C0`|11|000|000|%es|
|`E0`|11|100|000|%fs|
|`E8`|11|101|000|%gs|
|`D0`|11|010|000|%ss|

#### データ転送

##### bootpack

memcpy 関数が

```Assembly
memcpy:
	movl	(%esi), %eax
	addl	$4, %esi
	movl	%eax, (%edi)
	addl	$4, %edi
	subl	$1, %ecx
	jnz	memcpy          /* 引き算した結果が0でなければmemcpyへ */
	ret
```

という実装なので、

```Assembly
	movl	$bootpack, %esi
	movl	$BOTPAK, %edi
	movl	$512*1024/4, %ecx
	call	memcpy
```

は `bootpack` ラベルから 512**KB** をアドレス `BOTPAK`（== 0x00280000 | 2.5MB）のメモリ領域にコピーする。  
memcpy(3) と異なり単位が 4bytes なので、%ecx の値は 1/4 しておく必要がある。

##### ブートセクタ

```Assembly
	movl	$0x7c00, %esi   /* 転送元 */
	movl	$DSKCAC, %edi   /* 転送先 */
	movl	$512/4, %ecx
	call	memcpy
```

はアドレス `0x7c00` から 512**B** をアドレス `DSKCAC`（== 0x00100000 | 1MB）のメモリ領域にコピーする。

`0x7c00` は PC BIOS がブートセクタを読み込むアドレスであることに注意。

##### その他のディスクデータ

```Assembly
	movl	$DSKCAC0+512, %esi /* 転送元 */
	movl	$DSKCAC+512, %edi  /* 転送先 */
	movl	$0, %ecx
	movb	(CYLS), %cl
	imull	$512*18*2/4,%ecx /* シリンダ数からバイト数/4に変換 */
	subl	$512/4, %ecx       /* IPLの分だけ差し引く */
	call	memcpy
```

はアドレス `DSKCAC0`+512（== 0x00008200 | 32.5KB） からをアドレス `DSKCAC`+512（== 0x00100200 | 1MB+0.5KB）のメモリ領域にコピーする。  
`0x8200` からなのは [harib00a](harib00a.md) で第 2 セクタをそこに読み込むようにしたため。  
また、ipl10.S で読み込んだシリンダ数は `(CYLS)` に保存してあるため、コピーサイズは `(CYLS)`\*512\*18\*2 バイトになる。

##### メモリマップ

データ転送完了後のメモリマップは以下の通り。

```
0x00000000  +---------------+
            | 未使用        | 1MB
            |               |
            |               |
            |               |
            |               |
            |               |
            |               |
            |               |
0x00100000  +---------------+
            | FD内容の      | 1.44MB(1440KB)
            | コピー        |
            | （先頭10      |
            | シリンダ分）  |
            |               |
            |               |
            |               |
            |               |
0x00200000  +               +
            |               |
            |               |
0x00268000  +---------------+
            | 未使用        | 30KB
0x0026f800  +---------------+
            | IDT           | 2KB
0x00270000  +---------------+
            | GDT           | 64KB
0x00280000  +---------------+
            | bootpack.hrb  | 512KB
            |               |
            |               |
            |               |
0x00300000  +---------------+
            | stack(64KB)   | 1MB
0x00310000  +               +<---- %esp 初期値
            | data          |
            |               |
            |               |
            |               |
            |               |
            |               |
            |               |
0x00400000  +---------------+
            | 未使用        |
```

#### 参考

- [8259 PIC - OSDev Wiki](https://wiki.osdev.org/8259_PIC)
- [8259A PROGRAMMABLE INTERRUPT CONTROLLER](https://pdos.csail.mit.edu/6.828/2005/readings/hardware/8259A.pdf)
- [The PS/2 Keyboard Interface](https://web.archive.org/web/20180217074705/http://www.computer-engineering.org/ps2keyboard)
- [A20 Line - OSDev Wiki](https://wiki.osdev.org/A20_Line)
- [gate A20](https://www.hazymoon.jp/OpenBSD/annex/gate_a20.html)
- [A20 - a pain from the past](https://www.win.tue.nl/~aeb/linux/kbd/A20.html)
- [coder32 edition | X86 Opcode and Instruction Reference 1.12](http://ref.x86asm.net/coder32.html)
- [80386 Programmer's Reference Manual -- Opcode MOV Special Registers](https://pdos.csail.mit.edu/6.828/2011/readings/i386/MOVRS.htm)
- [80386 Programmer's Reference Manual -- Opcode AND](https://pdos.csail.mit.edu/6.828/2011/readings/i386/AND.htm)
- [80386 Programmer's Reference Manual -- Opcode OR](https://pdos.csail.mit.edu/6.828/2011/readings/i386/OR.htm)
- [Control register - Wikipedia](https://en.wikipedia.org/wiki/Control_register#CR0)
- [80386 Programmer's Reference Manual -- Opcode JMP](https://pdos.csail.mit.edu/6.828/2011/readings/i386/JMP.htm)
- [80386 Programmer's Reference Manual -- Section 10.3](https://pdos.csail.mit.edu/6.828/2011/readings/i386/s10_03.htm)
- [80386 Programmer's Reference Manual -- Section 5.1](https://pdos.csail.mit.edu/6.828/2011/readings/i386/s05_01.htm)
- [80386 Programmer's Reference Manual -- Opcode MOV](https://pdos.csail.mit.edu/6.828/2011/readings/i386/MOV.htm) （`8D` は `8E` の誤り）
- [List of floppy disk formats - Wikipedia](https://en.wikipedia.org/wiki/List_of_floppy_disk_formats#Logical_formats)

### 成果

なし

----

Next: [harib06a](harib06a.md), Previous: [harib05d](harib05d.md), Up: [Chapter8](chapter8.md)
