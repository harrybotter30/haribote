	.file	"naskfunc.S"    /* ソースファイル名情報 */
	.code32                 /* 32ビットモード用の機械語を作らせる */
	.text

/* オブジェクトファイルのための情報 */

	.globl	io_hlt          /* このプログラムに含まれる関数名 */
	.type	io_hlt, @function

/* 以下は実際の関数 */

io_hlt:
	hlt
	ret
