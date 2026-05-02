module mux_ulaB(
    input wire [1:0] selector,
    input wire [31:0] Data_0,
    input wire [31:0] Data_1,
    input wire [31:0] Data_2,
    output wire [31:0] Data_out
);
    wire [31:0] A1; // cria o fio do A1 pra pegar o 4 e o Data 0 

    // fez a seleção instantanea - se V eh 4 em binario ou decimal, se F eh data0 
    // em binario 32'b0000000000000000000000000000100
    // em decimal 32'd4
    assign A1 = (selector[0]) ? 32'd4 : Data_0;
    // vai selecionar o bit mais a esquerda 
    assign Data_out = (selector[1]) ? Data_1 : A1;

endmodule