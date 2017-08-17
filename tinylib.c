#include <sys/types.h>
#include <limits.h>
#include <string.h>
#include <stdarg.h>
#ifdef _TEST
#define	toupper my_toupper
#define	tolower my_tolower
#define	strtoupper my_strtoupper
#define	strtolower my_strtolower
#define	strcpy my_strcpy
#define	strlen my_strlen
#define	_itoa my__itoa
#define	vsprintf my_vsprintf
#define	sprintf my_sprintf
#endif

int toupper(int __c)
{
    return __c >= 'a' && __c <= 'z' ? __c - 'a' + 'A': __c;
}
int tolower(int __c)
{
    return __c >= 'A' && __c <= 'Z' ? __c - 'A' + 'a': __c;
}
char *strtoupper(char *__s)
{
    for (char *t = __s; *t; t++)
        *t = toupper(*t);
    return __s;
}
char *strtolower(char *__s)
{
    for (char *t = __s; *t; t++)
        *t = tolower(*t);
    return __s;
}
char *strcpy (char *__restrict __dest, const char *__restrict __src)
{
    for (char *t = __dest; (*t++ = *__src++) != '\0';)
        ;
    return __dest;
}
size_t strlen(const char *__s)
{
    const char *t = __s;
    for (; *t; t++)
        ;
    return t - __s;
}

static int _uw10(unsigned int value)
{
    int w;
    if (value == 0)
        return 1;
    for (w = 0; value > 0; w++, value /= 10)
        ;
    return w;
}
static int _uw16(unsigned int value)
{
    int w;
    if (value == 0)
        return 1;
    for (w = 0; value > 0; w++, value >>= 4)
        ;
    return w;
}
static char *_utoa10(unsigned int value, char *str)
{
    if (value == 0) {
        *str = '0';
        *(str + 1) = '\0';
    }
    else {
        int digit = 10 - 1;     /* max 10 digits */
        char *t = str;
        int mask = 10;
        for (; digit > 0 && value / mask > 0; digit--, mask *= 10, t++)
            ;
        *(t + 1) = '\0';
        for (; value > 0; value /= 10)
            *t-- = value % 10 + '0';
    }
    return str;
}
static char *_utoa16(unsigned int value, char *str)
{
    if (value == 0) {
        *str = '0';
        *(str + 1) = '\0';
    }
    else {
        char *t = str + 8;      /* max 8 digits */
        unsigned int mask = 0xf << (8 - 1) * 4;
        for (; t > str && (value & mask) == 0; t--, mask >>= 4)
            ;
        *t-- = '\0';
        for (; t >= str; value >>= 4)
            *t-- = "0123456789abcdef"[value & 0xf];
    }
    return str;
}
char *_itoa(int value, char *str, int radix)
{
    if (value == 0) {
        *str = '0';
        *(str + 1) = '\0';
    }
    else {
        char *s, *t;
        unsigned int u;
        switch (radix) {
        case 16:
            return _utoa16((unsigned int)value, str);
        case 10:
        decimal:
            if (value < 0) {
                if (value == INT_MIN)
                    return strcpy(str, "-2147483648");
                else {
                    _utoa10((unsigned int)-value, str + 1);
                    *str = '-';
                    return str;
                }
            }
            return _utoa10((unsigned int)value, str);
        }
        if (radix < 2 && radix > 36)
            goto decimal;
        t = s = str;
        if (value >= 0)
            u = value;
        else {
            u = (unsigned int)((long long)value * -1);
            s++;
            *t++ = '-';
        }
        for (; u > 0; u /= radix) {
            int c = u % radix;
            *t++ = c + (c >= 0 && c < 10 ? '0': 'a' - 10);
        }
        for (*t-- = '\0'; s < t; s++, t--) {
            int c = *s;
            *s = *t;
            *t = c;
        }
    }
    return str;
}

