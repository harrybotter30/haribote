Next: [harib03a](harib03a.md), Previous: [harib02h](harib02h.md), Up: [Chapter5](chapter5.md)

----

# Chapter5

## harib02i

### 課題

GDT と IDT を設定する。

### 学習

#### セグメントディスクリプタ

プロテクトモードではセグメントの情報をメモリ上のセグメントディスクリプタに設定する。
一つのセグメントディスクリプタは 64bit（== 8 バイト）であり、セグメントは最大 8192 個まで保持することができるので、
セグメントディスクリプタを並べたセグメントディスクリプタテーブルは最大 8 * 8192 == 65536 バイトのメモリを消費する。

また、作成したセグメントディスクリプタテーブルは LGDT 命令を使用することで GDTR（グローバルディスクリプタテーブルレジスタ）に登録することができる。

##### セグメントディスクリプタの構造

80286 互換のため複雑な構成になっている。 
80386 以降は 64bit（== 8 バイト）だが、80286 では上位 16bit は使用しない（0 を設定）。

```
    <---- 16bit ----><--------    32bit    --------><---- 16bit ---->
    +---------------+-----------------------+-------+---+---+-------+
    |  limit_l      |  base_l               |type_l |l_h|t_h|base_h |
    +---------------+-----------------------+-------+---+---+-------+
    下位                                                         上位

            <-----  20bit  ----->
            +---+---------------+
    limit   |l_h|  limit_l      |
            +---+---------------+

            <---------    32bit    --------->
            +-------+-----------------------+
    base    |base_h |  base_l               |
            +-------+-----------------------+

            <-- 12bit -->
            +---+-------+
    type    |t_h|type_l |
            +---+-------+
            +----+----+----+----+
    type_h  | G  |D/B | L  |AVL |
            +----+----+----+----+----+----+----+----+
    type_l  | P  |  DPL    | S  |  TYPE             |
            +----+----+----+----+----+----+----+----+
    G       Granularity 
    D/B     Default operation size (0 = 16-bit segment; 1 = 32-bit segment)
    L       64-bit code segment (IA-32e mode only)
    AVL     Available for use by system software
    P       Segment present
    DPL     Descriptor privilege level
    S       Descriptor type (0 = system; 1 = code or data)
    TYPE    Segment type
```

- limit は 20bit で 1MB まで表現できるが、セグメント属性の G フラグが設定されていれば 4KB 単位で最大 4GB を表す
- base は 32bit で 4GB までのリニアアドレスを指定する
- G フラグが設定されている場合は limit フィールドの値を 4KB 単位とする
- D/B フラグの設定は、コードセグメントであれば 32bit アドレスやオペランドを、スタックセグメントなら 32bit ポインタをデフォルトとする
- L フラグはコードセグメントに 64bit 命令があることを示す。この場合 D/B フラグは 0 とする。コードセグメント以外は 0 を設定する。
- AVL フラグはシステムソフトウェアで使用するために利用できる
- P はセグメントがメモリ上にあれば 1、なければ 0
- DPL は権限レベルを 0 から 3 で表す
- S はクリアするとシステムセグメント、セットするとコード・データセグメント
- TYPE 値の意味は以下の通り

TYPE | 11 | 10 |  9 |  8 | 種別 | 意味
---|----|----|----|----|------|-----
-- |  - |  E |  W |  A |      |
 0 |  0 |  0 |  0 |  0 | Data | Read-Only
 1 |  0 |  0 |  0 |  1 | Data | Read-Only, accessed
 2 |  0 |  0 |  1 |  0 | Data | Read/Write
 3 |  0 |  0 |  1 |  1 | Data | Read/Write, accessed
 4 |  0 |  1 |  0 |  0 | Data | Read-Only, expand-down
 5 |  0 |  1 |  0 |  1 | Data | Read-Only, expand-down, accessed
 6 |  0 |  1 |  1 |  0 | Data | Read/Write, expand-down
 7 |  0 |  1 |  1 |  1 | Data | Read/Write, expand-down, accessed
-- |  - |  C |  R |  A |      |
 8 |  1 |  0 |  0 |  0 | Code | Execute-Only
 9 |  1 |  0 |  0 |  1 | Code | Execute-Only, accessed
