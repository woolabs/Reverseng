# 第四十九章
# 处理不当的反汇编代码

逆向工程师经常需要处理不当的反汇编代码

##　49.1反汇编于不正确起始位置(x86)

不同于ARM和MIPS架构(任何指令长度只有2个字节长度或者4个字节长度)， x86架构的指令长度是不定长的，因此，任何反汇编器从x86指令中间开始反汇编，可能会长生不正确的结果。

举个例子：

```
add [ebp-31F7Bh], cl
dec dword ptr [ecx-3277Bh]
dec dword ptr [ebp-2CF7Bh]
inc dword ptr [ebx-7A76F33Ch]
fdiv st(4), st
;-------------------------------------------------------------
db 0FFh
;-------------------------------------------------------------
dec dword ptr [ecx-21F7Bh]
dec dword ptr [ecx-22373h]
dec dword ptr [ecx-2276Bh]
dec dword ptr [ecx-22B63h]
dec dword ptr [ecx-22F4Bh]
dec dword ptr [ecx-23343h]
jmp dword ptr [esi-74h]
;-------------------------------------------------------------
xchg eax, ebp
clc
std
;-------------------------------------------------------------
db 0FFh
db 0FFh
;-------------------------------------------------------------
mov word ptr [ebp-214h], cs
mov word ptr [ebp-238h], ds
mov word ptr [ebp-23Ch], es
mov word ptr [ebp-240h], fs
mov word ptr [ebp-244h], gs
pushf
pop dword ptr [ebp-210h]
mov eax, [ebp+4]
mov [ebp-218h], eax
lea eax, [ebp+4]
mov [ebp-20Ch], eax
mov dword ptr [ebp-2D0h], 10001h
mov eax, [eax-4]
mov [ebp-21Ch], eax
mov eax, [ebp+0Ch]
mov [ebp-320h], eax
mov eax, [ebp+10h]
mov [ebp-31Ch], eax
mov eax, [ebp+4]
mov [ebp-314h], eax
call ds:IsDebuggerPresent
mov edi, eax
lea eax, [ebp-328h]
push eax
call sub_407663
pop ecx
test eax, eax
jnz short loc_402D7B
```

虽然上面的代码片段一开始是从错误的起始位置反汇编的，但最终，反汇编器能够自己调整到正确的轨道上。

## 49.2 不正确的反汇编代码的特点

可以很容易发现它们的共同特点是：

很少出现大尺寸的指令，最常见的有x86指令的push，mov，call。 但是我们可以看到这些指令来自各个不同的指令组，有FPU指令，IN/OUT指令，少数的系统指令，一切都是因为反汇编器从一个错误的位置上开始反汇编机器码给搞砸了。
偏移量和立即数都是一些随机值，而且数值较大。
跳转到不正确的偏移地址常常会跳转到另一个指令的中间。
代码清单28.1:x86架构不正确的反汇编代码示例