int vsprintf(char *__restrict __s, const char *__restrict __format, va_list __arg)
{
    char *t = __s;
    const char *s = __format;
    while (*s) {
        if (*s != '%')
            *t++ = *s++;
        else {
            int width = 0;
            char pad = ' ';
            char f;
            int len;
            const char *sval;
            int ival;
            unsigned int uval;
            if (*++s == '0')
                pad = '0';
            while (*s >= '0' && *s <= '9') {
                width *= 10;
                width += *s++ - '0';
            }
            switch (f = *s++) {
            case 's':
                sval = va_arg(__arg, const char *);
                len = strlen(sval);
                for (width -= len; width > 0; width--)
                    *t++ = pad;
                strcpy(t, sval);
                t += len;
                break;
            case 'd':
            case 'x':
            case 'X':
                ival = va_arg(__arg, int);
                uval = ival < 0 ? (unsigned int)((long long)ival * -1): (unsigned int)ival;
                len = f == 'd' ? _uw10(uval): _uw16(uval);
                if (ival < 0) {
                    *t++ = '-';
                    width--;
                }
                for (width -= len; width > 0; width--)
                    *t++ = pad;
                if (f == 'd')
                    _utoa10(uval, t);
                else
                    _utoa16(uval, t);
                if (f == 'X')
                    strtoupper(t);
                t += len;
                break;
            case 'c':
                ival = va_arg(__arg, int);
                for (width--; width > 0; width--)
                    *t++ = pad;
                *t++ = (char)ival;
                break;
            default:
                *t++ = f;
                break;
            }
        }
    }
    *t++ = '\0';
    return t - __s;
}
int sprintf(char *__restrict __s, const char *__restrict __format, ...)
{
    int ret;
    va_list ap;
    va_start(ap, __format);
    ret = vsprintf(__s, __format, ap);
    va_end(ap);
    return ret;
}

