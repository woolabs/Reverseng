# 数组

数组是在内存中连续排列的一组变量，这些变量具有相同类型1。

## 16.1 小例子

```
#include <stdio.h>
int main()
{
    int a[20];
    int i;
    for (i=0; i<20; i++)
        a[i]=i*2;
    for (i=0; i<20; i++)
        printf ("a[%d]=%d", i, a[i]);
    return 0;
};
```

### 16.1.1 x86

编译后：

Listing 16.1: MSVC

```
_TEXT   SEGMENT
_i$ = -84                                   ; size = 4
_a$ = -80                                   ; size = 80
_main       PROC
    push    ebp
    mov     ebp, esp
    sub     esp, 84         ; 00000054H
    mov     DWORD PTR _i$[ebp], 0
    jmp     SHORT $LN6@main
$LN5@main:
    mov     eax, DWORD PTR _i$[ebp]
    add     eax, 1
    mov     DWORD PTR _i$[ebp], eax
$LN6@main:
    cmp     DWORD PTR _i$[ebp], 20 ; 00000014H
    jge     SHORT $LN4@main
    mov     ecx, DWORD PTR _i$[ebp]
    shl     ecx, 1
    mov     edx, DWORD PTR _i$[ebp]
    mov     DWORD PTR _a$[ebp+edx*4], ecx
    jmp     SHORT $LN5@main
$LN4@main:
    mov     DWORD PTR _i$[ebp], 0
    jmp     SHORT $LN3@main
$LN2@main:
    mov     eax, DWORD PTR _i$[ebp]
    add     eax, 1
    mov     DWORD PTR _i$[ebp], eax
$LN3@main:
    cmp     DWORD PTR _i$[ebp], 20 ; 00000014H
    jge     SHORT $LN1@main
    mov     ecx, DWORD PTR _i$[ebp]
    mov     edx, DWORD PTR _a$[ebp+ecx*4]
    push    edx
    mov     eax, DWORD PTR _i$[ebp]
    push    eax
    push    OFFSET $SG2463
    call    _printf
    add     esp, 12 ; 0000000cH
    jmp     SHORT $LN2@main
$LN1@main:
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret 0
_main ENDP
```

这段代码主要有两个循环：第一个循环填充数组，第二个循环打印数组元素。shl ecx,1指令使ecx的值乘以2，更多关于左移请参考17.3.1。 在堆栈上为数组分配了80个字节的空间，包含20个元素，每个元素4字节大小。

GCC 4.4.1编译后为：

Listing 16.2: GCC 4.4.1

```
            public main
main        proc near                       ; DATA XREF: _start+17
 
var_70      = dword ptr -70h
var_6C      = dword ptr -6Ch
var_68      = dword ptr -68h
i_2         = dword ptr -54h
i           = dword ptr -4
 
            push    ebp
            mov     ebp, esp
            and     esp, 0FFFFFFF0h
            sub     esp, 70h
            mov     [esp+70h+i], 0 ; i=0
            jmp     short loc_804840A
loc_80483F7:
            mov     eax, [esp+70h+i]
            mov     edx, [esp+70h+i]
            add     edx, edx ; edx=i*2
            mov     [esp+eax*4+70h+i_2], edx
            add     [esp+70h+i], 1 ; i++
loc_804840A:
            cmp     [esp+70h+i], 13h
            jle     short loc_80483F7
            mov     [esp+70h+i], 0
            jmp     short loc_8048441
loc_804841B:
            mov     eax, [esp+70h+i]
            mov     edx, [esp+eax*4+70h+i_2]
            mov     eax, offset aADD ; "a[%d]=%d
"
            mov     [esp+70h+var_68], edx
            mov     edx, [esp+70h+i]
            mov     [esp+70h+var_6C], edx
            mov     [esp+70h+var_70], eax
            call    _printf
            add     [esp+70h+i], 1
loc_8048441:
            cmp     [esp+70h+i], 13h
            jle     short loc_804841B
            mov     eax, 0
            leave
            retn
main        endp
```

