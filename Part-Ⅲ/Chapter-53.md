# 第五十三章
# 16位Windows

16位windows程序现在很少见了，但是在旧式计算机或者入侵软件狗的时候（58章），我有时候还会遇到这个问题。 16位的windows版本最高到3.11，95(*注：作者笔误写成了Win96)/98/ME也支持16位代码，他们同时也是一个Windows NT家族的32位版本。64位版本的Windows NT家族完全不支持16位程序。 代码类似于MS-DOS代码。 执行文件并不是MZ式或者PE文件，而是NE式（所谓的“New Executable”，新执行程序）。 所有的例子都由OpenWatcom 1.9编译器编译，使用这些参数：

`Wcl.exe -i=C:/WATCOM/h/win/ -s -os -bt=windows example.c`

## 53.1 例子#1

```
#include <windows.h>
int PASCAL WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    MessageBeep(MB_ICONEXCLAMATION);
    return 0;
};
```

```
WinMain proc near
    push bp
    mov bp, sp
    mov ax, 30h ; ’0’ ; MB_ICONEXCLAMATION constant
    push ax
    call MESSAGEBEEP
    xor ax, ax ; return 0
    pop bp
    retn 0Ah
WinMain endp
```

到现在为止，看起来都很简单。

## 53.2 例子#2

```
#include <windows.h>
int PASCAL WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    MessageBox (NULL, "hello, world", "caption", MB_YESNOCANCEL);
    return 0;
};
```

```
WinMain proc near
        push bp
        mov bp, sp
        xor ax, ax ; NULL
        push ax
        push ds
        mov ax, offset aHelloWorld ; 0x18. "hello, world"
        push ax
        push ds
        mov ax, offset aCaption ; 0x10. "caption"
        push ax
        mov ax, 3 ; MB_YESNOCANCEL
        push ax
        call MESSAGEBOX
        xor ax, ax ; return 0
        pop bp
        retn 0Ah
WinMain endp
dseg02:0010 aCaption db ’caption’,0
dseg02:0018 aHelloWorld db ’hello, world’,0
```

有两个重要的信息：PASCAL调用转换表明先传递最后的参数（MB_YESNOCANCEL），然后才是第一个参数NULL。这个调用也表明了调用者恢复栈指针：因为RETN有一个0Ah的参数，这个意味着栈指针将在函数退出时上移10个字节。 指针按对传递：一组数据先传递，指针就在这组数据里面。例子这里只有一组数据，所以DS永远指向可执行文件的data段。

## 53.3 例子#3

```
#include <windows.h>
int PASCAL WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    int result=MessageBox (NULL, "hello, world", "caption", MB_YESNOCANCEL);
    if (result==IDCANCEL)
        MessageBox (NULL, "you pressed cancel", "caption", MB_OK);
    else if (result==IDYES)
        MessageBox (NULL, "you pressed yes", "caption", MB_OK);
    else if (result==IDNO)
        MessageBox (NULL, "you pressed no", "caption", MB_OK);
    return 0;
};
```

```
WinMain proc near
        push bp
        mov bp, sp
        xor ax, ax ; NULL
        push ax
        push ds
        mov ax, offset aHelloWorld ; "hello, world"
        push ax
        push ds
        mov ax, offset aCaption ; "caption"
        push ax
        mov ax, 3 ; MB_YESNOCANCEL
        push ax
        call MESSAGEBOX
        cmp ax, 2 ; IDCANCEL
        jnz short loc_2F
        xor ax, ax
        push ax
        push ds
        mov ax, offset aYouPressedCanc ; "you pressed cancel"
        jmp short loc_49
        ; ---------------------------------------------------------------------------
        loc_2F:
        cmp ax, 6 ; IDYES
        jnz short loc_3D
        xor ax, ax
        push ax
        push ds
        mov ax, offset aYouPressedYes ; "you pressed yes"
        jmp short loc_49
        ; ---------------------------------------------------------------------------
        loc_3D:
        cmp ax, 7 ; IDNO
        jnz short loc_57
        xor ax, ax
        push ax
        push ds
        mov ax, offset aYouPressedNo ; "you pressed no"
        loc_49:
        push ax
        push ds
        mov ax, offset aCaption ; "caption"
        push ax
        xor ax, ax
        push ax
        call MESSAGEBOX
        loc_57:
        xor ax, ax
        pop bp
        retn 0Ah
WinMain endp
```

就是前一节的扩展而已。

## 53.4 例子#4

```
#include <windows.h>
int PASCAL func1 (int a, int b, int c)
{
    return a*b+c;
};
long PASCAL func2 (long a, long b, long c)
{
    return a*b+c;
};
long PASCAL func3 (long a, long b, long c, int d)
{
    return a*b+c-d;
};

int PASCAL WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    func1 (123, 456, 789);
    func2 (600000, 700000, 800000);
    func3 (600000, 700000, 800000, 123);
    return 0;
};
```

