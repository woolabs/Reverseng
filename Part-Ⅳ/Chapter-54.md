# 第五十四章
# JAVA

## 54.1介绍
大家都知道，java有很多的反编译器（或是产生JVM字节码）
原因是JVM字节码比其他的X86低级代码更容易进行反编译。

- 多很多相关数据类型的信息。
- JVM（java虚拟机）内存模型更严格和概括。
- java编译器没有做任何的优化工作（JVM JIT不是实时），所以，类文件中的字节代码的通常更清晰易读。

JVM字节码知识什么时候有用呢？

- 文件的快速粗糙的打补丁任务，类文件不需要重新编译反编译的结果。
- 分析混淆代码
- 创建你自己的混淆器。
- 创建编译器代码生成器（后端）目标。

我们从一段简短的代码开始，除非特殊声明，我们用的都是JDK1.7

反编译类文件使用的命令，随处可见：javap -c -verbase.

在这本书中提供的很多的例子，都用到了这个。


## 54.2 返回一个值

可能最简单的java函数就是返回一些值，oh，并且我们必须注意，一边情况下，在java中没有孤立存在的函数，他们是“方法”(method)，每个方法都是被关联到某些类，所以方法不会被定义在类外面， 但是我还是叫他们“函数”
(function),我这么用。


    public class ret
    {
    public static int main(String[] args)
    {
    return 0;
    }
    }
    

编译它。
    
    javac ret.java

。。。使用Java标准工具反编译。

    javap -c -verbose ret.class
    
会得到结果：

    public static int main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=1, args_size=1
    0: iconst_0
    1: ireturn

对于java开发者在编程中，0是使用频率最高的常量。
因为区分短一个短字节的 iconst_0指令入栈0，iconst_1指令（入栈），iconst_2等等，直到iconst5。也可以有iconst_m1, 推送-1。


就像在MIPS中，分离一个寄存器给0常数：3.5.2 在第三页。

栈在JVM中用于在函数调用时，传参和传返回值。因此， iconst_0是将0入栈，ireturn指令，（i就是integer的意思。）是从栈顶返回整数值。

［校准到这,未完待续...］

让我们写一个简单的例子， 现在我们返回1234：

    public class ret
    {
    public static int main(String[] args)
    {
    return 1234;
    }
    }

我们得到：

清单：  54.2:jdk1.7(节选)
    public static int main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=1, args_size=1
    0: sipush 1234
    3: ireturn
    
sipush(shot integer)如栈值是1234,slot的名字以为着一个16bytes值将会入栈。
sipush(短整型)
1234数值确认时候16-bit值。

    public class ret
    {
    public static int main(String[] args)
    {
    return 12345678;
    }
    }
    
更大的值是什么？

清单 54.3 常量区


    ...
    #2 = Integer 12345678
    ...
5栈顶


    public static int main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATI
    Code:
    stack=1, locals=1, args_size=1
    0: ldc #2 // int 12345678
    2: ireturn


操作码
JVM的指令码操作码不可能编码成32位数，开发者放弃这种可能。因此，32位数字12345678是被存储在一个叫做常量区的地方。让我们说（大多数被使用的常数（包括字符，对象等等车））
对我们而言。

对JVM来说传递常量不是唯一的，MIPS ARM和其他的RISC CPUS也不可能把32位操作编码成32位数字，因此 RISC CPU（包括MIPS和ARM）去构造一个值需要一系列的步骤，或是他们保存在数据段中：
28。3 在654页.291 在695页。

MIPS码也有一个传统的常量区，literal pool(原语区)
这个段被叫做"lit4"(对于32位单精度浮点数常数存储)
和lit8(64位双精度浮点整数常量区)

布尔型

    public class ret
    {
    public static boolean main(String[] args)
    {
    return true;
    }
    }



    public static boolean main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=1, args_size=1
    0: iconst_1


这个JVM字节码是不同于返回的整数学 ，32位数据，在形参中被当成逻辑值使用。像C/C++，但是不能像使用整型或是viceversa返回布尔型，类型信息被存储在类文件中，在运行时检查。

16位短整型也是一样。

    public class ret
    {
    
    public static short main(String[] args)
    {
    return 1234;
    }
    }
    public static short main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=1, args_size=1
    0: sipush 1234
    3: ireturn

还有char 字符型？

    public class ret
    {
    public static char main(String[] args)
    {
    return 'A';
    }
    }
    public static char main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=1, args_size=1
    0: bipush 65
    2: ireturn


bipush 的意思"push byte"字节入栈，不必说java的char是16位UTF16字符，和short 短整型相等，单ASCII码的A字符是65，它可能使用指令传输字节到栈。

让我们是试一下byte。

    public class retc
    {
    public static byte main(String[] args)
    {
    return 123;
    }
    }
    public static byte main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    
    Code:
    stack=1, locals=1, args_size=1
    0: bipush 123
    2: ireturn


也许会问，位什么费事用两个16位整型当32位用？为什么char数据类型和短整型类型还使用char.

答案很简单，为了数据类型的控制和代码的可读性。char也许本质上short相同，但是我们快速的掌握它的占位符，16位的UTF字符，并且不像其他的integer值符。使用 short,为各位展现一下变量的范围被限制在16位。在需要的地方使用boolean型也是一个很好的主意。代替C样式的int也是为了相同的目的。

在java中integer的64位数据类型。

    public class ret3
    {
    public static long main(String[] args)
    {
    return 1234567890123456789L;
    }
    }

清单54.4常量区

    ...
    #2 = Long 1234567890123456789l
    ...
    public static long main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=1, args_size=1
    0: ldc2_w #2 // long ⤦
    Ç 1234567890123456789l
    3: lreturn


64位数也被在存储在常量区，ldc2_w 加载它，lreturn返回它。 ldc2_w指令也是从内存常量区中加载双精度浮点数。（同样占64位）


    public class ret
    {
    public static double main(String[] args)
    {
    return 123.456d;
    }
    }
    
清单54.5常量区

    ...
    #2 = Double 123.456d
    ...
    public static double main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=1, args_size=1
    0: ldc2_w #2 // double 123.456⤦
    Ç d
    3: dreturn


dreturn 代表 "return double"

最后，单精度浮点数：

    public class ret
    {
    public static float main(String[] args)
    {
    return 123.456f;
    }
    }

清单54.6 常量区

    ...
    #2 = Float 123.456f
    ...
    public static float main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=1, args_size=1
    0: ldc #2 // float 123.456f
    2: freturn

此处的ldc指令使用和32位整型数据一样，从常量区中加载。freturn 的意思是"return float"




那么函数还能返回什么呢？

    
    public class ret
    {
    public static void main(String[] args)
    {
    return;
    }
    }
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=0, locals=1, args_size=1
    0: return


这以为着，使用return控制指令确没有返回实际的值，知道这一点就非常容易的从最后一条指令中演绎出函数（或是方法）的返回类型。

## 54.3 简单的计算函数

让我们继续看简单的计算函数。

    public class calc
    {
    public static int half(int a)
    {
    return a/2;
    }
    }

