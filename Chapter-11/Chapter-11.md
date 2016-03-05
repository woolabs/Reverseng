# 选择结构switch()/case/default

## 11.1 一些例子

```
void f (int a)
{
    switch (a)
    {
        case 0: printf ("zero"); break;
        case 1: printf ("one"); break;
        case 2: printf ("two"); break;
        default: printf ("something unknown"); break;
    };
};
```

### 11.1.1 X86

反汇编结果如下（MSVC 2010）：

清单11.1: MSVC 2010

```
tv64 = -4       ; size = 4
_a$ = 8         ; size = 4
_f  PROC
    push    ebp
    mov     ebp, esp
    push    ecx
    mov     eax, DWORD PTR _a$[ebp]
    mov     DWORD PTR tv64[ebp], eax
    cmp     DWORD PTR tv64[ebp], 0
    je      SHORT $LN4@f
    cmp     DWORD PTR tv64[ebp], 1
    je      SHORT $LN3@f
    cmp     DWORD PTR tv64[ebp], 2
    je      SHORT $LN2@f
    jmp     SHORT $LN1@f
$LN4@f:
    push    OFFSET $SG739 ; ’zero’, 0aH, 00H
    call    _printf
    add     esp, 4
    jmp     SHORT $LN7@f
$LN3@f:
    push    OFFSET $SG741 ; ’one’, 0aH, 00H
    call    _printf
    add     esp, 4
    jmp     SHORT $LN7@f
$LN2@f:
    push    OFFSET $SG743 ; ’two’, 0aH, 00H
    call    _printf
    add     esp, 4
    jmp     SHORT $LN7@f
$LN1@f:
    push    OFFSET $SG745 ; ’something unknown’, 0aH, 00H
    call    _printf
    add     esp, 4
$LN7@f:
    mov     esp, ebp
    pop     ebp
    ret     0
_f    ENDP
```

输出函数的switch中有一些case选择分支，事实上，它是和下面这个形式等价的：

```
void f (int a)
{
    if (a==0)
        printf ("zero");
    else if (a==1)
        printf ("one");
    else if (a==2)
        printf ("two");
    else
        printf ("something unknown");
};
```

当switch()中有一些case分支时，我们可以看到此类代码，虽然不能确定，但是，事实上switch()在机器码级别上就是对if()的封装。这也就是说，switch()其实只是对有一大堆类似条件判断的if()的一个语法糖。

在生成代码时，除了编译器把输入变量移动到一个临时本地变量tv64中之外，这块代码对我们来说并无新意。

如果是在GCC 4.4.1下编译同样的代码，我们得到的结果也几乎一样，即使你打开了最高优化（-O3）也是如此。

让我们在微软VC编译器中打开/Ox优化选项： `cl 1.c /Fa1.asm /Ox`

清单11.2: MSVC

```
_a$ = 8                 ; size = 4
_f  PROC
    mov     eax, DWORD PTR _a$[esp-4]
    sub     eax, 0
    je      SHORT $LN4@f
    sub     eax, 1
    je      SHORT $LN3@f
    sub     eax, 1
    je      SHORT $LN2@f
    mov     DWORD PTR _a$[esp-4], OFFSET $SG791 ; ’something unknown’, 0aH, 00H
    jmp     _printf
$LN2@f:
    mov     DWORD PTR _a$[esp-4], OFFSET $SG789 ; ’two’, 0aH, 00H
    jmp     _printf
$LN3@f:
    mov     DWORD PTR _a$[esp-4], OFFSET $SG787 ; ’one’, 0aH, 00H
    jmp     _printf
$LN4@f:
    mov     DWORD PTR _a$[esp-4], OFFSET $SG785 ; ’zero’, 0aH, 00H
    jmp     _printf
_f ENDP
```

我们可以看到浏览器做了更多的难以阅读的优化（Dirty hacks）。

首先，变量的值会被放入EAX，接着EAX减0。听起来这很奇怪，但它之后是需要检查先前EAX寄存器的值是否为0的，如果是，那么程序会设置上零标志位ZF（这也表示了减去0之后，结果依然是0），第一个条件跳转语句JE（Jump if Equal 或者同义词 JZ - Jump if Zero）会因此触发跳转。如果这个条件不满足，JE没有跳转的话，输入值将减去1，之后就和之前的一样了，如果哪一次值是0，那么JE就会触发，从而跳转到对应的处理语句上。