顺便提一下，一个int*类型（指向int的指针）的变量—你可以使该变量指向数组并将该数组传递给另一个函数，更准确的说，传递的指针指向数组的第一个元素（该数组其它元素的地址需要显示计算）。比如a[idx]，idx加上指向该数组的指针并返回该元素。 一个有趣的例子：类似”string”字符数组的类型是const char*，索引可以应用与该指针。比如可能写作”string”[i]—正确的C/C++表达式。

### 16.1.2 ARM + Non-optimizing Keil + ARM mode

```
        EXPORT _main
_main
        STMFD   SP!, {R4,LR}
        SUB     SP, SP, #0x50           ; allocate place for 20 int variables
; first loop
        MOV     R4, #0                  ; i
        B       loc_4A0
loc_494
        MOV     R0, R4,LSL#1            ; R0=R4*2
        STR     R0, [SP,R4,LSL#2]       ; store R0 to SP+R4<<2 (same as SP+R4*4)
        ADD     R4, R4, #1              ; i=i+1
loc_4A0
        CMP     R4, #20                 ; i<20?
        BLT     loc_494                 ; yes, run loop body again
; second loop
        MOV     R4, #0                  ; i
        B       loc_4C4
loc_4B0
        LDR     R2, [SP,R4,LSL#2]       ; (second printf argument) R2=*(SP+R4<<4) (same as *(SP+R4*4))
        MOV     R1, R4                  ; (first printf argument) R1=i
        ADR     R0, aADD                ; "a[%d]=%d
"
        BL      __2printf
        ADD     R4, R4, #1              ; i=i+1
loc_4C4
        CMP     R4, #20                 ; i<20?
        BLT     loc_4B0                 ; yes, run loop body again
        MOV     R0, #0                  ; value to return
        ADD     SP, SP, #0x50           ; deallocate place, allocated for 20 int variables
        LDMFD   SP!, {R4,PC}
```

int类型长度为32bits即4字节，20个int变量需要80（0x50）字节，因此“sub sp,sp,#0x50”指令为在栈上分配存储空间。 两个循环迭代器i被存储在R4寄存器中。 值i*2被写入数组，通过将i值左移1位实现乘以2的效果，整个过程通过”MOV R0,R4,LSL#1指令来实现。 “STR R0, [SP,R4,LSL#2]”把R0内容写入数组。过程为：SP指向数组开始，R4是i，i左移2位相当于乘以4，即*(SP+R4*4)=R0。 第二个loop的“LDR R2, [SP,R4,LSL#2]”从数组读取数值到寄存器，R2=*(SP+R4*4)。

### 16.1.3 ARM + Keil + thumb 模式优化后

```
_main
        PUSH    {R4,R5,LR}
; allocate place for 20 int variables + one more variable
        SUB     SP, SP, #0x54
; first loop
        MOVS    R0, #0                  ; i
        MOV     R5, SP                  ; pointer to first array element
loc_1CE
        LSLS    R1, R0, #1              ; R1=i<<1 (same as i*2)
        LSLS    R2, R0, #2              ; R2=i<<2 (same as i*4)
        ADDS    R0, R0, #1              ; i=i+1
        CMP     R0, #20                 ; i<20?
        STR     R1, [R5,R2]             ; store R1 to *(R5+R2) (same R5+i*4)
        BLT     loc_1CE                 ; yes, i<20, run loop body again
; second loop
        MOVS    R4, #0                  ; i=0
loc_1DC
        LSLS    R0, R4, #2              ; R0=i<<2 (same as i*4)
        LDR     R2, [R5,R0]             ; load from *(R5+R0) (same as R5+i*4)
        MOVS    R1, R4
        ADR     R0, aADD                ; "a[%d]=%d
"
        BL      __2printf
        ADDS    R4, R4, #1              ; i=i+1
        CMP     R4, #20                 ; i<20?
        BLT     loc_1DC                 ; yes, i<20, run loop body again
        MOVS    R0, #0                  ; value to return
; deallocate place, allocated for 20 int variables + one more variable
        ADD     SP, SP, #0x54
        POP     {R4,R5,PC}
```

