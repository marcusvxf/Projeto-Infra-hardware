module mux_shift_shamp(
    input wire [1:0] selector,
    input wire [31:0] Data_0, 
    input wire [15:0] Data_1,
    input wire [4:0] Data_2,
    output wire [4:0] Data_out
);
    assign Data_out = (selector == 2'b00) ? Data_0[4:0] :
                      (selector == 2'b01) ? Data_1[10:6] :
                      Data_2;

endmodule