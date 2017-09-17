Next: [harib04b](harib04b.md), Previous: [harib03e](harib03e.md), Up: [Chapter7](chapter7.md)

----

# Chapter7

## harib04a

### 課題

キーコードを取得する。

### 学習

#### 割り込み完了通知（OCW2）

割り込み処理が完了したら PIC に対して EOI (End Of Interrupt) 通知を行う。

コマンドポート（マスタ: 0x0020、スレーブ: 0x00a0）に OCW2 (Operation Command Words 2) を出力することで EOI を通知できる。

```
            +----+----+----+----+----+----+----+----+
    OCW2    |  R | SL |EOI |  0 |  0 | L2 | L1 I L0 |
            +----+----+----+----+----+----+----+----+
```

R  | SL | EOI | 意味 | グループ
-- | -- | --- | ---- | --------
0 |  0 |  1  | NON-SPECIFIC EOI COMMAND | END OF INTERRUPT
0 |  1 |  1  | SPECIFIC EOI COMMAND | 〃
1 |  0 |  1  | ROTATE ON NON-SPECIFIC EOI COMMAND | AUTOMATIC ROTATION
1 |  0 |  0  | ROTATE IN AUTOMATIC EOI MODE (SET) | 〃
0 |  0 |  0  | ROTATE IN AUTOMATIC EOI MODE (CLEAR) | 〃
1 |  1 |  1  | *ROTATE ON SPECIFIC EOI COMMAND | SPECIFIC ROTATION
1 |  1 |  0  | *SET PRIORITY COMMAND | 〃
0 |  1 |  0  | NO OPERATION

*L0-L2 ARE USED

これらのビットは、

- R: ROTATE をするかしないか？
- SL: L0-L2（0-7）の IR LEVEL を参照するかしないか？
- EOI: End Of Interrupt 通知を行うか行わないか？

を表す。

今回は 0x61 なので

- ```R == 0```: ROTATE しない
- ```SL == 1```: L0-L2 の IR LEVEL を参照する
- ```EOI == 1```: EOI 通知を行う
- ```L0-L2 == 1```: 対象は IR LEVEL 1（キーボード）

#### キーコードの取得

キーコードを取得するにはポート ```0x60``` から読み込めばよい。

#### 参考

- [The PS/2 Keyboard Interface](http://www.computer-engineering.org/ps2keyboard/)
- [8259A Programmable Interrupt Controller](https://pdos.csail.mit.edu/6.828/2014/readings/hardware/8259A.pdf)
- [パソコンのレガシィI/O活用大全](http://www.cqpub.co.jp/column/books/2001a/34331PC_Legacy/default.htm)

### 成果

- [bootpack.h](/bootpack.h)
    - io_in8() 定義
- [int.c](/int.c)
    - 割り込みハンドラでキーコードを取得して表示

----

Next: [harib04b](harib04b.md), Previous: [harib03e](harib03e.md), Up: [Chapter7](chapter7.md)
