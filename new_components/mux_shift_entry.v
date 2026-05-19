module mux_shift_entry(
    input wire selector,
    input wire [31:0] Data_0, 
    input wire [31:0] Data_1,
    output wire [31:0] Data_out
);
    assign Data_out = (selector == 1'b0) ? Data_0 :
                      Data_1;

endmodule