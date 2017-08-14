Next: [harib02b](harib02b.md), Previous: [harib01h](harib01h.md), Up: [Chapter5](chapter5.md)

----

# Chapter5

## harib02a

### 課題

画面情報を起動情報から受け取る。

### 学習

[asmhead.S](/asmhead.S) にあるように、起動情報には以下が設定されている。

アドレス | データ型 | 内容
-------- | -------- | ----
0x0ff0 | int8_t | ブートセクタが読み込んだシリンダ数
0x0ff1 | int8_t | [キーボードシフト状態](harib00h.md#%E3%82%B7%E3%83%95%E3%83%88%E7%8A%B6%E6%85%8B)
0x0ff2 | int8_t | bits per pixel （画面モード 0x13 なので 8bpp）
0x0ff4 | int16_t | 画面の X 解像度
0x0ff6 | int16_t | 画面の Y 解像度
0x0ff8 | int32_t | グラフィックバッファの開始番地

### 成果

- [bootpack.c](/bootpack.c)
    - 画面情報を起動情報から受け取り適切にデスクトップを描く

----

Next: [harib02b](harib02b.md), Previous: [harib01h](harib01h.md), Up: [Chapter5](chapter5.md)
