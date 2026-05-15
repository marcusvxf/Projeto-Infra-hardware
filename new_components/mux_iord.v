module mux_iord(
    input wire [3:0] selector,
    input wire [31:0] Data_0,   // PC_out
    input wire [31:0] Data_1,   // REG_ALU_OUT_out
    input wire [31:0] Data_2,   // B_out
    input wire [31:0] Data_3,   // A_out
    output reg [31:0] Data_out
);
    always @(*) begin
        case (selector[1:0])
            2'b00:   Data_out = Data_0;
            2'b01:   Data_out = Data_1;
            2'b10:   Data_out = Data_2;
            2'b11:   Data_out = Data_3;
            default: Data_out = 32'b0;
        endcase
    end
endmodule