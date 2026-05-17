// =============================================================================
// Module Name:   merge_bytes
// Description:   Componente combinacional para mesclagem de barramentos byte a byte.
// Author:        equipe5-2026.1
// Date:          2026-05-16
// =============================================================================
module merge_bytes (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  OP,
    output wire [31:0] OUT
);
    assign OUT[31:24] = OP[3] ? B[31:24] : A[31:24];
    assign OUT[23:16] = OP[2] ? B[23:16] : A[23:16];
    assign OUT[15:8]  = OP[1] ? B[15:8]  : A[15:8];
    assign OUT[7:0]   = OP[0] ? B[7:0]   : A[7:0];
	 
endmodule