Thumb代码也是非常类似的。Thumb模式计算数组偏移的移位操作使用特定的指令LSLS。 编译器在堆栈中申请的数组空间更大，但是最后4个字节的空间未使用。

## 16.2 缓冲区溢出

Array[index]中index指代数组索引，仔细观察下面的代码，你可能注意到代码没有index是否小于20。如果index大于20？这是C/C++经常被批评的特征。 以下代码可以成功编译可以工作：

```
#include <stdio.h>
int main()
{
    int a[20];
    int i;
    for (i=0; i<20; i++)
        a[i]=i*2;
    printf ("a[100]=%d", a[100]);
    return 0;
};
```

编译后 (MSVC 2010)：

```
_TEXT   SEGMENT
_i$ = -84                               ; size = 4
_a$ = -80                               ; size = 80
_main       PROC
    push    ebp
    mov     ebp, esp
    sub     esp, 84                 ; 00000054H
    mov     DWORD PTR _i$[ebp], 0
    jmp     SHORT $LN3@main
$LN2@main:
    mov     eax, DWORD PTR _i$[ebp]
    add     eax, 1
    mov     DWORD PTR _i$[ebp], eax
$LN3@main:
    cmp     DWORD PTR _i$[ebp], 20  ; 00000014H
    jge     SHORT $LN1@main
    mov     ecx, DWORD PTR _i$[ebp]
    shl     ecx, 1
    mov     edx, DWORD PTR _i$[ebp]
    mov     DWORD PTR _a$[ebp+edx*4], ecx
    jmp     SHORT $LN2@main
$LN1@main:
    mov     eax, DWORD PTR _a$[ebp+400]
    push    eax
    push    OFFSET $SG2460
    call    _printf
    add     esp, 8
    xor     eax, eax
    mov     esp, ebp
    pop     ebp
    ret     0
_main       ENDP
```

运行，我们得到： a[100]=760826203

打印的数字仅仅是距离数组第一个元素400个字节处的堆栈上的数值。 编译器可能会自动添加一些判断数组边界的检测代码（更高级语言3），但是这可能影响运行速度。 我们可以从栈上非法读取数值，是否可以写入数值呢？ 下面我们将写入数值：

```
#include <stdio.h>
int main()
{
    int a[20];
    int i;
 
    for (i=0; i<30; i++)
        a[i]=i;
 
    return 0;
};
```

我们得到：

```
_TEXT   SEGMENT
_i$ = -84                                   ; size = 4
_a$ = -80                                   ; size = 80
_main       PROC
    push    ebp
    mov     ebp, esp
    sub     esp, 84 ; 00000054H
    mov     DWORD PTR _i$[ebp], 0
    jmp     SHORT $LN3@main
$LN2@main:
    mov     eax, DWORD PTR _i$[ebp]
    add     eax, 1
    mov     DWORD PTR _i$[ebp], eax
$LN3@main:
    cmp     DWORD PTR _i$[ebp], 30 ; 0000001eH
    jge     SHORT $LN1@main
    mov     ecx, DWORD PTR _i$[ebp]
    mov     edx, DWORD PTR _i$[ebp] ; that instruction is obviously redundant
    mov     DWORD PTR _a$[ebp+ecx*4], edx ; ECX could be used as second operand here instead
    jmp     SHORT $LN2@main
$LN1@main:
    xor     eax, eax
    mov     esp, ebp
    pop     ebp
    ret     0
_main       ENDP
```

编译后运行，程序崩溃。我们找出导致崩溃的地方。 没有使用调试器，而是使用我自己写的小工具tracer足以完成任务。 我们用它看被调试进程崩溃的地方：

```
generic tracer 0.4 (WIN32), http://conus.info/gt

New process: C:PRJ...1.exe, PID=7988
EXCEPTION_ACCESS_VIOLATION: 0x15 (<symbol (0x15) is in unknown module>), ExceptionInformation
[0]=8
EAX=0x00000000 EBX=0x7EFDE000 ECX=0x0000001D EDX=0x0000001D
ESI=0x00000000 EDI=0x00000000 EBP=0x00000014 ESP=0x0018FF48
EIP=0x00000015
FLAGS=PF ZF IF RF
PID=7988|Process exit, return code -1073740791
```

