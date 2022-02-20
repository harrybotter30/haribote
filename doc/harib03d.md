Next: [harib03e](harib03e.md), Previous: [harib03c](harib03c.md), Up: [Chapter6](chapter6.md)

----

# Chapter6

## harib03d

### 課題

PIC を初期化する。

### 学習

#### 8259A PIC の初期化

init_pic() では Intel 8259A PIC (Programmable Interrupt Controller) の初期化を行う。
内容を擬似アセンブリ言語風に記述すると以下のようになる。

```Assembly
	outb	$0xff, $0x0021  ; 全ての割り込みを受け付けない
	outb	$0xff, $0x00a1  ; 全ての割り込みを受け付けない

	outb	$0x11, $0x0020  ; エッジトリガモード
	outb	$0x20, $0x0021  ; IRQ0-7は、INT20-27で受ける
	outb	$4, $0x0021     ; PIC1はIRQ2にて接続
	outb	$0x01, $0x0021  ; ノンバッファモード

	outb	$0x11, $0x00a0  ; エッジトリガモード
	outb	$0x28, $0x00a1  ; IRQ8-15は、INT28-2fで受ける
	outb	$2, $0x00a1     ; PIC1はIRQ2にて接続
	outb	$0x01, $0x00a1  ; ノンバッファモード

	outb	$0xfb, $0x0021  ; 11111011 PIC1以外は全て禁止
	outb	$0xff, $0x00a1  ; 11111111 全ての割り込みを受け付けない
```

このうち二番目のブロックでマスタ PIC を、三番目のブロックでスレーブ PIC を初期化している。

ポートアドレス | 用途
------ | --------
0x0020 | マスタ PIC コマンド（ステータス）
0x0021 | マスタ PIC データ
0x00a0 | スレーブ PIC コマンド（ステータス）
0x00a1 | スレーブ PIC データ

初期化シーケンスはデータポートに ICW1 (Initialization Command Word 1) を出力することで開始され、続けて ICW2, ICW3, ICW4（指定によっては ICW3, ICW4 はスキップ）をコマンドポートに出力することで終了する。

#### ICW1

最初にポート 0x0020（または 0x00a0）に出力する 8bit は以下の意味を持つ。

```
            +----+----+----+----+----+----+----+----+
    ICW1    | Int Vec Addr |  1 |LTIM|ADI |SNGL|IC4 |
            +----+----+----+----+----+----+----+----+
    Interrupt Vector Address (MCS-80/85 mode only)
    LTIM    1: Level Trigger Mode / 0: Edge Trigger Mode
    ADI     Call Address Interval, 1: interval of 4 / 0: interval of 8
    SNGL    1: Single Mode / 0: Cascade Mode
    IC4     1: ICW4 Needed / 0: No ICW4 Needed
```

- SNGL == 1 であればこの後の ICW3 は発行されない。
- IC4 == 0 であればこの後の ICW4 は発行されない。

今回は 0x11 を出力しているので以下の意味となる。

- Interrupt Vector Address == 0: （8086 モードでは使用しない）
- LTIM == 0: Edge Trigger Mode
- ADI == 0: Interval == 8
- SNGL == 0: Cascade Mode（ICW3 は発行される）
- IC4 == 1: ICW4 Needed

#### ICW2

次にポート 0x0021（または 0x00a1）に出力する 8bit は以下の意味を持つ。

```
            +----+----+----+----+----+----+----+----+
    ICW2    |A8-A15 (MCS-80/85) or T7-T3 (8086/8088)|
            +----+----+----+----+----+----+----+----+
```

どちらのモードでもこの PIC で使用する割り込みベクタ番号（の最初の値？）を指定するようだが、8086/8088 mode の場合下位 3bit は無効らしい。8 の倍数でしか指定できないということか？

また、割り込みベクタ 0-31 は例外割り込みに使用されていたり予約されていたりするので、32-255 の範囲から指定するようにする。

今回は 0x20（マスタ）, 0x28（スレーブ）を出力しているので以下の意味となる。

- マスタからの IR0-7 を INT 0x20-0x27 に割り当てる
- スレーブからの IR8-15 を INT 0x28-0x2f に割り当てる

#### ICW3

次にポート 0x0021（または 0x00a1）に出力する 8bit は以下の意味を持つ。
ICW1 で SNGL == 0 にした場合のみこの設定を行い、SNGL == 1 にした場合はこの設定を行わない。

```
            +----+----+----+----+----+----+----+----+
    ICW3/M  |1: has a slave/0: does not have a slave|
            +----+----+----+----+----+----+----+----+
            +----+----+----+----+----+----+----+----+
    ICW3/S  |  0 |  0 |  0 |  0 |  0 |  slave id    |
            +----+----+----+----+----+----+----+----+
```

上図のようにマスタ PIC への設定と、スレーブ PIC への設定は異なる。

マスタはビットマップでスレーブが接続されているラインを指定する。
スレーブはマスタ側のラインを指定する。

PC ではマスタの IR2 がスレーブと接続されているので、

- マスタ側では (1 << 2) == 4
- スレーブ側では 2

を設定する。

#### ICW4

最後にポート 0x0021（または 0x00a1）に出力する 8bit は以下の意味を持つ。
ICW1 で IC4 == 1 にした場合のみこの設定を行い、IC4 == 0 にした場合はこの設定を行わない。

```
            +----+----+----+----+----+----+----+----+
    ICW4    |  0 |  0 |  0 |SFNM|BUF |M/S |AEOI|μPM |
            +----+----+----+----+----+----+----+----+
    SFNM    1: Special Fully Nested Mode / 0: Not Special Fully Nested Mode
    BUF     0: Non Buffered Mode / 1: Buffered Mode
    M/S     1: Buffered Mode Master / 0: Buffered Mode Slave
    AEOI    1: Auto EOI / 0: Normal EOI
    μPM     1: 8086/8088 mode / 0: MCS-80/85 mode
```

今回は 0x01 を出力しているので以下の意味となる。

- SFNM == 0: Not Special Fully Nested Mode
- BUF == 0: Non Buffered Mode
- M/S == 0: Non Buffered Mode なので不使用
- AEOI == 0: Normal EOI
- μPM == 1: 8086/8088 mode

#### 割り込みのマスク（OCW1）

データポートに OCW1 (Operation Command Words 1) を出力することで割り込みをマスクできる。出力する 8bit はビットマップで割り込みライン番号（スレーブの場合は番号 -8）を指定すれば良い。

今回は初期化の

- 最初のブロックで IR0-7, 8-15 をすべてマスク
- 最後ののブロックで IR0, 1, 3-7, 8-15（IR2 以外すべて）をマスク

していることが判る。

#### 参考

- [8259A Programmable Interrupt Controller](https://pdos.csail.mit.edu/6.828/2014/readings/hardware/8259A.pdf)
- [8259 PIC - OSDev Wiki](http://wiki.osdev.org/8259_PIC)
- [パソコンのレガシィI/O活用大全](http://www.cqpub.co.jp/column/books/2001a/34331PC_Legacy/default.htm)
- [０から作るOS開発　割り込みその２　PICとIRQ](https://web.archive.org/web/20200201060558/http://softwaretechnique.jp/OS_Development/kernel_development03.html)

### 成果

- [Makefile](/Makefile)
    - int.c 追加
- [bootpack.c](/bootpack.c)
    - init_pic() 呼び出し
- [bootpack.h](/bootpack.h)
    - PIC 関連定数追加
- [int.c](/int.c)
    - init_pic() 実装

----

Next: [harib03e](harib03e.md), Previous: [harib03c](harib03c.md), Up: [Chapter6](chapter6.md)
