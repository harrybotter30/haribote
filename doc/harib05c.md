Next: [harib05d](harib05d.md), Previous: [harib05b](harib05b.md), Up: [Chapter8](chapter8.md)

----

# Chapter8

## harib05c

### 課題

マウスデータパケットを復号する。

### 学習

マウスのデータパケット 1 バイト目は以下の意味を持つ。

|ビット位置|意味|
|--------:|---|
|7|Y オーバーフロー|
|6|X オーバーフロー|
|5|Y 符号ビット|
|4|X 符号ビット|
|3|常に 1|
|2|中ボタン|
|1|右ボタン|
|0|左ボタン|

マウスのデータパケット 2 バイト目は X 座標の移動量、3 バイト目は Y 座標の移動量を表す。

よって、

```c
		if ((dat & 0xc8) == 0x08) {
			/* 正しい 1 バイト目だった */
			mdec->buf[0] = dat;
			mdec->phase = 2;
		}
```

0xc8 と bit and した結果が 0x08 というのは、X も Y もオーバーフロービットが立っていないことを表す。

また、

```c
		if ((mdec->buf[0] & 0x10) != 0) {
			mdec->x |= 0xffffff00;
		}
```

や

```c
		if ((mdec->buf[0] & 0x20) != 0) {
			mdec->y |= 0xffffff00;
		}
```

は X, Y の符号ビットが立っていたら X, Y の移動量（8 ビット整数）に 0xffffff00 を bit or することで二の補数表現での負数に変換している。  
変則的ではあるが、X, Y の移動量は最上位ビットが別の場所にある 9 ビットの二の補数表現整数と考えることができる。

#### 参考

- [PS/2 Mouse Interfacing / Movement Data Packet](https://web.archive.org/web/20180202180653/http://www.computer-engineering.org/ps2mouse/#Movement_Data_Packet)

### 成果

- [bootpack.c](/bootpack.c)
    - マウスデータパケットを復号して解りやすい情報として管理する

----

Next: [harib05c](harib05c.md), Previous: [harib05a](harib05a.md), Up: [Chapter8](chapter8.md)
