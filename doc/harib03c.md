Next: [harib03d](harib03d.md), Previous: [harib03b](harib03b.md), Up: [Chapter6](chapter6.md)

----

# Chapter6

## harib03c

### 課題

ヘッダファイルを導入する。

### 学習

- *.c から関数プロトタイプや定数、構造体定義を bootpack.h に移動
- bootpack.h に共通の関数プロトタイプや定数、構造体定義を集約
- 絶対メモリアドレスなどのマジックナンバーを定数定義
- $(OBJS) は bootpack.h にも依存

### 成果

- [Makefile](/Makefile)
    - $(OBJS) は bootpack.h にも依存
- [bootpack.c](/bootpack.c)
    - 関数プロトタイプや定数、構造体定義を bootpack.h に移動
    - 絶対メモリアドレスを定数化（ADR_BOOTINFO）
- [bootpack.h](/bootpack.h)
    - 共通の関数プロトタイプや定数、構造体定義を集約
- [dsctbl.c](/dsctbl.c)
    - 関数プロトタイプや定数、構造体定義を bootpack.h に移動
    - 絶対メモリアドレスを定数化（ADR_GDT, ADR_IDT）
    - セグメント種別を定数化（AR_DATA32_RW, AR_CODE32_ER）
- [graphic.c](/graphic.c)
    - 関数プロトタイプや定数、構造体定義を bootpack.h に移動

----

Next: [harib03d](harib03d.md), Previous: [harib03b](harib03b.md), Up: [Chapter6](chapter6.md)