我们来看各个寄存器的状态，异常发生在地址0x15。这是个非法地址—至少对win32代码来说是！这种情况并不是我们期望的，我们还可以看到EBP值为0x14,ECX和EDX都为0x1D。 让我们来研究堆栈布局。 代码进入main（）后，EBP寄存器的值被保存在栈上。为数组和变量i一共分配84字节的栈空间，即(20+1)*sizeof(int)。此时ESP指向_i变量，之后执行push something，something将紧挨着_i。 此时main()函数内栈布局为：

```
ESP
ESP+4
ESP+84
ESP+88
4 bytes for i
80 bytes for a[20] array
saved EBP value
returning address
```

指令a[19]=something写入最后的int到数组边界（这里是数组边界！）。 指令a[20]=something，something将覆盖栈上保存的EBP值。 请注意崩溃时寄存器的状态。在此例中，数字20被写入第20个元素，即原来存放EBP值得地方被写入了20（20的16进制表示是0x14）。然后RET指令被执行，相当于执行POP EIP指令。 RET指令从堆栈中取出返回地址（该地址为CRT内部调用main()的地址），返回地址处被存储了21（0x15）。CPU执行地址0x15的代码，异常被抛出。 Welcome！这被称为缓冲区溢出4。 使用字符数组代替int数组，创建一个较长的字符串，把字符串传递给程序，函数没有检测字符串长度，把字符复制到较短的缓冲区，你能够找到找到程序必须跳转的地址。事实上，找出它们并不是很简单。 我们来看GCC 4.4.1编译后的同类代码：

```
            public main
main        proc near
 
a           = dword ptr -54h
i           = dword ptr -4
 
            push    ebp
            mov     ebp, esp
            sub     esp, 60h
            mov     [ebp+i], 0
            jmp     short loc_80483D1
loc_80483C3:
            mov     eax, [ebp+i]
            mov     edx, [ebp+i]
            mov     [ebp+eax*4+a], edx
            add     [ebp+i], 1
loc_80483D1:
            cmp     [ebp+i], 1Dh
            jle     short loc_80483C3
            mov     eax, 0
            leave
            retn
main        endp
```

在linux下运行将产生：段错误。使用GDB调试：

```
(gdb) r
Starting program: /home/dennis/RE/1
 
Program received signal SIGSEGV, Segmentation fault.
0x00000016 in ?? ()
(gdb) info registers
eax         0x0                 0
ecx         0xd2f96388      -755407992
edx         0x1d            29
ebx         0x26eff4        2551796
esp         0xbffff4b0      0xbffff4b0
ebp         0x15            0x15
esi         0x0                 0
edi         0x0                 0
eip         0x16            0x16
eflags      0x10202         [ IF RF ]
cs          0x73            115
ss          0x7b            123
ds          0x7b            123
es          0x7b            123
fs          0x0                 0
gs          0x33            51
(gdb)
```

寄存器的值与win32例子略微不同，因为堆栈布局也不太一样。

## 16.3 防止缓冲区溢出的方法

下面一些方法防止缓冲区溢出。MSVC使用以下编译选项：

```
/RTCs Stack Frame runtime checking
/GZ Enable stack checks (/RTCs)
```

一种方法是在函数局部变量和序言之间写入随机值。在函数退出之前检查该值。如果该值不一致则挂起而不执行RET。进程将被挂起。 该随机值有时被称为“探测值”。 如果使用MSVC编译简单的例子（16.1），使用RTC1和RTCs选项，将能看到函数调用@_RTC_CheckStackVars@8函数来检测“探测值“。

我们来看GCC如何处理这些。我们使用alloca()(4.2.4)例子：

```
#include <malloc.h>
#include <stdio.h>
void f()
{
    char *buf=(char*)alloca (600);
    _snprintf (buf, 600, "hi! %d, %d, %d", 1, 2, 3);
 
    puts (buf);
};
```

我们不使用任何附加编译选项，只使用默认选项，GCC 4.7.3将插入“探测“检测代码： 

