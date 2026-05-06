// multiplier.v
module multiplier (
    input  wire [31:0] A,
    input  wire [31:0] B,
    output wire [31:0] HI,
    output wire [31:0] LO
);
    wire signed [31:0] a_signed, b_signed;
    wire signed [63:0] product;
    assign a_signed = A;
    assign b_signed = B;
    assign product = a_signed * b_signed;
    assign HI = product[63:32];
    assign LO = product[31:0];
endmodule