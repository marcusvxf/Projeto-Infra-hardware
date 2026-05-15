module calc_j_shift_left_2 (
    input  wire [4:0]  instr_25_21, // Recebe [25-21]
    input  wire [4:0]  instr_20_16, // Recebe [20-16]
    input  wire [15:0] instr_15_0,  // Recebe [15-0]
    input  wire [31:0] pc_atual,    // Recebe o PC completo (31 a 0)
    
    output wire [31:0] jump_addr    // Endereço de destino final
);

    assign jump_addr = { pc_atual[31:28], instr_25_21, instr_20_16, instr_15_0, 2'b00 };

endmodule