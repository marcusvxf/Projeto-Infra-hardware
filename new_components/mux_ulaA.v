module mux_ulaA(
    input wire selector,
    input wire [31:0] Data_0,
    input wire [31:0] Data_1,
    output wire [31:0] Data_out
);
    assign Data_out = (selector) ? Data_1 : Data_0;
    
endmodule