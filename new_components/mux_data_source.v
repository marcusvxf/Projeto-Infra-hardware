module mux_data_source(
    input wire [3:0] selector,
    input wire [31:0] Data_0,   // A_out
    input wire [31:0] Data_1,   // B_out
    input wire [31:0] Data_2,   // XCHG_OUT_1
    input wire [31:0] Data_3,   // XCHG_OUT_2
    input wire [31:0] Data_4,   // byte_merged_data (para SB)
    output reg [31:0] Data_out
);
    always @(*) begin
        case (selector)
            4'b0000: Data_out = Data_0;
            4'b0001: Data_out = Data_1;
            4'b0010: Data_out = Data_2;
            4'b0011: Data_out = Data_3;
            4'b0100: Data_out = Data_4;
            default: Data_out = 32'b0;
        endcase
    end
endmodule