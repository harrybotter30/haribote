Next: [Interlude](interlude.md), Previous: [Interlude](interlude.md), Up: [Interlude](interlude.md)

----

# Interlude

## actions

### 課題

GitHub Actions を利用できるようにする。

### 学習

#### GitHub Actions

2019/11 に [GitHub Actions](https://docs.github.com/ja/actions) が公開された。  
このプロジェクトではテストが実装できていないのでそれほど恩恵は受けられないかもしれないが、いまどきの開発事情にふれるためにやってみる。

ただ make するたけなので簡単だろうと思ったが甘かった...

#### アクション

登録しようとしたら GitHub から提案してきた。

- [C/C++ with Make](https://github.com/harrybotter30/haribote/new/main?filename=.github%2Fworkflows%2Fc-cpp.yml&workflow_template=c-cpp)
- [Build projects with Make](https://github.com/harrybotter30/haribote/new/main?filename=.github%2Fworkflows%2Fmakefile.yml&workflow_template=makefile)
- [CMake based projects](https://github.com/harrybotter30/haribote/new/main?filename=.github%2Fworkflows%2Fcmake.yml&workflow_template=cmake)
- [MSBuild based projects](https://github.com/harrybotter30/haribote/new/main?filename=.github%2Fworkflows%2Fmsbuild.yml&workflow_template=msbuild)

違いがよく判らないが、`Build projects with Make` を選んでみた。

#### 1回目

/.github/workflows/makefile.yml として以下のようなファイルが追加された。

```yaml
name: Makefile CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    
    - name: Install dependencies
      run: make
```

Install dependencies でエラー発生。

```
Run make
cc -E -fno-pic -Os -Wall -m32  ipl10.S -o ipl10.s
as -al --32  ipl10.s -o ipl10.o >ipl10.lst
...
cc -fno-pic -Os -Wall -m32   -c -o bootpack.o bootpack.c
In file included from bootpack.c:4:
/usr/include/stdio.h:27:10: fatal error: bits/libc-header-start.h: No such file or directory
   27 | #include <bits/libc-header-start.h>
      |          ^~~~~~~~~~~~~~~~~~~~~~~~~~
compilation terminated.
make: *** [<builtin>: bootpack.o] Error 1
Error: Process completed with exit code 2.
```

libc-dev-i386 パッケージがない。

#### 2回目

https://github.com/harrybotter30/haribote/commit/6009aaf251517753bed1a7c5c158d4b03da0ab07

```diff
diff --git a/.github/workflows/makefile.yml b/.github/workflows/makefile.yml
index 86666c5..3404287 100644
--- a/.github/workflows/makefile.yml
+++ b/.github/workflows/makefile.yml
@@ -14,5 +14,8 @@ jobs:
     steps:
     - uses: actions/checkout@v2
     
+    - name: Install i386 library
+      run: sudo apt-get install -y libc6-dev-i386
+    
     - name: Install dependencies
       run: make
```

`cast from pointer to integer of different size` は解消されたが別のエラーが出るようになった。

```
Run make
cc -E -fno-pic -Os -Wall -m32  ipl10.S -o ipl10.s
as -al --32  ipl10.s -o ipl10.o >ipl10.lst
...
cc -fno-pic -Os -Wall -m32   -c -o tinylib.o tinylib.c
ld -m elf_i386 -T asmhead.lds -o asmhead.bin asmhead.o
support/makefont hankaku.txt >font.bin
objcopy -Ibinary -Bi386 -Oelf32-i386 font.bin font.o
ld -m elf_i386 -T hrb.lds -o bootpack.hrb bootpack.o dsctbl.o graphic.o int.o fifo.o naskfunc.o tinylib.o
ld: section .note.gnu.property LMA [0000000000000f3c,0000000000000fff] overlaps section .data LMA [0000000000000f3c,000000000000209b]
ld: bootpack.o: in function `HariMain':
bootpack.c:(.text+0x184): undefined reference to `__sprintf_chk'
ld: bootpack.c:(.text+0x211): undefined reference to `__sprintf_chk'
ld: bootpack.c:(.text+0x27b): undefined reference to `__sprintf_chk'
make: *** [Makefile:35: haribote.sys] Error 1
Error: Process completed with exit code 2.
```

#### `__sprintf_chk` 対応

`__sprintf_chk` とはなにか？  
いかにも sprintf(3) 仕様問題を緩和するためのもののように思える。

- [-fno-stack-protector をつけてみたが変わらず](https://github.com/harrybotter30/haribote/pull/109)
- [-nostdlib をつけてみても変わらず](https://github.com/harrybotter30/haribote/pull/111)

当初手元では都合により Debian buster を使っているから問題が発生しないのだと思っていたが、Debian sid でもエラーにならなかったことから、ようやく Debian と Ubuntu の相違であることに気づいた。

##### ubuntu 環境でビルド

docker 環境を構築し [ubuntu:latest](https://hub.docker.com/layers/ubuntu/library/ubuntu/latest/images/sha256-7c9c7fed23def3653a0da5bc9ecb651efe155ebd5802c7ba5d585edaa6c89496?context=explore) を取得する。（現在のところ 20.04.3 LTS）

確かにこの環境でビルドすると \_\_sprintf\_chk の解決に失敗する。

```shell-session
docker$ uname -a
Linux 63a9a791491b 5.16.0-1-amd64 #1 SMP PREEMPT Debian 5.16.7-2 (2022-02-09) x86_64 x86_64 x86_64 GNU/Linux
docker$ cat /etc/issue
Ubuntu 20.04.3 LTS \n \l

docker$ nm bootpack.o
00000081 T HariMain
         U __sprintf_chk
         U boxfill8
0000004c T enable_mouse
         U fifo8_get
         U fifo8_init
         U fifo8_status
         U init_gdtidt
0000001d T init_keyboard
         U init_mouse_cursor8
         U init_palette
         U init_pic
         U init_screen8
         U io_cli
         U io_in8
         U io_out8
         U io_sti
         U io_stihlt
         U keyfifo
         U mousefifo
         U putblock8_8
         U putfonts8_asc
00000000 T wait_KBC_sendready
docker$ 
```

##### specs

おそらくコンパイル時のオプションが異なるのだろう。

<details><summary>Debian (buster)</summary>

```shell-session
debian$ gcc -dumpspecs
*asm:
%{m16|m32:--32}  %{m16|m32|mx32:;:--64}  %{mx32:--x32}  %{msse2avx:%{!mavx:-msse2avx}}

*asm_debug:
%{%:debug-level-gt(0):%{gstabs*:--gstabs}%{!gstabs*:%{g*:--gdwarf2}}} %{fdebug-prefix-map=*:--debug-prefix-map %*}

*asm_final:
%{gsplit-dwarf: 
       objcopy --extract-dwo 	 %{c:%{o*:%*}%{!o*:%b%O}}%{!c:%U%O} 	 %{c:%{o*:%:replace-extension(%{o*:%*} .dwo)}%{!o*:%b.dwo}}%{!c:%b.dwo} 
       objcopy --strip-dwo 	 %{c:%{o*:%*}%{!o*:%b%O}}%{!c:%U%O}     }

*asm_options:
%{-target-help:%:print-asm-header()} %{v} %{w:-W} %{I*}  %{gz|gz=zlib:--compress-debug-sections=zlib} %{gz=none:--compress-debug-sections=none} %{gz=zlib-gnu:--compress-debug-sections=zlib-gnu} %a %Y %{c:%W{o*}%{!o*:-o %w%b%O}}%{!c:-o %d%w%u%O}

*invoke_as:
%{!fwpa*:   %{fcompare-debug=*|fdump-final-insns=*:%:compare-debug-dump-opt()}   %{!S:-o %|.s |
 as %(asm_options) %m.s %A }  }

*cpp:
%{posix:-D_POSIX_SOURCE} %{pthread:-D_REENTRANT}

*cpp_options:
%(cpp_unique_options) %1 %{m*} %{std*&ansi&trigraphs} %{W*&pedantic*} %{w} %{f*} %{g*:%{%:debug-level-gt(0):%{g*} %{!fno-working-directory:-fworking-directory}}} %{O*} %{undef} %{save-temps*:-fpch-preprocess}

*cpp_debug_options:
%{d*}

*cpp_unique_options:
%{!Q:-quiet} %{nostdinc*} %{C} %{CC} %{v} %{I*&F*} %{P} %I %{MD:-MD %{!o:%b.d}%{o*:%.d%*}} %{MMD:-MMD %{!o:%b.d}%{o*:%.d%*}} %{M} %{MM} %{MF*} %{MG} %{MP} %{MQ*} %{MT*} %{!E:%{!M:%{!MM:%{!MT:%{!MQ:%{MD|MMD:%{o*:-MQ %*}}}}}}} %{remap} %{g3|ggdb3|gstabs3|gxcoff3|gvms3:-dD} %{!iplugindir*:%{fplugin*:%:find-plugindir()}} %{H} %C %{D*&U*&A*} %{i*} %Z %i %{E|M|MM:%W{o*}}

*trad_capable_cpp:
cc1 -E %{traditional|traditional-cpp:-traditional-cpp}

*cc1:
%{!mandroid|tno-android-cc:%(cc1_cpu) %{profile:-p};:%(cc1_cpu) %{profile:-p} %{!mglibc:%{!muclibc:%{!mbionic: -mbionic}}} %{!fno-pic:%{!fno-PIC:%{!fpic:%{!fPIC: -fPIC}}}}}

*cc1_options:
%{pg:%{fomit-frame-pointer:%e-pg and -fomit-frame-pointer are incompatible}} %{!iplugindir*:%{fplugin*:%:find-plugindir()}} %1 %{!Q:-quiet} %{!dumpbase:-dumpbase %B} %{d*} %{m*} %{aux-info*} %{fcompare-debug-second:%:compare-debug-auxbase-opt(%b)}  %{!fcompare-debug-second:%{c|S:%{o*:-auxbase-strip %*}%{!o*:-auxbase %b}}}%{!c:%{!S:-auxbase %b}}  %{g*} %{O*} %{W*&pedantic*} %{w} %{std*&ansi&trigraphs} %{v:-version} %{pg:-p} %{p} %{f*} %{undef} %{Qn:-fno-ident} %{Qy:} %{-help:--help} %{-target-help:--target-help} %{-version:--version} %{-help=*:--help=%*} %{!fsyntax-only:%{S:%W{o*}%{!o*:-o %b.s}}} %{fsyntax-only:-o %j} %{-param*} %{coverage:-fprofile-arcs -ftest-coverage} %{fprofile-arcs|fprofile-generate*|coverage:   %{!fprofile-update=single:     %{pthread:-fprofile-update=prefer-atomic}}}

*cc1plus:


*link_gcc_c_sequence:
%{static|static-pie:--start-group} %G %L    %{static|static-pie:--end-group}%{!static:%{!static-pie:%G}}

*link_ssp:
%{fstack-protector|fstack-protector-all|fstack-protector-strong|fstack-protector-explicit:}

*endfile:
%{!mandroid|tno-android-ld:%{Ofast|ffast-math|funsafe-math-optimizations:crtfastmath.o%s}    %{mpc32:crtprec32.o%s}    %{mpc64:crtprec64.o%s}    %{mpc80:crtprec80.o%s} %{fvtable-verify=none:%s;      fvtable-verify=preinit:vtv_end_preinit.o%s;      fvtable-verify=std:vtv_end.o%s}    %{static:crtend.o%s;      shared|static-pie|!no-pie:crtendS.o%s;      :crtend.o%s}    crtn.o%s    %{fopenacc|fopenmp:crtoffloadend%O%s};:%{Ofast|ffast-math|funsafe-math-optimizations:crtfastmath.o%s}    %{mpc32:crtprec32.o%s}    %{mpc64:crtprec64.o%s}    %{mpc80:crtprec80.o%s} %{shared: crtend_so%O%s;: crtend_android%O%s}}

*link:
%{!r:--build-id} %{!static|static-pie:--eh-frame-hdr} %{!mandroid|tno-android-ld:%{m16|m32|mx32:;:-m elf_x86_64}                    %{m16|m32:-m elf_i386}                    %{mx32:-m elf32_x86_64}   --hash-style=gnu   %{shared:-shared}   %{!shared:     %{!static:       %{!static-pie: 	%{rdynamic:-export-dynamic} 	%{m16|m32:-dynamic-linker %{muclibc:/lib/ld-uClibc.so.0;:%{mbionic:/system/bin/linker;:%{mmusl:/lib/ld-musl-i386.so.1;:/lib/ld-linux.so.2}}}} 	%{m16|m32|mx32:;:-dynamic-linker %{muclibc:/lib/ld64-uClibc.so.0;:%{mbionic:/system/bin/linker64;:%{mmusl:/lib/ld-musl-x86_64.so.1;:/lib64/ld-linux-x86-64.so.2}}}} 	%{mx32:-dynamic-linker %{muclibc:/lib/ldx32-uClibc.so.0;:%{mbionic:/system/bin/linkerx32;:%{mmusl:/lib/ld-musl-x32.so.1;:/libx32/ld-linux-x32.so.2}}}}}}     %{static:-static} %{static-pie:-static -pie --no-dynamic-linker -z text}};:%{m16|m32|mx32:;:-m elf_x86_64}                    %{m16|m32:-m elf_i386}                    %{mx32:-m elf32_x86_64}   --hash-style=gnu   %{shared:-shared}   %{!shared:     %{!static:       %{!static-pie: 	%{rdynamic:-export-dynamic} 	%{m16|m32:-dynamic-linker %{muclibc:/lib/ld-uClibc.so.0;:%{mbionic:/system/bin/linker;:%{mmusl:/lib/ld-musl-i386.so.1;:/lib/ld-linux.so.2}}}} 	%{m16|m32|mx32:;:-dynamic-linker %{muclibc:/lib/ld64-uClibc.so.0;:%{mbionic:/system/bin/linker64;:%{mmusl:/lib/ld-musl-x86_64.so.1;:/lib64/ld-linux-x86-64.so.2}}}} 	%{mx32:-dynamic-linker %{muclibc:/lib/ldx32-uClibc.so.0;:%{mbionic:/system/bin/linkerx32;:%{mmusl:/lib/ld-musl-x32.so.1;:/libx32/ld-linux-x32.so.2}}}}}}     %{static:-static} %{static-pie:-static -pie --no-dynamic-linker -z text}} %{shared: -Bsymbolic}}

*lib:
%{!mandroid|tno-android-ld:%{pthread:-lpthread} %{shared:-lc}    %{!shared:%{profile:-lc_p}%{!profile:-lc}};:%{shared:-lc}    %{!shared:%{profile:-lc_p}%{!profile:-lc}} %{!static: -ldl}}

*link_gomp:


*libgcc:
%{static|static-libgcc|static-pie:-lgcc -lgcc_eh}%{!static:%{!static-libgcc:%{!static-pie:%{!shared-libgcc:-lgcc --push-state --as-needed -lgcc_s --pop-state}%{shared-libgcc:-lgcc_s%{!shared: -lgcc}}}}}

*startfile:
%{!mandroid|tno-android-ld:%{shared:;      pg|p|profile:%{static-pie:grcrt1.o%s;:gcrt1.o%s};      static:crt1.o%s;      static-pie:rcrt1.o%s;      !no-pie:Scrt1.o%s;      :crt1.o%s}    crti.o%s    %{static:crtbeginT.o%s;      shared|static-pie|!no-pie:crtbeginS.o%s;      :crtbegin.o%s}    %{fvtable-verify=none:%s;      fvtable-verify=preinit:vtv_start_preinit.o%s;      fvtable-verify=std:vtv_start.o%s}    %{fopenacc|fopenmp:crtoffloadbegin%O%s};:%{shared: crtbegin_so%O%s;:  %{static: crtbegin_static%O%s;: crtbegin_dynamic%O%s}}}

*cross_compile:
0

*version:
8.3.0

*multilib:
. !m32 !m64 !mx32;32:../lib32:i386-linux-gnu m32 !m64 !mx32;64:../lib:x86_64-linux-gnu !m32 m64 !mx32;x32:../libx32:x86_64-linux-gnux32 !m32 !m64 mx32;

*multilib_defaults:
m64

*multilib_extra:


*multilib_matches:
m32 m32;m64 m64;mx32 mx32;

*multilib_exclusions:


*multilib_options:
m32/m64/mx32

*multilib_reuse:


*linker:
collect2

*linker_plugin_file:


*lto_wrapper:


*lto_gcc:


*post_link:


*link_libgcc:
%D

*md_exec_prefix:


*md_startfile_prefix:


*md_startfile_prefix_1:


*startfile_prefix_spec:


*sysroot_spec:
--sysroot=%R

*sysroot_suffix_spec:


*sysroot_hdrs_suffix_spec:


*self_spec:


*cc1_cpu:
%{march=native:%>march=native %:local_cpu_detect(arch)   %{!mtune=*:%>mtune=native %:local_cpu_detect(tune)}} %{mtune=native:%>mtune=native %:local_cpu_detect(tune)}

*link_command:
%{!fsyntax-only:%{!c:%{!M:%{!MM:%{!E:%{!S:    %(linker) %{!fno-use-linker-plugin:%{!fno-lto:     -plugin %(linker_plugin_file)     -plugin-opt=%(lto_wrapper)     -plugin-opt=-fresolution=%u.res     %{!nostdlib:%{!nodefaultlibs:%:pass-through-libs(%(link_gcc_c_sequence))}}     }}%{flto|flto=*:%<fcompare-debug*}     %{flto} %{fno-lto} %{flto=*} %l %{static|shared|r:;!no-pie:-pie} %{fuse-ld=*:-fuse-ld=%*}  %{gz|gz=zlib:--compress-debug-sections=zlib} %{gz=none:--compress-debug-sections=none} %{gz=zlib-gnu:--compress-debug-sections=zlib-gnu} %X %{o*} %{e*} %{N} %{n} %{r}    %{s} %{t} %{u*} %{z} %{Z} %{!nostdlib:%{!nostartfiles:%S}}     %{static|no-pie|static-pie:} %{L*} %(mfwrap) %(link_libgcc) %{fvtable-verify=none:} %{fvtable-verify=std:   %e-fvtable-verify=std is not supported in this configuration} %{fvtable-verify=preinit:   %e-fvtable-verify=preinit is not supported in this configuration} %{!nostdlib:%{!nodefaultlibs:%{%:sanitize(address):%{!shared:libasan_preinit%O%s} %{static-libasan:%{!shared:-Bstatic --whole-archive -lasan --no-whole-archive -Bdynamic}}%{!static-libasan:-lasan}}     %{%:sanitize(thread):%{!shared:libtsan_preinit%O%s} %{static-libtsan:%{!shared:-Bstatic --whole-archive -ltsan --no-whole-archive -Bdynamic}}%{!static-libtsan:-ltsan}}     %{%:sanitize(leak):%{!shared:liblsan_preinit%O%s} %{static-liblsan:%{!shared:-Bstatic --whole-archive -llsan --no-whole-archive -Bdynamic}}%{!static-liblsan:-llsan}}}} %o %{!nostdlib:%{!nodefaultlibs:%{mmpx:%{fcheck-pointer-bounds:    %{static:--whole-archive -lmpx --no-whole-archive %:include(libmpx.spec)%(link_libmpx)}    %{!static:%{static-libmpx:-Bstatic --whole-archive}    %{!static-libmpx:--push-state --no-as-needed} -lmpx     %{!static-libmpx:--pop-state}     %{static-libmpx:--no-whole-archive -Bdynamic %:include(libmpx.spec)%(link_libmpx)}}}}%{mmpx:%{fcheck-pointer-bounds:%{!fno-chkp-use-wrappers:    %{static:-lmpxwrappers}    %{!static:%{static-libmpxwrappers:-Bstatic}    -lmpxwrappers %{static-libmpxwrappers: -Bdynamic}}}}}}} %{mmpx:%{fcheck-pointer-bounds:%{!static:%{m16|m32|mx32:;:-z bndplt }}}}     %{fopenacc|fopenmp|%:gt(%{ftree-parallelize-loops=*:%*} 1):	%:include(libgomp.spec)%(link_gomp)}    %{fgnu-tm:%:include(libitm.spec)%(link_itm)}    %(mflib)  %{fsplit-stack: --wrap=pthread_create}    %{fprofile-arcs|fprofile-generate*|coverage:-lgcov} %{!nostdlib:%{!nodefaultlibs:%{%:sanitize(address): %{static-libasan|static:%:include(libsanitizer.spec)%(link_libasan)}    %{static:%ecannot specify -static with -fsanitize=address}}    %{%:sanitize(thread): %{static-libtsan|static:%:include(libsanitizer.spec)%(link_libtsan)}    %{static:%ecannot specify -static with -fsanitize=thread}}    %{%:sanitize(undefined):%{static-libubsan:-Bstatic} -lubsan %{static-libubsan:-Bdynamic} %{static-libubsan|static:%:include(libsanitizer.spec)%(link_libubsan)}}    %{%:sanitize(leak): %{static-liblsan|static:%:include(libsanitizer.spec)%(link_liblsan)}}}}     %{!nostdlib:%{!nodefaultlibs:%(link_ssp) %(link_gcc_c_sequence)}}    %{!nostdlib:%{!nostartfiles:%E}} %{T*}  
%(post_link) }}}}}}

debian$ 
```

</details>

<details><summary>Debian (buster)</summary>

```shell-session
docker$ gcc -dumpspecs
*asm:
%{m16|m32:--32}  %{m16|m32|mx32:;:--64}  %{mx32:--x32}  %{msse2avx:%{!mavx:-msse2avx}}

*asm_debug:
%{%:debug-level-gt(0):%{gstabs*:--gstabs}%{!gstabs*:%{g*:--gdwarf2}}} %{fdebug-prefix-map=*:--debug-prefix-map %*}

*asm_final:
%{gsplit-dwarf: 
       objcopy --extract-dwo 	 %{c:%{o*:%*}%{!o*:%b%O}}%{!c:%U%O} 	 %{c:%{o*:%:replace-extension(%{o*:%*} .dwo)}%{!o*:%b.dwo}}%{!c:%b.dwo} 
       objcopy --strip-dwo 	 %{c:%{o*:%*}%{!o*:%b%O}}%{!c:%U%O}     }

*asm_options:
%{-target-help:%:print-asm-header()} %{v} %{w:-W} %{I*}  %{gz|gz=zlib:--compress-debug-sections=zlib} %{gz=none:--compress-debug-sections=none} %{gz=zlib-gnu:--compress-debug-sections=zlib-gnu} %a %Y %{c:%W{o*}%{!o*:-o %w%b%O}}%{!c:-o %d%w%u%O}

*invoke_as:
%{!fwpa*:   %{fcompare-debug=*|fdump-final-insns=*:%:compare-debug-dump-opt()}   %{!S:-o %|.s |
 as %(asm_options) %m.s %A }  }

*cpp:
%{posix:-D_POSIX_SOURCE} %{pthread:-D_REENTRANT}

*cpp_options:
%(cpp_unique_options) %1 %{m*} %{std*&ansi&trigraphs} %{W*&pedantic*} %{w} %{f*} %{g*:%{%:debug-level-gt(0):%{g*} %{!fno-working-directory:-fworking-directory}}} %{O*} %{undef} %{save-temps*:-fpch-preprocess} %(distro_defaults)

*cpp_debug_options:
%{d*}

*cpp_unique_options:
%{!Q:-quiet} %{nostdinc*} %{C} %{CC} %{v} %@{I*&F*} %{P} %I %{MD:-MD %{!o:%b.d}%{o*:%.d%*}} %{MMD:-MMD %{!o:%b.d}%{o*:%.d%*}} %{M} %{MM} %{MF*} %{MG} %{MP} %{MQ*} %{MT*} %{!E:%{!M:%{!MM:%{!MT:%{!MQ:%{MD|MMD:%{o*:-MQ %*}}}}}}} %{remap} %{g3|ggdb3|gstabs3|gxcoff3|gvms3:-dD} %{!iplugindir*:%{fplugin*:%:find-plugindir()}} %{H} %C %{D*&U*&A*} %{i*} %Z %i %{E|M|MM:%W{o*}}

*trad_capable_cpp:
cc1 -E %{traditional|traditional-cpp:-traditional-cpp}

*cc1:
%{!mandroid|tno-android-cc:%(cc1_cpu) %{profile:-p};:%(cc1_cpu) %{profile:-p} %{!mglibc:%{!muclibc:%{!mbionic: -mbionic}}} %{!fno-pic:%{!fno-PIC:%{!fpic:%{!fPIC: -fPIC}}}}}

*cc1_options:
%{pg:%{fomit-frame-pointer:%e-pg and -fomit-frame-pointer are incompatible}} %{!iplugindir*:%{fplugin*:%:find-plugindir()}} %1 %{!Q:-quiet} %{!dumpbase:-dumpbase %B} %{d*} %{m*} %{aux-info*} %{fcompare-debug-second:%:compare-debug-auxbase-opt(%b)}  %{!fcompare-debug-second:%{c|S:%{o*:-auxbase-strip %*}%{!o*:-auxbase %b}}}%{!c:%{!S:-auxbase %b}}  %{g*} %{O*} %{W*&pedantic*} %{w} %{std*&ansi&trigraphs} %{v:-version} %{pg:-p} %{p} %{f*} %{undef} %{Qn:-fno-ident} %{Qy:} %{-help:--help} %{-target-help:--target-help} %{-version:--version} %{-help=*:--help=%*} %{!fsyntax-only:%{S:%W{o*}%{!o*:-o %b.s}}} %{fsyntax-only:-o %j} %{-param*} %{coverage:-fprofile-arcs -ftest-coverage} %{fprofile-arcs|fprofile-generate*|coverage:   %{!fprofile-update=single:     %{pthread:-fprofile-update=prefer-atomic}}}

*cc1plus:


*link_gcc_c_sequence:
%{static|static-pie:--start-group} %G %{!nolibc:%L}    %{static|static-pie:--end-group}%{!static:%{!static-pie:%G}}

*distro_defaults:
%{!fno-asynchronous-unwind-tables:-fasynchronous-unwind-tables} %{!fno-stack-protector:%{!fstack-protector-all:%{!ffreestanding:%{!nostdlib:%{!fstack-protector:-fstack-protector-strong}}}}} %{!Wformat:%{!Wformat=2:%{!Wformat=0:%{!Wall:-Wformat} %{!Wno-format-security:-Wformat-security}}}} %{!fno-stack-clash-protection:-fstack-clash-protection} %{!fcf-protection*:%{!fno-cf-protection:-fcf-protection}}

*link_ssp:
%{fstack-protector|fstack-protector-all|fstack-protector-strong|fstack-protector-explicit:}

*endfile:
%{!mandroid|tno-android-ld:%{Ofast|ffast-math|funsafe-math-optimizations:crtfastmath.o%s}    %{mpc32:crtprec32.o%s}    %{mpc64:crtprec64.o%s}    %{mpc80:crtprec80.o%s} %{fvtable-verify=none:%s;      fvtable-verify=preinit:vtv_end_preinit.o%s;      fvtable-verify=std:vtv_end.o%s}    %{static:crtend.o%s;      shared|static-pie|!no-pie:crtendS.o%s;      :crtend.o%s} crtn.o%s %{fopenacc|fopenmp:crtoffloadend%O%s};:%{Ofast|ffast-math|funsafe-math-optimizations:crtfastmath.o%s}    %{mpc32:crtprec32.o%s}    %{mpc64:crtprec64.o%s}    %{mpc80:crtprec80.o%s} %{shared: crtend_so%O%s;: crtend_android%O%s}}

*link:
%{!r:--build-id} %{!static|static-pie:--eh-frame-hdr} %{!mandroid|tno-android-ld:%{m16|m32|mx32:;:-m elf_x86_64}                    %{m16|m32:-m elf_i386}                    %{mx32:-m elf32_x86_64}   --hash-style=gnu   --as-needed   %{shared:-shared}   %{!shared:     %{!static:       %{!static-pie: 	%{rdynamic:-export-dynamic} 	%{m16|m32:-dynamic-linker %{muclibc:/lib/ld-uClibc.so.0;:%{mbionic:/system/bin/linker;:%{mmusl:/lib/ld-musl-i386.so.1;:/lib/ld-linux.so.2}}}} 	%{m16|m32|mx32:;:-dynamic-linker %{muclibc:/lib/ld64-uClibc.so.0;:%{mbionic:/system/bin/linker64;:%{mmusl:/lib/ld-musl-x86_64.so.1;:/lib64/ld-linux-x86-64.so.2}}}} 	%{mx32:-dynamic-linker %{muclibc:/lib/ldx32-uClibc.so.0;:%{mbionic:/system/bin/linkerx32;:%{mmusl:/lib/ld-musl-x32.so.1;:/libx32/ld-linux-x32.so.2}}}}}}     %{static:-static} %{static-pie:-static -pie --no-dynamic-linker -z text}};:%{m16|m32|mx32:;:-m elf_x86_64}                    %{m16|m32:-m elf_i386}                    %{mx32:-m elf32_x86_64}   --hash-style=gnu   --as-needed   %{shared:-shared}   %{!shared:     %{!static:       %{!static-pie: 	%{rdynamic:-export-dynamic} 	%{m16|m32:-dynamic-linker %{muclibc:/lib/ld-uClibc.so.0;:%{mbionic:/system/bin/linker;:%{mmusl:/lib/ld-musl-i386.so.1;:/lib/ld-linux.so.2}}}} 	%{m16|m32|mx32:;:-dynamic-linker %{muclibc:/lib/ld64-uClibc.so.0;:%{mbionic:/system/bin/linker64;:%{mmusl:/lib/ld-musl-x86_64.so.1;:/lib64/ld-linux-x86-64.so.2}}}} 	%{mx32:-dynamic-linker %{muclibc:/lib/ldx32-uClibc.so.0;:%{mbionic:/system/bin/linkerx32;:%{mmusl:/lib/ld-musl-x32.so.1;:/libx32/ld-linux-x32.so.2}}}}}}     %{static:-static} %{static-pie:-static -pie --no-dynamic-linker -z text}} %{shared: -Bsymbolic}}

*lib:
%{!mandroid|tno-android-ld:%{pthread:-lpthread} %{shared:-lc}    %{!shared:%{profile:-lc_p}%{!profile:-lc}};:%{shared:-lc}    %{!shared:%{profile:-lc_p}%{!profile:-lc}} %{!static: -ldl}}

*link_gomp:


*libgcc:
%{static|static-libgcc|static-pie:-lgcc -lgcc_eh}%{!static:%{!static-libgcc:%{!static-pie:%{!shared-libgcc:-lgcc --push-state --as-needed -lgcc_s --pop-state}%{shared-libgcc:-lgcc_s%{!shared: -lgcc}}}}}

*startfile:
%{!mandroid|tno-android-ld:%{shared:;      pg|p|profile:%{static-pie:grcrt1.o%s;:gcrt1.o%s};      static:crt1.o%s;      static-pie:rcrt1.o%s;      !no-pie:Scrt1.o%s;      :crt1.o%s} crti.o%s    %{static:crtbeginT.o%s;      shared|static-pie|!no-pie:crtbeginS.o%s;      :crtbegin.o%s}    %{fvtable-verify=none:%s;      fvtable-verify=preinit:vtv_start_preinit.o%s;      fvtable-verify=std:vtv_start.o%s} %{fopenacc|fopenmp:crtoffloadbegin%O%s};:%{shared: crtbegin_so%O%s;:  %{static: crtbegin_static%O%s;: crtbegin_dynamic%O%s}}}

*cross_compile:
0

*version:
9.3.0

*multilib:
. !m32 !m64 !mx32;32:../lib32:i386-linux-gnu m32 !m64 !mx32;64:../lib:x86_64-linux-gnu !m32 m64 !mx32;x32:../libx32:x86_64-linux-gnux32 !m32 !m64 mx32;

*multilib_defaults:
m64

*multilib_extra:


*multilib_matches:
m32 m32;m64 m64;mx32 mx32;

*multilib_exclusions:


*multilib_options:
m32/m64/mx32

*multilib_reuse:


*linker:
collect2

*linker_plugin_file:


*lto_wrapper:


*lto_gcc:


*post_link:


*link_libgcc:
%D

*md_exec_prefix:


*md_startfile_prefix:


*md_startfile_prefix_1:


*startfile_prefix_spec:


*sysroot_spec:
--sysroot=%R

*sysroot_suffix_spec:


*sysroot_hdrs_suffix_spec:


*self_spec:


*cc1_cpu:
%{march=native:%>march=native %:local_cpu_detect(arch)   %{!mtune=*:%>mtune=native %:local_cpu_detect(tune)}} %{mtune=native:%>mtune=native %:local_cpu_detect(tune)}

*link_command:
%{!fsyntax-only:%{!c:%{!M:%{!MM:%{!E:%{!S:    %(linker) %{!fno-use-linker-plugin:%{!fno-lto:     -plugin %(linker_plugin_file)     -plugin-opt=%(lto_wrapper)     -plugin-opt=-fresolution=%u.res     %{flinker-output=*:-plugin-opt=-linker-output-known}     %{!nostdlib:%{!nodefaultlibs:%:pass-through-libs(%(link_gcc_c_sequence))}}     }}%{flto|flto=*:%<fcompare-debug*}     %{flto} %{fno-lto} %{flto=*} %l %{static|shared|r:;!no-pie:-pie -z now} %{fuse-ld=*:-fuse-ld=%*}  %{gz|gz=zlib:--compress-debug-sections=zlib} %{gz=none:--compress-debug-sections=none} %{gz=zlib-gnu:--compress-debug-sections=zlib-gnu}  -z relro %X %{o*} %{e*} %{N} %{n} %{r}    %{s} %{t} %{u*} %{z} %{Z} %{!nostdlib:%{!r:%{!nostartfiles:%S}}}     %{static|no-pie|static-pie:} %@{L*} %(mfwrap) %(link_libgcc) %{fvtable-verify=none:} %{fvtable-verify=std:   %e-fvtable-verify=std is not supported in this configuration} %{fvtable-verify=preinit:   %e-fvtable-verify=preinit is not supported in this configuration} %{!nostdlib:%{!r:%{!nodefaultlibs:%{%:sanitize(address):%{!shared:libasan_preinit%O%s} %{static-libasan:%{!shared:-Bstatic --whole-archive -lasan --no-whole-archive -Bdynamic}}%{!static-libasan:%{!fuse-ld=gold:--push-state} --no-as-needed -lasan %{fuse-ld=gold:--as-needed;:--pop-state}}}     %{%:sanitize(thread):%{!shared:libtsan_preinit%O%s} %{static-libtsan:%{!shared:-Bstatic --whole-archive -ltsan --no-whole-archive -Bdynamic}}%{!static-libtsan:%{!fuse-ld=gold:--push-state} --no-as-needed -ltsan %{fuse-ld=gold:--as-needed;:--pop-state}}}     %{%:sanitize(leak):%{!shared:liblsan_preinit%O%s} %{static-liblsan:%{!shared:-Bstatic --whole-archive -llsan --no-whole-archive -Bdynamic}}%{!static-liblsan:%{!fuse-ld=gold:--push-state} --no-as-needed -llsan %{fuse-ld=gold:--as-needed;:--pop-state}}}}}} %o      %{fopenacc|fopenmp|%:gt(%{ftree-parallelize-loops=*:%*} 1):	%:include(libgomp.spec)%(link_gomp)}    %{fgnu-tm:%:include(libitm.spec)%(link_itm)}    %(mflib)  %{fsplit-stack: --wrap=pthread_create}    %{fprofile-arcs|fprofile-generate*|coverage:-lgcov} %{!nostdlib:%{!r:%{!nodefaultlibs:%{%:sanitize(address): %{static-libasan|static:%:include(libsanitizer.spec)%(link_libasan)}    %{static:%ecannot specify -static with -fsanitize=address}}    %{%:sanitize(thread): %{static-libtsan|static:%:include(libsanitizer.spec)%(link_libtsan)}    %{static:%ecannot specify -static with -fsanitize=thread}}    %{%:sanitize(undefined):%{static-libubsan:-Bstatic} %{!static-libubsan:--push-state --no-as-needed} -lubsan  %{static-libubsan:-Bdynamic} %{!static-libubsan:--pop-state} %{static-libubsan|static:%:include(libsanitizer.spec)%(link_libubsan)}}    %{%:sanitize(leak): %{static-liblsan|static:%:include(libsanitizer.spec)%(link_liblsan)}}}}}     %{!nostdlib:%{!r:%{!nodefaultlibs:%(link_ssp) %(link_gcc_c_sequence)}}}    %{!nostdlib:%{!r:%{!nostartfiles:%E}}} %{T*}  
%(post_link) }}}}}}

docker$ 
```
</details>

だいぶ違う？

```diff
$ diff -ub debian ubuntu
--- debian	2022-02-27 09:26:24.652063500 +0900
+++ ubuntu	2022-02-27 09:26:54.282633600 +0900
@@ -20,13 +20,13 @@
 %{posix:-D_POSIX_SOURCE} %{pthread:-D_REENTRANT}
 
 *cpp_options:
-%(cpp_unique_options) %1 %{m*} %{std*&ansi&trigraphs} %{W*&pedantic*} %{w} %{f*} %{g*:%{%:debug-level-gt(0):%{g*} %{!fno-working-directory:-fworking-directory}}} %{O*} %{undef} %{save-temps*:-fpch-preprocess}
+%(cpp_unique_options) %1 %{m*} %{std*&ansi&trigraphs} %{W*&pedantic*} %{w} %{f*} %{g*:%{%:debug-level-gt(0):%{g*} %{!fno-working-directory:-fworking-directory}}} %{O*} %{undef} %{save-temps*:-fpch-preprocess} %(distro_defaults)
 
 *cpp_debug_options:
 %{d*}
 
 *cpp_unique_options:
-%{!Q:-quiet} %{nostdinc*} %{C} %{CC} %{v} %{I*&F*} %{P} %I %{MD:-MD %{!o:%b.d}%{o*:%.d%*}} %{MMD:-MMD %{!o:%b.d}%{o*:%.d%*}} %{M} %{MM} %{MF*} %{MG} %{MP} %{MQ*} %{MT*} %{!E:%{!M:%{!MM:%{!MT:%{!MQ:%{MD|MMD:%{o*:-MQ %*}}}}}}} %{remap} %{g3|ggdb3|gstabs3|gxcoff3|gvms3:-dD} %{!iplugindir*:%{fplugin*:%:find-plugindir()}} %{H} %C %{D*&U*&A*} %{i*} %Z %i %{E|M|MM:%W{o*}}
+%{!Q:-quiet} %{nostdinc*} %{C} %{CC} %{v} %@{I*&F*} %{P} %I %{MD:-MD %{!o:%b.d}%{o*:%.d%*}} %{MMD:-MMD %{!o:%b.d}%{o*:%.d%*}} %{M} %{MM} %{MF*} %{MG} %{MP} %{MQ*} %{MT*} %{!E:%{!M:%{!MM:%{!MT:%{!MQ:%{MD|MMD:%{o*:-MQ %*}}}}}}} %{remap} %{g3|ggdb3|gstabs3|gxcoff3|gvms3:-dD} %{!iplugindir*:%{fplugin*:%:find-plugindir()}} %{H} %C %{D*&U*&A*} %{i*} %Z %i %{E|M|MM:%W{o*}}
 
 *trad_capable_cpp:
 cc1 -E %{traditional|traditional-cpp:-traditional-cpp}
@@ -41,7 +41,10 @@
 
 
 *link_gcc_c_sequence:
-%{static|static-pie:--start-group} %G %L    %{static|static-pie:--end-group}%{!static:%{!static-pie:%G}}
+%{static|static-pie:--start-group} %G %{!nolibc:%L}    %{static|static-pie:--end-group}%{!static:%{!static-pie:%G}}
+
+*distro_defaults:
+%{!fno-asynchronous-unwind-tables:-fasynchronous-unwind-tables} %{!fno-stack-protector:%{!fstack-protector-all:%{!ffreestanding:%{!nostdlib:%{!fstack-protector:-fstack-protector-strong}}}}} %{!Wformat:%{!Wformat=2:%{!Wformat=0:%{!Wall:-Wformat} %{!Wno-format-security:-Wformat-security}}}} %{!fno-stack-clash-protection:-fstack-clash-protection} %{!fcf-protection*:%{!fno-cf-protection:-fcf-protection}}
 
 *link_ssp:
 %{fstack-protector|fstack-protector-all|fstack-protector-strong|fstack-protector-explicit:}
@@ -50,7 +53,7 @@
 %{!mandroid|tno-android-ld:%{Ofast|ffast-math|funsafe-math-optimizations:crtfastmath.o%s}    %{mpc32:crtprec32.o%s}    %{mpc64:crtprec64.o%s}    %{mpc80:crtprec80.o%s} %{fvtable-verify=none:%s;      fvtable-verify=preinit:vtv_end_preinit.o%s;      fvtable-verify=std:vtv_end.o%s}    %{static:crtend.o%s;      shared|static-pie|!no-pie:crtendS.o%s;      :crtend.o%s}    crtn.o%s    %{fopenacc|fopenmp:crtoffloadend%O%s};:%{Ofast|ffast-math|funsafe-math-optimizations:crtfastmath.o%s}    %{mpc32:crtprec32.o%s}    %{mpc64:crtprec64.o%s}    %{mpc80:crtprec80.o%s} %{shared: crtend_so%O%s;: crtend_android%O%s}}
 
 *link:
-%{!r:--build-id} %{!static|static-pie:--eh-frame-hdr} %{!mandroid|tno-android-ld:%{m16|m32|mx32:;:-m elf_x86_64}                    %{m16|m32:-m elf_i386}                    %{mx32:-m elf32_x86_64}   --hash-style=gnu   %{shared:-shared}   %{!shared:     %{!static:       %{!static-pie: 	%{rdynamic:-export-dynamic} 	%{m16|m32:-dynamic-linker %{muclibc:/lib/ld-uClibc.so.0;:%{mbionic:/system/bin/linker;:%{mmusl:/lib/ld-musl-i386.so.1;:/lib/ld-linux.so.2}}}} 	%{m16|m32|mx32:;:-dynamic-linker %{muclibc:/lib/ld64-uClibc.so.0;:%{mbionic:/system/bin/linker64;:%{mmusl:/lib/ld-musl-x86_64.so.1;:/lib64/ld-linux-x86-64.so.2}}}} 	%{mx32:-dynamic-linker %{muclibc:/lib/ldx32-uClibc.so.0;:%{mbionic:/system/bin/linkerx32;:%{mmusl:/lib/ld-musl-x32.so.1;:/libx32/ld-linux-x32.so.2}}}}}}     %{static:-static} %{static-pie:-static -pie --no-dynamic-linker -z text}};:%{m16|m32|mx32:;:-m elf_x86_64}                    %{m16|m32:-m elf_i386}                    %{mx32:-m elf32_x86_64}   --hash-style=gnu   %{shared:-shared}   %{!shared:     %{!static:       %{!static-pie: 	%{rdynamic:-export-dynamic} 	%{m16|m32:-dynamic-linker %{muclibc:/lib/ld-uClibc.so.0;:%{mbionic:/system/bin/linker;:%{mmusl:/lib/ld-musl-i386.so.1;:/lib/ld-linux.so.2}}}} 	%{m16|m32|mx32:;:-dynamic-linker %{muclibc:/lib/ld64-uClibc.so.0;:%{mbionic:/system/bin/linker64;:%{mmusl:/lib/ld-musl-x86_64.so.1;:/lib64/ld-linux-x86-64.so.2}}}} 	%{mx32:-dynamic-linker %{muclibc:/lib/ldx32-uClibc.so.0;:%{mbionic:/system/bin/linkerx32;:%{mmusl:/lib/ld-musl-x32.so.1;:/libx32/ld-linux-x32.so.2}}}}}}     %{static:-static} %{static-pie:-static -pie --no-dynamic-linker -z text}} %{shared: -Bsymbolic}}
+%{!r:--build-id} %{!static|static-pie:--eh-frame-hdr} %{!mandroid|tno-android-ld:%{m16|m32|mx32:;:-m elf_x86_64}                    %{m16|m32:-m elf_i386}                    %{mx32:-m elf32_x86_64}   --hash-style=gnu   --as-needed   %{shared:-shared}   %{!shared:     %{!static:       %{!static-pie: 	%{rdynamic:-export-dynamic} 	%{m16|m32:-dynamic-linker %{muclibc:/lib/ld-uClibc.so.0;:%{mbionic:/system/bin/linker;:%{mmusl:/lib/ld-musl-i386.so.1;:/lib/ld-linux.so.2}}}} 	%{m16|m32|mx32:;:-dynamic-linker %{muclibc:/lib/ld64-uClibc.so.0;:%{mbionic:/system/bin/linker64;:%{mmusl:/lib/ld-musl-x86_64.so.1;:/lib64/ld-linux-x86-64.so.2}}}} 	%{mx32:-dynamic-linker %{muclibc:/lib/ldx32-uClibc.so.0;:%{mbionic:/system/bin/linkerx32;:%{mmusl:/lib/ld-musl-x32.so.1;:/libx32/ld-linux-x32.so.2}}}}}}     %{static:-static} %{static-pie:-static -pie --no-dynamic-linker -z text}};:%{m16|m32|mx32:;:-m elf_x86_64}                    %{m16|m32:-m elf_i386}                    %{mx32:-m elf32_x86_64}   --hash-style=gnu   --as-needed   %{shared:-shared}   %{!shared:     %{!static:       %{!static-pie: 	%{rdynamic:-export-dynamic} 	%{m16|m32:-dynamic-linker %{muclibc:/lib/ld-uClibc.so.0;:%{mbionic:/system/bin/linker;:%{mmusl:/lib/ld-musl-i386.so.1;:/lib/ld-linux.so.2}}}} 	%{m16|m32|mx32:;:-dynamic-linker %{muclibc:/lib/ld64-uClibc.so.0;:%{mbionic:/system/bin/linker64;:%{mmusl:/lib/ld-musl-x86_64.so.1;:/lib64/ld-linux-x86-64.so.2}}}} 	%{mx32:-dynamic-linker %{muclibc:/lib/ldx32-uClibc.so.0;:%{mbionic:/system/bin/linkerx32;:%{mmusl:/lib/ld-musl-x32.so.1;:/libx32/ld-linux-x32.so.2}}}}}}     %{static:-static} %{static-pie:-static -pie --no-dynamic-linker -z text}} %{shared: -Bsymbolic}}
 
 *lib:
 %{!mandroid|tno-android-ld:%{pthread:-lpthread} %{shared:-lc}    %{!shared:%{profile:-lc_p}%{!profile:-lc}};:%{shared:-lc}    %{!shared:%{profile:-lc_p}%{!profile:-lc}} %{!static: -ldl}}
@@ -68,7 +71,7 @@
 0
 
 *version:
-8.3.0
+9.3.0
 
 *multilib:
 . !m32 !m64 !mx32;32:../lib32:i386-linux-gnu m32 !m64 !mx32;64:../lib:x86_64-linux-gnu !m32 m64 !mx32;x32:../libx32:x86_64-linux-gnux32 !m32 !m64 mx32;
@@ -137,6 +140,6 @@
 %{march=native:%>march=native %:local_cpu_detect(arch)   %{!mtune=*:%>mtune=native %:local_cpu_detect(tune)}} %{mtune=native:%>mtune=native %:local_cpu_detect(tune)}
 
 *link_command:
-%{!fsyntax-only:%{!c:%{!M:%{!MM:%{!E:%{!S:    %(linker) %{!fno-use-linker-plugin:%{!fno-lto:     -plugin %(linker_plugin_file)     -plugin-opt=%(lto_wrapper)     -plugin-opt=-fresolution=%u.res     %{!nostdlib:%{!nodefaultlibs:%:pass-through-libs(%(link_gcc_c_sequence))}}     }}%{flto|flto=*:%<fcompare-debug*}     %{flto} %{fno-lto} %{flto=*} %l %{static|shared|r:;!no-pie:-pie} %{fuse-ld=*:-fuse-ld=%*}  %{gz|gz=zlib:--compress-debug-sections=zlib} %{gz=none:--compress-debug-sections=none} %{gz=zlib-gnu:--compress-debug-sections=zlib-gnu} %X %{o*} %{e*} %{N} %{n} %{r}    %{s} %{t} %{u*} %{z} %{Z} %{!nostdlib:%{!nostartfiles:%S}}     %{static|no-pie|static-pie:} %{L*} %(mfwrap) %(link_libgcc) %{fvtable-verify=none:} %{fvtable-verify=std:   %e-fvtable-verify=std is not supported in this configuration} %{fvtable-verify=preinit:   %e-fvtable-verify=preinit is not supported in this configuration} %{!nostdlib:%{!nodefaultlibs:%{%:sanitize(address):%{!shared:libasan_preinit%O%s} %{static-libasan:%{!shared:-Bstatic --whole-archive -lasan --no-whole-archive -Bdynamic}}%{!static-libasan:-lasan}}     %{%:sanitize(thread):%{!shared:libtsan_preinit%O%s} %{static-libtsan:%{!shared:-Bstatic --whole-archive -ltsan --no-whole-archive -Bdynamic}}%{!static-libtsan:-ltsan}}     %{%:sanitize(leak):%{!shared:liblsan_preinit%O%s} %{static-liblsan:%{!shared:-Bstatic --whole-archive -llsan --no-whole-archive -Bdynamic}}%{!static-liblsan:-llsan}}}} %o %{!nostdlib:%{!nodefaultlibs:%{mmpx:%{fcheck-pointer-bounds:    %{static:--whole-archive -lmpx --no-whole-archive %:include(libmpx.spec)%(link_libmpx)}    %{!static:%{static-libmpx:-Bstatic --whole-archive}    %{!static-libmpx:--push-state --no-as-needed} -lmpx     %{!static-libmpx:--pop-state}     %{static-libmpx:--no-whole-archive -Bdynamic %:include(libmpx.spec)%(link_libmpx)}}}}%{mmpx:%{fcheck-pointer-bounds:%{!fno-chkp-use-wrappers:    %{static:-lmpxwrappers}    %{!static:%{static-libmpxwrappers:-Bstatic}    -lmpxwrappers %{static-libmpxwrappers: -Bdynamic}}}}}}} %{mmpx:%{fcheck-pointer-bounds:%{!static:%{m16|m32|mx32:;:-z bndplt }}}}     %{fopenacc|fopenmp|%:gt(%{ftree-parallelize-loops=*:%*} 1):	%:include(libgomp.spec)%(link_gomp)}    %{fgnu-tm:%:include(libitm.spec)%(link_itm)}    %(mflib)  %{fsplit-stack: --wrap=pthread_create}    %{fprofile-arcs|fprofile-generate*|coverage:-lgcov} %{!nostdlib:%{!nodefaultlibs:%{%:sanitize(address): %{static-libasan|static:%:include(libsanitizer.spec)%(link_libasan)}    %{static:%ecannot specify -static with -fsanitize=address}}    %{%:sanitize(thread): %{static-libtsan|static:%:include(libsanitizer.spec)%(link_libtsan)}    %{static:%ecannot specify -static with -fsanitize=thread}}    %{%:sanitize(undefined):%{static-libubsan:-Bstatic} -lubsan %{static-libubsan:-Bdynamic} %{static-libubsan|static:%:include(libsanitizer.spec)%(link_libubsan)}}    %{%:sanitize(leak): %{static-liblsan|static:%:include(libsanitizer.spec)%(link_liblsan)}}}}     %{!nostdlib:%{!nodefaultlibs:%(link_ssp) %(link_gcc_c_sequence)}}    %{!nostdlib:%{!nostartfiles:%E}} %{T*}  
+%{!fsyntax-only:%{!c:%{!M:%{!MM:%{!E:%{!S:    %(linker) %{!fno-use-linker-plugin:%{!fno-lto:     -plugin %(linker_plugin_file)     -plugin-opt=%(lto_wrapper)     -plugin-opt=-fresolution=%u.res     %{flinker-output=*:-plugin-opt=-linker-output-known}     %{!nostdlib:%{!nodefaultlibs:%:pass-through-libs(%(link_gcc_c_sequence))}}     }}%{flto|flto=*:%<fcompare-debug*}     %{flto} %{fno-lto} %{flto=*} %l %{static|shared|r:;!no-pie:-pie -z now} %{fuse-ld=*:-fuse-ld=%*}  %{gz|gz=zlib:--compress-debug-sections=zlib} %{gz=none:--compress-debug-sections=none} %{gz=zlib-gnu:--compress-debug-sections=zlib-gnu}  -z relro %X %{o*} %{e*} %{N} %{n} %{r}    %{s} %{t} %{u*} %{z} %{Z} %{!nostdlib:%{!r:%{!nostartfiles:%S}}}     %{static|no-pie|static-pie:} %@{L*} %(mfwrap) %(link_libgcc) %{fvtable-verify=none:} %{fvtable-verify=std:   %e-fvtable-verify=std is not supported in this configuration} %{fvtable-verify=preinit:   %e-fvtable-verify=preinit is not supported in this configuration} %{!nostdlib:%{!r:%{!nodefaultlibs:%{%:sanitize(address):%{!shared:libasan_preinit%O%s} %{static-libasan:%{!shared:-Bstatic --whole-archive -lasan --no-whole-archive -Bdynamic}}%{!static-libasan:%{!fuse-ld=gold:--push-state} --no-as-needed -lasan %{fuse-ld=gold:--as-needed;:--pop-state}}}     %{%:sanitize(thread):%{!shared:libtsan_preinit%O%s} %{static-libtsan:%{!shared:-Bstatic --whole-archive -ltsan --no-whole-archive -Bdynamic}}%{!static-libtsan:%{!fuse-ld=gold:--push-state} --no-as-needed -ltsan %{fuse-ld=gold:--as-needed;:--pop-state}}}     %{%:sanitize(leak):%{!shared:liblsan_preinit%O%s} %{static-liblsan:%{!shared:-Bstatic --whole-archive -llsan --no-whole-archive -Bdynamic}}%{!static-liblsan:%{!fuse-ld=gold:--push-state} --no-as-needed -llsan %{fuse-ld=gold:--as-needed;:--pop-state}}}}}} %o      %{fopenacc|fopenmp|%:gt(%{ftree-parallelize-loops=*:%*} 1):	%:include(libgomp.spec)%(link_gomp)}    %{fgnu-tm:%:include(libitm.spec)%(link_itm)}    %(mflib)  %{fsplit-stack: --wrap=pthread_create}    %{fprofile-arcs|fprofile-generate*|coverage:-lgcov} %{!nostdlib:%{!r:%{!nodefaultlibs:%{%:sanitize(address): %{static-libasan|static:%:include(libsanitizer.spec)%(link_libasan)}    %{static:%ecannot specify -static with -fsanitize=address}}    %{%:sanitize(thread): %{static-libtsan|static:%:include(libsanitizer.spec)%(link_libtsan)}    %{static:%ecannot specify -static with -fsanitize=thread}}    %{%:sanitize(undefined):%{static-libubsan:-Bstatic} %{!static-libubsan:--push-state --no-as-needed} -lubsan  %{static-libubsan:-Bdynamic} %{!static-libubsan:--pop-state} %{static-libubsan|static:%:include(libsanitizer.spec)%(link_libubsan)}}    %{%:sanitize(leak): %{static-liblsan|static:%:include(libsanitizer.spec)%(link_liblsan)}}}}}     %{!nostdlib:%{!r:%{!nodefaultlibs:%(link_ssp) %(link_gcc_c_sequence)}}}    %{!nostdlib:%{!r:%{!nostartfiles:%E}}} %{T*}  
 %(post_link) }}}}}}
 
$ 
```

distro_defaults がいかにも怪しそうだがよく判らない...

##### feature\_test\_macros

結局 Stack Overflow で発見。[c++ - Disable using __sprintf_chk() - Stack Overflow](https://stackoverflow.com/questions/12201625/disable-using-sprintf-chk)

glibc 2.3.4 からの機能で、cpp マクロ `_FORTIFY_SOURCE` の値によりバッファオーバーフローチェックを行うようになったとのこと。  
しかしながらここで使っている sprintf(3) は glibc のものではなく自作の簡易版だ。勝手に \_\_sprintf\_chk() に置換されても対応できない。

fstack-protector あたりのオプションで制御できるのかもしれないが、直接 -U\_FORTIFY\_SOURCE することで呼び出しを抑制した。

##### 参考

- [feature_test_macros(7) - Linux manual page](https://man7.org/linux/man-pages/man7/feature_test_macros.7.html)

#### `.note.gnu.property` 対応

もうひとつエラーが出ている。

```
ld: section .note.gnu.property LMA [0000000000000f3c,0000000000000fff] overlaps section .data LMA [0000000000000f3c,000000000000209b]
```

.note.gnu.property セクションと .data セクションが重なっているというエラーだろう。

.note.gnu.property セクションとはなにか？

```shell-session
docker$ readelf -S bootpack.o
There are 14 section headers, starting at offset 0x924:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000034 0002b9 00  AX  0   0  1
  [ 2] .rel.text         REL             00000000 0006f8 000190 08   I 11   1  4
  [ 3] .data             PROGBITS        00000000 0002ed 000000 00  WA  0   0  1
  [ 4] .bss              NOBITS          00000000 0002ed 000000 00  WA  0   0  1
  [ 5] .rodata.str1.1    PROGBITS        00000000 0002ed 00000e 01 AMS  0   0  1
  [ 6] .comment          PROGBITS        00000000 0002fb 00002b 01  MS  0   0  1
  [ 7] .note.GNU-stack   PROGBITS        00000000 000326 000000 00      0   0  1
  [ 8] .note.gnu.propert NOTE            00000000 000328 00001c 00   A  0   0  4
  [ 9] .eh_frame         PROGBITS        00000000 000344 000098 00   A  0   0  4
  [10] .rel.eh_frame     REL             00000000 000888 000020 08   I 11   9  4
  [11] .symtab           SYMTAB          00000000 0003dc 000210 10     12  10  4
  [12] .strtab           STRTAB          00000000 0005ec 00010b 00      0   0  1
  [13] .shstrtab         STRTAB          00000000 0008a8 000079 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  p (processor specific)
docker$ readelf -x 8 bootpack.o

Hex dump of section '.note.gnu.property':
  0x00000000 04000000 0c000000 05000000 474e5500 ............GNU.
  0x00000010 020000c0 04000000 03000000          ............

docker$ readelf -n bootpack.o

Displaying notes found in: .note.gnu.property
  Owner                 Data size       Description
  GNU                  0x0000000c       NT_GNU_PROPERTY_TYPE_0
      Properties: x86 feature: IBT, SHSTK
docker$
```

Note とは ELF バイナリに埋め込んでさまざまな情報を提供するためのセクションで `.note.ABI-tag`, `.note.gnu.build-id`, `.note.GNU-stack` などがあるらしい（`.note.gnu.property` の用途は不明）が、そもそもはりぼて OS では ELF を使用しないので削除してしまえばよいだろう。

```diff
diff --git a/hrb.lds b/hrb.lds
index 5ca4f39..687360a 100644
--- a/hrb.lds
+++ b/hrb.lds
@@ -33,5 +33,6 @@ SECTIONS
     } = 0x00000000

     /DISCARD/ : { *(.eh_frame) }
+    /DISCARD/ : { *(.note.gnu.property) }

 }
```

これでエラーが出なくなった。

##### 参考

- [Output Section LMA (LD)](https://sourceware.org/binutils/docs/ld/Output-Section-LMA.html)
- [elf(5) - Linux manual page](https://man7.org/linux/man-pages/man5/elf.5.html)

### 成果

- [makefile.yml](/.github/workflows/makefile.yml)
    - 実際には GitHub 経由で main ブランチに設定
- [Makefile](/Makefile)
    - sprintf に対するバッファオーバーフローチェック抑制
- [hrb.lds](/hrb.lds)
    - .note.gnu.property セクションを取り除く

----

Next: [Interlude](interlude.md), Previous: [Interlude](interlude.md), Up: [Interlude](interlude.md)
