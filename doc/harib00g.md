Next: [harib00h](harib00h.md), Previous: [harib00f](harib00f.md), Up: [Chapter3](chapter3.md)

----

# Chapter3

## harib00g

### 課題

画面モードを切り替える。

### 学習

#### Video BIOS

INT 10h で Video BIOS を呼び出せる。

（一部）

機能番号 | 機能
-------- | ----
AH = 00h | ビデオモードを設定する
AH = 01h | テキストモードカーソル形状を設定する
AH = 02h | カーソル位置を設定する
AH = 03h | カーソル位置とサイズを取得する
AH = 04h | ライトペンの位置を読み取る（EGA のみ）
AH = 05h | アクティブな表示ページを選択する
AH = 06h | ウィンドウをスクロールアップする
AH = 07h | ウィンドウをスクロールダウンする
AH = 08h | カーソル位置の文字と属性を読み取る
AH = 09h | カーソル位置に文字と属性を書き込む
AH = 0Ah | カーソル位置に文字だけを書き込む
AH = 0Bh | 背景・境界色を設定する/パレットを設定する
AH = 0Ch | グラフィックピクセルを書く
AH = 0Dh | グラフィックピクセルを読む
AH = 0Eh | テレタイプ出力
AH = 0Fh | 現在のビデオモードを取得する

#### ビデオモード

モード | T/G | text resol | pixel box | pixel resol | colors | display pages | screen addr | system
------ | --- | ---------- | --------- | ----------- | ------ | ------------- | ----------- | ------
00h | T | 40x25 | 8x14 | | 16gray | 8 | B800 | EGA
00h | T | 40x25 | 8x16 | | 16     | 8 | B800 | MCGA
00h | T | 40x25 | 9x16 | | 16     | 8 | B800 | VGA
01h | T | 40x25 | 8x14 | | 16 | 8 | B800 | EGA
01h | T | 40x25 | 8x16 | | 16 | 8 | B800 | MCGA
01h | T | 40x25 | 9x16 | | 16 | 8 | B800 | VGA
02h | T | 80x25 | 8x14 | | 16gray | 4 | B800 | EGA
02h | T | 80x25 | 8x16 | | 16     | 4 | B800 | MCGA
02h | T | 80x25 | 9x16 | | 16     | 4 | B800 | VGA
03h | T | 80x25 | 8x14 | | 16 | 4 | B800 | EGA
03h | T | 80x25 | 8x16 | | 16 | 4 | B800 | MCGA
03h | T | 80x25 | 9x16 | | 16 | 4 | B800 | VGA
04h | G | 40x25 | 8x8 | 320x200 | | 4 | B800 | CGA,PCjr,EGA,MCGA,VGA
05h | G | 40x25 | 8x8 | 320x200 | 4gray | | B800 | CGA,PCjr,EGA
05h | G | 40x25 | 8x8 | 320x200 | 4 | | B800 | MCGA,VGA
06h | G | 80x25 | 8x8 | 640x200 | 2 | | B800 | CGA,PCjr,EGA,MCGA,VGA
07h | T | 80x25 | 9x14 | | mono | var | B000 | MDA,Hercules,EGA
07h | T | 80x25 | 9x16 | | mono |     | B000 | VGA
0Bh | | | | | | | | reserved (used internally by EGA BIOS)
0Ch | | | | | | | | reserved (used internally by EGA BIOS)
0Dh | G | 40x25 | 8x8 | 320x200 | 16 | 8 | A000 | EGA,VGA
0Eh | G | 80x25 | 8x8 | 640x200 | 16 | 4 | A000 | EGA,VGA
0Fh | G | 80x25 | 8x14 | 640x350 | mono | 2 | A000 | EGA,VGA
10h | G | 80x25 | 8x14 | 640x350 | 4    | 2 | A000 | 64k EGA
10h | G |       |      | 640x350 | 16   |   | A000 | 256k EGA,VGA
11h | G | 80x30 | 8x16 | 640x480 | mono | | A000 | VGA,MCGA,ATI EGA,ATI VIP
12h | G | 80x30 | 8x16 | 640x480 | 16/256k | | A000 | VGA,ATI VIP
12h | G | 80x30 | 8x16 | 640x480 | 16/64   | | A000 | ATI EGA Wonder
13h | G | 40x25 | 8x8 | 320x200 | 256/256k | | A000 | VGA,MCGA,ATI VIP

