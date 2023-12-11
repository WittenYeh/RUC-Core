module DCache (
    input wire clk,
    input wire reset,
    input wire memRead,
    input wire memWrite,
    input wire[31: 0] addr, // write a word at one time
    input wire[31: 0] writeData,
    input wire[31: 0] instAddr,
    output wire[31: 0] readData,
    output wire[31: 0] dmState [2047:0]
);

integer i;
// integer fd, err, str;

reg [31: 0] data [2047: 0];
// reg [31: 0] tmpReadData;
// assign readData = tmpReadData;

assign dmState = data;
assign readData = data[addr/4];

always_ff @(negedge clk) begin
    if (reset) begin
        for (i = 0; i < 1024; i=i+1) begin
            data[i] <= 0;
        end
    end
    else begin
        if (memWrite) begin 
            // $display("write data %h to address %h", writeData, addr);
            // fd = $fopen("I:\\GitHub\\COAD-Note\\homework\\SingleCycleCPU\\SingleCycleCPU.srcs\\sim_1\\new\\result.txt", "a+");
            // err = $ferror(fd, str);
            // $write("@%h: *%h <= %h\n", instAddr, addr, writeData);
            data[addr/4] <= writeData;
        end
//        if (memRead) begin
//            $display("read data %h from address %h", data[addr], addr);
//            tmpReadData <= data[addr];
//        end
    end
end

endmodule