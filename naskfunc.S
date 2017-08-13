	.file	"naskfunc.S"    /* ソースファイル名情報 */
	.arch	i486            /* 486の命令まで使いたいという記述 */
	.code32                 /* 32ビットモード用の機械語を作らせる */
	.text

/* オブジェクトファイルのための情報 */

	.globl	io_hlt
	.type	io_hlt, @function

/* 以下は実際の関数 */

io_hlt:                         /* void io_hlt(void); */
	hlt
	ret