```
    mov     bl, 0Ch
    mov     ecx, 0D38558Dh
    mov     eax, ds:2C869A86h
    db      67h
    mov     dl, 0CCh
    insb
    movsb
    push    eax
    xor     [edx-53h], ah
    fcom    qword ptr [edi-45A0EF72h]
    pop     esp
    pop     ss
    in      eax, dx
    dec     ebx
    push    esp
    lds     esp, [esi-41h]
    retf
    rcl     dword ptr [eax], cl
    mov     cl, 9Ch
    mov     ch, 0DFh
    push    cs
    insb
    mov     esi, 0D9C65E4Dh
    imul    ebp, [ecx], 66h
    pushf
    sal     dword ptr [ebp-64h], cl
    sub     eax, 0AC433D64h
    out     8Ch, eax
    pop     ss
    sbb     [eax], ebx
    aas
    xchg    cl, [ebx+ebx*4+14B31Eh]
    jecxz   short near ptr loc_58+1
    xor     al, 0C6h
    inc     edx
    db      36h
    pusha
    stosb
    test    [ebx], ebx
    sub     al, 0D3h ; 'L'
    pop     eax
    stosb

loc_58: ; CODE XREF: seg000:0000004A
    test    [esi], eax
    inc     ebp
    das
    db      64h
    pop     ecx
    das
    hlt

    pop     edx
    out     0B0h, al
    lodsb
    push    ebx
    cdq
    out     dx, al
    sub     al, 0Ah
    sti
    outsd
    add     dword ptr [edx], 96FCBE4Bh
    and     eax, 0E537EE4Fh
    inc     esp
    stosd
    cdq
    push    ecx
    in      al, 0CBh
    mov     ds:0D114C45Ch, al
    mov     esi, 659D1985h
    enter   6FE8h, 0D9h
    enter   6FE6h, 0D9h
    xchg    eax, esi
    sub     eax, 0A599866Eh
    retn

    pop     eax
    dec     eax
    adc     al, 21h ; '!'
    lahf
    inc     edi
    sub     eax, 9062EE5Bh
    bound   eax, [ebx]

loc_A2: ; CODE XREF: seg000:00000120
    wait
    iret

    jnb     short loc_D7
    cmpsd
    iret

    jnb     short loc_D7
    sub     ebx, [ecx]
    in      al, 0Ch
    add     esp, esp
    mov     bl, 8Fh
    xchg    eax, ecx
    int     67h
    pop     ds
    pop     ebx
    db      36h
    xor     esi, [ebp-4Ah]
    mov     ebx, 0EB4F980Ch
    repne add bl, dh
    imul    ebx, [ebp+5616E7A5h], 67A4D1EEh
    xchg    eax, ebp
    scasb
    push    esp
    wait
    mov     dl, 11h
    mov     ah, 29h ; ')'
    fist    dword ptr [edx]

loc_D7: ; CODE XREF: seg000:000000A4
        ; seg000:000000A8 ...
    dec     dword ptr [ebp-5D0E0BA4h]
    call    near ptr 622FEE3Eh
    sbb     ax, 5A2Fh
    jmp     dword ptr cs:[ebx]

    xor     ch, [edx-5]
    inc     esp
    push    edi
    xor     esp, [ebx-6779D3B8h]
    pop     eax
    int     3               ; Trap to Debugger
    rcl     byte ptr [ebx-3Eh], cl
    xor     [edi], bl
    sbb     al, [edx+ecx*4]
    xor     ah, [ecx-1DA4E05Dh]
    push    edi
    xor     ah, cl
    popa
    cmp     dword ptr [edx-62h], 46h ; 'F'
    dec     eax
    in      al, 69h
    dec     ebx
    iret

    or      al, 6
    jns     short near ptr loc_D7+3
    shl     byte ptr [esi], 42h
    repne adc [ebx+2Ch], eax
    icebp
    cmpsd
    leave
    push    esi
    jmp     short loc_A2

    and     eax, 0F2E41FE9h
    push    esi
    loop    loc_14F
    add     ah, fs:[edx]

loc_12D: ; CODE XREF: seg000:00000169
    mov     dh, 0F7h
    add     [ebx+7B61D47Eh], esp
    mov     edi, 79F19525h
    rcl     byte ptr [eax+22015F55h], cl
    cli
    sub     al, 0D2h ; 'T'
    dec     eax
    mov     ds:0A81406F5h, eax
    sbb     eax, 0A7AA179Ah
    in      eax, dx

loc_14F: ; CODE XREF: seg000:00000128
    and     [ebx-4CDFAC74h], ah
    pop     ecx
    push    esi
    mov     bl, 2Dh ; '-'
    in      eax, 2Ch
    stosd
    inc     edi
    push    esp

locret_15E: ; CODE XREF: seg000:loc_1A0
    retn    0C432h

    and     al, 86h
    cwde
    and     al, 8Fh
    cmp     ebp, [ebp+7]
    jz      short loc_12D
    sub     bh, ch
    or      dword ptr [edi-7Bh], 8A16C0F7h
    db      65h
    insd
    mov     al, ds:0A3A5173Dh
    dec     ecx
    push    ds
    xor     al, cl
    jg      short loc_195
    push    6Eh ; 'n'
    out     0DDh, al
    inc     edi
    sub     eax, 6899BBF1h
    leave
    rcr     dword ptr [ecx-69h], cl
    sbb     ch, [edi+5EDDCB54h]

loc_195: ; CODE XREF: seg000:0000017F
    push    es
    repne sub ah, [eax-105FF22Dh]
    cmc
    and     ch, al

loc_1A0: ; CODE XREF: seg000:00000217
    jnp     short near ptr locret_15E+1
    or      ch, [eax-66h]
    add     [edi+edx-35h], esi
    out     dx, al
    db      2Eh
    call    far ptr 1AAh:6832F5DDh
    jz      short near ptr loc_1DA+1
    sbb     esp, [edi+2CB02CEFh]
    xchg    eax, edi
    xor     [ebx-766342ABh], edx

loc_1C1: ; CODE XREF: seg000:00000212
    cmp     eax, 1BE9080h
    add     [ecx], edi
    aad     0
    imul    esp, [edx-70h], 0A8990126h
    or      dword ptr [edx+10C33693h], 4Bh
    popf

loc_1DA: ; CODE XREF: seg000:000001B2
    mov     ecx, cs
    aaa
    mov     al, 39h ; '9'
    adc     byte ptr [eax-77F7F1C5h], 0C7h
    add     [ecx], bl
    retn    0DD42h

    db      3Eh
    mov     fs:[edi], edi
    and     [ebx-24h], esp
    db      64h
    xchg    eax, ebp
    push    cs
    adc     eax, [edi+36h]
    mov     bh, 0C7h
    sub     eax, 0A710CBE7h
    xchg    eax, ecx
    or      eax, 51836E42h
    xchg    eax, ebx
    inc     ecx
    jb      short near ptr loc_21E+3
    db      64h
    xchg    eax, esp
    and     dh, [eax-31h]
    mov     ch, 13h
    add     ebx, edx
    jnb     short loc_1C1
    db      65h
    adc     al, 0C5h
    js      short loc_1A0
    sbb     eax, 887F5BEEh

loc_21E: ; CODE XREF: seg000:00000207
    mov     eax, 888E1FD6h
    mov     bl, 90h
    cmp     [eax], ecx
    rep int 61h             ; reserved for user interrupt
    and     edx, [esi-7EB5C9EAh]
    fisttp  qword ptr [eax+esi*4+38F9BA6h]
    jmp     short loc_27C

    fadd    st, st(2)
    db      3Eh
    mov     edx, 54C03172h
    retn

    db      64h
    pop     ds
    xchg    eax, esi
    rcr     ebx, cl
    cmp     [di+2Eh], ebx
    repne xor [di-19h], dh
    insd
    adc     dl, [eax-0C4579F7h]
    push    ss
    xor     [ecx+edx*4+65h], ecx
    mov     cl, [ecx+ebx-32E8AC51h]
    or      [ebx], ebp
    cmpsb
    lodsb
    iret
```

