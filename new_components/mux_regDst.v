module mux_regDst(
    input wire selector,
    input wire [4:0] Data_0,
    input wire [15:0] Data_1,
    output wire [4:0] Data_out
);
    assign Data_out = (selector) ? Data_1[4:0] : Data_0;

endmodule