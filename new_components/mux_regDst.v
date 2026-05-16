module mux_regDst(
    input wire [1:0] selector,
    input wire [4:0] Data_0, 
    input wire [15:0] Data_1, // 15:11 => rd
    output wire [4:0] Data_out
);
    assign Data_out = (selector == 2'b00) ? Data_0 :
                      (selector == 2'b01) ? Data_1[15:11] : 5'b11111 ;

endmodule