// divider.v
module divider (
    input  wire [31:0] A,
    input  wire [31:0] B,
    output wire [31:0] LO,
    output wire [31:0] HI,
    output wire        div_zero
);
    wire signed [31:0] a_signed, b_signed;
    assign a_signed = A;
    assign b_signed = B;
    assign div_zero = (B == 32'd0);
    assign LO = div_zero ? 32'd0 : (a_signed / b_signed);
    assign HI = div_zero ? 32'd0 : (a_signed % b_signed);
endmodule