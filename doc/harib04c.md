Next: [harib04d](harib04d.md), Previous: [harib04b](harib04b.md), Up: [Chapter7](chapter7.md)

----

# Chapter7

## harib04c

### 課題

FIFO バッファを使う。

### 学習

割り込みハンドラの中ではキーコードを FIFO バッファに格納するだけにし、メインループではバッファから取り出して画面表示をする。

### 成果

- [bootpack.c](/bootpack.c)
    - FIFO バッファにデータがあればそれを表示する
    - 先頭を取り出したらデータをずらす
- [bootpack.h](/bootpack.h)
    - struct KEYBUF で FIFO バッファ使用
- [int.c](/int.c)
    - 割り込みハンドラではキーコードを取得しバッファに保存するだけ

----

Next: [harib04d](harib04d.md), Previous: [harib04b](harib04b.md), Up: [Chapter7](chapter7.md)
