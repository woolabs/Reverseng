# ostream

继续以一个hello world程序为例，但是这次使用ostream

```
#include <iostream>
int main()
{
    std::cout << "Hello, world!\n";
}
```

几乎所有关于c++的书籍都会提到<<操作支持很多数据类型。这些支持是在ostream中完成的。通过反汇编之后的代码，可以看到ostream中的<<操作被调用：

```
$SG37112 DB ’Hello, world!’, 0aH, 00H
_main PROC
push OFFSET $SG37112
push OFFSET ?cout@std@@3V?$basic_ostream@DU?$char_traits@D@std@@@1@A ; std::cout
call ??$?6U?$char_traits@D@std@@@std@@YAAAV?$basic_ostream@DU?
$char_traits@D@std@@@0@AAV10@PBD@Z ; std::operator<<<std::char_traits<char> >
add esp, 8
xor eax, eax
ret 0
_main ENDP
```

对示例程序做如下修改：

```
#include <iostream>
int main()
{
    std::cout << "Hello, " << "world!\n";
}
```

同样的，从许多C++书籍中可以知道，ostream的输出操作的运算结果可以用作下一次输出（即ostream的输出操作返回ostream对象）。

```
$SG37112 DB ’world!’, 0aH, 00H
$SG37113 DB ’Hello, ’, 00H
_main PROC
push OFFSET $SG37113 ; ’Hello, ’
push OFFSET ?cout@std@@3V?$basic_ostream@DU?$char_traits@D@std@@@1@A ; std::cout
call ??$?6U?$char_traits@D@std@@@std@@YAAAV?$basic_ostream@DU?
$char_traits@D@std@@@0@AAV10@PBD@Z ; std::operator<<<std::char_traits<char> >
add esp, 8
push OFFSET $SG37112 ; ’world!’
push eax ; result of previous function
call ??$?6U?$char_traits@D@std@@@std@@YAAAV?$basic_ostream@DU?
$char_traits@D@std@@@0@AAV10@PBD@Z ; std::operator<<<std::char_traits<char> >
add esp, 8
xor eax, eax
ret 0
_main ENDP
```

如果用函数f()替换<<运算符，示例代码等价于：

`f(f(std::cout, "Hello, "), "world!")`

通过GCC生成的代码和MSVC的代码基本相同。

引用： 在c++中，引用和指针一样，但是使用的时候更安全，因为在使用引用的时候几乎不会发生错误。例如，引用必须始终指向一个相应类型的对象，而不能为NULL。甚至于，引用不能被改变，不能将一个对象的引用重新赋值以指向另一个对象。 如果我们尝试修改指针的例子（9），将指针替换为引用：

```
void f2 (int x, int y, int & sum, int & product)
{
    sum=x+y;
    product=x*y;
};
```

可以想到，编译后的代码和使用指针生成的代码一致。

```
_x$ = 8 ; size = 4
_y$ = 12 ; size = 4
_sum$ = 16 ; size = 4
_product$ = 20 ; size = 4
?f2@@YAXHHAAH0@Z PROC ; f2
mov ecx, DWORD PTR _y$[esp-4]
mov eax, DWORD PTR _x$[esp-4]
lea edx, DWORD PTR [eax+ecx]
imul eax, ecx
mov ecx, DWORD PTR _product$[esp-4]
push esi
mov esi, DWORD PTR _sum$[esp]
mov DWORD PTR [esi], edx
mov DWORD PTR [ecx], eax
pop esi
ret 0
?f2@@YAXHHAAH0@Z ENDP ; f2
```