代码清单28.2:x86_64架构不正确的反汇编代码示例

```
    lea     esi, [rax+rdx*4+43558D29h]

loc_AF3: ; CODE XREF: seg000:0000000000000B46
    rcl     byte ptr [rsi+rax*8+29BB423Ah], 1
    lea     ecx, cs:0FFFFFFFFB2A6780Fh
    mov     al, 96h
    mov     ah, 0CEh
    push    rsp
    lods    byte ptr [esi]

    db  2Fh ; /

    pop     rsp
    db      64h
    retf    0E993h

    cmp     ah, [rax+4Ah]
    movzx   rsi, dword ptr [rbp-25h]
    push    4Ah
    movzx   rdi, dword ptr [rdi+rdx*8]

    db  9Ah

    rcr     byte ptr [rax+1Dh], cl
    lodsd
    xor     [rbp+6CF20173h], edx
    xor     [rbp+66F8B593h], edx
    push    rbx
    sbb     ch, [rbx-0Fh]
    stosd
    int     87h
    db      46h, 4Ch
    out     33h, rax
    xchg    eax, ebp
    test    ecx, ebp
    movsd
    leave
    push    rsp

    db  16h

    xchg    eax, esi
    pop     rdi

loc_B3D: ; CODE XREF: seg000:0000000000000B5F
    mov     ds:93CA685DF98A90F9h, eax
    jnz     short near ptr loc_AF3+6
    out     dx, eax
    cwde
    mov     bh, 5Dh ; ']'
    movsb
    pop     rbp

    db  60h ; `

    movsxd  rbp, dword ptr [rbp-17h]
    pop     rbx
    out     7Dh, al
    add     eax, 0D79BE769h

    db  1Fh

    retf    0CAB9h

    jl      short near ptr loc_B3D+4
    sal     dword ptr [rbx+rbp+4Dh], 0D3h
    mov     cl, 41h ; 'A'
    imul    eax, [rbp-5B77E717h], 1DDE6E5h
    imul    ecx, ebx, 66359BCCh
    xlat

    db  60h ; `

    cmp     bl, [rax]
    and     ebp, [rcx-57h]
    stc
    sub     [rcx+1A533AB4h], al
    jmp     short loc_C05

    db  4Bh ; K

    int     3               ; Trap to Debugger
    xchg    ebx, [rsp+rdx-5Bh]

    db 0D6h

    mov     esp, 0C5BA61F7h
    out     0A3h, al        ; Interrupt Controller #2, 8259A
    add     al, 0A6h
    pop     rbx
    cmp     bh, fs:[rsi]
    and     ch, cl
    cmp     al, 0F3h

    db  0Eh

    xchg    dh, [rbp+rax*4-4CE9621Ah]
    stosd
    xor     [rdi], ebx
    stosb
    xchg    eax, ecx
    push    rsi
    insd
    fidiv   word ptr [rcx]
    xchg    eax, ecx
    mov     dh, 0C0h ; 'L'
    xchg    eax, esp
    push    rsi
    mov     dh, [rdx+rbp+6918F1F3h]
    xchg    eax, ebp
    out     9Dh, al

loc_BC0: ; CODE XREF: seg000:0000000000000C26
    or      [rcx-0Dh], ch
    int     67h             ;  - LIM EMS
    push    rdx
    sub     al, 43h ; 'C'
    test    ecx, ebp
    test    [rdi+71F372A4h], cl

    db    7

    imul    ebx, [rsi-0Dh], 2BB30231h
    xor     ebx, [rbp-718B6E64h]
    jns     short near ptr loc_C56+1
    ficomp  dword ptr [rcx-1Ah]
    and     eax, 69BEECC7h
    mov     esi, 37DA40F6h
    imul    r13, [rbp+rdi*8+529F33CDh], 0FFFFFFFFF35CDD30h
    or      [rbx], edx
    imul    esi, [rbx-34h], 0CDA42B87h

    db  36h ; 6
    db  1Fh


loc_C05: ; CODE XREF: seg000:0000000000000B86
    add     dh, [rcx]
    mov     edi, 0DD3E659h
    ror     byte ptr [rdx-33h], cl
    xlat
    db      48h
    sub     rsi, [rcx]

    db  1Fh
    db    6

    xor     [rdi+13F5F362h], bh
    cmpsb
    sub     esi, [rdx]
    pop     rbp
    sbb     al, 62h ; 'b'
    mov     dl, 33h ; '3'

    db  4Dh ; M
    db  17h

    jns     short loc_BC0
    push    0FFFFFFFFFFFFFF86h

loc_C2A: ; CODE XREF: seg000:0000000000000C8F
    sub     [rdi-2Ah], eax

    db 0FEh

    cmpsb
    wait
    rcr     byte ptr [rax+5Fh], cl
    cmp     bl, al
    pushfq
    xchg    ch, cl

    db  4Eh ; N
    db  37h ; 7

    mov     ds:0E43F3CCD3D9AB295h, eax
    cmp     ebp, ecx
    jl      short loc_C87
    retn    8574h

    out     3, al           ; DMA controller, 8237A-5.
                            ; channel 1 base address and word count

loc_C4C: ; CODE XREF: seg000:0000000000000C7F
    cmp     al, 0A6h
    wait
    push    0FFFFFFFFFFFFFFBEh

    db  82h

    ficom   dword ptr [rbx+r10*8]

loc_C56: ; CODE XREF: seg000:0000000000000BDE
    jnz     short loc_C76
    xchg    eax, edx
    db      26h
    wait
    iret

    push    rcx

    db  48h ; H
    db  9Bh
    db  64h ; d
    db  3Eh ; >
    db  2Fh ; /

    mov     al, ds:8A7490CA2E9AA728h
    stc

    db  60h ; `

    test    [rbx+rcx], ebp
    int     3               ; Trap to Debugger
    xlat

