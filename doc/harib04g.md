Next: [harib05a](harib05a.md), Previous: [harib04f](harib04f.md), Up: [Chapter7](chapter7.md)

----

# Chapter7

## harib04g

### 課題

マウスからデータを受信する。

### 学習

マウスからの割り込みをハンドラ内で FIFO に積み直し、メインループで画面に表示する。

方法は [harib04a](harib04a.md) と同様だが、
- IRQ-12 の受付完了を表すために 0x64 == 0b01100100（SL | EOI | L2）
- IRQ-02 の受付完了を表すために 0x62 == 0b01100010（SL | EOI | L1）
の二回の通知を行っている。

### 成果

- [bootpack.c](/bootpack.c)
    - マウスバッファにデータがあればそれを表示する
- [int.c](/int.c)
    - 割り込みハンドラではマウスからの送信データを取得しバッファに保存する

----

Next: [harib05a](harib05a.md), Previous: [harib04f](harib04f.md), Up: [Chapter7](chapter7.md)
