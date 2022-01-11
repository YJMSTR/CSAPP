# Bomblab

针对自学材料的bomblab解题过程。

题目要求找出六个字符串，通过反汇编和gdb等方式。

首先可以用objdump -d 或gdb disassemble命令进行反汇编，查看汇编代码。

随后使用gdb的layout asm功能，可以对汇编代码进行调试

gdb中的x命令可以查看字节中的内容

比如`x/14xb sumstore` 命令可以查看sumstore函数开始的14个字节的16进制表示

## 汇编

`movq %rcx, %rax`表示将寄存器rcx中的值复制给寄存器rax

`(%rax)` 表示将$rax$中的值作为地址，指向的那个寄存器中所储存的值

`D(%rax)`表示内存中rax指向的地址+D 位置上储存的值，记为Mem[Reg[rax]+D]

还有如下涉及两个寄存器的表达形式：

`D(Rb, Ri, S)` 表示`Mem[Reg[Rb] + S * Reg[Ri] + D]`

其中S为1，2，4或8

leaq Src, Dst

​	将Src对应的表达式的值存进Dst中，Dst必须是寄存器

​	