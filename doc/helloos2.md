Next: [helloos3](helloos3.md), Previous: [helloos1](helloos1.md), Up: [Chapter1](chapter1.md)

----

# Chapter1

## helloos2

### 課題

ソース内のデータ部分を理解しやすい形に書き換える。

### 学習

#### ディレクティブ

- .short
    - 普通は .word と同じ（多分 16 ビット整数）
- .long
    - 普通は .int と同じ（多分 32 ビット整数）
- .ascii
    - 文字列リテラル（\0 で終わるのは .asciz）
- .org
    - 指定した値までロケーションカウンタを進める

オリジナルの ```RESB 0x1fe-$``` を ```.space 0x1fe-$``` に置き換えたところエラーになった。

```shell-session
$ ./asm
helloos.S: Assembler messages:
helloos.S:37: Error: .space specifies non-absolute value
```

そのため、```.org 0x1fe``` を使用した。

### 成果

- [helloos.S](/helloos.S)
    - helloos.nas を参考に gas 用に書き換えたソース

----

Next: [helloos3](helloos3.md), Previous: [helloos1](helloos1.md), Up: [Chapter1](chapter1.md)
