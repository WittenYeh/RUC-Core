# RUC-Core 实验设计指南

## 多指令并行读取模块

## 分支预测模块

## 指令解码模块

## 寄存器重命名模块

本实验的寄存器重命名模块主要由三部分实现：

- 重排序缓存（Reorder Buffer）
- 源寄存器号广播通路
- 重排序缓存数据提交通路

为了降低项目实现复杂度和减少周期数，本实验采用了重排序缓存来直接作为物理寄存器堆（Physical Register File, PRF），另外，本实验并没有采用传统的寄存器重命名地址表（Renaming Address Table，RAT），而是直接采用广播重排序缓存中指令的 `dest` 字段实现。该实现方案虽然增加了布线的数量（在工业中可能带来不菲的功耗），但是能够在一个周期内完成寄存器号的重命名，并且节约了对 RAT 进行 checkpoint 保存和错误恢复的成本。

### 重排序缓存结构设计

本实验的重排序缓存表项设计结构如下：

```verilog
typedef struct {
    InstructionInfo inst_info;
    logic [31:0] rd_value;
    logic [`ROB_INDEX_WIDTH-1: 0] rob_id;
    logic dispatched;
    logic occupied;
    logic executed;
} ROBEntry;
```

其中，`inst_info` 是解码阶段解析出的指令信息，`rd_value` 是指令要计算出的目标值，`rob_id` 是指令在重排序缓存中所占据表项的编号，`dispatched` 表示该指令是否已经分配到发射队列中，`occupied` 表示该表项是否被占用，`executed` 表示该指令是否已经执行完毕。

该重排序缓存在逻辑上就是一个 FIFO，该结构确保重排序缓存中的指令排列顺序遵照程序中原始的指令顺序，这在提交阶段起到非常重要的作用。

### 利用表项编号的重命名机制

每次新的指令从指令缓存中读取时，都会在重排序缓存中分配一个新的表项，然后这个表项的编号就成为这条指令的重命名后的寄存器号，这样能够确保当前所有指令的目的寄存器都是唯一的，而不会触发写冲突。该方案的实现逻辑比较朴素，但是不需要通过复杂的布线讨论寄存器分配的逻辑。

### 源寄存器号广播通路

每当一条新的指令写入重排序缓存时，根据上述思路，目的寄存器和重排序缓存的表项编号已经天然地形成一一映射的关系，我们只需要对它进行源寄存器重名即可。此处采用了对源寄存器号进行广播的重命名思路，即通过比对重排序缓存中的所有指令，如果发现目的寄存器号等于当前指令源寄存器的指令，则对齐进行标记。从所有被标记的重排序缓存表项中选择最新的一项（因为要确保当前指令总是使用最新的结果）作为当前指令源寄存器重命名的结果。该操作的实现代码如下：

```verilog 
for (int j = commit_ptr; j != write_ptr; j=(j+1)%ROB_SIZE) begin 
    if (entries[j].inst_info.dest_valid) begin 
        if ( entries[j].inst_info.dest==inst_info_in[i].srcL &&
            inst_info_in[i].srcL_valid
        ) begin 
            renamed_srcL[i] = entries[j].rob_id;
        end 
        if ( entries[j].inst_info.dest==inst_info_in[i].srcR &&
            inst_info_in[i].srcR_valid
        ) begin 
            renamed_srcR[i] = entries[j].rob_id;
        end 
    end    
end   
```

由于本实验采用了多发射 CPU 的架构，因此寄存器重命名过程会更加复杂一些，还需要考虑同周期到达指令之间的数据依赖关系，因此补充同周期到达指令的寄存器重命名思路如下：

```verilog 
for (int j = 0; j < i; j += 1) begin 
    // the bigger j, the newer instruction
    if (inst_info_in[j].dest_valid) begin 
        if ( inst_info_in[j].dest==inst_info_in[i].srcL &&
            inst_info_in[i].srcL_valid
        ) begin 
            renamed_srcL[i] = wptrs[j];
        end 
        if ( inst_info_in[j].dest==inst_info_in[i].srcR &&
            inst_info_in[i].srcR_valid
        ) begin 
            renamed_srcR[i] = wptrs[j];
        end
    end  
end
```

如果在重排序缓存和同周期到达的指令中都没有发现目的寄存器等于当前指令源操作数的指令，那说明流水线中不存在与当前指令数据依赖的指令，那么只需要从逻辑寄存器堆（Architecture Register File, ARF）中直接取数据即可。

### 重排序缓存数据提交

当一条指令执行完毕并计算出结果时，我们并不直接将结果更新到 ARF 中，而是先写回到重排序缓存的 `rd_value` 字段中，这是因为本实验采取乱序多发的架构，所以一条指令在执行结束后并不一定能够马上提交，它需要等待所有原始顺序在它以前的指令提交后才能提交。此时 `rd_value` 就可以被新来的指令直接读取（实际上是通过 payload RAM 捕获，在发射阶段解释），用作源寄存器数的值。

而当一条指令正式提交以后，它在重排序缓存中的表项就需要清楚，因此执行数据提交流程，有一条从重排序缓存到 ARF 的通路，可以每周期将提交指令的 `rd_value` 写回逻辑寄存器堆对应的位置。这样就构成了“正确的虚像”。

## 发射队列

## 执行模块


## 提交模块

### 分支预测错误恢复

### 