```
func1 proc near
    c = word ptr 4
    b = word ptr 6
    a = word ptr 8
    push bp
    mov bp, sp
    mov ax, [bp+a]
    imul [bp+b]
    add ax, [bp+c]
    pop bp
    retn 6
func1 endp
func2 proc near
    arg_0 = word ptr 4
    arg_2 = word ptr 6
    arg_4 = word ptr 8
    arg_6 = word ptr 0Ah
    arg_8 = word ptr 0Ch
    arg_A = word ptr 0Eh
    push bp
    mov bp, sp
    mov ax, [bp+arg_8]
    mov dx, [bp+arg_A]
    mov bx, [bp+arg_4]
    mov cx, [bp+arg_6]
    call sub_B2 ; long 32-bit multiplication
    add ax, [bp+arg_0]
    adc dx, [bp+arg_2]
    pop bp
    retn 12
func2 endp
func3 proc near
    arg_0 = word ptr 4
    arg_2 = word ptr 6
    arg_4 = word ptr 8
    arg_6 = word ptr 0Ah
    arg_8 = word ptr 0Ch
    arg_A = word ptr 0Eh
    arg_C = word ptr 10h
    push bp
    mov bp, sp
    mov ax, [bp+arg_A]
    mov dx, [bp+arg_C]
    mov bx, [bp+arg_6]
    mov cx, [bp+arg_8]
    call sub_B2 ; long 32-bit multiplication
    mov cx, [bp+arg_2]
    add cx, ax
    mov bx, [bp+arg_4]
    adc bx, dx ; BX=high part, CX=low part
    mov ax, [bp+arg_0]
    cwd ; AX=low part d, DX=high part d
    sub cx, ax
    mov ax, cx
    sbb bx, dx
    mov dx, bx
    pop bp
    retn 14
    func3 endp
    WinMain proc near
    push bp
    mov bp, sp
    mov ax, 123
    push ax
    mov ax, 456
    push ax
    mov ax, 789
    push ax
    call func1
    mov ax, 9 ; high part of 600000
    push ax
    mov ax, 27C0h ; low part of 600000
    push ax
    mov ax, 0Ah ; high part of 700000
    push ax
    mov ax, 0AE60h ; low part of 700000
    push ax
    mov ax, 0Ch ; high part of 800000
    push ax
    mov ax, 3500h ; low part of 800000
    push ax
    call func2
    mov ax, 9 ; high part of 600000
    push ax
    mov ax, 27C0h ; low part of 600000
    push ax
    mov ax, 0Ah ; high part of 700000
    push ax
    mov ax, 0AE60h ; low part of 700000
    push ax
    mov ax, 0Ch ; high part of 800000
    push ax
    mov ax, 3500h ; low part of 800000
    push ax
    mov ax, 7Bh ; 123
    push ax
    call func3
    xor ax, ax ; return 0
    pop bp
    retn 0Ah
WinMain endp
```

32位的值（long数据类型代表32位，int代表16位数据）在16位模式下（MSDOS和win16）都会按对传递，就像64位数据在32位环境下使用的方式一样（21章）。

Sub_B2在这里是一个编译器生成的库函数，他的作用是“long乘法”，例如两个32位类型想成，其他的编译器函数列在了附录E, D.中。 ADD/ADC指令对用来相加两个值：ADD将设置/清空CF进位标识，ADC将会使用它。 SUB/SBB将会做减法，SUB会设置/清空CF标识位，SBB将会使用它。 32位值按照DX:AX寄存器对返回。 常数同样在WinMain()中按照值对的方式传递。 Int类型的123常量首先被转为32位的值，使用的是CWD指令。

## 53.5 例子#5

```
#include <windows.h>
int PASCAL string_compare (char *s1, char *s2)
{
    while (1)
    {
        if (*s1!=*s2)
            return 0;
        if (*s1==0 || *s2==0)
            return 1; // end of string
        s1++;
        s2++;
    };
};

int PASCAL string_compare_far (char far *s1, char far *s2)
{
    while (1)
    {
        if (*s1!=*s2)
            return 0;
        if (*s1==0 || *s2==0)
            return 1; // end of string
        s1++;
        s2++;
    };
};
void PASCAL remove_digits (char *s)
{
    while (*s)
    {
        if (*s>=’0’ && *s<=’9’)
            *s=’-’;
        s++;
    };
};

char str[]="hello 1234 world";
int PASCAL WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    string_compare ("asd", "def");
    string_compare_far ("asd", "def");
    remove_digits (str);
    MessageBox (NULL, str, "caption", MB_YESNOCANCEL);
    return 0;
};

```