（译注：SUB操作会重置零标志位ZF，但是MOV不会设置标志位，而JE将只有在ZF标志位设置之后才会跳转。如果需要基于EAX的值来做JE跳转的话，是需要用这个方法设置标志位的）。

并且，如果没有JE语句被触发，最终，printf()函数将收到“something unknown”的参数。

其次：我们看到了一些不寻常的东西——字符串指针被放在了变量里，然后printf()并没有通过CALL，而是通过JMP来调用的。 这个可以很简单的解释清楚，调用者把参数压栈，然后通过CALL调用函数。CALL通过把返回地址压栈，然后做无条件跳转来跳到我们的函数地址。我们的函数在执行时，不管在任何时候都有以下的栈结构（因为它没有任何移动栈指针的语句）：

```
· ESP —— 指向返回地址
· ESP+4 —— 指向变量a （也即参数）
```

另一方面，当我们这儿调用printf()函数的时候，它也需要有与我们这个函数相同的栈结构，不同之处只在于printf()的第一个参数是指向一个字符串的。 这也就是你之前看到的我们的代码所做的事情。

我们的代码把第一个参数的地址替换了，然后跳转到printf()，就像第一个没有调用我们的函数f()而是先调用了printf()一样。 printf()把一串字符输出到stdout 中，然后执行RET语句， 这一句会从栈上弹出返回地址，因此，此时控制流会返回到调用f()的函数上，而不是f()上。

这一切之所以能发生，是因为printf()在f()的末尾。在一些情况下，这有些类似于longjmp()函数。当然，这一切只是为了提高执行速度。

ARM编译器也有类似的优化，请见5.3.2节“带有多个参数的printf()函数调用”。

### 11.1.2 ARM： 优化后的 Keil + ARM 模式

```
.text:0000014C             f1
.text:0000014C 00 00 50 E3          CMP R0, #0
.text:00000150 13 0E 8F 02          ADREQ R0, aZero     ; "zero
"
.text:00000154 05 00 00 0A          BEQ loc_170
.text:00000158 01 00 50 E3          CMP R0, #1
.text:0000015C 4B 0F 8F 02          ADREQ R0, aOne      ; "one
"
.text:00000160 02 00 00 0A          BEQ loc_170
.text:00000164 02 00 50 E3          CMP R0, #2
.text:00000168 4A 0F 8F 12          ADRNE R0, aSomethingUnkno ; "something unknown
"
.text:0000016C 4E 0F 8F 02          ADREQ R0, aTwo      ; "two
"
.text:00000170
.text:00000170                      loc_170             ; CODE XREF: f1+8
.text:00000170                                          ; f1+14
.text:00000170 78 18 00 EA          B __2printf
```

我们再一次看看这个代码，我们不能确定的说这就是源代码里面的switch()或者说它是if()的封装。

但是，我们可以看到这里它也在试图预测指令（像是ADREQ（相等）），这里它会在R0=0的情况下触发，并且字符串“zero”的地址将被加载到R0中。如果R0=0，下一个指令BEQ将把控制流定向到loc_170处。顺带一说，机智的读者们可能会文，之前的ADREQ已经用其他值填充了R0寄存器了，那么BEQ会被正确触发吗？答案是“是”。因为BEQ检查的是CMP所设置的标记位，但是ADREQ根本没有修改标记位。

还有，在ARM中，一些指令还会加上-S后缀，这表明指令将会根据结果设置标记位。如果没有-S的话，表明标记位并不会被修改。比如，ADD（而不是ADDS）将会把两个操作数相加，但是并不会涉及标记位。这类指令对使用CMP设置标记位之后使用标记位的指令，例如条件跳转来说非常有用。

其他指令对我们来说已经很熟悉了。这里只有一个调用指向printf（），在末尾，我们已经知道了这个小技巧（见5.3.2节）。在末尾处有三个指向printf（）的地址。 还有，需要注意的是如果a=2但是a并不在它的选择分支给定的常数中时，“CMP R0, #2”指令在这个情况下就需要知道a是否等于2。如果结果为假，ADRNE将会读取字符串“something unknown ”到R0中，因为a在之前已经和0、1做过是否相等的判断了，这里我们可以假定a并不等于0或者1。并且，如果R0=2，a指向的字符串“two ”将会被ADREQ载入R0。

### 11.1.3 ARM： 优化后的 Keil + thumb 模式

