module sram(
    input wire [31:0] rt_data,
    input wire [31:0] mem_data,
    output wire [31:0] result
);
    wire [4:0] shamt = mem_data[4:0];

    assign result = $signed(rt_data) >>> shamt;

endmodule
