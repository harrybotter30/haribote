Next: [harib05e](harib05e.md), Previous: [harib05c](harib05c.md), Up: [Chapter8](chapter8.md)

----

# Chapter8

## harib05d

### 課題

マウスカーソルを動かす。

### 学習

復号したマウスデータパケットを参照してマウスカーソルを動かす。

- マウスカーソルを消す
- マウスの移動量でマウスカーソルの位置を更新する
- デスクトップの範囲を超えないよう補正
- マウスカーソルを描画する

デスクトップ上の描画内容に配慮していないのでタスクバーに触れると消してしまう。

### 成果

- [bootpack.c](/bootpack.c)
    - マウスデータパケットを参照してマウスカーソルを動かす

----

Next: [harib05e](harib05e.md), Previous: [harib05c](harib05c.md), Up: [Chapter8](chapter8.md)