```
.text:000000D4          f1
.text:000000D4 10 B5            PUSH    {R4,LR}
.text:000000D6 00 28            CMP     R0, #0
.text:000000D8 05 D0            BEQ     zero_case
.text:000000DA 01 28            CMP     R0, #1
.text:000000DC 05 D0            BEQ     one_case
.text:000000DE 02 28            CMP     R0, #2
.text:000000E0 05 D0            BEQ     two_case
.text:000000E2 91 A0            ADR     R0, aSomethingUnkno ; "something unknown
"
.text:000000E4 04 E0            B       default_case
.text:000000E6 ;
-------------------------------------------------------------------------
.text:000000E6          zero_case                           ; CODE XREF: f1+4
.text:000000E6 95 A0            ADR     R0, aZero           ; "zero
"
.text:000000E8 02 E0            B       default_case
.text:000000EA ;
-------------------------------------------------------------------------
.text:000000EA          one_case                            ; CODE XREF: f1+8
.text:000000EA 96 A0            ADR     R0, aOne            ; "one
"
.text:000000EC 00 E0            B       default_case
.text:000000EE          ;
-------------------------------------------------------------------------
.text:000000EE          two_case                            ; CODE XREF: f1+C
.text:000000EE 97 A0            ADR     R0, aTwo            ; "two
"
.text:000000F0                  default_case                ; CODE XREF: f1+10
.text:000000F0                                              ; f1+14
.text:000000F0 06 F0 7E F8      BL      __2printf
.text:000000F4 10 BD            POP     {R4,PC}
.text:000000F4           ; End of function f1
```

正如我之前提到的，在thumb模式下并没有什么功能来连接预测结果，所以这里的thumb代码有点像容易理解的x86 CISC代码。

### 11.2 多case情况的例子

在有许多case分支的switch()语句中，对编译器来说，转换出一大堆JE/JNE语句并不是太方便。

```
void f (int a)
{
    switch (a)
    {
        case 0: printf ("zero"); break;
        case 1: printf ("one"); break;
        case 2: printf ("two"); break;
        case 3: printf ("three"); break;
        case 4: printf ("four"); break;
        default: printf ("something unknown"); break;
    };
};
```

###　11.2.1 x86

反汇编结果如下（MSVC 2010）：

清单11.3: MSVC 2010

```
tv64 = -4           ; size = 4
_a$ = 8             ; size = 4
_f      PROC
    push    ebp
    mov     ebp, esp
    push    ecx
    mov     eax, DWORD PTR _a$[ebp]
    mov     DWORD PTR tv64[ebp], eax
    cmp     DWORD PTR tv64[ebp], 4
    ja      SHORT $LN1@f
    mov     ecx, DWORD PTR tv64[ebp]
    jmp     DWORD PTR $LN11@f[ecx*4]
$LN6@f:
    push    OFFSET $SG739 ; ’zero’, 0aH, 00H
    call    _printf
    add     esp, 4
    jmp     SHORT $LN9@f
$LN5@f:
    push    OFFSET $SG741 ; ’one’, 0aH, 00H
    call    _printf
    add     esp, 4
    jmp     SHORT $LN9@f
$LN4@f:
    push    OFFSET $SG743 ; ’two’, 0aH, 00H
    call    _printf
    add     esp, 4
    jmp     SHORT $LN9@f
$LN3@f:
    push    OFFSET $SG745 ; ’three’, 0aH, 00H
    call    _printf
    add     esp, 4
    jmp     SHORT $LN9@f
$LN2@f:
    push    OFFSET $SG747 ; ’four’, 0aH, 00H
    call    _printf
    add     esp, 4
    jmp     SHORT $LN9@f
$LN1@f:
    push    OFFSET $SG749 ; ’something unknown’, 0aH, 00H
    call    _printf
    add     esp, 4
$LN9@f:
    mov     esp, ebp
    pop     ebp
    ret     0
    npad    2
$LN11@f:
    DD  $LN6@f ; 0
    DD  $LN5@f ; 1
    DD  $LN4@f ; 2
    DD  $LN3@f ; 3
    DD  $LN2@f ; 4
_f     ENDP
```

好的，我们可以看到这儿有一组不同参数的printf()调用。 它们不仅有内存中的地址，编译器还给它们带上了符号信息。顺带一提，这些符号标签也都存在于$LN11@f内部函数表中。

在函数最开始，如果a大于4，控制流将会被传递到标签$LN1@f上，这儿会有一个参数为“something unknown”的printf()调用。

