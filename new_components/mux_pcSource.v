module mux_PcSource(
    input wire [1:0] selector,
    input wire [31:0] Data_0,
    input wire [31:0] Data_1,
    input wire [31:0] Data_2,
    output wire [31:0] Data_out
);
    assign Data_out = (selector == 2'b00) ? Data_0 :
                      (selector == 2'b01) ? Data_1 : Data_2;

endmodule