10 |  1 |  0 |  1 |  0 | Code | Execute/Read
11 |  1 |  0 |  1 |  1 | Code | Execute/Read, accessed
12 |  1 |  1 |  0 |  0 | Code | Execute-Only, conforming
13 |  1 |  1 |  0 |  1 | Code | Execute-Only, conforming, accessed
14 |  1 |  1 |  1 |  0 | Code | Execute/Read, conforming
15 |  1 |  1 |  1 |  1 | Code | Execute/Read, conforming, accessed

##### GDTR

GDTR（グローバルディスクリプタテーブルレジスタ）は、グローバルディスクリプタテーブルのアドレス（addr）とバイト単位でのサイズ（limit）を保持する。

```
            <-16bit-><--  32bit  --->
            +-------+---------------+
            | limit |  addr         |
            +-------+---------------+
```

#### 割り込みディスクリプタ

プロテクトモードではシステムコールのような動作レベルの移行にコールゲートを使うが、コールゲートの情報はメモリ上のゲートディスクリプタに設定する。
一つのゲートディスクリプタは 64bit（== 8 バイト）であり、割り込みに使用するディスクリプタは最大 256 個まで保持することができるので、割り込みディスクリプタテーブルは最大 8 * 256 == 2048 バイトのメモリを消費する。

##### ゲートディスクリプタの構造

セグメントディスクリプタの複雑さに比べればかなりまし。

```
    <---- 16bit ----><--- 16bit ---><-8bit-><-8bit-><---- 16bit ---->
    +---------------+---------------+-------+-------+---------------+
    |  offset_l     | selector      | count | type  |  offset_h     |
    +---------------+---------------+-------+-------+---------------+
    下位                                                         上位

            <-------      32bit      ------->
            +---------------+---------------+
    offset  |  offset_h     |  offset_l     |
            +---------------+---------------+

            +----+----+----+----+----+----+----+----+
    type    | P  |  DPL    | S  |  TYPE             |
            +----+----+----+----+----+----+----+----+
    P       Segment present
    DPL     Descriptor privilege level
    S       Descriptor type (0 = system; 1 = code or data)
    TYPE    Gate type
```

- offset はゲートのオフセットを 32bit で表す
- selector はゲートのあるセグメントセレクタを 16bit で表す
- count はスタックのコピー回数を下位 5bit で表す（上位 3bit は 0）
- P はセグメントがメモリ上にあれば 1、なければ 0
- DPL は権限レベルを 0 から 3 で表す
- S はクリアするとシステムセグメント、セットするとコード・データセグメント
- TYPE 値の意味は以下の通り

TYPE | 11 | 10 |  9 |  8 | 32bit mode | IA-32e mode
-----|----|----|----|----|------------|-----------
   0 |  0 |  0 |  0 |  0 | Reserved   | Upper 8 bytes of an 16-byte descriptor
   1 |  0 |  0 |  0 |  1 | 16-bit TSS (Available) | Reserved
   2 |  0 |  0 |  1 |  0 | LDT        | LDT
   3 |  0 |  0 |  1 |  1 | 16-bit TSS (Busy) | Reserved
   4 |  0 |  1 |  0 |  0 | 16-bit Call Gate | Reserved
   5 |  0 |  1 |  0 |  1 | Task Gate  | Reserved
   6 |  0 |  1 |  1 |  0 | 16-bit Interrupt Gate | Reserved
   7 |  0 |  1 |  1 |  1 | 16-bit Trap Gate | Reserved
   8 |  1 |  0 |  0 |  0 | Reserved   | Reserved
   9 |  1 |  0 |  0 |  1 | 32-bit TSS (Available) | 64-bit TSS (Available)
  10 |  1 |  0 |  1 |  0 | Reserved   | Reserved
  11 |  1 |  0 |  1 |  1 | 32-bit TSS (Busy) | 64-bit TSS (Busy)
  12 |  1 |  1 |  0 |  0 | 32-bit Call Gate | 64-bit Call Gate
  13 |  1 |  1 |  0 |  1 | Reserved   | Reserved
  14 |  1 |  1 |  1 |  0 | 32-bit Interrupt Gate | 64-bit Interrupt Gate
  15 |  1 |  1 |  1 |  1 | 32-bit Trap Gate | 64-bit Trap Gate

##### IDTR

IDTR（割り込みディスクリプタテーブルレジスタ）は、割り込みディスクリプタテーブルのアドレス（addr）とバイト単位でのサイズ（limit）を保持する。

```
            <-16bit-><--  32bit  --->
            +-------+---------------+
            | limit |  addr         |
            +-------+---------------+
```