如果a值小于等于4，然后我们把它乘以4，[email protected]�址的方法，这样可以正好指向我们需要的元素。比如a等于2。 那么，2×4=8（在32位进程下，所有的函数表元素的长度都只有4字节），$LN11@f的函数表地址+8——这样就能取得$LN4@f标签的位置。 JMP将从函数表中获得$LN4@f的地址，然后跳转向它。

这个函数表，有时候也叫做跳转表（jumptable）。

然后，对应的，printf()的参数就是“two”了。 字面意思， JMP DWORD PTR $LN11@f[ECX*4] 指令意味着“ 跳转到存储在$LN11@f + ecx * 4 地址上的双字”。 npad（64）是一个编译时语言宏，它用于对齐下一个标签，这样存储的地址就会按照4字节（或者16字节）对齐。这个对于处理器来说是十分合适的，因为通过内存总线、缓存从内存中获取32位的值是非常方便而且有效率的。

让我们看看GCC 4.4.1 生成的代码：

清单11.4： GCC 4.4.1

```
        public f
f       proc near ; CODE XREF: main+10
 
var_18  = dword ptr -18h
arg_0   = dword ptr 8
        push    ebp
        mov     ebp, esp
        sub     esp, 18h ; char *
        cmp     [ebp+arg_0], 4
        ja      short loc_8048444
        mov     eax, [ebp+arg_0]
        shl     eax, 2
        mov     eax, ds:off_804855C[eax]
        jmp     eax
loc_80483FE:                    ; DATA XREF: .rodata:off_804855C
        mov     [esp+18h+var_18], offset aZero ; "zero"
        call    _puts
        jmp     short locret_8048450
loc_804840C:                    ; DATA XREF: .rodata:08048560
        mov     [esp+18h+var_18], offset aOne ; "one"
        call    _puts
        jmp     short locret_8048450
loc_804841A:                    ; DATA XREF: .rodata:08048564
        mov     [esp+18h+var_18], offset aTwo ; "two"
        call    _puts
        jmp     short locret_8048450
loc_8048428:                    ; DATA XREF: .rodata:08048568
        mov     [esp+18h+var_18], offset aThree ; "three"
        call    _puts
        jmp     short locret_8048450
loc_8048436:                    ; DATA XREF: .rodata:0804856C
        mov     [esp+18h+var_18], offset aFour ; "four"
        call    _puts
        jmp     short locret_8048450
loc_8048444:                    ; CODE XREF: f+A
        mov     [esp+18h+var_18], offset aSomethingUnkno ; "something unknown"
        call    _puts
locret_8048450:                 ; CODE XREF: f+26
                                ; f+34...
        leave
        retn
f       endp
 
off_804855C dd offset loc_80483FE ; DATA XREF: f+12
            dd offset loc_804840C
            dd offset loc_804841A
            dd offset loc_8048428
            dd offset loc_8048436
```

基本和VC生成的相同，除了少许的差别：参数arg_0的乘以4操作被左移2位替换了（这集合和乘以4一样）（见17.3.1节）。 然后标签地址从off_804855C处的数组获取，地址计算之后存储到EAX中，然后通过JMP EAX跳转到实际的地址上。

### 11.2.2 ARM： 优化后的 Keil + ARM 模式

