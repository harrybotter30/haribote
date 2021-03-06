Next: [harib00i](harib00i.md), Previous: [harib00g](harib00g.md), Up: [Chapter3](chapter3.md)

----

# Chapter3

## harib00h

### 課題

キーボードのシフト状態を取得する。

### 学習

#### Keyboard BIOS

- INT 16h で Keyboard BIOS を呼び出せる。

機能番号（AH） | 機能
-------------- | ----
00h | 入力された文字を読み込む
01h | 入力状態を読み込む
02h | キーボードのシフト状態を読み込む
05h | キーボードバッファにキーストロールを保存する
0Ah | キーボードの ID を取得する
10h | 入力された文字を読み込む（拡張）
11h | 入力状態を読み込む（拡張）
12h | キーボードのシフト状態を読み込む（拡張）

#### シフト状態

- AH == 02h でシフト状態を取得できる。

- AL: ビットフラグでシフト状態を表す
- AH: 多くの BIOS で破壊される

ビット位置 | キー
---------- | ----
7 | Insert
6 | CapsLock
5 | NumLock
4 | ScrollLock
3 | Alt
2 | Ctrl
1 | left Shift
0 | right Shift

#### メモリダイレクトアドレス

- いくつかの値を固定メモリアドレスに書き込んでいたので確認する。

アセンブリ言語 | 機械語
-------------- | ------
```movb	$8, (VMODE)``` | ```C6 06 F2 0F 08```
```movw	$320, (SCRNX)``` | ```C7 06 F4 0F 40 01```
```movw	$200, (SCRNY)``` | ```C7 06 F6 0F C8 00```
```movl	$0x000a0000, (VRAM)``` | ```66 C7 06 F8 0F 00 00 0A 00```
```movb	%al, (LEDS)``` | ```A2 F1 0F```

- ```C6 06```

```Assembly
	mov	mem/reg, data
```
の ```1100011w``` ```mod 000 r/m``` ```kk``` ```jj``` になっている。

オペコード | 意味
---------- | ----
w | 0: 8 ビット移動、1: 16 ビット移動

オペランド | 意味
---------- | ----
mod | 上位 2 ビットで、メモリとレジスタのアドレッシングを区別する
000 | 中位 3 ビットで、この場合は使用しない
r/m | 下位 3 ビットで、mod == 11 の場合はレジスタを表す

mod | 意味
--- | ----
00 | r/m は絶対アドレスでディスプレイスメントなし
01 | r/m は絶対アドレスでその後に 1 バイトのディスプレイスメントが後続
10 | r/m は絶対アドレスでその後に 2 バイトのディスプレイスメントが後続
11 | r/m はレジスタで前述の w に応じてサイズが決まる

r/m（mod == 00 の場合） | 意味
----------------------- | ----
000 | %bx+%si
001 | %bx+%di
010 | %bp+%si
011 | %bp+%di
100 | %si
101 | %di
110 | direct
111 | %bx

今回の場合 ```C6 06 F2 0F 08``` なので、

- w == 0 から 8 ビット操作
- mod == 00 から対象は絶対アドレスでディスプレイスメントなし
- r/m == 110（かつ mod == 00）から対象はダイレクトアドレス
- kk == f2, jj == 0f からイミディエイトオペランドは 0ff2

となり、

```Assembly
	mov byte ptr	[0ff2h], 8
```

の意味になることが確認できた。

- ```C7 06```

```C7 06``` は ```C6 06``` と w == 1 だけが異なるので、

```Assembly
	mov word ptr	[0ff4h], 0140h
```

や

```Assembly
	mov word ptr	[0ff6h], 00c8h
```

の意味になることが確認できた。

- ```66 C7 06```

```66``` は i386 で拡張されたオペランドサイズプレフィックス命令で、それを除くと ```C7 06``` と同様の意味になるので、

```Assembly
	mov  dword ptr	[0ff8h], 000a0000h
```

の意味になることが確認できた。

- ```A2```

```Assembly
	mov	mem, ac
```
の ```1010001w``` ```kk``` ```jj``` になっている。

オペコード | 意味
---------- | ----
w | 0: 8 ビット移動（%al がソース）、1: 16 ビット移動（%ax がソース）

今回の場合 ```A2 F1 0F``` なので、

- w == 0 から 8 ビット操作（%al がソース）

となり、

```Assembly
	mov byte ptr	[0ff1h], al
```

の意味になることが確認できた。

#### 参考

- [INT 16H - Wikipedia](https://en.wikipedia.org/wiki/INT_16H)
- [Int 16/AH=02h](http://www.ctyme.com/intr/rb-1756.htm)
- [80386 Programmer's Reference Manual -- Section 16.2](http://css.csail.mit.edu/6.858/2013/readings/i386/s16_02.htm)

### 成果

- [ipl.S](/ipl.S)
    - キーボードのシフト状態を取得して 0x0ff1 に保存する（1 バイト）
    - ビデオの色深度を 0x0ff2 に保存する（1 バイト）
    - ビデオの X 解像度を 0x0ff4 に保存する（2 バイト）
    - ビデオの Y 解像度を 0x0ff6 に保存する（2 バイト）
    - グラフィックメモリァの開始アドレスを 0x0ff8 に保存する（4 バイト）

----

Next: [harib00i](harib00i.md), Previous: [harib00g](harib00g.md), Up: [Chapter3](chapter3.md)