Listing 16.3: GCC 4.7.3

```
.LC0:
    .string "hi! %d, %d, %d
"
f:
    push    ebp
    mov     ebp, esp
    push    ebx
    sub     esp, 676
    lea     ebx, [esp+39]
    and     ebx, -16
    mov     DWORD PTR [esp+20], 3
    mov     DWORD PTR [esp+16], 2
    mov     DWORD PTR [esp+12], 1
    mov     DWORD PTR [esp+8], OFFSET FLAT:.LC0     ; "hi! %d, %d, %d
"
    mov     DWORD PTR [esp+4], 600
    mov     DWORD PTR [esp], ebx
    mov     eax, DWORD PTR gs:20                    ; canary
    mov     DWORD PTR [ebp-12], eax
    xor     eax, eax
    call    _snprintf
    mov     DWORD PTR [esp], ebx
    call    puts
    mov     eax, DWORD PTR [ebp-12]
    xor     eax, DWORD PTR gs:20                    ; canary
    jne     .L5
    mov     ebx, DWORD PTR [ebp-4]
    leave
    ret
.L5:
call __stack_chk_fail
```

随机值存在于gs:20。它被写入到堆栈，在函数的结尾与gs:20的探测值对比，如果不一致，__stack_chk_fail函数将被调用，控制台(Ubuntu 13.04 x86)将输出以下信息：

```
*** buffer overflow detected ***: ./2_1 terminated
======= Backtrace: =========
/lib/i386-linux-gnu/libc.so.6(__fortify_fail+0x63)[0xb7699bc3]
/lib/i386-linux-gnu/libc.so.6(+0x10593a)[0xb769893a]
/lib/i386-linux-gnu/libc.so.6(+0x105008)[0xb7698008]
/lib/i386-linux-gnu/libc.so.6(_IO_default_xsputn+0x8c)[0xb7606e5c]
/lib/i386-linux-gnu/libc.so.6(_IO_vfprintf+0x165)[0xb75d7a45]
/lib/i386-linux-gnu/libc.so.6(__vsprintf_chk+0xc9)[0xb76980d9]
/lib/i386-linux-gnu/libc.so.6(__sprintf_chk+0x2f)[0xb7697fef]
./2_1[0x8048404]
/lib/i386-linux-gnu/libc.so.6(__libc_start_main+0xf5)[0xb75ac935]
======= Memory map: ========
08048000-08049000 r-xp 00000000 08:01 2097586 /home/dennis/2_1
08049000-0804a000 r--p 00000000 08:01 2097586 /home/dennis/2_1
0804a000-0804b000 rw-p 00001000 08:01 2097586 /home/dennis/2_1
094d1000-094f2000 rw-p 00000000 00:00 0 [heap]
b7560000-b757b000 r-xp 00000000 08:01 1048602 /lib/i386-linux-gnu/libgcc_s.so.1
b757b000-b757c000 r--p 0001a000 08:01 1048602 /lib/i386-linux-gnu/libgcc_s.so.1
b757c000-b757d000 rw-p 0001b000 08:01 1048602 /lib/i386-linux-gnu/libgcc_s.so.1
b7592000-b7593000 rw-p 00000000 00:00 0
b7593000-b7740000 r-xp 00000000 08:01 1050781 /lib/i386-linux-gnu/libc-2.17.so
b7740000-b7742000 r--p 001ad000 08:01 1050781 /lib/i386-linux-gnu/libc-2.17.so
b7742000-b7743000 rw-p 001af000 08:01 1050781 /lib/i386-linux-gnu/libc-2.17.so
b7743000-b7746000 rw-p 00000000 00:00 0
b775a000-b775d000 rw-p 00000000 00:00 0
b775d000-b775e000 r-xp 00000000 00:00 0 [vdso]
b775e000-b777e000 r-xp 00000000 08:01 1050794 /lib/i386-linux-gnu/ld-2.17.so
b777e000-b777f000 r--p 0001f000 08:01 1050794 /lib/i386-linux-gnu/ld-2.17.so
b777f000-b7780000 rw-p 00020000 08:01 1050794 /lib/i386-linux-gnu/ld-2.17.so
bff35000-bff56000 rw-p 00000000 00:00 0 [stack]
Aborted (core dumped)
```