loc_C72: ; CODE XREF: seg000:0000000000000CC6
    mov     bh, 98h

    db  2Eh ; .
    db 0DFh


loc_C76: ; CODE XREF: seg000:loc_C56
    jl      short loc_C91
    sub     ecx, 13A7CCF2h
    movsb
    jns     short near ptr loc_C4C+1
    cmpsd
    sub     ah, ah
    cdq

    db  6Bh ; k
    db  5Ah ; Z


loc_C87: ; CODE XREF: seg000:0000000000000C45
    or      ecx, [rbx+6Eh]
    rep in eax, 0Eh         ; DMA controller, 8237A-5.
                            ; Clear mask registers.
                            ; Any OUT enables all 4 channels.
    cmpsb
    jnb     short loc_C2A

loc_C91: ; CODE XREF: seg000:loc_C76
    scasd
    add     dl, [rcx+5FEF30E6h]
    enter   0FFFFFFFFFFFFC733h, 7Ch
    insd
    mov     ecx, gs
    in      al, dx
    out     2Dh, al
    mov     ds:6599E434E6D96814h, al
    cmpsb
    push    0FFFFFFFFFFFFFFD6h
    popfq
    xor     ecx, ebp
    db      48h
    insb
    test    al, cl
    xor     [rbp-7Bh], cl
    and     al, 9Bh

    db  9Ah

    push    rsp
    xor     al, 8Fh
    cmp     eax, 924E81B9h
    clc
    mov     bh, 0DEh
    jbe     short near ptr loc_C72+1

    db  1Eh

    retn    8FCAh

    db 0C4h ; -