这种情况使用icont_2会被使用。

    public static int half(int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=1, args_size=1
    0: iload_0
    1: iconst_2
    2: idiv
    3: ireturn

iload_0 将零给函数做参数，然后将其入栈。iconst_2将2入栈，这两个指令执行后，栈看上去是这个样子的。

    +---+
    TOS ->| 2 |
    +---+
    | a |
    +---+


idiv携带两个值在栈顶，
divides 只有一个值，返回结果在栈顶。

    +--------+
    TOS ->| result |
    +--------+

ireturn取得比返回。
让我们处理双精度浮点整数。

    public class calc
    {
    public static double half_double(double a)
    {
    return a/2.0;
    }
    }
    

清单54.7 常量区

    ...
    #2 = Double 2.0d
    ...
    public static double half_double(double);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=4, locals=2, args_size=1
    0: dload_0
    1: ldc2_w #2 // double 2.0d
    4: ddiv
    5: dreturn


类似，只是ldc2_w指令是从常量区装载2.0，另外，所有其他三条指令有d前缀，意思是他们工作在double数据类型下。

我们现在使用两个参数的函数。
    
    public class calc
    {
    public static int sum(int a, int b)
    {
    return a+b;
    }
    }
    public static int sum(int, int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=2, args_size=2
    0: iload_0
    1: iload_1
    2: iadd
    3: ireturn


iload_0加载第一个函数参数（a)，iload_2 第二个参数(b)下面两条指令执行后，栈的情况如下：

    +---+
    TOS ->| b |
    +---+
    | a |
    +---+


iadds 增加两个值，返回结果在栈顶。
    +--------+
    TOS ->| result |
    +--------+


让我们把这个例子扩展成长整型数据类型。

    public static long lsum(long a, long b)
    {
    return a+b;
    }

我们得到的是：

    public static long lsum(long, long);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=4, locals=4, args_size=2
    0: lload_0
    1: lload_2
    2: ladd
    3: lreturn

第二个（load指令从第二参数槽中，取得第二参数。这是因为64位长整型的值占用来位，用了另外的话2位参数槽。）

稍微复杂的例子

    public class calc
    {
    public static int mult_add(int a, int b, int c)
    {
    return a*b+c;
    }
    }
    public static int mult_add(int, int, int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=3, args_size=3
    0: iload_0
    1: iload_1
    2: imul
    3: iload_2
    4: iadd
    5: ireturn

第一是相乘，积被存储在栈顶。

    +---------+
    TOS ->| product |
    +---------+
iload_2加载第三个参数（C）入栈。

    +---------+
    TOS ->| c |
    +---------+
    | product |
    +---------+

现在iadd指令可以相加两个值。


## 54.4 JVM内存模型

X86和其他低级环境系统使用栈传递参数和存储本地变量，JVM稍微有些不同。

主要体现在：
本地变量数组（LVA）被用于存储到来函数的参数和本地变量。iload_0指令是从其中加载值，istore存储值在其中，首先，函数参数到达：开始从0 或者1(如果0参被this指针用。)，那么本地局部变量被分配。

每个槽子的大小都是32位，因此long和double数据类型都占两个槽。

操作数栈（或只是"栈"），被用于在其他函数调用时，计算和传递参数。不像低级X86的环境，它不能去访问栈，而又不明确的使用pushes和pops指令，进行出入栈操作。


## 54.5 简单的函数调用
mathrandom()返回一个伪随机数，函数范围在「0.0...1.0)之间，但对我们来说，由于一些原因，我们常常需要设计一个函数返回数值范围在「0.0...0.5)


    public class HalfRandom
    {
    public static double f()
    {
    return Math.random()/2;
    }
    }
    


54.8 常量区

    ...
    #2 = Methodref #18.#19 // java/lang/Math.⤦
    Ç random:()D
    6(Java) Local Variable Array
    
    #3 = Double 2.0d
    ...
    #12 = Utf8 ()D
    ...
    #18 = Class #22 // java/lang/Math
    #19 = NameAndType #23:#12 // random:()D
    #22 = Utf8 java/lang/Math
    #23 = Utf8 random
    public static double f();
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=4, locals=0, args_size=0
    0: invokestatic #2 // Method java/⤦
    Ç lang/Math.random:()D
    3: ldc2_w #3 // double 2.0d
    6: ddiv
    7: dreturn

java本地变量数组
916
静态执行调用math.random()函数，返回值在栈顶。结果是被0.5初返回的，但函数名是怎么被编码的呢？
在常量区使用methodres表达式,进行编码的，它定义类和方法的名称。第一个methodref 字段指向表达式，其次，指向通常文本字符（"java/lang/math"）
第二个methodref表达指向名字和类型表达式，同时链接两个字符。第一个方法的名字式字符串"random",第二个字符串是"()D",来编码函数类型，它以为这两个值（因此D是字符串）这种方式1JVM可以检查数据类型的正确性：2）java反编译器可以从被编译的类文件中修改数据类型。

最后，我们试着使用"hello，world！"作为例子。

    public class HelloWorld
    {
    public static void main(String[] args)
    {
    System.out.println("Hello, World");
    }
    }


54.9 常量区


常量区的ldc行偏移3，指向"hello，world！"字符串，并且将其入栈，在java里它被成为饮用，其实它就是指针，或是地址。


    ...
    #2 = Fieldref #16.#17 // java/lang/System.⤦
    Ç out:Ljava/io/PrintStream;
    #3 = String #18 // Hello, World
    #4 = Methodref #19.#20 // java/io/⤦
    Ç PrintStream.println:(Ljava/lang/String;)V
    ...
    #16 = Class #23 // java/lang/System
    #17 = NameAndType #24:#25 // out:Ljava/io/⤦
    Ç PrintStream;
    #18 = Utf8 Hello, World
    #19 = Class #26 // java/io/⤦
    Ç PrintStream
    #20 = NameAndType #27:#28 // println:(Ljava/⤦
    Ç lang/String;)V
    ...
    #23 = Utf8 java/lang/System
    #24 = Utf8 out
    #25 = Utf8 Ljava/io/PrintStream;
    #26 = Utf8 java/io/PrintStream
    #27 = Utf8 println
    #28 = Utf8 (Ljava/lang/String;)V
    ...
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=1, args_size=1
    0: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    3: ldc #3 // String Hello, ⤦
    Ç World
    5: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    8: return

常见的invokevirtual指令，从常量区取信息，然后调用pringln()方法，貌似我们知道的println()方法，适用于各种数据类型，我这种println()函数版本，预先给的是字符串类型。

但是第一个getstatic指令是干什么的？这条指令取得对象信息的字段的一个引用或是地址。输出并将其进栈，这个值实际更像是println放的指针，因此，内部的print method取得两个参数，输入1指向对象的this指针，2）"hello，world"字符串的地址，确实，println()在被初始化系统的调用，对象之外，为了方便，javap使用工具把所有的信息都写入到注释中。


## 54.6  调用beep()函数
这可能是最简单的，不使用参数的调用两个函数。


    public static void main(String[] args)
    {
    java.awt.Toolkit.getDefaultToolkit().beep();
    };
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=1, args_size=1
    0: invokestatic #2 // Method java/⤦
    Ç awt/Toolkit.getDefaultToolkit:()Ljava/awt/Toolkit;
    3: invokevirtual #3 // Method java/⤦
    Ç awt/Toolkit.beep:()V
    6: return