```
00000174                f2
00000174 05 00 50 E3            CMP     R0, #5                  ; switch 5 cases
00000178 00 F1 8F 30            ADDCC   PC, PC, R0,LSL#2        ; switch jump
0000017C 0E 00 00 EA            B       default_case            ; jumptable 00000178 default case
00000180                ; -------------------------------------------------------------------------
00000180
00000180                loc_180                         ; CODE XREF: f2+4
00000180 03 00 00 EA            B       zero_case       ; jumptable 00000178 case 0
00000184                ; -------------------------------------------------------------------------
00000184
00000184                loc_184                         ; CODE XREF: f2+4
00000184 04 00 00 EA            B       one_case        ; jumptable 00000178 case 1
00000188                ; -------------------------------------------------------------------------
00000188
00000188                loc_188                         ; CODE XREF: f2+4
00000188 05 00 00 EA            B       two_case        ; jumptable 00000178 case 2
0000018C                ; -------------------------------------------------------------------------
0000018C
0000018C                loc_18C                         ; CODE XREF: f2+4
0000018C 06 00 00 EA            B       three_case      ; jumptable 00000178 case 3
00000190                ; -------------------------------------------------------------------------
00000190
00000190                loc_190                         ; CODE XREF: f2+4
00000190 07 00 00 EA            B       four_case       ; jumptable 00000178 case 4
00000194                ; -------------------------------------------------------------------------
00000194
00000194                zero_case                       ; CODE XREF: f2+4
00000194                                                ; f2:loc_180
00000194 EC 00 8F E2            ADR     R0, aZero       ; jumptable 00000178 case 0
00000198 06 00 00 EA            B       loc_1B8
0000019C                ; -------------------------------------------------------------------------
0000019C
0000019C one_case                                       ; CODE XREF: f2+4
0000019C                                                ; f2:loc_184
0000019C EC 00 8F E2            ADR     R0, aOne        ; jumptable 00000178 case 1
000001A0 04 00 00 EA            B       loc_1B8
000001A4                ; -------------------------------------------------------------------------
000001A4
000001A4                two_case                        ; CODE XREF: f2+4
000001A4                                                ; f2:loc_188
000001A4 01 0C 8F E2            ADR     R0, aTwo        ; jumptable 00000178 case 2
000001A8 02 00 00 EA            B       loc_1B8
000001AC                ; -------------------------------------------------------------------------
000001AC
000001AC                three_case                      ; CODE XREF: f2+4
000001AC                                                ; f2:loc_18C
000001AC 01 0C 8F E2            ADR     R0, aThree ; jumptable 00000178 case 3
000001B0 00 00 00 EA            B       loc_1B8
000001B4 ; -------------------------------------------------------------------------
000001B4
000001B4                four_case                       ; CODE XREF: f2+4
000001B4                                                ; f2:loc_190
000001B4 01 0C 8F E2            ADR     R0, aFour       ; jumptable 00000178 case 4
000001B8
000001B8                loc_1B8                         ; CODE XREF: f2+24
000001B8                                                ; f2+2C
000001B8 66 18 00 EA            B       __2printf
000001BC ; -------------------------------------------------------------------------
000001BC
000001BC                default_case                    ; CODE XREF: f2+4
000001BC                                                ; f2+8
000001BC D4 00 8F E2            ADR     R0, aSomethingUnkno ; jumptable 00000178 default case
000001C0 FC FF FF EA            B       loc_1B8
000001C0                ; End of function f2
```

这个代码利用了ARM的特性，这里ARM模式下所有指令都是4个字节。

让我们记住a的最大值是4，任何更大额值都会导致它输出“something unknown”。

最开始的“CMP R0, #5”指令将a的值与5比较。

下一个“ADDCC PC, PC, R0, LSL#2”指令将仅在R0<5的时候执行（CC = Carry clear ， 小于）。所以，如果ADDCC并没有触发（R0>=5时），它将会跳转到default _case标签上。

但是，如果R0<5，而且ADDCC触发了，将会发生下列事情：

R0中的值会乘以4，事实上，LSL#2代表着“左移2位”，但是像我们接下来（见17.3.1节）要看到的“移位”一样，左移2位代表乘以4。

然后，我们得到了R0 * 4的值，这个值将会和PC中现有的值相加，因此跳转到下述其中一个B（Branch 分支）指令上。

在ADDCC执行时，PC中的值（0x180）比ADDCC指令的值（0x178）提前8个字节，换句话说，提前2个指令。

这也就是为ARM处理器通道工作的方式：当ADDCC指令执行的时候，此时处理器将开始处理下一个指令，这也就是PC会指向这里的原因。

如果a=0，那么PC将不会和任何值相加，PC中实际的值将写入PC中（它相对之领先8个字节），然后跳转到标签loc_180处。这就是领先ADDCC指令8个字节的地方。

在a=1时，PC+8+a4 = PC+8+14 = PC+16= 0x184 将被写入PC中，这是loc_184标签的地址。

每当a上加1，PC都会增加4，4也是ARM模式的指令长度，而且也是B指令的长度。这组里面有5个这样的指令。

这5个B指令将传递控制流，也就是传递switch（）中指定的字符串和对应的操作等等。

### 11.2.3 ARM： 优化后的 Keil + thumb 模式