#ifdef _TEST
#include <stdio.h>
int main(int argc, char **argv)
{
    char buffer[512];
#if 0
    for (int c = ' '; c <= '~'; c++)
        printf("toupper(%c): %c, tolower(%c): %c\n", c, toupper(c), c, tolower(c));

    printf("0: %s\n", _utoa10(0, buffer));
    printf("158: %s\n", _utoa10(158, buffer));
    printf("-32769: %s\n", _utoa10(-32769, buffer));
    printf("INT_MAX: %s\n", _utoa10(INT_MAX, buffer));
    printf("INT_MIN: %s\n", _utoa10(INT_MIN, buffer));
    printf("INT_MIN-1: %s\n", _utoa10(INT_MIN-1, buffer));
    printf("INT_MIN+1: %s\n", _utoa10(INT_MIN+1, buffer));
    printf("INT_MAX-1: %s\n", _utoa10(INT_MAX-1, buffer));
    printf("INT_MAX+1: %s\n", _utoa10(INT_MAX+1, buffer));
    printf("999999999 : %s\n", _utoa10(999999999 , buffer));
    printf("-999999999 : %s\n", _utoa10(-999999999 , buffer));
    printf("1000000000 : %s\n", _utoa10(1000000000 , buffer));
    printf("-1000000000 : %s\n", _utoa10(-1000000000 , buffer));
    printf("1999899989 : %s\n", _utoa10(1999899989 , buffer));
    printf("-1234567890 : %s\n", _utoa10(-1234567890 , buffer));
    printf("2000000000 : %s\n", _utoa10(2000000000 , buffer));
    printf("-2000000000 : %s\n", _utoa10(-2000000000 , buffer));
    printf("2100000000 : %s\n", _utoa10(2100000000 , buffer));
    printf("-2100000000 : %s\n", _utoa10(-2100000000 , buffer));

    printf("0: %s\n", _utoa16(0, buffer));
    printf("-1: %s\n", _utoa16(-1, buffer));
    printf("158: %s\n", _utoa16(158, buffer));
    printf("-32769: %s\n", _utoa16(-32769, buffer));
    printf("INT_MAX: %s\n", _utoa16(INT_MAX, buffer));
    printf("INT_MIN: %s\n", _utoa16(INT_MIN, buffer));
    printf("INT_MIN-1: %s\n", _utoa16(INT_MIN-1, buffer));
    printf("INT_MIN+1: %s\n", _utoa16(INT_MIN+1, buffer));
    printf("INT_MAX-1: %s\n", _utoa16(INT_MAX-1, buffer));
    printf("INT_MAX+1: %s\n", _utoa16(INT_MAX+1, buffer));
    printf("999999999 : %s\n", _utoa16(999999999 , buffer));
    printf("-999999999 : %s\n", _utoa16(-999999999 , buffer));
    printf("1000000000 : %s\n", _utoa16(1000000000 , buffer));
    printf("-1000000000 : %s\n", _utoa16(-1000000000 , buffer));
    printf("1999899989 : %s\n", _utoa16(1999899989 , buffer));
    printf("-1234567890 : %s\n", _utoa16(-1234567890 , buffer));
    printf("2000000000 : %s\n", _utoa16(2000000000 , buffer));
    printf("-2000000000 : %s\n", _utoa16(-2000000000 , buffer));
    printf("2100000000 : %s\n", _utoa16(2100000000 , buffer));
    printf("-2100000000 : %s\n", _utoa16(-2100000000 , buffer));

    printf("0ff0 : %s\n", _itoa(0x0ff0, buffer, 2));
    printf("0ff0 : %s\n", _itoa(0x0ff0, buffer, 4));
    printf("0ff0 : %s\n", _itoa(0x0ff0, buffer, 8));
    printf("0ff0 : %s\n", _itoa(0x0ff0, buffer, 10));
    printf("0ff0 : %s\n", _itoa(0x0ff0, buffer, 12));
    printf("0ff0 : %s\n", _itoa(0x0ff0, buffer, 32));
    printf("0ff0 : %s\n", _itoa(0x0ff0, buffer, 36));

    printf("0ff0 : %s\n", _itoa(-4080, buffer, 2));
    printf("0ff0 : %s\n", _itoa(-4080, buffer, 4));
    printf("0ff0 : %s\n", _itoa(-4080, buffer, 8));
    printf("0ff0 : %s\n", _itoa(-4080, buffer, 10));
    printf("0ff0 : %s\n", _itoa(-4080, buffer, 12));
    printf("0ff0 : %s\n", _itoa(-4080, buffer, 32));
    printf("0ff0 : %s\n", _itoa(-4080, buffer, 36));

    printf("INT_MIN : %s\n", _itoa(INT_MIN, buffer, 2));
    printf("INT_MIN : %s\n", _itoa(INT_MIN, buffer, 4));
    printf("INT_MIN : %s\n", _itoa(INT_MIN, buffer, 8));
    printf("INT_MIN : %s\n", _itoa(INT_MIN, buffer, 10));
    printf("INT_MIN : %s\n", _itoa(INT_MIN, buffer, 12));
    printf("INT_MIN : %s\n", _itoa(INT_MIN, buffer, 32));
    printf("INT_MIN : %s\n", _itoa(INT_MIN, buffer, 36));
#endif

    sprintf(buffer, "scrnx = %d", 320); puts(buffer);
    sprintf(buffer, "%%5d: %5d", -123); puts(buffer);
    sprintf(buffer, "%%05d: %05d", -123); puts(buffer);
    sprintf(buffer, "%%x: %x", 456); puts(buffer);
    sprintf(buffer, "%%X: %X", 456); puts(buffer);
    sprintf(buffer, "%%5x: %5x", 456); puts(buffer);
    sprintf(buffer, "%%05x: %05x", 456); puts(buffer);
    return 0;
}
#endif
/*
 * Local Variables:
 * compile-command: "cc -D_TEST -fno-pic -Os -Wall tinylib.c && ./a.out"
 * End:
 */
