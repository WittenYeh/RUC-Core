# 对于多乘法器问题的解决方案

## mult 指令异步执行

本实验中一共设置两个处理乘除法的复杂操作计算单元，当两个单元都被占据时，负责乘除法的发射队列就会被冻结，即无法再进行相关指令的发射。（但是其它发射队列仍然可以执行发射操作）

## 让阻塞不发生在 `mfhi`, `mflo` 指令上

重新实现 move 指令，当发现 move 指令的源寄存器位于重命名寄存器表中时，则不必进行实际的数据搬移操作，而是直接在重命名寄存器表中的位置进行更改，这样，后面的指令都会使用到更改后的源寄存器号。

举例如下：

```mips
ori $1, $0, 114
ori $2, $0, 514
mult $1, $2 # 不阻塞
mflo $3 # 不阻塞
mflo $4 # 不阻塞
add $5, $3, $4 # 阻塞
```

假设 mult 对应的 ROB 表项编号为 k，那么 RAT 中将会记载两个值：

```
LO -> k1
HI -> k2
```

`mflo $3` 和 `mflo $4` 对应的 ROB 表项编号为 m、n，那么这两条操作只需要将 RAT 中 `$3` 和 `$4` 两个寄存器对应的重命名寄存器改成 `k1` 和 `k2` 即可，这两条指令都不会受到阻塞。


## 多乘法器支持

在本实验的多发架构中，本身已经实现了基于 ROB 的寄存器重命名，因此天然地支持这个功能，关于本实验寄存器重命名的机制，参见提交包内的文档“寄存器重命名实现”。