loc_CCD: ; CODE XREF: seg000:0000000000000D22
    adc     eax, 7CABFBF8h

    db  38h ; 8

    mov     ebp, 9C3E66FCh
    push    rbp
    dec     byte ptr [rcx]
    sahf
    fidivr  word ptr [rdi+2Ch]

    db  1Fh

    db      3Eh
    xchg    eax, esi

loc_CE2: ; CODE XREF: seg000:0000000000000D5E
    mov     ebx, 0C7AFE30Bh
    clc
    in      eax, dx
    sbb     bh, bl
    xchg    eax, ebp

    db  3Fh ; ?

    cmp     edx, 3EC3E4D7h
    push    51h
    db      3Eh
    pushfq
    jl      short loc_D17
    test    [rax-4CFF0D49h], ebx

    db  2Fh ; /

    rdtsc
    jns     short near ptr loc_D40+4
    mov     ebp, 0B2BB03D8h
    in      eax, dx

    db  1Eh

    fsubr   dword ptr [rbx-0Bh]
    jns     short loc_D70
    scasd
    mov     ch, 0C1h ; '+'
    add     edi, [rbx-53h]

    db 0E7h


loc_D17: ; CODE XREF: seg000:0000000000000CF7
    jp      short near ptr unk_D79
    scasd
    cmc
    sbb     ebx, [rsi]
    fsubr   dword ptr [rbx+3Dh]
    retn

    db    3

    jnp     short near ptr loc_CCD+4
    db      36h
    adc     r14b, r13b

    db  1Fh

    retf

    test    [rdi+rdi*2], ebx
    cdq
    or      ebx, edi
    test    eax, 310B94BCh
    ffreep  st(7)
    cwde
    sbb     esi, [rdx+53h]
    push    5372CBAAh

