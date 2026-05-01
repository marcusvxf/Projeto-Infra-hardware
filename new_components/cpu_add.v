module cpu_add(
    input wire clk
    input wire reset
);

// data Wires
    wire [31:0] PC_out;
    wire [31:0] ULA_out;
    wire [31:0] MEM_to_ir;

// Sinais de controle
    wire PC_W;
    wire MEM_W;

    Registrador PC_(
        clk,
        reset,
        PC_W,
        PC_out,
        ULA_out
    );

    Memoria MEM_(
        PC_out,
        clk,
        MEM_W,
        MEM_out,
        ULA_out,
        MEM_to_ir
    );

endmodule