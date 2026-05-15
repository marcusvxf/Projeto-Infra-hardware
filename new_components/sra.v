module sra(
    input wire [31:0] rt_data,
    input wire [4:0] shamt,
    output wire [31:0] result
);
    assign result = $signed(rt_data) >>> shamt;

endmodule
