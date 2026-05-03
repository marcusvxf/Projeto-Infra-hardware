module mux_mem_to_reg(
    input wire [2:0] selector,
    input wire [31:0] Data_0, // ULA_out
    input wire [31:0] Data_1, // MDR
    input wire [31:0] Data_2, // HI_out
    input wire [31:0] Data_3, // LO_out
    input wire [31:0] Data_4, // SHIFT_out
    input wire [31:0] Data_5, // sign_ext_out_1->32
    input wire [31:0] Data_6, // sign_ext_out_16->32
    input wire [31:0] Data_7, // Merge Bytes Oute
    output wire [31:0] Data_out
);
    reg [31:0] selected_data;

    always @(*) begin
        case (selector)
            3'b000: selected_data = Data_0; 
            3'b001: selected_data = Data_1; 
            3'b010: selected_data = Data_2; 
            3'b011: selected_data = Data_3; 
            3'b100: selected_data = Data_4; 
            3'b101: selected_data = Data_5; 
            3'b110: selected_data = Data_6; 
            3'b111: selected_data = Data_7;
        endcase
    end

    assign Data_out = selected_data;
endmodule