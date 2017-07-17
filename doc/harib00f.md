Next: [harib00g](harib00g.md), Previous: [harib00e](harib00e.md), Up: [Chapter3](chapter3.md)

----

# Chapter3

## harib00f

### 課題

ブートセクタから haribote.sys を呼び出す。

### 学習

- ソース上の ```jmp 0xc200``` はリスティングファイルによれば ```E9FEC1``` に変換されていた。
- この命令のオフセットは ```0x00a8``` で jmp の次の命令は ```0x00ab```。
- jmp disp16 は ```e9 <disp-low> <disp-high>```。
- よって ```0x00ab + 0xc1fe == 0xc2a9``` ？？？

生成されたコードが誤っており、また何か変更が必要と考えていたが...

- haribote.img でのこの部分は ld によって ```e9 55 45``` に書き換えられていた。
- ブートセクタは ```0x7c00``` にロードされるためこの命令は ```0x7ca8``` に存在する。
- 次の命令は ```0x7cab``` でジャンプオフセットは ```0x4555``` より
  ```0x7cab + 0x4555 == 0xc200```。
- 無事 haribote.sys の内容にジャンプすることが確認できた。

### 成果

- [binary.lds](/binary.lds)
    - haribote.sys が 0xc200 にロードされることを明示（haribote.img の作成には使用しないので実際には意味がない）
- [ipl.S](/ipl.S)
    - ディスクを読み終わったら 0xc200 にジャンプする

----

Next: [harib00g](harib00g.md), Previous: [harib00e](harib00e.md), Up: [Chapter3](chapter3.md)
