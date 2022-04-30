Next: [harib07c](harib07c.md), Previous: [harib07a](harib07a.md), Up: [Chapter10](chapter10.md)

----

# Chapter10

## harib07b

### 課題

描画オブジェクトを重ね合わせる。

### 学習

#### データ構造

一つのオブジェクトを struct SHEET で表す。  
また、それを MAX_SHEETS まで保持できるようにして全体を struct SHTCTL で管理する。

```C
struct SHEET {
	unsigned char *buf;
	int bxsize, bysize, vx0, vy0, col_inv, height, flags;
};
```

- SHEET::buf はそのシートの描画データを保持するバッファへのポインタ
- SHEET::bxsize, SHEET::bysize はそのシートのサイズ
- SHEET::vx0, vy0 はそのシートのコンソール内の位置
- SHEET::col_inv は背景色
- SHEET::height はシートの Z 表示順（数値の大きいものが上面、0 が最下面、-1 は非表示）
- SHEET::flags は使用中かどうか

```C
struct SHTCTL {
	unsigned char *vram;
	int xsize, ysize, top;
	struct SHEET *sheets[MAX_SHEETS];
	struct SHEET sheets0[MAX_SHEETS];
};
```

- SHTCTL::vram は VRAM へのポインタ
- SHTCTL::xsize, ysize はコンソールのサイズ
- SHTCTL::top は保持しているシートの最上面（-1 は保持シートなし）
- SHTCTL::sheets はシートポインタの Z 表示順配列
- SHTCTL::sheets0 は利用中のシート配列（順不同）

#### 関数

##### 初期化

`struct SHTCTL *shtctl_init(struct MEMMAN *memman, unsigned char *vram, int xsize, int ysize)`

空の struct SHTCTL を作成して返す。

#### 描画シート作成

`struct SHEET *sheet_alloc(struct SHTCTL *ctl)`

空の struct SHEET を一つ作成して返す。シートには使用中のフラグと非表示属性のみ設定する。

#### シートの属性設定

`void sheet_setbuf(struct SHEET *sht, unsigned char *buf, int xsize, int ysize, int col_inv)`

シートに、シートへの描画データを保持するバッファとシートのサイズ・背景色を設定する。

従来 VRAM に対して直接書き込んでいたデータは、ここで割り当てたバッファ（buf）に対して書き込むようにする。  
全シート再描画で実際の画面に反映する。

#### シートの Z 表示順設定

`void sheet_updown(struct SHTCTL *ctl, struct SHEET *sht, int height)`

指定したシートの Z 表示順を指定した値に設定する。  
そのシート以外の表示順も矛盾しないように設定する。  
height に -1 を指定すると非表示になる。

表示順に変更があった場合は内部で sheet\_refresh() を実行する。

#### 全シート再描画

`void sheet_refresh(struct SHTCTL *ctl)`

SHTCTL::sheets[0] から SHTCTL::sheets[SHTCTL::top] まで SHEET::buf の内容を SHTCTL::vram に書き込む。

Z 表示順の最下面（SHEET::height == 0） から順に、より上面のシートを上書きしてゆく。
Z 表示順で後に上書きされるピクセルもすべて描画する。

#### シートの描画位置指定

`void sheet_slide(struct SHTCTL *ctl, struct SHEET *sht, int vx0, int vy0)`

対象シートが非表示でなければ内部で sheet\_refresh() を実行する。

#### シート破棄

`void sheet_free(struct SHTCTL *ctl, struct SHEET *sht)`

対象シートが非表示でなければ非表示にした上で（内部で sheet\_refresh() が実行される）未使用状態にする。

### 成果

- [Makefile](/Makefile)
    - sheet.\[co\] 追加
- [bootpack.c](/bootpack.c)
    - sheet\_\*() に対応
- [bootpack.h](/bootpack.h)
    - sheet.c 対応
- [sheet.c](/sheet.c)
    - 描画オブジェクト重ね合せ処理

----

Next: [harib07c](harib07c.md), Previous: [harib07a](harib07a.md), Up: [Chapter10](chapter10.md)
