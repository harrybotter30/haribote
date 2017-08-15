Next: [harib02c](harib02c.md), Previous: [harib02a](harib02a.md), Up: [Chapter5](chapter5.md)

----

# Chapter5

## harib02b

### 課題

起動情報を構造体を使用して参照する。

### 学習

char メンバが含まれているためパディングが発生するかもしれないと思ったが、reserve メンバを配置するなど 4 バイト境界を意識しているためきっちり詰まった構造体になっていた。

```shell-session
$ cc -fno-pic -Os -Wall -x c - <<EOF && ./a.out && rm ./a.out
> #include <stdio.h>
> #include <stddef.h>
> struct BOOTINFO {
> 	char cyls, leds, vmode, reserve;
> 	short scrnx, scrny;
> 	unsigned char *vram;
> };
> int main(int argc, char **argv)
> {
>   printf("cyls:\t%d\n"
>          "leds:\t%d\n"
>          "vmode:\t%d\n"
>          "reserve:\t%d\n"
>          "scrnx:\t%d\n"
>          "scrny:\t%d\n"
>          "vram:\t%x\n", 
>          offsetof(struct BOOTINFO, cyls),
>          offsetof(struct BOOTINFO, leds),
>          offsetof(struct BOOTINFO, vmode),
>          offsetof(struct BOOTINFO, reserve),
>          offsetof(struct BOOTINFO, scrnx),
>          offsetof(struct BOOTINFO, scrny),
>          offsetof(struct BOOTINFO, vram));
>   return 0;
> }
> EOF
cyls:	0
leds:	1
vmode:	2
reserve:	3
scrnx:	4
scrny:	6
vram:	8
```

#### パディングの制御

今回は不要だったが gcc を使用してパディングを制御する方法を確認した。

##### パディングが発生する場合

```shell-session
$ cc -fno-pic -Os -Wall -x c - <<EOF && ./a.out && rm ./a.out
> #include <stdio.h>
> #include <stddef.h>
> struct BOOTINFO {
> 	char cyls;
> 	short scrnx;
> 	unsigned char *vram;
> };
> int main(int argc, char **argv)
> {
>   printf("cyls:\t%d\n"
>          "scrnx:\t%d\n"
>          "vram:\t%x\n", 
>          offsetof(struct BOOTINFO, cyls),
>          offsetof(struct BOOTINFO, scrnx),
>          offsetof(struct BOOTINFO, vram));
>   return 0;
> }
> EOF
cyls:	0
scrnx:	2
vram:	4
```

##### \_\_attribute\_\_ を使用する

[\_\_attribute\_\_((\_\_packed\_\_))](https://gcc.gnu.org/onlinedocs/gcc-7.2.0/gcc/Common-Type-Attributes.html#index-packed-type-attribute) を使用してパックする。

```shell-session
$ cc -fno-pic -Os -Wall -x c - <<EOF && ./a.out && rm ./a.out
> #include <stdio.h>
> #include <stddef.h>
> struct __attribute__ ((__packed__)) BOOTINFO {
> 	char cyls;
> 	short scrnx;
> 	unsigned char *vram;
> };
> int main(int argc, char **argv)
> {
>   printf("cyls:\t%d\n"
>          "scrnx:\t%d\n"
>          "vram:\t%x\n", 
>          offsetof(struct BOOTINFO, cyls),
>          offsetof(struct BOOTINFO, scrnx),
>          offsetof(struct BOOTINFO, vram));
>   return 0;
> }
> EOF
cyls:	0
scrnx:	1
vram:	3
```

##### \#pragma を使用する

[\#pragma](https://gcc.gnu.org/onlinedocs/gcc-7.2.0/gcc/Structure-Layout-Pragmas.html#Structure-Layout-Pragmas-1) を使用してパックする。

```shell-session
$ cc -fno-pic -Os -Wall -x c - <<EOF && ./a.out && rm ./a.out
> #include <stdio.h>
> #include <stddef.h>
> #pragma pack(1)
> struct BOOTINFO {
> 	char cyls;
> 	short scrnx;
> 	unsigned char *vram;
> };
> #pragma pack()
> int main(int argc, char **argv)
> {
>   printf("cyls:\t%d\n"
>          "scrnx:\t%d\n"
>          "vram:\t%x\n", 
>          offsetof(struct BOOTINFO, cyls),
>          offsetof(struct BOOTINFO, scrnx),
>          offsetof(struct BOOTINFO, vram));
>   return 0;
> }
> EOF
cyls:	0
scrnx:	1
vram:	3
```

#### 参考

- [Using the GNU Compiler Collection (GCC): Common Type Attributes](https://gcc.gnu.org/onlinedocs/gcc-7.2.0/gcc/Common-Type-Attributes.html)
- [Using the GNU Compiler Collection (GCC): Structure-Layout Pragmas](https://gcc.gnu.org/onlinedocs/gcc-7.2.0/gcc/Structure-Layout-Pragmas.html)

### 成果

- [bootpack.c](/bootpack.c)
    - 起動時の画面情報を構造体を使用して参照する

----

Next: [harib02c](harib02c.md), Previous: [harib02a](harib02a.md), Up: [Chapter5](chapter5.md)
