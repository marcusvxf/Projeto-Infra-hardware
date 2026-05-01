module mux_regDst(
    input wire selector,
    input wire [4:0] Data_0,
    input wire [15:0] Data_1,
    input wire [15:0] Data_2,
    output wire [4:0] Data_out
);
    assign Data_out = (selector == 2'b00) ? Data_0 :
                      (selector == 2'b01) ? Data_1[4:0] : Data_2[4:0];

endmodule