首先，invokestatic在0行偏移调用javaawt.toolkit. getDefaultTookKit()函数,返回toolkit类对象的引用，invokedvirtualIFge指令在3行偏移，调用这个类的beep（）方法。


## 54.7 线性同余伪随机数生成器
我们来试一个简单的伪随机函数生成器，我已经在这本书中用过一次了。（在500页20行）



    public class LCG
    {
    public static int rand_state;
    public void my_srand (int init)
    {
    rand_state=init;
    }
    public static int RNG_a=1664525;
    public static int RNG_c=1013904223;
    
    public int my_rand ()
    {
    rand_state=rand_state*RNG_a;
    rand_state=rand_state+RNG_c;
    return rand_state & 0x7fff;
    }
    }


一对类的字段，在最开始时被初始化。但是怎么能，在javap的输出中，发现类的构造呢？

    static {};
    flags: ACC_STATIC
    Code:
    stack=1, locals=0, args_size=0
    0: ldc #5 // int 1664525
    2: putstatic #3 // Field RNG_a:I
    5: ldc #6 // int 1013904223
    7: putstatic #4 // Field RNG_c:I
    10: return

这种变量的初始化，RNG_a占用了3个参数槽，iRNG_C是4个，而puststatic指令是，用于设定常量。

my_srand()函数，只是将输入值，存储到rand_state中;

    public void my_srand(int);
    flags: ACC_PUBLIC
    Code:
    stack=1, locals=2, args_size=2
    0: iload_1
    1: putstatic #2 // Field ⤦
    Ç rand_state:I
    4: return

 iload_1 取得输入值并将其入栈。但为什么不用iload_0?因为这个函数可能使用类的字段属性，因此这个变量被作为参数0传递给了函数，rand_state字段属性，在类中占用2个参数槽子。

现在my_rand():

    public int my_rand();
    flags: ACC_PUBLIC
    Code:
    stack=2, locals=1, args_size=1
    0: getstatic #2 // Field ⤦
    Ç rand_state:I
    3: getstatic #3 // Field RNG_a:I
    6: imul
    7: putstatic #2 // Field ⤦
    Ç rand_state:I
    10: getstatic #2 // Field ⤦
    Ç rand_state:I
    13: getstatic #4 // Field RNG_c:I
    16: iadd
    17: putstatic #2 // Field ⤦
    Ç rand_state:I
    20: getstatic #2 // Field ⤦
    Ç rand_state:I
    23: sipush 32767
    26: iand
    27: ireturn

它仅是加载了所有对象字段的值。在20行偏移，操作和更新rand_state，使用putstatic指令。

 rand_state 值被再次重载（因为之前，使用过putstatic指令，其被从栈中弃出）这种代码其实比较低效率，但是可以肯定的是，JVM会经常的，对其进行很好的优化。

