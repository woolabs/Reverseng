# 内联函数

内联代码是指当编译的时候，将函数体直接嵌入正确位置，而不是在这个位置放上函数声明。

```
#include <stdio.h>
int celsius_to_fahrenheit (int celsius)
{
    return celsius * 9 / 5 + 32;
};
int main(int argc, char *argv[])
{
    int celsius=atol(argv[1]);
    printf ("%d\n", celsius_to_fahrenheit (celsius));
};
```

这个编译是意料之中的，但是如果换成GCC的优化方案，我们会看到：

清单27.2: GCC 4.8.1 -O3

```
_main:
    push ebp
    mov ebp, esp
    and esp, -16
    sub esp, 16
    call ___main
    mov eax, DWORD PTR [ebp+12]
    mov eax, DWORD PTR [eax+4]
    mov DWORD PTR [esp], eax
    call _atol
    mov edx, 1717986919
    mov DWORD PTR [esp], OFFSET FLAT:LC2 ; "%d\12\0"
    lea ecx, [eax+eax*8]
    mov eax, ecx
    imul edx
    sar ecx, 31
    sar edx
    sub edx, ecx
    add edx, 32
    mov DWORD PTR [esp+4], edx
    call _printf
    leave
    ret
```

这里的除法由乘法完成。 是的，我们的小函数被放到了printf()调用之前。为什么？因为这比直接执行函数之前的“调用/返回”过程速度更快。 在过去，这样的函数在函数声明的时候必须被标记为“内联”。在现代，这样的函数会自动被编译器识别。 另外一个普通的自动优化的例子是内联字符串函数，比如strcpy(),strcmp()等

清单27.3 : 另一个简单的例子

```
bool is_bool (char *s)
{
    if (strcmp (s, "true")==0)
    return true;
    if (strcmp (s, "false")==0)
    return false;
    assert(0);
};
```

清单27.4： GCC 4.8.1 -O3

```
_is_bool:
    push edi
    mov ecx, 5
    push esi
    mov edi, OFFSET FLAT:LC0 ; "true\0"
    sub esp, 20
    mov esi, DWORD PTR [esp+32]
    repz cmpsb
    je L3
    mov esi, DWORD PTR [esp+32]
    mov ecx, 6
    mov edi, OFFSET FLAT:LC1 ; "false\0"
    repz cmpsb
    seta cl
    setb dl
    xor eax, eax
    cmp cl, dl
    jne L8
    add esp, 20
    pop esi
    pop edi
    ret
```

这是一个经常可以见到的关于MSVC生成的strcmp()的例子。

清单27.5: MSVC

```
    mov dl, [eax]
    cmp dl, [ecx]
    jnz short loc_10027FA0
    test dl, dl
    jz short loc_10027F9C
    mov dl, [eax+1]
    cmp dl, [ecx+1]
    jnz short loc_10027FA0
    add eax, 2
    add ecx, 2
    test dl, dl
    jnz short loc_10027F80
    loc_10027F9C: ; CODE XREF: f1+448
    xor eax, eax
    jmp short loc_10027FA5
; ---------------------------------------------------------------------------
    loc_10027FA0: ; CODE XREF: f1+444
; f1+450
    sbb eax, eax
    sbb eax, 0FFFFFFFFh
```

我写了一个小的用于搜索和归纳的IDA脚本，这样的脚本经常能在内联代码中看到：[IDA_scripts](https://github.com/yurichev/IDA_scripts).