```
000000F6                        EXPORT  f2
000000F6                f2
000000F6 10 B5                  PUSH    {R4,LR}
000000F8 03 00                  MOVS    R3, R0
000000FA 06 F0 69 F8            BL      __ARM_common_switch8_thumb ; switch 6 cases
000000FA                        ;-------------------------------------------------------------------------
000000FE 05                     DCB 5
000000FF 04 06 08 0A 0C 10      DCB 4, 6, 8, 0xA, 0xC, 0x10 ; jump table for switch
statement
00000105 00                     ALIGN 2
00000106
00000106                zero_case                       ; CODE XREF: f2+4
00000106 8D A0                  ADR       R0, aZero       ; jumptable 000000FA case 0
00000108 06 E0                  B       loc_118
0000010A                        ;-------------------------------------------------------------------------
0000010A
0000010A                    one_case                    ; CODE XREF: f2+4
0000010A 8E A0                  ADR       R0, aOne        ; jumptable 000000FA case 1
0000010C 04 E0                  B       loc_118
0000010E                        ;-------------------------------------------------------------------------
0000010E
0000010E                    two_case                    ; CODE XREF: f2+4
0000010E 8F A0                  ADR       R0, aTwo        ; jumptable 000000FA case 2
00000110 02 E0                  B       loc_118
00000112                        ;-------------------------------------------------------------------------
00000112
00000112                    three_case                  ; CODE XREF: f2+4
00000112 90 A0                  ADR       R0, aThree      ; jumptable 000000FA case 3
00000114 00 E0                  B       loc_118
00000116                        ;-------------------------------------------------------------------------
00000116
00000116                    four_case                   ; CODE XREF: f2+4
00000116 91 A0                  ADR       R0, aFour       ; jumptable 000000FA case 4
00000118
00000118                    loc_118                     ; CODE XREF: f2+12
00000118                                                ; f2+16
00000118 06 F0 6A F8            BL        __2printf
0000011C 10 BD                  POP       {R4,PC}
0000011E                        ;-------------------------------------------------------------------------
0000011E
0000011E                    default_case                ; CODE XREF: f2+4
0000011E 82 A0                  ADR       R0, aSomethingUnkno ; jumptable 000000FA default
case
00000120 FA E7                  B         loc_118
 
000061D0                        EXPORT __ARM_common_switch8_thumb
000061D0                    __ARM_common_switch8_thumb ; CODE XREF: example6_f2+4
000061D0 78 47                  BX          PC
000061D0                    ;---------------------------------------------------------------------------
000061D2 00 00                  ALIGN 4
000061D2                    ; End of function __ARM_common_switch8_thumb
000061D2
000061D4                        CODE32
000061D4
000061D4                    ; =============== S U B R O U T I N E =======================================
000061D4
000061D4
000061D4                    __32__ARM_common_switch8_thumb  ; CODE XREF:
    __ARM_common_switch8_thumb
000061D4 01 C0 5E E5            LDRB    R12, [LR,#-1]
000061D8 0C 00 53 E1            CMP     R3, R12
000061DC 0C 30 DE 27            LDRCSB  R3, [LR,R12]
000061E0 03 30 DE 37            LDRCCB  R3, [LR,R3]
000061E4 83 C0 8E E0            ADD     R12, LR, R3,LSL#1
000061E8 1C FF 2F E1            BX      R12
000061E8                ; End of function __32__ARM_common_switch8_thumb
```

一个不能确定的事实是thumb、thumb-2中的所有指令都有同样的大小。甚至可以说是在这些模式下，指令的长度是可变的，就像x86一样。

所以这一定有一个特别的表单，里面包含有多少个case（除了默认的case），然后和它们的偏移，并且给他们每个都加上一个标签，这样控制流就可以传递到正确的位置。 这里有一个特别的函数来处理表单和处理控制流，被命名为__ARM_common_switch8_thumb。它由“BX PC”指令开始，这个函数用来将处理器切换到ARM模式，然后你就可以看到处理表单的函数。不过对我们来说，在这里解释它太复杂了，所以我们将省去一些细节。

但是有趣的是，这个函数使用LR寄存器作为表单的指针。还有，在这个函数调用后，LR将包含有紧跟着“BL __ARM_common_switch8_thumb”指令的地址，然后表单就由此开始。

当然，这里也不值得去把生成的代码作为单独的函数，然后再去重用它们。因此在switch()处理相似的位置、相似的case时编译器并不会生成相同的代码。

IDA成功的发觉到它是一个服务函数以及函数表，然后给各个标签加上了合适的注释，比如jumptable 000000FA case 0。