gs被叫做段寄存器，这些寄存器被广泛用在MS-DOS和扩展DOS时代。现在的作用和以前不同。简要的说，gs寄存器在linux下一直指向TLS（48）--存储线程的各种信息（win32环境下，fs寄存器同样的作用，指向TIB8 9）。 更多信息请参考linux源码arch/x86/include/asm/stackprotector.h（至少3.11版本）。

### 16.3.1 Optimizing Xcode (LLVM) + thumb-2 mode

我们回头看简单的数组例子(16.1)。我们来看LLVM如何检查“探测值“。

```
_main
var_64      = -0x64
var_60      = -0x60
var_5C      = -0x5C
var_58      = -0x58
var_54      = -0x54
var_50      = -0x50
var_4C      = -0x4C
var_48      = -0x48
var_44      = -0x44
var_40      = -0x40
var_3C      = -0x3C
var_38      = -0x38
var_34      = -0x34
var_30      = -0x30
var_2C      = -0x2C
var_28      = -0x28
var_24      = -0x24
var_20      = -0x20
var_1C      = -0x1C
var_18      = -0x18
canary      = -0x14
var_10      = -0x10
 
            PUSH    {R4-R7,LR}
            ADD     R7, SP, #0xC
            STR.W   R8, [SP,#0xC+var_10]!
            SUB     SP, SP, #0x54
            MOVW    R0, #aObjc_methtype ; "objc_methtype"
            MOVS    R2, #0
            MOVT.W  R0, #0
            MOVS    R5, #0
            ADD     R0, PC
            LDR.W   R8, [R0]
            LDR.W   R0, [R8]
            STR     R0, [SP,#0x64+canary]
            MOVS    R0, #2
            STR     R2, [SP,#0x64+var_64]
            STR     R0, [SP,#0x64+var_60]
            MOVS    R0, #4
            STR     R0, [SP,#0x64+var_5C]
            MOVS    R0, #6
            STR     R0, [SP,#0x64+var_58]
            MOVS    R0, #8
            STR     R0, [SP,#0x64+var_54]
            MOVS    R0, #0xA
            STR     R0, [SP,#0x64+var_50]
            MOVS    R0, #0xC
            STR     R0, [SP,#0x64+var_4C]
            MOVS    R0, #0xE
            STR     R0, [SP,#0x64+var_48]
            MOVS    R0, #0x10
            STR     R0, [SP,#0x64+var_44]
            MOVS    R0, #0x12
            STR     R0, [SP,#0x64+var_40]
            MOVS    R0, #0x14
            STR     R0, [SP,#0x64+var_3C]
            MOVS    R0, #0x16
            STR     R0, [SP,#0x64+var_38]
            MOVS    R0, #0x18
            STR     R0, [SP,#0x64+var_34]
            MOVS    R0, #0x1A
            STR     R0, [SP,#0x64+var_30]
            MOVS    R0, #0x1C
            STR     R0, [SP,#0x64+var_2C]
            MOVS    R0, #0x1E
            STR     R0, [SP,#0x64+var_28]
            MOVS    R0, #0x20
            STR     R0, [SP,#0x64+var_24]
            MOVS    R0, #0x22
            STR     R0, [SP,#0x64+var_20]
            MOVS    R0, #0x24
            STR     R0, [SP,#0x64+var_1C]
            MOVS    R0, #0x26
            STR     R0, [SP,#0x64+var_18]
            MOV     R4, 0xFDA ; "a[%d]=%d
"
            MOV     R0, SP
            ADDS    R6, R0, #4
            ADD     R4, PC
            B loc_2F1C
; second loop begin
 
loc_2F14
            ADDS    R0, R5, #1
            LDR.W   R2, [R6,R5,LSL#2]
            MOV     R5, R0
loc_2F1C
            MOV     R0, R4
            MOV     R1, R5
            BLX     _printf
            CMP     R5, #0x13
            BNE     loc_2F14
            LDR.W   R0, [R8]
            LDR     R1, [SP,#0x64+canary]
            CMP     R0, R1
            ITTTT   EQ              ; canary still correct?
            MOVEQ   R0, #0
            ADDEQ   SP, SP, #0x54
            LDREQ.W R8, [SP+0x64+var_64],#4
            POPEQ   {R4-R7,PC}
            BLX     ___stack_chk_fail
```

