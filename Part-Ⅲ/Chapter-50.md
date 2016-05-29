# 第五十章
# 花指令

花指令是企图隐藏掉不想被逆向工程的代码块(或其它功能)的一种方法。

## 50.1 文本字符串

我发现在文本字符串使用可能会很有用，程序员意识某字符串不想被逆向工程的时候，可能会试图隐藏掉该字符串，让IDA或者其他十六进制编辑器无法找到。 这里说明一个简单的方法，那就是怎么去构造这样的字符串的实现方式：

```
mov byte ptr [ebx], ’h’
mov byte ptr [ebx+1], ’e’
mov byte ptr [ebx+2], ’l’
mov byte ptr [ebx+3], ’l’
mov byte ptr [ebx+4], ’o’
mov byte ptr [ebx+5], ’ ’
mov byte ptr [ebx+6], ’w’
mov byte ptr [ebx+7], ’o’
mov byte ptr [ebx+8], ’r’
mov byte ptr [ebx+9], ’l’
mov byte ptr [ebx+10], ’d’
```

当两个字符串进行比较的时候看起来是这样：

```
mov ebx, offset username
cmp byte ptr [ebx], ’j’
jnz fail
cmp byte ptr [ebx+1], ’o’
jnz fail
cmp byte ptr [ebx+2], ’h’
jnz fail
cmp byte ptr [ebx+3], ’n’
jnz fail
jz it_is_john
```

在这两种情况下，是不可能通过十六进制编辑器中找到这些字符串的。

顺便提一下，这种方法使得字符串不可能被分配到程序的代码段中。在某些场合可能会用到，比如，在PIC或者在shellcode中。

另一种方法是，我曾经看到用sprintf()构造字符串。

`sprintf(buf, "%s%c%s%c%s", "hel",’l’,"o w",’o’,"rld");`

代码看起来比较怪异，但是做为一个简单的防止逆向工程确实一个有用的方法。 文本字符串也可能存在于加密的形式，那么所有字符串在使用前比较闲将字符串解密了。

## 50.2 可执行代码

### 50.2.1 插入垃圾

可执行代码花指令的意思是在真实的代码中插入一些垃圾代码，但是保证原有程序的执行正确。

举个简单的例子：

```
add eax, ebx
mul ecx
```

代码清单29.1： 花指令

```
xor esi, 011223344h ; garbage
add esi, eax ; garbage
add eax, ebx
mov edx, eax ; garbage
shl edx, 4 ; garbage
mul ecx
xor esi, ecx ; garbage
```

这里的花指令使用原程序代码中没有使用的寄存器(ESI和EDX)。无论如何，增加花指令之后，原有的汇编代码变得更为枯涩难懂，从而达到不轻易被逆向工程的效果。

### 50.2.2 替换与原有指令等价的指令

```
mov op1, op2可以替换为 push op2/pop op1这两条指令。
jmp label可以替换为 push label/ret这两条指令，IDA将不会显示被引用的label。
call label可以替换为push label_after_call_instruction/push label/ref这三条指令。
push op可以替换为 sub esp, 4(或者8)/mov [esp], op这两条指令。
```

### 50.2.3 绝对被执行的代码与绝对不被执行的代码

如果开发人员肯定ESI寄存器始终为0：

```
    mov esi, 1
    ... ; some code not touching ESI
    dec esi
    ... ; some code not touching ESI
    cmp esi, 0
    jz real_code
    ;fakeluggage
real_code:
```

逆向工程需要一段时间才能够执行到real_code。这也被称为opaque predicate。 另一个例子(同上，假设可以肯定ESI寄存器始终为0):

```
add eax, ebx ; real code
mul ecx ; real code
add eax, esi ; opaque predicate. XOR, AND or SHL, etc, can be here instead of ADD.
```

### 50.2.4打乱执行流程

举个例子，比如执行下面这三条指令：

```
instruction 1
instruction 2
instruction 3
```

可以被替换为：

```
begin: 
    jmp ins1_label
ins2_label: 
    instruction 2
    jmp ins3_label
ins3_label: 
    instruction 3
    jmp exit
ins1_label: 
    instruction 1
    jmp ins2_label
exit:
```

### 50.2.4使用间接指针

```
dummy_data1 db 100h dup (0)
message1 db ’hello world’,0

dummy_data2 db 200h dup (0)
message2 db ’another message’,0

func proc
    ...
    mov eax, offset dummy_data1 ; PE or ELF reloc here
    add eax, 100h
    push eax
    call dump_string
    ...
    mov eax, offset dummy_data2 ; PE or ELF reloc here
    add eax, 200h
    push eax
    call dump_string
    ...
func endp
```

IDA仅会显示dummy_data1和dummy_data2的引用，但无法引导到文本字符串，全局变量甚至是函数的访问方式都可能使用这种方法以达到混淆代码的目地。

## 50.3 虚拟机/伪代码

程序员可能写一个PL或者ISA来解释程序(例如Visual Basic 5.0与之前的版本, .NET, Java machine)。这使得逆向工程不得不花费更多的时间去了解这些语言它们的所有ISP指令详细信息。更有甚者，他们可能需要编写其中某些语言的反汇编器。

## 50.4 其它

我为TCC(Tiny C compiler)添加一个产生花指令功能的补丁：http://blog.yurichev.com/node/58。

## 50.5练习

* http://challenges.re/29