loc_D40: ; CODE XREF: seg000:0000000000000D02
    push    53728BAAh
    push    0FFFFFFFFF85CF2FCh

    db  0Eh

    retn    9B9Bh

    movzx   r9, dword ptr [rdx]
    adc     [rcx+43h], ebp
    in      al, 31h

    db  37h ; 7

    jl      short loc_DC5
    icebp
    sub     esi, [rdi]
    clc
    pop     rdi
    jb      short near ptr loc_CE2+1
    or      al, 8Fh
    mov     ecx, 770EFF81h
    sub     al, ch
    sub     al, 73h ; 's'
    cmpsd
    adc     bl, al
    out     87h, eax        ; DMA page register 74LS612:
                            ; Channel 0 (address bits 16-23)

loc_D70: ; CODE XREF: seg000:0000000000000D0E
    adc     edi, ebx
    db      49h
    outsb
    enter   33E5h, 97h
    xchg    eax, ebx

unk_D79   db 0FEh ; CODE XREF: seg000:loc_D17
          db 0BEh
          db 0E1h
          db  82h


loc_D7D: ; CODE XREF: seg000:0000000000000DB3
    cwde

    db    7
    db  5Ch ; \
    db  10h
    db  73h ; s
    db 0A9h
    db  2Bh ; +
    db  9Fh


loc_D85: ; CODE XREF: seg000:0000000000000DD1
    dec     dh
    jnz     short near ptr loc_DD3+3
    mov     ds:7C1758CB282EF9BFh, al
    sal     ch, 91h
    rol     dword ptr [rbx+7Fh], cl
    fbstp   tbyte ptr [rcx+2]
    repne mov al, ds:4BFAB3C3ECF2BE13h
    pushfq
    imul    edx, [rbx+rsi*8+3B484EE9h], 8EDC09C6h
    cmp     [rax], al
    jg      short loc_D7D
    xor     [rcx-638C1102h], edx
    test    eax, 14E3AD7h
    insd

    db  38h ; 8
    db  80h
    db 0C3h


loc_DC5: ; CODE XREF: seg000:0000000000000D57
         ; seg000:0000000000000DD8
    cmp     ah, [rsi+rdi*2+527C01D3h]
    sbb     eax, 5FC631F0h
    jnb     short loc_D85

loc_DD3: ; CODE XREF: seg000:0000000000000D87
    call    near ptr 0FFFFFFFFC03919C7h
    loope   near ptr loc_DC5+3
    sbb     al, 0C8h
    std
