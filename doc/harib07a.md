Next: [harib07b](harib07b.md), Previous: [harib06d](harib06d.md), Up: [Chapter10](chapter10.md)

----

# Chapter10

## harib07a

### 課題

メモリ管理を改善する。

### 学習

1 バイト単位でメモリを確保・解放していると断片化が発生しやすい。  
一定サイズのブロックを単位として管理することで断片化を抑制できる。

ブロックのサイズを 2 の冪乗数 N とした場合、任意の size は

```C
(size + (N - 1)) & ((size_t)(-1) - N)
```

によりブロック単位に丸められる。

### 成果

- [memory.c](/memory.c)
    - bootpack.c からメモリ管理を移動
    - memman\_alloc\_4k(), memman\_free\_4k() を追加

----

Next: [harib07b](harib07b.md), Previous: [harib06d](harib06d.md), Up: [Chapter10](chapter10.md)
