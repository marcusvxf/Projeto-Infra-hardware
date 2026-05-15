module mux_data_source(
    input wire [3:0]selector,
    input wire [31:0] Data_0,
    input wire [31:0] Data_1,
    input wire [31:0] Data_2,
    input wire [31:0] Data_3,
    output wire [31:0] Data_out
);
    assign Data_out = (selector == 2'b00) ? Data_0 :
                      (selector == 2'b01) ? Data_1 :
                      (selector == 2'b10) ? Data_2 : Data_3;
    
endmodule