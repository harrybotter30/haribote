Next: [harib00b](harib00b.md), Previous: [helloos5](helloos5.md), Up: [Chapter3](chapter3.md)

----

# Chapter3

## harib00a

### 課題

Disk BIOS を使用してブートセクタ以外のセクタを読み込む。

### 学習

- PC/AT の Disk BIOS は INT 13h を使用する。
- セクタ読み込み機能は AH=02h

#### INT 13h AH=02h: Read Sectors From Drive

- パラメータ

レジスタ | 値
---- | ----
%ah | 02h
%al | 読み込みセクタ数
%ch | シリンダ番号
%cl | セクタ番号（下位 6 ビットまで、上位 2 ビットはシリンダ番号の 10, 9 ビットとして扱われる）
%dh | ヘッド番号
%dl | ドライブ番号
%es:%bx  | 読み込みバッファアドレス

- 結果

レジスタ | 値
---- | ----
cf | エラー時に設定
%ah | リターンコード
%al | 読み込みセクタ数

##### 参考

- [INT 13h AH=02h: Read Sectors From Drive](https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH.3D02h:_Read_Sectors_From_Drive)

##### その他

- ブートセクタの名前を "HELLOIPL" から "HARIB0TE" に変更
- ディスクラベルを "HELLO-OS" から "HARIB0TE" に変更
- ディスクイメージを helloos.img から haribote.img に変更
- それに合わせてリンカスクリプトも helloos.lds から haribote.lds に変更
- QEMU の起動オプションが誤っていたので修正

### 成果

- [ipl.S](/ipl.S)
    - 第 2 セクタ読み込み処理を追加
- [haribote.lds](/haribote.lds)
    - ディスクイメージ構成部分を追加
- [Makefile](/Makefile)
    - 名前変更と QEMU 起動オプションの修正

----

Next: [harib00b](harib00b.md), Previous: [helloos5](helloos5.md), Up: [Chapter3](chapter3.md)
