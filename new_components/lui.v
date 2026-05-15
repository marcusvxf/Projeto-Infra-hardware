module lui(
    input wire [15:0] imm,
    output wire [31:0] result
);
    assign result = {imm, 16'b0};

endmodule