## 54.8 条件跳转
让我们进入条件跳转

    public class abs
    {
    public static int abs(int a)
    {
    if (a<0)
    return -a;
    return a;
    }
    }
    public static int abs(int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=1, args_size=1
    0: iload_0
    1: ifge 7
    4: iload_0
    5: ineg
    6: ireturn
    7: iload_0
    8: ireturn


ifge跳转到7行偏移，如果栈顶的值大于等于0，别忘了，任何IFXX指令从栈中pop出栈值（用于进行比较）

另外一个例子

    public static int min (int a, int b)
    {
    if (a>b)
    return b;
    return a;
    }


我们得到的是：

    public static int min(int, int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=2, args_size=2
    0: iload_0
    1: iload_1
    2: if_icmple 7
    5: iload_1
    6: ireturn
    7: iload_0
    8: ireturn

if_icmple出栈两个值并比较他们，如果第三个子值比第一个值小（或者等于）发生跳转到行偏移7.

当我们定义max()函数。

    public static int max (int a, int b)
    {
    if (a>b)
    return a;
    return b;
    }

。。。结果代码是是一样的，但是最后两个iload指令（行偏移5和行偏移7）被跳转了。

    public static int max(int, int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=2, args_size=2
    0: iload_0
    1: iload_1
    2: if_icmple 7
    5: iload_0
    6: ireturn
    7: iload_1
    8: ireturn


更复杂的例子。。

    public class cond
    {
    public static void f(int i)
    {
    if (i<100)
    System.out.print("<100");
    if (i==100)
    System.out.print("==100");
    if (i>100)
    System.out.print(">100");
    if (i==0)
    System.out.print("==0");
    }
    }
    public static void f(int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=1, args_size=1
    0: iload_0
    1: bipush 100
    3: if_icmpge 14
    6: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    9: ldc #3 // String <100
    11: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.print:(Ljava/lang/String;)V
    14: iload_0
    15: bipush 100
    17: if_icmpne 28
    20: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    23: ldc #5 // String ==100
    25: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.print:(Ljava/lang/String;)V
    28: iload_0
    29: bipush 100
    31: if_icmple 42
    34: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    37: ldc #6 // String >100
    39: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.print:(Ljava/lang/String;)V
    42: iload_0
    43: ifne 54
    46: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    49: ldc #7 // String ==0
    51: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.print:(Ljava/lang/String;)V
    54: return
    

if_icmpge出栈两个值，并且比较它们，如果第的二个值大于第一个，发生跳转到行偏移14，if_icmpne和if_icmple做的工作类似，但是使用不同的判断条件。

在行偏移43的ifne指令，它的名字不是很恰当，我要愿意把它命名为ifnz

如果栈定的值不是0跳转，但是这是怎么做的，总跳转到行偏移54，如果输入的值不是另，如果是0，执行流程进入行偏移46，“==”字符串被打印。

N.BJVM没有无符号数据类型，所以，比较指令的操作数，只有还有符号整数值。


## 54.9 传递参数值

我们来扩展一下min()/max()这个例子。


    public class minmax
    {
    public static int min (int a, int b)
    {
    if (a>b)
    return b;
    return a;
    }
    public static int max (int a, int b)
    {
    if (a>b)
    return a;
    return b;
    }
    public static void main(String[] args)
    {
    int a=123, b=456;
    int max_value=max(a, b);
    int min_value=min(a, b);
    System.out.println(min_value);
    System.out.println(max_value);
    }
    }


这是main()函数的代码。

    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=5, args_size=1
    0: bipush 123
    2: istore_1
    3: sipush 456
    6: istore_2
    7: iload_1
    8: iload_2
    9: invokestatic #2 // Method max:(II⤦
    Ç )I
    12: istore_3
    13: iload_1
    14: iload_2
    15: invokestatic #3 // Method min:(II⤦
    Ç )I
    18: istore 4
    20: getstatic #4 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    23: iload 4
    25: invokevirtual #5 // Method java/io⤦
    Ç /PrintStream.println:(I)V
    28: getstatic #4 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    31: iload_3
    32: invokevirtual #5 // Method java/io⤦
    Ç /PrintStream.println:(I)V
    35: return

参数在栈中的被传给其他函数，返回值在栈顶。


## 54.10位。

所有位操作工作，与其他的一些ISA（指令集架构）类似：

    public static int set (int a, int b)
    {
    return a | 1<<b;
    }
    public static int clear (int a, int b)
    {
    return a & (~(1<<b));
    }
    public static int set(int, int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=2, args_size=2
    0: iload_0
    1: iconst_1
    2: iload_1
    3: ishl
    4: ior
    5: ireturn
    public static int clear(int, int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=2, args_size=2
    0: iload_0
    1: iconst_1
    2: iload_1
    3: ishl
    4: iconst_m1
    5: ixor
    6: iand
    7: ireturn


iconst_m1将-1入栈，这数其实就是16进制的0xFFFFFFFF，将0xFFFFFFFF作为XOR-ing指令执行的操作数。起到的效果就是把所有bits位反向，（A.6.2在1406页）

我将所有数据类型，扩展成64为长整型。

    public static long lset (long a, int b)
    {
    return a | 1<<b;
    }
    public static long lclear (long a, int b)
    {
    return a & (~(1<<b));
    }
    public static long lset(long, int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=4, locals=3, args_size=2
    0: lload_0
    1: iconst_1
    2: iload_2
    3: ishl
    4: i2l
    5: lor
    6: lreturn
    public static long lclear(long, int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=4, locals=3, args_size=2
    0: lload_0
    1: iconst_1
    2: iload_2
    3: ishl
    4: iconst_m1
    5: ixor
    6: i2l
    7: land
    8: lreturn
    
代码是相同的，但是指令前面使用了前缀L，操作64位值，并且第二个函数参数还是int类型，并且32值需要升级为64位值，值被i21指令使用，本质上
就是把整型，扩展成64位长整型.


## 54.11循环

    
    public class Loop
    {
    public static void main(String[] args)
    {
    for (int i = 1; i <= 10; i++)
    {
    System.out.println(i);
    }
    }
    }
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=2, args_size=1
    0: iconst_1
    1: istore_1
    2: iload_1
    3: bipush 10
    5: if_icmpgt 21
    8: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    11: iload_1
    12: invokevirtual #3 // Method java/io⤦
    Ç /PrintStream.println:(I)V
    15: iinc 1, 1
    18: goto 2
    21: return


icont_1将1推入到栈顶，istore_1将其存入到LVA的参数槽1，为什么没有零槽？因为main()函数只有一个参数，并且指向其的引用，就在第0号槽中。

因此，i本地变量总是在1号参数槽中。
指令在行3偏移和行5偏移，将i和10的比较。如果i大，执行流进入行21偏移，函数结束了，如果不被println调用。i在行11偏移进行了重新加载，之后给println使用。

多说一句，我们调用pringln打印数据类型是整型，我们看注释，“i，v”，i的意思是整型，v的意思是返回void。

当println函数结束，i是步进到行15偏移，指令第一个操作数是参数槽1的值。第二个是数值1与本地变量相加结果。

goto指令就是跳转，它跳转到循环体的开始地址，再行偏移2.


让我们进行更复杂的例子。

    public class Fibonacci
    {
    public static void main(String[] args)
    {
    int limit = 20, f = 0, g = 1;
    for (int i = 1; i <= limit; i++)
    {
    f = f + g;
    g = f - g;
    System.out.println(f);
    }
    }
    }
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=5, args_size=1
    0: bipush 20
    2: istore_1
    3: iconst_0
    4: istore_2
    5: iconst_1
    6: istore_3
    7: iconst_1
    8: istore 4
    10: iload 4
    12: iload_1
    13: if_icmpgt 37
    16: iload_2
    17: iload_3
    18: iadd
    19: istore_2
    20: iload_2
    21: iload_3
    22: isub
    23: istore_3
    24: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    27: iload_2
    28: invokevirtual #3 // Method java/io⤦
    Ç /PrintStream.println:(I)V
    31: iinc 4, 1
    34: goto 10
    37: return




LVA槽中参数映射。
0-main（）的唯一参数。
1-限制，总是20.
2-f
3-g
4-i

我们可以看到java编译器在LVA参数槽分配变量，并且是相同的顺序，就像在源代码中声明变量。

分离指令istore，是用于访问参数槽0123，但是不能大于4，因此，附加一些操作，在行2，8偏移，使用槽中数据作为操作数，类似于在偏移10位置的iload指令。

无可口非，分离其他的槽，限制变量总是20（其本质上就是一个常数），重加载值很经常吗？

JVM JIT 编译器经常可以对其优化的很好。在代码中人工的干预优化其实是没有什么太大价值的。


## 54.12 switch()函数

switch（）语句的实现是用tableswitch指令，
public static void f(int a)
{
switch (a)
{
case 0: System.out.println("zero"); break;
case 1: System.out.println("one\n"); break;
case 2: System.out.println("two\n"); break;
case 3: System.out.println("three\n"); break;
case 4: System.out.println("four\n"); break;
default: System.out.println("something unknown\⤦
Ç n"); break;
};
}

尽可能简单的例子


    public static void f(int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=1, args_size=1
    0: iload_0
    1: tableswitch { // 0 to 4
    0: 36
    1: 47
    2: 58
    3: 69
    4: 80
    default: 91
    }
    36: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    39: ldc #3 // String zero
    41: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    44: goto 99
    47: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    50: ldc #5 // String one\n
    52: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    55: goto 99
    58: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    61: ldc #6 // String two\n
    63: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    66: goto 99
    69: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    72: ldc #7 // String three\n
    74: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    77: goto 99
    80: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    83: ldc #8 // String four\n
    85: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    88: goto 99
    91: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    94: ldc #9 // String ⤦
    Ç something unknown\n
    931
    CHAPTER 54. JAVA 54.13. ARRAYS
    96: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    99: return
    

## 54.13数组
### 54.13.1简单的例子
我们首先创建一个长度是10的整型的数组，对其初始化。

    
    public static void main(String[] args)
    {
    int a[]=new int[10];
    for (int i=0; i<10; i++)
    a[i]=i;
    dump (a);
    }
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=3, args_size=1
    0: bipush 10
    2: newarray int
    4: astore_1
    5: iconst_0
    6: istore_2
    7: iload_2
    8: bipush 10
    10: if_icmpge 23
    13: aload_1
    14: iload_2
    15: iload_2
    16: iastore
    17: iinc 2, 1
    20: goto 7
    23: aload_1
    24: invokestatic #4 // Method dump:([⤦
    Ç I)V
    27: return

newarray指令，创建了一个有10个整数元素的数组，数组的大小设置使用bipush指令，然后结果会返回到栈顶。数组类型用newarry指令操作符，进行设定。


newarray被执行后，引用（指针）到新创建的数据，栈顶的槽中，astore_1存储引用指向到LVA的一号槽，main()函数的第二个部分，是循环的存储值1到相应的素组元素。
aload_1得到数据的引用并放入到栈中。lastore将integer值从堆中存储到素组中，引用当前的栈顶。main()函数代用dump()的函数部分，参数是，准备给aload_1指令的（行偏移23）

现在我们进入dump()函数。

    public static void dump(int a[])
    {
    for (int i=0; i<a.length; i++)
    System.out.println(a[i]);
    }
    public static void dump(int[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=2, args_size=1
    0: iconst_0
    1: istore_1
    2: iload_1
    3: aload_0
    4: arraylength
    5: if_icmpge 23
    8: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    11: aload_0
    12: iload_1
    13: iaload
    14: invokevirtual #3 // Method java/io⤦
    Ç /PrintStream.println:(I)V
    17: iinc 1, 1
    20: goto 2
    23: return

到了引用的数组在0槽，a.length表达式在源代码中是转化到arraylength指令，它取得数组的引用，并且数组的大小在栈顶。
iaload在行偏移13被用于装载数据元素。
它需要在堆栈中的数组引用。用aload_0 11并且索引（用iload_1在行偏移12准备）

无可厚非，指令前缀可能会被错误的理解，就像数组指令，那样不正确，这些指令和对象的引用一起工作的。数组和字符串都是对象。

### 54.13.2 数组元素的求和

另外的例子

    public class ArraySum
    {
    public static int f (int[] a)
    {
    int sum=0;
    for (int i=0; i<a.length; i++)
    sum=sum+a[i];
    return sum;
    }
    }
    public static int f(int[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=3, args_size=1
    0: iconst_0
    1: istore_1
    2: iconst_0
    3: istore_2
    4: iload_2
    5: aload_0
    6: arraylength
    7: if_icmpge 22
    10: iload_1
    11: aload_0
    12: iload_2
    13: iaload
    14: iadd
    15: istore_1
    16: iinc 2, 1
    19: goto 4
    22: iload_1
    23: ireturn

LVA槽0是数组的引用，LVA槽1是本地变量和。

### 54.13.3 main（）函数唯一的数据参数

让我们使用唯一的main()函数参数，字符串数组。

    public class UseArgument
    {
    public static void main(String[] args)
    {
    System.out.print("Hi, ");
    System.out.print(args[1]);
    System.out.println(". How are you?");
    }
    }



0参（argument）第0个参数是程序（和C/C++类似）

因此第一个参数，而第一参数是拥护提供的。

    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=1, args_size=1
    0: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    3: ldc #3 // String Hi,
    5: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.print:(Ljava/lang/String;)V
    8: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    11: aload_0
    12: iconst_1
    13: aaload
    14: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.print:(Ljava/lang/String;)V
    17: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    20: ldc #5 // String . How ⤦
    Ç are you?
    22: invokevirtual #6 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    25: return

aload_0在11行加载，第0个LVA槽的引用（main（）函数唯一的参数）
iconst_1和aload在行偏移12,13，取得数组第一个元素的引用（从0计数）
字符串对象的引用在栈顶行14行偏移，给println方法。

### 54.1.34 初始化字符串数组


    class Month
    {
    
    public static String[] months =
    {
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
    };
    public String get_month (int i)
    {
    return months[i];
    };
    }


get_month()函数很简单

    public java.lang.String get_month(int);
    flags: ACC_PUBLIC
    Code:
    stack=2, locals=2, args_size=2
    0: getstatic #2 // Field months:[⤦
    Ç Ljava/lang/String;
    3: iload_1
    4: aaload
    5: areturn

aaload操作数组引用，java字符串是一个对象，所以a_instructiong被用于操作他们.areturn返回字符串对象的引用。

 month[]数值是如果初始化的？

    static {};
    flags: ACC_STATIC
    Code:
    stack=4, locals=0, args_size=0
    0: bipush 12
    2: anewarray #3 // class java/⤦
    Ç lang/String
    5: dup
    6: iconst_0
    7: ldc #4 // String January
    9: aastore
    10: dup
    11: iconst_1
    12: ldc #5 // String ⤦
    Ç February
    14: aastore
    15: dup
    16: iconst_2
    17: ldc #6 // String March
    19: aastore
    20: dup
    21: iconst_3
    22: ldc #7 // String April
    24: aastore
    25: dup
    26: iconst_4
    27: ldc #8 // String May
    29: aastore
    30: dup
    31: iconst_5
    32: ldc #9 // String June
    34: aastore
    35: dup
    36: bipush 6
    38: ldc #10 // String July
    40: aastore
    41: dup
    42: bipush 7
    44: ldc #11 // String August
    46: aastore
    47: dup
    48: bipush 8
    50: ldc #12 // String ⤦
    Ç September
    52: aastore
    53: dup
    54: bipush 9
    56: ldc #13 // String October
    58: aastore
    59: dup
    60: bipush 10
    62: ldc #14 // String ⤦
    Ç November
    64: aastore
    65: dup
    66: bipush 11
    68: ldc #15 // String ⤦
    Ç December
    70: aastore
    71: putstatic #2 // Field months:[⤦
    Ç Ljava/lang/String;
    74: return
    

anewarray  创建一个新数组的引用（a是一个前缀）对象的类型被定义在anewarray操作数中，它在这是“java/lang/string”文本字符串，在这之前的bipush 1L是设置数组的大小。
对于我们再这看到一个新指令dup，他是一个众所周知的堆栈操作的计算机指令。用于复制栈顶的值。（包括了之后的编程语言）它在这是用于复制数组的引用。因为aastore张玲玲
起到弹出堆栈中的数组的作用，但是之后，aastore需要在使用一次，java编译器，最好同dup代替getstatic指令，用于生成之前的每个数组的存贮操作。例如，月份字段。

### 54.13.5可变参数
可变参数
变长参数函数，实际上使用的就是数组，实际使用的就是数组。

    public static void f(int... values)
    {
    for (int i=0; i<values.length; i++)
    System.out.println(values[i]);
    }
    public static void main(String[] args)
    {
    f (1,2,3,4,5);
    }
    public static void f(int...);
    flags: ACC_PUBLIC, ACC_STATIC, ACC_VARARGS
    Code:
    stack=3, locals=2, args_size=1
    0: iconst_0
    1: istore_1
    2: iload_1
    3: aload_0
    4: arraylength
    5: if_icmpge 23
    8: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    11: aload_0
    12: iload_1
    13: iaload
    14: invokevirtual #3 // Method java/io⤦
    Ç /PrintStream.println:(I)V
    17: iinc 1, 1
    20: goto 2
    23: return

f()函数，取得一个整数数组，使用的是aload_0 在行偏移3行。取得到了一个数组的大小，等等。

    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=4, locals=1, args_size=1
    0: iconst_5
    1: newarray int
    3: dup
    4: iconst_0
    5: iconst_1
    6: iastore
    7: dup
    8: iconst_1
    9: iconst_2
    10: iastore
    11: dup
    12: iconst_2
    13: iconst_3
    14: iastore
    15: dup
    16: iconst_3
    17: iconst_4
    18: iastore
    19: dup
    20: iconst_4
    21: iconst_5
    22: iastore
    23: invokestatic #4 // Method f:([I)V
    26: return



素组在main()函数是构造的，使用newarray指令，被填充慢了之后f()被调用。


随便提一句，数组对象并不是在main()中销毁的，在整个java中也没有被析构。因为JVM的垃圾收集齐不是自动的，当他感觉需要的时候。
format()方法是做什么的？它用两个参数作为输入，字符串和数组对象。

    public PrintStream format(String format, Object... args⤦)


让我们看一下。

    public static void main(String[] args)
    {
    int i=123;
    double d=123.456;
    System.out.format("int: %d double: %f.%n", i, d⤦
    Ç );
    }
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=7, locals=4, args_size=1
    0: bipush 123
    2: istore_1
    3: ldc2_w #2 // double 123.456⤦
    Ç d
    6: dstore_2
    7: getstatic #4 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    10: ldc #5 // String int: %d⤦
    Ç double: %f.%n
    12: iconst_2
    13: anewarray #6 // class java/⤦
    Ç lang/Object
    16: dup
    17: iconst_0
    18: iload_1
    19: invokestatic #7 // Method java/⤦
    Ç lang/Integer.valueOf:(I)Ljava/lang/Integer;
    22: aastore
    23: dup
    24: iconst_1
    25: dload_2
    26: invokestatic #8 // Method java/⤦
    Ç lang/Double.valueOf:(D)Ljava/lang/Double;
    29: aastore
    30: invokevirtual #9 // Method java/io⤦
    Ç /PrintStream.format:(Ljava/lang/String;[Ljava/lang/Object⤦
    Ç ;)Ljava/io/PrintStream;
    33: pop
    34: return
    

所以int和double类型是被首先普生为integer和double 对象，被用于方法的值。。。format()方法需要，对象雷翔的对象作为输入，因为integer和double类是继承于根类root。他们适合作为数组输入的元素，
另一方面，数组总是同质的，例如，同一个数组不能含有两种不同的数据类型。不能同时都把integer和double类型的数据同时放入的数组。

数组对象的对象在偏移13行，整型对象被添加到在行偏移22.
double对象被添加到数组在29行。

倒数第二的pop指令，丢弃了栈顶的元素，因此，这些return执行，堆栈是的空的（平行）


### 54.13.6 二位数组

二位数组在java 中是一个数组去引用另外一个数组
让我们来创建二位素组。（）

    public static void main(String[] args)
    {
    int[][] a = new int[5][10];
    a[1][2]=3;
    }
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=2, args_size=1
    0: iconst_5
    1: bipush 10
    3: multianewarray #2, 2 // class "[[I"
    7: astore_1
    8: aload_1
    9: iconst_1
    10: aaload
    11: iconst_2
    12: iconst_3
    13: iastore
    14: return

它创建使用的是multianewarry指令：对象类型和维数作为操作数，数组的大小（10*5），返回到栈中。（使用iconst_5和bipush指令）

行引用在行偏移10加载（iconst_1和aaload）列引用是选择使用iconst_2指令，在行偏移11行。值得写入和设定在12行，iastore在13
行，写入数据元素？

    public static int get12 (int[][] in)
    {
    return in[1][2];
    }
    public static int get12(int[][]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=1, args_size=1
    0: aload_0
    1: iconst_1
    2: aaload
    3: iconst_2
    4: iaload
    5: ireturn


引用数组在行2加载，列的设置是在行3，iaload加载数组。

### 54.13.7   三维数组
三维数组是，引用一维数组引用一维数组。


    public static void main(String[] args)
    {
    int[][][] a = new int[5][10][15];
    a[1][2][3]=4;
    get_elem(a);
    }
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=2, args_size=1
    0: iconst_5
    1: bipush 10
    3: bipush 15
    5: multianewarray #2, 3 // class "[[[I"
    9: astore_1
    10: aload_1
    11: iconst_1
    12: aaload
    13: iconst_2
    14: aaload
    15: iconst_3
    16: iconst_4
    17: iastore
    18: aload_1
    19: invokestatic #3 // Method ⤦
    Ç get_elem:([[[I)I
    22: pop
    23: return


它是用两个aaload指令去找right引用。

    public static int get_elem (int[][][] a)
    {
    return a[1][2][3];
    }
    public static int get_elem(int[][][]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=1, args_size=1
    0: aload_0
    1: iconst_1
    2: aaload
    3: iconst_2
    4: aaload
    5: iconst_3
    6: iaload
    7: ireturn


### 53.13.8总结
在java中可能出现栈溢出吗？不可能，数组长度实际就代表有多少个对象，数组的边界是可控的，而发生越界访问的情况时，会抛出异常。


### 54.14 字符串
### 54.14.1 第一个例子

字符串也是对象，和其他对象的构造方式相同。（还有数组）


    public static void main(String[] args)
    {
    System.out.println("What is your name?");
    String input = System.console().readLine();
    System.out.println("Hello, "+input);
    }
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=2, args_size=1
    0: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    3: ldc #3 // String What is⤦
    Ç your name?
    5: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    8: invokestatic #5 // Method java/⤦
    Ç lang/System.console:()Ljava/io/Console;
    11: invokevirtual #6 // Method java/io⤦
    Ç /Console.readLine:()Ljava/lang/String;
    14: astore_1
    15: getstatic #2 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    18: new #7 // class java/⤦
    Ç lang/StringBuilder
    21: dup
    22: invokespecial #8 // Method java/⤦
    Ç lang/StringBuilder."<init>":()V
    25: ldc #9 // String Hello,
    27: invokevirtual #10 // Method java/⤦
    Ç lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/⤦
    Ç StringBuilder;
    30: aload_1
    31: invokevirtual #10 // Method java/⤦
    Ç lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/⤦
    Ç StringBuilder;
    34: invokevirtual #11 // Method java/⤦
    Ç lang/StringBuilder.toString:()Ljava/lang/String;
    37: invokevirtual #4 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    40: return


在11行偏移调用了readline()方法，字符串引用（由用户提供）被存储在栈顶，在14行偏移,字符串引用被存储在LVA的1号槽中。


用户输入的字符串在30行偏移处重新加载并和 “hello”字符进行了链接，使用的是StringBulder类，在17行偏移,构造的字符串被pirntln方法打印。

### 54.14.2 第二个例子
另外一个例子

    public class strings
    {
    public static char test (String a)
    {
    return a.charAt(3);
    };
    public static String concat (String a, String b)
    {
    return a+b;
    }
    }
    public static char test(java.lang.String);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=1, args_size=1
    0: aload_0
    1: iconst_3
    2: invokevirtual #2 // Method java/⤦
    Ç lang/String.charAt:(I)C
    5: ireturn



字符串的链接使用用StringBuilder类完成。


    public static java.lang.String concat(java.lang.String, java.⤦
    Ç lang.String);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=2, args_size=2
    0: new #3 // class java/⤦
    Ç lang/StringBuilder
    3: dup
    4: invokespecial #4 // Method java/⤦
    Ç lang/StringBuilder."<init>":()V
    7: aload_0
    8: invokevirtual #5 // Method java/⤦
    Ç lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/⤦
    Ç StringBuilder;
    11: aload_1
    12: invokevirtual #5 // Method java/⤦
    Ç lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/⤦
    Ç StringBuilder;
    15: invokevirtual #6 // Method java/⤦
    Ç lang/StringBuilder.toString:()Ljava/lang/String;
    18: areturn

另外一个例子
    
    public static void main(String[] args)
    {
    String s="Hello!";
    int n=123;
    System.out.println("s=" + s + " n=" + n);
    }

字符串构造用StringBuilder类，和它的添加方法，被构造的字符串被传递给println方法。

    
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=3, args_size=1
    0: ldc #2 // String Hello!
    2: astore_1
    3: bipush 123
    5: istore_2
    6: getstatic #3 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    9: new #4 // class java/⤦
    Ç lang/StringBuilder
    12: dup
    13: invokespecial #5 // Method java/⤦
    Ç lang/StringBuilder."<init>":()V
    16: ldc #6 // String s=
    18: invokevirtual #7 // Method java/⤦
    Ç lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/⤦
    Ç StringBuilder;
    21: aload_1
    22: invokevirtual #7 // Method java/⤦
    Ç lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/⤦
    Ç StringBuilder;
    25: ldc #8 // String n=
    27: invokevirtual #7 // Method java/⤦
    Ç lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/⤦
    Ç StringBuilder;
    30: iload_2
    31: invokevirtual #9 // Method java/⤦
    Ç lang/StringBuilder.append:(I)Ljava/lang/StringBuilder;
    34: invokevirtual #10 // Method java/⤦
    Ç lang/StringBuilder.toString:()Ljava/lang/String;
    37: invokevirtual #11 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    40: return


## 54.15 异常
让我们稍微修改一下，月处理的那个例子(在932页的54.13.4)

清单 54.10: IncorrectMonthException.java
    
    public class IncorrectMonthException extends Exception
    {
    private int index;
    public IncorrectMonthException(int index)
    {
    this.index = index;
    }
    public int getIndex()
    {
    return index;
    }
    }

清单 54.11: Month2.java


    class Month2
    {
    public static String[] months =
    {
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
    };
    public static String get_month (int i) throws ⤦
    Ç IncorrectMonthException
    {
    if (i<0 || i>11)
    throw new IncorrectMonthException(i);
    return months[i];
    };
    public static void main (String[] args)
    {
    try
    {
    System.out.println(get_month(100));
    }
    catch(IncorrectMonthException e)
    {
    System.out.println("incorrect month ⤦
    Ç index: "+ e.getIndex());
    e.printStackTrace();
    }
    };
    }
    

本质上，IncorrectMonthExceptinClass类只是做了对象构造，还有访问器方法。
IncorrectMonthExceptinClass是继承于Exception类，所以，IncorrectMonth类构造之前，构造父类Exception，然后传递整数给IncorrectMonthException类作为唯一的属性值。


    public IncorrectMonthException(int);
    flags: ACC_PUBLIC
    Code:
    stack=2, locals=2, args_size=2
    0: aload_0
    1: invokespecial #1 // Method java/⤦
    Ç lang/Exception."<init>":()V
    4: aload_0
    5: iload_1
    6: putfield #2 // Field index:I
    9: return

getIndex()只是一个访问器，引用到IncorrectMothnException类，被传到LVA的0槽(this指针),用aload_0指令取得， 用getfield指令取得对象的整数值，用ireturn指令将其返回。

    public int getIndex();
    flags: ACC_PUBLIC
    Code:
    stack=1, locals=1, args_size=1
    0: aload_0
    1: getfield #2 // Field index:I
    4: ireturn

现在来看下month.class的get_month方法。

清单 54.12: Month2.class
    
    public static java.lang.String get_month(int) throws ⤦
    Ç IncorrectMonthException;
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=1, args_size=1
    0: iload_0
    1: iflt 10
    4: iload_0
    5: bipush 11
    7: if_icmple 19
    10: new #2 // class ⤦
    Ç IncorrectMonthException
    13: dup
    14: iload_0
    15: invokespecial #3 // Method ⤦
    Ç IncorrectMonthException."<init>":(I)V
    18: athrow
    19: getstatic #4 // Field months:[⤦
    Ç Ljava/lang/String;
    22: iload_0
    23: aaload
    24: areturn


iflt 在行偏移1 ，如果小于的话，

这种情况其实是无效的索引，在行偏移10创建了一个对象，对象类型是作为操作书传递指令的。（这个IncorrectMonthException的构造届时，下标整数是被通过TOS传递的。行15偏移）
时间流程走到了行18偏移，对象已经被构造了，现在athrow指令取得新构对象的引用，然后发信号给JVM去找个合适的异常句柄。

athrow指令在这个不返回到控制流，行19偏移的其他的个基本模块，和异常无关，我们能得到到行7偏移。
句柄怎么工作？ main()在inmonth2.class

清单 54.13: Month2.class

    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=3, locals=2, args_size=1
    0: getstatic #5 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    3: bipush 100
    5: invokestatic #6 // Method ⤦
    Ç get_month:(I)Ljava/lang/String;
    8: invokevirtual #7 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    11: goto 47
    14: astore_1
    15: getstatic #5 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    18: new #8 // class java/⤦
    Ç lang/StringBuilder
    21: dup
    22: invokespecial #9 // Method java/⤦
    Ç lang/StringBuilder."<init>":()V
    25: ldc #10 // String ⤦
    Ç incorrect month index:
    27: invokevirtual #11 // Method java/⤦
    Ç lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/⤦
    Ç StringBuilder;
    30: aload_1
    31: invokevirtual #12 // Method ⤦
    Ç IncorrectMonthException.getIndex:()I
    34: invokevirtual #13 // Method java/⤦
    Ç lang/StringBuilder.append:(I)Ljava/lang/StringBuilder;
    37: invokevirtual #14 // Method java/⤦
    Ç lang/StringBuilder.toString:()Ljava/lang/String;
    40: invokevirtual #7 // Method java/io⤦
    Ç /PrintStream.println:(Ljava/lang/String;)V
    43: aload_1
    44: invokevirtual #15 // Method ⤦
    Ç IncorrectMonthException.printStackTrace:()V
    47: return
    Exception table:
    from to target type
    0 11 14 Class IncorrectMonthException

这是一个异常表，在行偏移0-11（包括）行，一个IncorrectinMonthException异常可能发生，如果发生，控制流到达14行偏移，确实main程序在11行偏移结束，在14行异常开始，
没有进入此区域条件(condition/uncondition)设定，是不可能到打这个位置的。（PS：就是没有异常捕获的设定，就不会有异常流被调用执行。）


但是JVM会传递并覆盖执行这个异常case。
第一个astore_1(在行偏移14)取得，将到来的异常对象的引用，存储在LVA的槽参数1之后。getIndex()方法（这个异常对象）
会被在31行偏移调用。引用当前的异常对象，是在30行偏移之前。
所有的这些代码重置都是字符串操作代码：第一个整数值使用的是getIndex()方法，被转换成字符串使用的是toString()方法，它会和“正确月份下标”的文本字符来链接（像我们之前考虑的那样）。
println()和printStackTrace(1)会被调用，PrintStackTrace(1)调用
结束之后，异常被捕获，我们可以处理正常的函数，在47行偏移，return结束main（）函数 , 如果没有发生异常，不会执行任何的代码。


这有个例子，IDA是如何显示异常范围：

清单54.14 
我从我的计算机中找到 random.class 这个文件

    
    .catch java/io/FileNotFoundException from met001_335 to ⤦
    Ç met001_360\
    using met001_360
    .catch java/io/FileNotFoundException from met001_185 to ⤦
    Ç met001_214\
    using met001_214
    .catch java/io/FileNotFoundException from met001_181 to ⤦
    Ç met001_192\
    using met001_195
    951
    CHAPTER 54. JAVA 54.16. CLASSES
    .catch java/io/FileNotFoundException from met001_155 to ⤦
    Ç met001_176\
    using met001_176
    .catch java/io/FileNotFoundException from met001_83 to ⤦
    Ç met001_129 using \
    met001_129
    .catch java/io/FileNotFoundException from met001_42 to ⤦
    Ç met001_66 using \
    met001_69
    .catch java/io/FileNotFoundException from met001_begin to ⤦
    Ç met001_37\
    using met001_37


［校准到这结束。］


### 54.16 类
简单类

清单 54.15: test.java
    
    public class test
    {
    public static int a;
    private static int b;
    public test()
    {
    a=0;
    b=0;
    }
    public static void set_a (int input)
    {
    a=input;
    }
    public static int get_a ()
    {
    return a;
    }
    public static void set_b (int input)
    {
    b=input;
    }
    public static int get_b ()
    {
    return b;
    }
    }


构造函数，只是把两个之段设置成0.

    public test();
    flags: ACC_PUBLIC
    Code:
    stack=1, locals=1, args_size=1
    0: aload_0
    1: invokespecial #1 // Method java/⤦
    Ç lang/Object."<init>":()V
    4: iconst_0
    5: putstatic #2 // Field a:I
    8: iconst_0
    9: putstatic #3 // Field b:I
    12: return

a的设定器

    public static void set_a(int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=1, args_size=1
    0: iload_0
    1: putstatic #2 // Field a:I
    4: return

a的取得器

    public static int get_a();
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=0, args_size=0
    0: getstatic #2 // Field a:I
    3: ireturn

b的设定器

    public static void set_b(int);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=1, args_size=1
    0: iload_0
    1: putstatic #3 // Field b:I
    4: return

b的取得器

    public static int get_b();
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=1, locals=0, args_size=0
    0: getstatic #3 // Field b:I
    3: ireturn


类中的公有和私有字段代码没什么区别。 但是类型信息会在in.class 文件中表示，并且，无论如何私有变量是不可以被访问的。

让我们创建对象并调用方法：
清单 54.16: ex1.java


新指令创建对象，但不调用构造函数（它在4行偏移被调用）set_a()方法被在16行偏移被调用，字段访问使用的getstatic指令,在行偏移21。

    Listing 54.16: ex1.java
    public class ex1
    {
    public static void main(String[] args)
    {
    test obj=new test();
    obj.set_a (1234);
    System.out.println(obj.a);
    }
    }
    public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
    stack=2, locals=2, args_size=1
    0: new #2 // class test
    3: dup
    4: invokespecial #3 // Method test."<⤦
    Ç init>":()V
    7: astore_1
    8: aload_1
    9: pop
    10: sipush 1234
    13: invokestatic #4 // Method test.⤦
    Ç set_a:(I)V
    16: getstatic #5 // Field java/⤦
    Ç lang/System.out:Ljava/io/PrintStream;
    19: aload_1
    20: pop
    21: getstatic #6 // Field test.a:I
    24: invokevirtual #7 // Method java/io⤦
    Ç /PrintStream.println:(I)V
    27: return


## 54.17 简单的补丁。
### 54.17.1 第一个例子

让我们进入一个简单的修补任务。


    public class nag
    {
    public static void nag_screen()
    {
    System.out.println("This program is not ⤦
    Ç registered");
    };
    public static void main(String[] args)
    {
    System.out.println("Greetings from the mega-⤦
    Ç software");
    nag_screen();
    }
    }


我们如何去除"This program is registered"的打印输出.

最会在IDA中加载.class文件。


清单54.1: IDA


我们修补一下函数的第一个byte在177(返回指令操作码)

Figure 54.2 : IDA


这个在JDK1.7中不工作

    Exception in thread "main" java.lang.VerifyError: Expecting a ⤦
    Ç stack map frame
    Exception Details:
    Location:
    nag.nag_screen()V @1: nop
    Reason:
    Error exists in the bytecode
    Bytecode:
    0000000: b100 0212 03b6 0004 b1
    at java.lang.Class.getDeclaredMethods0(Native Method)
    at java.lang.Class.privateGetDeclaredMethods(Class.java⤦
    Ç :2615)
    at java.lang.Class.getMethod0(Class.java:2856)
    at java.lang.Class.getMethod(Class.java:1668)
    at sun.launcher.LauncherHelper.getMainMethod(⤦
    Ç LauncherHelper.java:494)
    at sun.launcher.LauncherHelper.checkAndLoadMain(⤦
    Ç LauncherHelper.java:486)

也许，JVM有一些其他检查，关联到栈映射。
好的，我们修补成不同的，去掉nag()函数调用。


清单:54.5 IDA
 NOP的操作码是0:
这个可以了！

54.17.2第二个例子

现在是另外一个简单的crackme例子。

    public class password
    {
    public static void main(String[] args)
    {
    System.out.println("Please enter the password")⤦
    Ç ;
    String input = System.console().readLine();
    if (input.equals("secret"))
    System.out.println("password is correct⤦
    Ç ");
    957
    CHAPTER 54. JAVA 54.17. SIMPLE PATCHING
    else
    System.out.println("password is not ⤦
    Ç correct");
    }
    }



图54.4:IDA
我们看ifeq指令是怎么工作的，他的名字的意思是如果等于。
这是不恰当的，我更愿意命名if (ifz if zero)
如果栈顶值是0，他就会跳转，在我们这个例子，如果密码
不正确他就跳转。（equal方法返回的是0）
首先第一个方案就是修该这个指令... iefq是两个bytes的操作码
编码和跳转偏移，让这个指令定制，我们必须设定byte3
3byte（因为3是要添加当前地址结果，总是跳转同下一条指令）
因为ifeq的指令长度就是3bytes.



图54.5IDA

这个在JDK1.7中不工作

    Exception in thread "main" java.lang.VerifyError: Expecting a ⤦
    Ç stackmap frame at branch target 24
    Exception Details:
    Location:
    password.main([Ljava/lang/String;)V @21: ifeq
    Reason:
    Expected stackmap frame at this location.
    Bytecode:
    0000000: b200 0212 03b6 0004 b800 05b6 0006 4c2b
    0000010: 1207 b600 0899 0003 b200 0212 09b6 0004
    0000020: a700 0bb2 0002 120a b600 04b1
    Stackmap Table:
    append_frame(@35,Object[#20])
    same_frame(@43)
    at java.lang.Class.getDeclaredMethods0(Native Method)
    at java.lang.Class.privateGetDeclaredMethods(Class.java⤦
    Ç :2615)
    at java.lang.Class.getMethod0(Class.java:2856)
    at java.lang.Class.getMethod(Class.java:1668)
    at sun.launcher.LauncherHelper.getMainMethod(⤦
    Ç LauncherHelper.java:494)
    959
    CHAPTER 54. JAVA 54.18. SUMMARY
    at sun.launcher.LauncherHelper.checkAndLoadMain(⤦
    Ç LauncherHelper.java:486)
    
不用说了，它工作在JRE1.6
我也尝试把所有的3 ifeq的所有操作码都用0替换（NOP），它仍然会工作，好，可能没有更多的堆栈映射在JRE1.7中被检查出来。

好的，我替换整个equal方法调用，使用icore_1指令加NOPS的修改。


（TOS）栈顶总是1，当ifeq指令被执行...所以ifeq也不会被执行。

可以了。

54.18总结


和C/C+比较java少了一些什么？
- 结构体：使用类
- 联合：使用类继承。
- 无符号数据类型，多说一句，还有一些在Java中实现的加密算法的硬编码。
- 函数指针。