#### メモリダイレクトアドレス

IPL が何シリンダ読んだのかを ```0x0ff0``` に格納した。
これを GAS では

```Assembly
	movb	%ch, (0x0ff0)
```

と書く。

リスティングファイルおよび最終的な ```haribote.img``` ともに ```88 2E F0 0F``` という命令になっている。

これは

```Assembly
	mov	mem/reg1, mem/reg2
```
の ```100010dw``` ```mod reg r/m``` になっている。

オペコード | 意味
---------- | ----
w   | 0: 8 ビット移動、1: 16 ビット移動
d   | 移動の方向を示す

d  | 意味
-- | ----
0 | mod と r/m で示されるオペランドは mem/reg1 で、reg で示されるオペランドは mem/reg2
1 | mod と r/m で示されるオペランドは mem/reg2 で、reg で示されるオペランドは mem/reg1

オペランド | 意味
---------- | ----
mod | 上位 2 ビットで、メモリとレジスタのアドレッシングを区別する
reg | 中位 3 ビットで、操作に用いられるレジスタを表す
r/m | 下位 3 ビットで、mod フィールドとともにアドレッシングを表す

mod | 意味
--- | ----
00 | r/m は絶対アドレスでディスプレイスメントなし
01 | r/m は絶対アドレスでその後に 1 バイトのディスプレイスメントが後続
10 | r/m は絶対アドレスでその後に 2 バイトのディスプレイスメントが後続
11 | r/m はレジスタで前述の w に応じてサイズが決まる

reg | w == 0 | w == 1
--- | --- | ---
000 | %al | %ax
001 | %cl | %cx
010 | %dl | %dx
011 | %bl | %bx
100 | %ah | %sp
101 | %ch | %bp
110 | %dh | %si
111 | %bh | %di

r/m | mod == 00 | mod == 01 | mod == 10 | w == 0 | w == 1
--- | --------- | ----------- | ------- | ------ | ------
000 | %bx+%si | %bx+%si+disp8 | %bx+%si+disp16 | %al | %ax
001 | %bx+%di | %bx+%di+disp8 | %bx+%di+disp16 | %cl | %cx
010 | %bp+%si | %bp+%si+disp8 | %bp+%si+disp16 | %dl | %dx
011 | %bp+%di | %bp+%di+disp8 | %bp+%di+disp16 | %bl | %bx
100 | %si     | %si+disp8     | %si+disp16     | %ah | %sp
101 | %di     | %di+disp8     | %di+disp16     | %ch | %bp
110 | direct  | %bp+disp8     | %bp+disp16     | %dh | %si
111 | %bx     | %bx+disp8     | %bx+disp16     | %bh | %di

今回の場合 ```88 2E F0 0F``` なので、

- w == 0 から 8 ビット移動
- d == 0 から mod と r/m で示されるオペランドは mem/reg1 で、reg で示されるオペランドは mem/reg2
- mod == 00 から r/m は絶対アドレスでディスプレイスメントなし
- reg == 101 から（かつ w == 0）対象は %ch
- r/m == 110 から（かつ mod == 00）対象はダイレクトアドレス

となり、

```Assembly
	mov	[0ff0h], ch
```

の意味になることが確認できた。

#### 参考

- [INT 10 -- VGA BIOS](https://pdos.csail.mit.edu/6.828/2008/readings/hardware/vgadoc/VGABIOS.TXT)

### 成果

- [haribote.S](/haribote.S)
    - ビデオモード 13h を設定する
- [ipl10.S](/ipl10.S)
    - 10 シリンダ読み込むため名前を変更
    - 読み込んだシリンダ数を [0x0ff0] に保存

----

Next: [harib00h](harib00h.md), Previous: [harib00f](harib00f.md), Up: [Chapter3](chapter3.md)
