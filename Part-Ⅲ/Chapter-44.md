# C99的限制

这个例子说明了为什么某些情况下FORTRAN的速度比C/C++要快

```
void f1 (int* x, int* y, int* sum, int* product, int* sum_product, int* update_me, size_t s)
{
    for (int i=0; i<s; i++)
        {
        sum[i]=x[i]+y[i];
        product[i]=x[i]*y[i];
        update_me[i]=i*123; // some dummy value
        sum_product[i]=sum[i]+product[i];
    };
};
```

这是一个十分简单的例子，但是有一点需要注意：指向update_me数组的指针也可以指向sum数组，甚至是sum_product数组。但是这不是严重的错误，对吗？ 编译器很清楚这一点，所以他在循环体中产生了四个阶段： 1.计算下一个sum[i] 2.计算下一个product[i] 3.计算下一个unpdate_me[i] 4.计算下一个sum_product[i],在这个阶段，我们需要从已经计算过sum[i]和product[i]的内存中载入数据

最后一个阶段可以优化吗？既然已经计算过的sum[i]和product[i]是不需要再次从内存装载的（因为我们已经计算过他们了）。但是编译器不能保证在第三个阶段没有东西被覆盖掉！这就叫“指针别名”，在这种情况下编译器无法确定指针指向区域的内存是否已经被改变。

C99标准中的限制给解决这一问题带来了一线曙光。由设计器传送给编译器的函数单元在标记这种关键字(restrict)后，它会指向不同的内存区域，并且不 会被混用。 如果要更加准确地描述这种情况，restrict表明了只有指针是可以访问对象的。这样的话我们可以通过特定的指针进行工作，并且不会用到其他指针。也就是说一个对象如果被标记为restrict，那么它只能通过一个指针访问。 我们把每个指向变量的指针标记为restrict关键字：

```
void f2 (int* restrict x, int* restrict y, int* restrict sum, int* restrict product, int*
restrict sum_product,
int* restrict update_me, size_t s)
{
    for (int i=0; i<s; i++)
    {
        sum[i]=x[i]+y[i];
        product[i]=x[i]*y[i];
        update_me[i]=i*123; // some dummy value
        sum_product[i]=sum[i]+product[i];
    };
};
```

来看下结果：

清单44.1： GCC x64: f1()

```
f1:
    push r15 r14 r13 r12 rbp rdi rsi rbx
    mov r13, QWORD PTR 120[rsp]
    mov rbp, QWORD PTR 104[rsp]
    mov r12, QWORD PTR 112[rsp]
    test r13, r13
    je .L1
    add r13, 1
    xor ebx, ebx
    mov edi, 1
    xor r11d, r11d
    jmp .L4
    .L6:
    mov r11, rdi
    mov rdi, rax
    .L4:
    lea rax, 0[0+r11*4]
    lea r10, [rcx+rax]
    lea r14, [rdx+rax]
    lea rsi, [r8+rax]
    add rax, r9
    mov r15d, DWORD PTR [r10]
    add r15d, DWORD PTR [r14]
    mov DWORD PTR [rsi], r15d ; store to sum[]
    mov r10d, DWORD PTR [r10]
    imul r10d, DWORD PTR [r14]
    mov DWORD PTR [rax], r10d ; store to product[]
    mov DWORD PTR [r12+r11*4], ebx ; store to update_me[]
    add ebx, 123
    mov r10d, DWORD PTR [rsi] ; reload sum[i]
    add r10d, DWORD PTR [rax] ; reload product[i]
    lea rax, 1[rdi]
    cmp rax, r13
    mov DWORD PTR 0[rbp+r11*4], r10d ; store to sum_product[]
    jne .L6
    .L1:
    pop rbx rsi rdi rbp r12 r13 r14 r15
    ret
```

清单44.2： GCC x64: f2()

```
f2:
    push r13 r12 rbp rdi rsi rbx
    mov r13, QWORD PTR 104[rsp]
    mov rbp, QWORD PTR 88[rsp]
    mov r12, QWORD PTR 96[rsp]
    test r13, r13
    je .L7
    add r13, 1
    xor r10d, r10d
    mov edi, 1
    xor eax, eax
    jmp .L10
    .L11:
    mov rax, rdi
    mov rdi, r11
    .L10:
    mov esi, DWORD PTR [rcx+rax*4]
    mov r11d, DWORD PTR [rdx+rax*4]
    mov DWORD PTR [r12+rax*4], r10d ; store to update_me[]
    add r10d, 123
    lea ebx, [rsi+r11]
    imul r11d, esi
    mov DWORD PTR [r8+rax*4], ebx ; store to sum[]
    mov DWORD PTR [r9+rax*4], r11d ; store to product[]
    add r11d, ebx
    mov DWORD PTR 0[rbp+rax*4], r11d ; store to sum_product[]
    lea r11, 1[rdi]
    cmp r11, r13
    jne .L11
    .L7:
    pop rbx rsi rdi rbp r12 r13
    ret
```

被编译过的f1()和f2()的不同点是：在f1()中，sum[i]和product[i]在循环中途被装入，但是在f2()中没有这样的特性。已经计算过的变量将被使用，既然我们已经向编译器“保证”在循环执行期间，sum[i]和product[i]不会发生改变，所以编译器“确信”变量的值不用从内存被再装入。很明显，第二个例子的程序更快。 但是如果函数变量中的指针发生混淆的情况又能如何呢？这与一个程序员的认知有关，并且结果是不正确的。 回到FORTRAN。FORTRAN语言编译器按照指针的本身含义对待他，所以当FORTRAN程序在这种情况下不可能使用restrict的时候，它可以生成生成执行更快的代码。

这有什么实用价值？当函数处理内存中很多大“块”的时候，比如说用超级计算机解决线性代数问题。或许这就是为什么FORTRAN语言还在这个领域被使用。 但是当迭代步骤不是很多的时候，速度的增加并不是显著的。