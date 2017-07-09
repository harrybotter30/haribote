Next: [helloos5](helloos5.md), Previous: [helloos3](helloos3.md), Up: [Chapter2](chapter2.md)

----

# Chapter2

## helloos4

### 課題

ソースからディスクイメージを構成する部分を削除し、ブートセクタのみ記述
する。

### 学習

ディスクイメージ構成部分の削除は問題なし。
問題はディスクイメージをどのように生成するか？

helloos0　で作成した [hex2bin](/support/hex2bin) を使用しても良いが、
最終的なイメージを生成する ld で実現するのが最も適切に思える。

調べてみるとロケーションカウンタ部分に任意のデータを出力する、'BYTE',
'SHORT', 'LONG', 'QUAD', 'SQUAD' というコマンドが見つかった。

また、出力セクション内の値が指定されていない部分を特定データで埋める
'=FILLEXP' という機能があったのでそれを使用した。

```
OUTPUT_FORMAT(binary)
SECTIONS
{
  . = 0x7c00;
  .text : {
    *(.text);
    BYTE(0xf0);
    BYTE(0xff);
    BYTE(0xff);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    . += 4600;
    BYTE(0xf0);
    BYTE(0xff);
    BYTE(0xff);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    . += 1469432;
  } = 0x00000000
}
```

#### 参考

- [Using LD, the GNU linker - Section Data Expressions](http://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_node/ld_20.html)

### 成果

- [ipl.S](/ipl.S)
    - ディスクイメージ構成部分を削除し名前を変更
- [helloos.lds](/helloos.lds)
    - ディスクイメージ構成部分を追加
- [asm](/asm)
    - ソース名を変更およびリスティングファイルを出力

----

Next: [helloos5](helloos5.md), Previous: [helloos3](helloos3.md), Up: [Chapter2](chapter2.md)
