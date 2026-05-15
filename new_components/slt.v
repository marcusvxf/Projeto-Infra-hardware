module slt(
    input wire [31:0] rs_data,
    input wire [31:0] rt_data,
    output wire [31:0] result
);
    wire signed [31:0] rs_signed = rs_data;
    wire signed [31:0] rt_signed = rt_data;

    assign result = (rs_signed < rt_signed) ? 32'd1 : 32'd0;

endmodule