#### load_gdtr, load_idtr 呼び出し

load_gdtr(int limit, int addr), load_idtr(int limit, int addr) の実装がやや特殊。

引数として int32_t で limit を定義しているが実際に使用できるのは int16_t。
よって、関数に入ったところではスタックは以下のようになっている。

```
            |               |
  (%esp)--> +---------------+
            |  ret address  |
 4(%esp)--> +-------+-------+
            | limit | nouse |
 8(%esp)--> +-------+-------+
            |  addr         |
            +---------------+
            |               |
             関数呼び出し後
```

ここで、

```Assembly
	movw	4(%esp), %ax    /* limit */
	movw	%ax, 6(%esp)
```

を行うことで、6(%esp) に int16_t の limit をコピーしている。

```
            |               |
  (%esp)--> +---------------+
            |  ret address  |
 4(%esp)--> +-------+-------+
            | limit | limit |
 8(%esp)--> +-------+-------+
            |  addr         |
            +---------------+
            |               |
             limit コピー後
```

GDTR（および IDTR）は

```
            <-16bit-><--  32bit  --->
            +-------+---------------+
            | limit |  addr         |
            +-------+---------------+
```

という構造をしているので、

```Assembly
	lgdt	6(%esp)
```

や

```Assembly
	lidt	6(%esp)
```

で、意図したデータを GDTR（および IDTR）に設定している。

#### セグメントディスクリプタ・割り込みディスクリプタの設定内容

[bootpack.c](/bootpack.c) によれば、

- セグメントディスクリプタテーブルは 0x00270000 にサイズ 64KB(0xffff) で
- 割り込みディスクリプタテーブルは 0x0026f800 にサイズ 2KB(0x7ff) で

設定している。

##### セグメントディスクリプタ

セグメントディスクリプタは 8192 個のほとんどが空だが二つだけ設定している。

セレクタ | limit | base | type
-------- | ----- | ---- | ----
1 | 0xffffffff(4GB(Gflag)) | 0x00000000(  0M) | 0x4092(D/B \| P \| S \| DPL==0 \| Read/Write)
2 | 0x0007ffff(512KB)      | 0x00280000(2.5M) | 0x409a(D/B \| P \| S \| DPL==0 \| Execute/Read)

- セレクタ 1 は実メモリ空間すべて（4GB まで）を 32bit モードの特権レベル 0 で Read/Write アクセスする通常セグメント
- セレクタ 2 は 0x00280000 からの 512KB を 32bit モードの特権レベル 0 で Execute/Write アクセスする通常セグメント

##### 割り込みディスクリプタ

割り込みディスクリプタはすべて空。

#### メモリマップ

ここまでのまとめとして、電源投入後、

- ipl10.o での FD 内容の読み込み
- asmhead.o でのデータコピー
- GDT/IDT 設定

まで完了した状態のメモリ状況を示しておく。
起動処理中は低位メモリを使用しているがプロテクトモード移行後は使用しない。

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
            | bootstack.hrb | 512KB
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

- [Intel® 64 and IA-32 Architectures Software Developer’s Manual Volume 3A: System Programming Guide, Part 1-- 3.4.5 Segment Descriptors/Figure 3-8. Segment Descriptor](https://software.intel.com/sites/default/files/managed/7c/f1/253668-sdm-vol-3a.pdf)
- [Intel® 64 and IA-32 Architectures Software Developer’s Manual Volume 3A: System Programming Guide, Part 1-- 5.8.2 Gate Descriptors/Figure 5-8. Call-Gate Descriptor](https://software.intel.com/sites/default/files/managed/7c/f1/253668-sdm-vol-3a.pdf)
- [80386 Programmer's Reference Manual -- Table of Contents](https://pdos.csail.mit.edu/6.828/2011/readings/i386/toc.htm)
- [Intel® 64 and IA-32 Architectures Software Developer Manuals | Intel® Software](https://software.intel.com/en-us/articles/intel-sdm)

### 成果

- [bootpack.c](/bootpack.c)
    - セグメントディスクリプタテーブルと割り込みディスクリプタテーブルを作成し設定する
- [naskfunc.S](/naskfunc.S)
    - LGDT および LIDT を呼び出す load_gdtr, load_idtr 追加

----

Next: [harib03a](harib03a.md), Previous: [harib02h](harib02h.md), Up: [Chapter5](chapter5.md)