```
string_compare proc near
arg_0 = word ptr 4
arg_2 = word ptr 6
push bp
mov bp, sp
push si
mov si, [bp+arg_0]
mov bx, [bp+arg_2]
loc_12: ; CODE XREF: string_compare+21j
mov al, [bx]
cmp al, [si]
jz short loc_1C
xor ax, ax
jmp short loc_2B
; ---------------------------------------------------------------------------
loc_1C: ; CODE XREF: string_compare+Ej
test al, al
jz short loc_22
jnz short loc_27
loc_22: ; CODE XREF: string_compare+16j
mov ax, 1
jmp short loc_2B
; ---------------------------------------------------------------------------
loc_27: ; CODE XREF: string_compare+18j
inc bx
inc si
jmp short loc_12
; ---------------------------------------------------------------------------
loc_2B: ; CODE XREF: string_compare+12j
; string_compare+1Dj
pop si
pop bp
retn 4
string_compare endp
string_compare_far proc near ; CODE XREF: WinMain+18p
arg_0 = word ptr 4
arg_2 = word ptr 6
arg_4 = word ptr 8
arg_6 = word ptr 0Ah
push bp
mov bp, sp
push si
mov si, [bp+arg_0]
mov bx, [bp+arg_4]
loc_3A: ; CODE XREF: string_compare_far+35j
mov es, [bp+arg_6]
mov al, es:[bx]
mov es, [bp+arg_2]
cmp al, es:[si]
jz short loc_4C
xor ax, ax
jmp short loc_67
; ---------------------------------------------------------------------------
loc_4C: ; CODE XREF: string_compare_far+16j
mov es, [bp+arg_6]
cmp byte ptr es:[bx], 0
jz short loc_5E
mov es, [bp+arg_2]
cmp byte ptr es:[si], 0
jnz short loc_63
loc_5E: ; CODE XREF: string_compare_far+23j
mov ax, 1
jmp short loc_67
; ---------------------------------------------------------------------------
loc_63: ; CODE XREF: string_compare_far+2Cj
inc bx
inc si
jmp short loc_3A
; ---------------------------------------------------------------------------
loc_67: ; CODE XREF: string_compare_far+1Aj
; string_compare_far+31j
pop si
pop bp
retn 8
string_compare_far endp
remove_digits proc near ; CODE XREF: WinMain+1Fp
arg_0 = word ptr 4
push bp
mov bp, sp
mov bx, [bp+arg_0]
loc_72: ; CODE XREF: remove_digits+18j
mov al, [bx]
test al, al
jz short loc_86
cmp al, 30h ; ’0’
jb short loc_83
cmp al, 39h ; ’9’
ja short loc_83
mov byte ptr [bx], 2Dh ; ’-’
loc_83: ; CODE XREF: remove_digits+Ej
; remove_digits+12j
inc bx
jmp short loc_72
; ---------------------------------------------------------------------------
loc_86: ; CODE XREF: remove_digits+Aj
pop bp
retn 2
remove_digits endp
WinMain proc near ; CODE XREF: start+EDp
push bp
mov bp, sp
mov ax, offset aAsd ; "asd"
push ax
mov ax, offset aDef ; "def"
push ax
call string_compare
push ds
mov ax, offset aAsd ; "asd"
push ax
push ds
mov ax, offset aDef ; "def"
push ax
call string_compare_far
mov ax, offset aHello1234World ; "hello 1234 world"
push ax
call remove_digits
xor ax, ax
push ax
push ds
mov ax, offset aHello1234World ; "hello 1234 world"
push ax
push ds
mov ax, offset aCaption ; "caption"
push ax
mov ax, 3 ; MB_YESNOCANCEL
push ax
call MESSAGEBOX
xor ax, ax
pop bp
retn 0Ah
WinMain endp
```

我们可以看到所谓的“near”指针和“far”指针：另一个奇怪的16位8086现象。 可以在70章继续读到相关内容。 近指针就是那些指向当前数据段内的指针。因为，string_compare()函数仅仅用到2个16位指针，而且访问数据通过DS指向了它（mov al, es:[bx]）。远指针也同样在我的16位MessageBox()例子里面：见30.2节。 因此，在访问文本时，Windows内核并不关心使用那个数据段，所以它需要更完整的信息。 使用这种区别的原因可能是因为紧凑的程序可能使用仅仅一个64kb的数据段。所以他并不需要传递地址的高位数据，因为它们永远是不变的。大一点的程序可能会使用多个64kb数据段，所以它们每次操作都需要需要区分它们是在哪个数据段里面。 对代码段来说也是相同的故事，比较短小的程序可能在64k的数据段里面包含有所有的可执行代码，然后所有的函数都会由CALL NEAR来调用，代码使用RETN返回。但是，如果有多个代码段的话，函数地址就会按对区分，然后使用CALL FAR来调用，代码会使用RETF返回。 这就是在编译器中指定“内存模型”会发生的事情。 MS-DOS和Win16编译器针对每个内存模型都有有特别的库：它们会因为数据和代码的不同的指针模型而不同。