首先可以看到，LLVM循环展开写入数组，LLVM认为先计算出数组元素的值速度更快。 在函数的结尾我们能看到“探测值“的检测—局部存储的值与R8指向的标准值对比。如果相等4指令块将通过”ITTTT EQ“触发，R0写入0，函数退出。如果不相等，指令块将不会被触发，跳向___stack_chk_fail函数，结束进程。

### 16.4 One more word about arrays

现在我们来理解下面的C/C++代码为什么不能正常使用10：

```
void f(int size)
{
    int a[size];
    ...
};
```

这是因为在编译阶段编译器不知道数组的具体大小无论是在堆栈或者数据段，无法分配具体空间。 如果你需要任意大小的数组，应该通过malloc()分配空间，然后访问内存块来访问你需要的类型数组。或者使用C99标准[15,6.7.5/2]，但它内部看起来更像alloca()(4.2.4)。

## 16.5 Multidimensional arrays

多维数组和线性数组在本质上是一样的。 因为计算机内存是线性的，它是一维数组。但是一维数组可以很容易用来表现多维的。 比如数组a[3][4]元素可以放置在一维数组的12个单元中：

```
[0][0]
[0][1]
[0][2]
[0][3]
[1][0]
[1][4]
[1][5]
[1][6]
[2][0]
[2][7]
[2][8]
[2][9]
```

该二维数组在内存中用一维数组索引表示为：

|   | 1 | 2 | 3 |
|---|---|---|---|
|4  |5  |6  |7  |
|8  |9  |10 |11 |

为了计算我们需要的元素地址，首先，第一个索引乘以4（矩阵宽度），然后加上第二个索引。这种被称为行优先，C/C++和Python常用这种方法。行优先的意思是：先写入第一行，接着是第二行，…，最后是最后一行。 另一种方法就是列优先，主要用在FORTRAN,MATLAB,R等。列优先的意思是：先写入第一列，然后是第二列，…，最后是最后一列。 多维数组与此类似。 我们看个例子：

Listing 16.4: simple example

```
#include <stdio.h>
 
int a[10][20][30];
 
void insert(int x, int y, int z, int value)
{
    a[x][y][z]=value;
};
```

### 16.5.1 x86

MSVC 2010：

Listing 16.5: MSVC 2010

```
_DATA   SEGMENT
COMM    _a:DWORD:01770H
_DATA   ENDS
PUBLIC  _insert
_TEXT   SEGMENT
_x$ = 8         ; size = 4
_y$ = 12        ; size = 4
_z$ = 16        ; size = 4
_value$ = 20    ; size = 4
_insert     PROC
    push    ebp
    mov     ebp, esp
    mov     eax, DWORD PTR _x$[ebp]
    imul    eax, 2400                   ; eax=600*4*x
    mov     ecx, DWORD PTR _y$[ebp]
    imul    ecx, 120                    ; ecx=30*4*y
    lea     edx, DWORD PTR _a[eax+ecx]  ; edx=a + 600*4*x + 30*4*y
    mov     eax, DWORD PTR _z$[ebp]
    mov     ecx, DWORD PTR _value$[ebp]
    mov     DWORD PTR [edx+eax*4], ecx  ; *(edx+z*4)=value
    pop     ebp
    ret     0
_insert ENDP
_TEXT ENDS
```

多维数组计算索引公式：address=600*4*x+30*4*y+4z。因为int类型为32-bits（4字节），所以要乘以4。

Listing 16.6: GCC 4.4.1

