module sign_xtend_16_32(
    input wire [15:0] Data_in,
    output wire [31:0] Data_out
);
    assign Data_out = { {16{Data_in[15]}}, Data_in };

endmodule