```

代码清单28.2:ARM架构(ARM 模式)不正确的反汇编代码示例

```
BLNE    0xFE16A9D8
BGE     0x1634D0C
SVCCS   0x450685
STRNVT  R5, [PC],#-0x964
LDCGE   p6, c14, [R0],#0x168
STCCSL  p9, c9, [LR],#0x14C
CMNHIP  PC, R10,LSL#22
FLDMIADNV LR!, {D4}
MCR     p5, 2, R2,c15,c6, 4
BLGE    0x1139558
BLGT    0xFF9146E4
STRNEB  R5, [R4],#0xCA2
STMNEIB R5, {R0,R4,R6,R7,R9-SP,PC}
STMIA   R8, {R0,R2-R4,R7,R8,R10,SP,LR}^
STRB    SP, [R8],PC,ROR#18
LDCCS   p9, c13, [R6,#0x1BC]
LDRGE   R8, [R9,#0x66E]
STRNEB  R5, [R8],#-0x8C3
STCCSL  p15, c9, [R7,#-0x84]
RSBLS   LR, R2, R11,ASR LR
SVCGT   0x9B0362
SVCGT   0xA73173
STMNEDB R11!, {R0,R1,R4-R6,R8,R10,R11,SP}
STR     R0, [R3],#-0xCE4
LDCGT   p15, c8, [R1,#0x2CC]
LDRCCB  R1, [R11],-R7,ROR#30
BLLT    0xFED9D58C
BL      0x13E60F4
LDMVSIB R3!, {R1,R4-R7}^
USATNE  R10, #7, SP,LSL#11
LDRGEB  LR, [R1],#0xE56
STRPLT  R9, [LR],#0x567
LDRLT   R11, [R1],#-0x29B
SVCNV   0x12DB29
MVNNVS  R5, SP,LSL#25
LDCL    p8, c14, [R12,#-0x288]
STCNEL  p2, c6, [R6,#-0xBC]!
SVCNV   0x2E5A2F
BLX     0x1A8C97E
TEQGE   R3, #0x1100000
STMLSIA R6, {R3,R6,R10,R11,SP}
BICPLS  R12, R2, #0x5800
BNE     0x7CC408
TEQGE   R2, R4,LSL#20
SUBS    R1, R11, #0x28C
BICVS   R3, R12, R7,ASR R0
LDRMI   R7, [LR],R3,LSL#21
BLMI    0x1A79234
STMVCDB R6, {R0-R3,R6,R7,R10,R11}
EORMI   R12, R6, #0xC5
MCRRCS  p1, 0xF, R1,R3,c2
```

代码清单28.2:ARM架构(Thumb 模式)不正确的反汇编代码示例

```
    LSRS    R3, R6, #0x12
    LDRH    R1, [R7,#0x2C]
    SUBS    R0, #0x55 ; 'U'
    ADR     R1, loc_3C
    LDR     R2, [SP,#0x218]
    CMP     R4, #0x86
    SXTB    R7, R4
    LDR     R4, [R1,#0x4C]
    STR     R4, [R4,R2]
    STR     R0, [R6,#0x20]
    BGT     0xFFFFFF72
    LDRH    R7, [R2,#0x34]
    LDRSH   R0, [R2,R4]
    LDRB    R2, [R7,R2]

    DCB 0x17
    DCB 0xED

    STRB    R3, [R1,R1]
    STR     R5, [R0,#0x6C]
    LDMIA   R3, {R0-R5,R7}
    ASRS    R3, R2, #3
    LDR     R4, [SP,#0x2C4]
    SVC     0xB5
    LDR     R6, [R1,#0x40]
    LDR     R5, =0xB2C5CA32
    STMIA   R6, {R1-R4,R6}
    LDR     R1, [R3,#0x3C]
    STR     R1, [R5,#0x60]
    BCC     0xFFFFFF70
    LDR     R4, [SP,#0x1D4]
    STR     R5, [R5,#0x40]
    ORRS    R5, R7

loc_3C ; DATA XREF: ROM:00000006
    B       0xFFFFFF98

    ASRS    R4, R1, #0x1E
    ADDS    R1, R3, R0
    STRH    R7, [R7,#0x30]
    LDR     R3, [SP,#0x230]
    CBZ     R6, loc_90
    MOVS    R4, R2
    LSRS    R3, R4, #0x17
    STMIA   R6!, {R2,R4,R5}
    ADDS    R6, #0x42 ; 'B'
    ADD     R2, SP, #0x180
    SUBS    R5, R0, R6
    BCC     loc_B0
    ADD     R2, SP, #0x160
    LSLS    R5, R0, #0x1A
    CMP     R7, #0x45
    LDR     R4, [R4,R5]

    DCB 0x2F ; /
    DCB 0xF4

    B       0xFFFFFD18

    ADD     R4, SP, #0x2C0
    LDR     R1, [SP,#0x14C]
    CMP     R4, #0xEE

    DCB  0xA
    DCB 0xFB

    STRH    R7, [R5,#0xA]
    LDR     R3, loc_78

    DCB 0xBE ; -
    DCB 0xFC

    MOVS    R5, #0x96

    DCB 0x4F ; O
    DCB 0xEE

    B       0xFFFFFAE6

    ADD     R3, SP, #0x110

loc_78 ; DATA XREF: ROM:0000006C
    STR     R1, [R3,R6]
    LDMIA   R3!, {R2,R5-R7}
    LDRB    R2, [R4,R2]
    ASRS    R4, R0, #0x13
    BKPT    0xD1
    ADDS    R5, R0, R6
    STR     R5, [R3,#0x58]
```

代码清单28.2:MIPS架构(小端序)不正确的反汇编代码示例

```
lw      $t9, 0xCB3($t5)
sb      $t5, 0x3855($t0)
sltiu   $a2, $a0, -0x657A
ldr     $t4, -0x4D99($a2)
daddi   $s0, $s1, 0x50A4
lw      $s7, -0x2353($s4)
bgtzl   $a1, 0x17C5C

.byte 0x17
.byte 0xED
.byte 0x4B  # K
.byte 0x54  # T

lwc2    $31, 0x66C5($sp)
lwu     $s1, 0x10D3($a1)
ldr     $t6, -0x204B($zero)
lwc1    $f30, 0x4DBE($s2)
daddiu  $t1, $s1, 0x6BD9
lwu     $s5, -0x2C64($v1)
cop0    0x13D642D
bne     $gp, $t4, 0xFFFF9EF0
lh      $ra, 0x1819($s1)
sdl     $fp, -0x6474($t8)
jal     0x78C0050
ori     $v0, $s2, 0xC634
blez    $gp, 0xFFFEA9D4
swl     $t8, -0x2CD4($s2)
sltiu   $a1, $k0, 0x685
sdc1    $f15, 0x5964($at)
sw      $s0, -0x19A6($a1)
sltiu   $t6, $a3, -0x66AD
lb      $t7, -0x4F6($t3)
sd      $fp, 0x4B02($a1)

.byte 0x96
.byte 0x25  # %
.byte 0x4F  # O
.byte 0xEE

swl     $a0, -0x1AC9($k0)
lwc2    $4, 0x5199($ra)
bne     $a2, $a0, 0x17308

.byte 0xD1
.byte 0xBE
.byte 0x85
.byte 0x19

swc2    $8, 0x659D($a2)
swc1    $f8, -0x2691($s6)
sltiu   $s6, $t4, -0x2691
sh      $t9, -0x7992($t4)
bne     $v0, $t0, 0x163A4
sltiu   $a3, $t2, -0x60DF
lbu     $v0, -0x11A5($v1)
pref    0x1B, 0x362($gp)
pref    7, 0x3173($sp)
blez    $t1, 0xB678
swc1    $f3, flt_CE4($zero)
pref    0x11, -0x704D($t4)
ori     $k1, $s2, 0x1F67
swr     $s6, 0x7533($sp)
swc2    $15, -0x67F4($k0)
ldl     $s3, 0xF2($t7)
bne     $s7, $a3, 0xFFFE973C
sh      $s1, -0x11AA($a2)
bnel    $a1, $t6, 0xFFFE566C
sdr     $s1, -0x4D65($zero)
sd      $s2, -0x24D7($t8)
scd     $s4, 0x5C8D($t7)

.byte 0xA2
.byte 0xE8
.byte 0x5C  # \
.byte 0xED

bgtz    $t3, 0x189A0
sd      $t6, 0x5A2F($t9)
sdc2    $10, 0x3223($k1)
sb      $s3, 0x5744($t9)
lwr     $a2, 0x2C48($a0)
beql    $fp, $s2, 0xFFFF3258
```

同样重要的是要记住，巧妙地运用解压缩和解密技术(包括自修改)，可能看起来像是一段不正确的反汇编代码，但是，它是能够正确运行的(注1)。

注1: 一段代码在经过压缩或者加密之后，他的机器码全都变乱了，因此，反汇编结果得到的是一段错误的反汇编代码。但是经过一段解压缩程序或者解密程序处理之后，它就能够还原出原来的机器码，因此反汇编出来的代码和运行结果都是正确的。
