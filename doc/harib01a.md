Next: [harib01b](harib01b.md), Previous: [harib00j](harib00j.md), Up: [Chapter4](chapter4.md)

----

# Chapter4

## harib01a

### 課題

メモリにデータを書き込む関数を追加する。

### 学習

32bit モードで int32_t の二つの引数を持つ関数を呼び出した場合、
呼び出された関数の中でスタックは以下のようになっている。

```
            |               |
  (%esp)--> +---------------+
            |  ret address  |
 4(%esp)--> +---------------+
            |  1st argument |
 8(%esp)--> +---------------+
            |  2nd argument |
            +---------------+
            |               |
```

通常は関数の先頭で以下の処理を行うので、

```Assembly
	pushl	%ebp
	movl	%esp, %ebp
```

フレームポインタ %ebp を使用して

```
            |               |
  (%ebp)--> +---------------+ %esp == %ebp
            |  %ebp         |
 4(%ebp)--> +---------------+
            |  ret address  |
 8(%ebp)--> +---------------+
            |  1st argument |
12(%ebp)--> +---------------+
            |  2nd argument |
            +---------------+
            |               |
```

のようにアクセスする。

なお関数から復帰する際は

```Assembly
	popl	%ebp
	ret
```

によって %ebp の値を復元しつつ %esp は return address を指すようにする。

今回は単純な関数であるためフレームポインタの操作を省略し %esp を直接参照している。

### 成果

- [bootpack.c](/bootpack.c)
    - write_mem8() を呼び出す
- [naskfunc.S](/naskfunc.S)
    - write_mem8() 追加

----

Next: [harib01b](harib01b.md), Previous: [harib00j](harib00j.md), Up: [Chapter4](chapter4.md)
