# 第九章
# 一个或者多个字的返回值

X86架构下通常返回EAX寄存器的值，如果是单字节char，则只使用EAX的低8位AL。如果返回float类型则使用FPU寄存器ST(0)。ARM架构下通常返回寄存器R0。

## 9.1 尝试用函数的返回值返回void
假如main()函数的返回值是void而不是int会怎么样？

通常启动函数调用main()为：

```
push envp
push argv
push argc
call main
push eax
call exit
```

换句话说为

`exit(main(argc,argv,envp));`

如果main()声明为void类型并且函数没有明确返回状态值，通常在main()结束时EAX寄存器的值被返回，然后作为exit()的参数。大多数情况下函数返回的是随机值。这种情况下程序的退出代码为伪随机的。

我们看一个实例，注意main()是void类型：

```
#include <stdio.h>
void main()
{
    printf ("Hello, world!");
};
```

我们在linux下编译。

GCC 4.8.1会使用puts()替代printf()（看前面章节2.3.3），没有关系，因为puts()会返回打印的字符数，就行printf()一样。请注意，main()结束时EAX寄存器的值是非0的，这意味着main()结束时保留puts()返回时EAX的值。

Listing 9.1: GCC 4.8.1

```
.LC0:
        .string "Hello, world!"
main:
        push    ebp
        mov     ebp, esp
        and     esp, -16
        sub     esp, 16
        mov     DWORD PTR [esp], OFFSET FLAT:.LC0
        call    puts
        leave
        ret
```

我们写bash脚本来看退出状态：

Listing 9.2: tst.sh

```
#!/bin/sh
./hello_world
echo $?
```

运行：

```
$ tst.sh
Hello, world!
14
```

14为打印的字符数。

## 9.2 如果我们不使用返回值会发生什么？

##　9.3 返回一个结构体

回到返回值是EAX寄存器值的事实，这也就是为什么老的C编译器不能够创建返回信息无法拟合到一个寄存器（通常是int型）的函数。如果必须这样，应该通过指针来传递。现在可以这样，比如返回整个结构体，这种情况应该避免。如果必须要返回大的结构体，调用者必须开辟存储空间，并通过第一个参数传递指针，整个过程对程序是透明的。像手动通过第一个参数传递指针一样，只是编译器隐藏了这个过程。

小例子：

```
struct s
{
    int a;
    int b;
    int c;
};

struct s get_some_values (int a)
{
    struct s rt;
    rt.a=a+1;
    rt.b=a+2;
    rt.c=a+3;

    return rt;
};
```

…我们可以得到(MSVC 2010 /Ox):

```
$T3853 = 8                  ; size = 4
_a$ = 12                    ; size = 4
?get_some_values@@YA?AUs@@H@Z PROC      ; get_some_values
    mov     ecx, DWORD PTR _a$[esp-4]
    mov     eax, DWORD PTR $T3853[esp-4]
    lea     edx, DWORD PTR [ecx+1]
    mov     DWORD PTR [eax], edx
    lea     edx, DWORD PTR [ecx+2]
    add     ecx, 3
    mov     DWORD PTR [eax+4], edx
    mov     DWORD PTR [eax+8], ecx
    ret     0
?get_some_values@@YA?AUs@@H@Z ENDP      ; get_some_values
```

内部变量传递指针到结构体的宏为$T3853。

这个例子可以用C99语言扩展来重写：

```
struct s
{
    int a;
    int b;
    int c;
};

struct s get_some_values (int a)
{
    return (struct s){.a=a+1, .b=a+2, .c=a+3};
};
```

Listing 9.3: GCC 4.8.1

```
_get_some_values proc near

ptr_to_struct   = dword ptr 4
a               = dword ptr 8
                mov     edx, [esp+a]
                mov     eax, [esp+ptr_to_struct]
                lea     ecx, [edx+1]
                mov     [eax], ecx
                lea     ecx, [edx+2]
                add     edx, 3
                mov     [eax+4], ecx
                mov     [eax+8], edx
                retn
_get_some_values endp
```

我们可以看到，函数仅仅填充调用者申请的结构体空间的相应字段。因此没有性能缺陷。
