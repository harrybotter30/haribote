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

#### load_gdtr, load_idtr の補足

harib03c の後半に load_gdtr, load_idtr の補足があった。

しかし、この内容は [harib02i の「load_gdtr, load_idtr 呼び出し」](harib02i.md#load_gdtr-load_idtr-%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%97) で確認済み。

#### set_segmdesc に関する補足

harib03c の後半に set_segmdesc に関する補足があった。

しかし、この内容についても [harib02i の「セグメントディスクリプタの構造」](harib02i.md#%E3%82%BB%E3%82%B0%E3%83%A1%E3%83%B3%E3%83%88%E3%83%87%E3%82%A3%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%97%E3%82%BF%E3%81%AE%E6%A7%8B%E9%80%A0)で確認済み。

また、セグメント種別に関する補足については [harib02i の「セグメントディスクリプタ・割り込みディスクリプタの設定内容」](harib02i.md#%E3%82%BB%E3%82%B0%E3%83%A1%E3%83%B3%E3%83%88%E3%83%87%E3%82%A3%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%97%E3%82%BF%E5%89%B2%E3%82%8A%E8%BE%BC%E3%81%BF%E3%83%87%E3%82%A3%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%97%E3%82%BF%E3%81%AE%E8%A8%AD%E5%AE%9A%E5%86%85%E5%AE%B9)で確認済み。

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
