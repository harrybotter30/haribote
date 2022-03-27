Next: [harib06c](harib06c.md), Previous: [harib06a](harib06a.md), Up: [Chapter9](chapter9.md)

----

# Chapter9

## harib06b

### 課題

メモリ容量を取得する。

### 学習

#### i468 の判定

- フラグレジスタ 15, 14 ビット（Reserved, Nested task flag）をクリアできない
    - 8086, 80186
- フラグレジスタ 14-12 ビット（Nested task flag, I/O privilege level）をセットできない
    - 80286
- フラグレジスタ 18 ビット（Alignment check）をセットできない
    - 80386
- フラグレジスタ 21 ビット（Able to use CPUID instruction）を反転できない
    - i486
- それ以降は cpuid で判定できる

#### CPU キャッシュの無効化

CR0 は以下の意味を持っているので、30, 29 ビットをセットするということは、Cache disable と Not-write through を設定することを意味する。

```
 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
+--+--+--+-----------------------------+--+--+--+-----------------------------+--+--+--+--+--+--+
|PG|CD|NW|                             |AM|  |WP|                             |NE|ET|TS|EM|MP|PE|
+--+--+--+-----------------------------+--+--+--+-----------------------------+--+--+--+--+--+--+
```

ただし、NW は Not-write through と名付けられているものの、Pentium およびそれ以降では意味が変更されて NW == 0 でライトバックが有効になる。

#### 容量取得方法

メモリが搭載されているかどうか判らないポインタに対して

- 特定の値を書き込む
- 以下の操作を二回行う
    - ポインタが指すメモリの値をビット反転する
    - 期待した値になっているか確認する

を行い、書き込めている間はポインタを進め、書き込めなくなるところを探す

#### 参考

- [Detect x86 CPU Type (8086, i286, i386, i486, Pentium, Pentium Pro) · GitHub](https://gist.github.com/ljmccarthy/e87d0e0b028413fad3317ad80e9e4db1)
- [Detecting Intel Processors -- Knowing the generation of a system CPU](http://www.rcollins.org/ddj/Sep96/Sep96.html)
- [FLAGS register - Wikipedia](https://en.wikipedia.org/wiki/FLAGS_register#FLAGS)
- [Control register - Wikipedia](https://en.wikipedia.org/wiki/Control_register#CR0)

### 成果

- [bootpack.c](/bootpack.c)
    - メモリチェック関数を追加
- [bootpack.h](/bootpack.h)
    - CR0 読み書き関数を定義
- [naskfunc.S](/naskfunc.S)
    - CR0 読み書き関数を追加

----

Next: [harib06c](harib06c.md), Previous: [harib06a](harib06a.md), Up: [Chapter9](chapter9.md)