## 53.6 例子#6

```
#include <windows.h>
#include <time.h>
#include <stdio.h>
char strbuf[256];

int PASCAL WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    struct tm *t;
    time_t unix_time;
    unix_time=time(NULL);
    t=localtime (&unix_time);
    sprintf (strbuf, "%04d-%02d-%02d %02d:%02d:%02d", t->tm_year+1900, t->tm_mon, t->tm_mday,
    t->tm_hour, t->tm_min, t->tm_sec);
    MessageBox (NULL, strbuf, "caption", MB_OK);
    return 0;
};
```

```
WinMain proc near
var_4 = word ptr -4
var_2 = word ptr -2
push bp
mov bp, sp
push ax
push ax
xor ax, ax
call time_
mov [bp+var_4], ax ; low part of UNIX time
mov [bp+var_2], dx ; high part of UNIX time
lea ax, [bp+var_4] ; take a pointer of high part
call localtime_
mov bx, ax ; t
push word ptr [bx] ; second
push word ptr [bx+2] ; minute
push word ptr [bx+4] ; hour
push word ptr [bx+6] ; day
push word ptr [bx+8] ; month
mov ax, [bx+0Ah] ; year
add ax, 1900
push ax
mov ax, offset a04d02d02d02d02 ; "%04d-%02d-%02d %02d:%02d:%02d"
push ax
mov ax, offset strbuf
push ax
call sprintf_
add sp, 10h
xor ax, ax ; NULL
push ax
push ds
mov ax, offset strbuf
push ax
push ds
mov ax, offset aCaption ; "caption"
push ax
xor ax, ax ; MB_OK
push ax
call MESSAGEBOX
xor ax, ax
mov sp, bp
pop bp
retn 0Ah
WinMain endp
```

UNIX时间是32位的，所以它返回在DX:AX寄存器对中，而且将他们存储到两个本地16位变量中。然后一个指向值对的指针会被当作参数传给localtime()函数。Localtime()函数有一个struct tm，它将通过C库分配内存，所以只有指向它的指针返回了。顺便一提，这也意味着在它的结果被使用之前，函数不能被再次调用。 对time()和localtime()两个函数来说，Watcom调用转换将会在这里：前四个参数使用AX、DX、BX、CX传递，剩余的通过栈来传递。使用这个转换的函数也会在名字最后使用下划线来标记。 Sprintf()并不使用PASCAL调用转换，也不会使用watcom转换，所以参数将使用寻常的cdecl方式传递（47.1节）。

### 53.6.1 全局变量

这里用同样的例子，但是变量是全局变量：

```
#include <windows.h>
#include <time.h>
#include <stdio.h>
char strbuf[256];
struct tm *t;
time_t unix_time;

int PASCAL WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    unix_time=time(NULL);
    t=localtime (&unix_time);
    sprintf (strbuf, "%04d-%02d-%02d %02d:%02d:%02d", t->tm_year+1900, t->tm_mon, t->tm_mday,
    t->tm_hour, t->tm_min, t->tm_sec);
    MessageBox (NULL, strbuf, "caption", MB_OK);
    return 0;
};

```

```
unix_time_low dw 0
unix_time_high dw 0
t dw 0
WinMain proc near
push bp
mov bp, sp
xor ax, ax
call time_
mov unix_time_low, ax
mov unix_time_high, dx
mov ax, offset unix_time_low
call localtime_
mov bx, ax
mov t, ax ; will not be used in future...
push word ptr [bx] ; seconds
push word ptr [bx+2] ; minutes
push word ptr [bx+4] ; hour
push word ptr [bx+6] ; day
push word ptr [bx+8] ; month
mov ax, [bx+0Ah] ; year
add ax, 1900
push ax
mov ax, offset a04d02d02d02d02 ; "%04d-%02d-%02d %02d:%02d:%02d"
push ax
mov ax, offset strbuf
push ax
call sprintf_
add sp, 10h
xor ax, ax ; NULL
push ax
push ds
mov ax, offset strbuf
push ax
push ds
mov ax, offset aCaption ; "caption"
push ax
xor ax, ax ; MB_OK
push ax
call MESSAGEBOX
xor ax, ax ; return 0
pop bp
retn 0Ah
WinMain endp
```

T不会被使用，但是编译器还是用代码存储了这个值。因为他并不确定，也许这个值会在某个地方被用到。