```
        public insert
insert  proc near
x       = dword ptr 8
y       = dword ptr 0Ch
z       = dword ptr 10h
value   = dword ptr 14h
        push    ebp
        mov     ebp, esp
        push    ebx
        mov     ebx, [ebp+x]
        mov     eax, [ebp+y]
        mov     ecx, [ebp+z]
        lea     edx, [eax+eax] ; edx=y*2
        mov     eax, edx ; eax=y*2
        shl     eax, 4 ; eax=(y*2)<<4 = y*2*16 = y*32
        sub     eax, edx ; eax=y*32 - y*2=y*30
        imul    edx, ebx, 600 ; edx=x*600
        add     eax, edx ; eax=eax+edx=y*30 + x*600
        lea     edx, [eax+ecx] ; edx=y*30 + x*600 + z
        mov     eax, [ebp+value]
        mov     dword ptr ds:a[edx*4], eax ; *(a+edx*4)=value
        pop     ebx
        pop     ebp
        retn
insert  endp
```

GCC使用的不同的计算方法。为计算第一个操作值30y，GCC没有使用乘法指令。GCC的做法是：(???? + ????) ≪ 4 − (???? + ????) = (2????) ≪ 4 − 2???? = 2 ・ 16 ・ ???? − 2???? = 32???? − 2???? = 30????。因此30y的计算仅使用加法和移位操作，这样速度更快。

### 16.5.2 ARM + Non-optimizing Xcode (LLVM) + thumb mode

Listing 16.7: Non-optimizing Xcode (LLVM) + thumb mode

```
_insert
 
value       = -0x10
z           = -0xC
y           = -8
x           = -4
 
; allocate place in local stack for 4 values of int type
SUB         SP, SP, #0x10
MOV         R9, 0xFC2 ; a
ADD         R9, PC
LDR.W       R9, [R9]
STR         R0, [SP,#0x10+x]
STR         R1, [SP,#0x10+y]
STR         R2, [SP,#0x10+z]
STR         R3, [SP,#0x10+value]
LDR         R0, [SP,#0x10+value]
LDR         R1, [SP,#0x10+z]
LDR         R2, [SP,#0x10+y]
LDR         R3, [SP,#0x10+x]
MOV         R12, 2400
MUL.W       R3, R3, R12
ADD         R3, R9
MOV         R9, 120
MUL.W       R2, R2, R9
ADD         R2, R3
LSLS        R1, R1, #2 ; R1=R1<<2
ADD         R1, R2
STR         R0, [R1] ; R1 - address of array element
; deallocate place in local stack, allocated for 4 values of int type
ADD         SP, SP, #0x10
BX          LR
```

非优化的LLVM代码在栈中保存了所有变量，这是冗余的。元素地址的计算我们通过公式已经找到了。

### 16.5.3 ARM + Optimizing Xcode (LLVM) + thumb mode

Listing 16.8: Optimizing Xcode (LLVM) + thumb mode

```
_insert
MOVW        R9, #0x10FC
MOV.W       R12, #2400
MOVT.W      R9, #0
RSB.W       R1, R1, R1,LSL#4    ; R1 - y. R1=y<<4 - y = y*16 - y = y*15
ADD         R9, PC ; R9 = pointer to a array
LDR.W       R9, [R9]
MLA.W       R0, R0, R12, R9     ; R0 - x, R12 - 2400, R9 - pointer to a. R0=x*2400 + ptr to a
ADD.W       R0, R0, R1,LSL#3    ; R0 = R0+R1<<3 = R0+R1*8 = x*2400 + ptr to a + y*15*8 =
                                ; ptr to a + y*30*4 + x*600*4
STR.W       R3, [R0,R2,LSL#2]   ; R2 - z, R3 - value. address=R0+z*4 =
                                ; ptr to a + y*30*4 + x*600*4 + z*4
BX          LR
```

这里的小技巧没有使用乘法，使用移位、加减法等。 这里有个新指令RSB（逆向减法），该指令的意义是让第一个操作数像SUB第二个操作数一样可以应用LSL#4附加操作。 “LDR.W R9, [R9]”类似于x86下的LEA指令（B.6.2），这里什么都没有做，是冗余的。显然，编译器没有优化它。