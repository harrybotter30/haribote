# haribote

川合秀実著「[30日でできる！　OS自作入門](https://book.mynavi.jp/ec/products/detail/id=22078)」について学習するリポジトリ。

- Linux 上で実施する
- 独自ツール群ではなく GNU toolchain を利用する
- GitHub の練習も行う

## 目次

### [Chapter1](/doc/chapter1.md)

#### [helloos0](/doc/helloos0.md)

バイナリエディタで、起動後特定のメッセージを表示するだけのフロッピーディ
スクイメージを作る。

#### [helloos1](/doc/helloos1.md)

gas を使って helloos.img を生成する。

#### [helloos2](/doc/helloos2.md)

ソース内のデータ部分を理解しやすい形に書き換える。

### [Chapter2](/doc/chapter2.md)

#### [helloos3](/doc/helloos3.md)

ソース内のプログラム部分を理解しやすい形に書き換える。

#### [helloos4](/doc/helloos4.md)

ソースからディスクイメージを構成する部分を削除し、ブートセクタのみ記述
する。

#### [helloos5](/doc/helloos5.md)

Makefile を使用して開発環境を管理する。

### [Chapter3](/doc/chapter3.md)

#### [harib00a](/doc/harib00a.md)

Disk BIOS を使用してブートセクタ以外のセクタを読み込む。

#### [harib00b](/doc/harib00b.md)

ディスク読み込みでエラーが発生した時にリトライする。

#### [harib00c](/doc/harib00c.md)

18 セクタまで読み込む。

#### [harib00d](/doc/harib00d.md)

10 シリンダ分読み込む。

#### [harib00e](/doc/harib00e.md)

halt するだけの OS である haribote.sys を含むディスクイメージを作成する。

#### [harib00f](/doc/harib00f.md)

ブートセクタから haribote.sys を呼び出す。

#### [harib00g](/doc/harib00g.md)

画面モードを切り替える。

#### [harib00h](/doc/harib00h.md)

キーボードのシフト状態を取得する。

#### [harib00i](/doc/harib00i.md)

C 言語で OS を記述できるようにする。

#### [harib00j](/doc/harib00j.md)

OS を hlt できるようにする。

### [Chapter4](/doc/chapter4.md)

#### [harib01a](/doc/harib01a.md)

メモリにデータを書き込む関数を追加する。

#### [harib01b](/doc/harib01b.md)

画面に縞模様を表示する。

#### [harib01c](/doc/harib01c.md)

write_mem8() の代わりにポインタを使う。

#### [harib01d](/doc/harib01d.md)

ポインタの表記を変える(1)。

#### [harib01e](/doc/harib01e.md)

ポインタの表記を変える(2)。

#### [harib01f](/doc/harib01f.md)

カラーパレットを設定する。

#### [harib01g](/doc/harib01g.md)

正方形を描く。

#### [harib01h](/doc/harib01h.md)

空のデスクトップを描く。

### [Chapter5](/doc/chapter5.md)

#### [harib02a](/doc/harib02a.md)

画面情報を起動情報から受け取る。

#### [harib02b](/doc/harib02b.md)

#### [harib02c](/doc/harib02c.md)

#### [harib02d](/doc/harib02d.md)

#### [harib02e](/doc/harib02e.md)

#### [harib02f](/doc/harib02f.md)

#### [harib02g](/doc/harib02g.md)

#### [harib02h](/doc/harib02h.md)

#### [harib02i](/doc/harib02i.md)

