module cpu_add(
    input wire clk,
    input wire reset
);

    wire    Of;
    wire    Ng;
    wire    Zr;
    wire    Eq;
    wire    Gt;
    wire    Lt;


// Controles de 1 bit

    wire PC_w;
    wire MEM_w;
    wire IR_w;
    wire ALU_OUT_W;
    wire aluOut_w;
    wire MemRead;
    wire ALUSrcA; // controle do multiplexador de A da ULA
    wire [1:0] ALUSrcB; // controle do multiplexador de B da ULA 
    wire [1:0] ALU_flag;
    wire [1:0] RegDst;
    wire Reg_w;
    wire AB_r;


// Fios de controle com mais de 1 bit 
    wire [2:0] ULA_c; 


// Controladores para os muxes 

    wire        M_WREG; // sinal de controle do mux 3 
    wire        M_ULAA;
    wire [1:0]  M_ULAB;
    wire [2:0]  MEM_TO_REG_Selector; // controle do mux mem to reg
    wire [3:0]  MUX_DATA_SOURCE_SELECTOR;


// Partes da instrucao necessarias  
    wire [5:0] OPCODE; // usa na ULA 
    wire [4:0]    RS;
    wire [4:0]    RT;
    wire [15:0]    OFFSET; // o imediato 

// Fio de dados com menos de 32 bits 
    // Write Reg 
    wire [4:0] WRITEREG_in; // variavel do mux 3 


    // DECLARAR OS SINAIS DE CONTROLE
    // Control wires 



    wire AB_w; // contrle de escrita de A e B ao mesmo tempo
    wire RB_w; // controle de escrita do banco de registradores, pra ler os dados e passar pra A e B
    

    // DECLARAR OS PC_w, ULA_out, PC_out 
  
    // Data_wires - fio de dados / sinais de dados
    wire [31:0] ULA_out;
   
    wire [31:0] PC_out;
    wire [31:0] MEM_to_IR;
   
    wire [31:0] RB_to_A; // sinal de dado
    wire [31:0] RB_to_B;  // sinal de dado
    wire [31:0] A_out;  // saida de B
    wire [31:0] B_out;  // saia de A  
    wire [31:0] REG_ALU_OUT_out;
    wire [31:0] SXTND_out;
    wire [31:0] ULAA_in;
    wire [31:0] ULAB_in;
    wire [31:0] ADDRESS_IORD_IN; // endereço de entrada do mux IorD, que vai pra memoria
    wire [31:0] DATA_DATA_SOURCE_IN;
    wire [31:0] BREG_WRITE_DATA_IN; 


    // instrução
    wire [5:0] funct;
    wire [2:0] ALU_op;
    wire [2:0] i_or_d;
    wire [7:0] MemtoReg;

    // MUXES

    mux_regDst M_REG_DST_(
        M_WREG,
        RT, // primeira entrada
        OFFSET, // segunda entrada 
        WRITEREG_in // a saida dele 
    );


    mux_mem_to_reg M_MEM_TO_REG_(
        MEM_TO_REG_Selector,
        ULA_out, // Data 0
        32'b0, // Data 1 - MDR - não tem na video aula
        32'b0, // Data 2 - HI_out - não tem na video aula
        32'b0, // Data 3 - LO_out - não tem na video aula
        32'b0, // Data 4 - SHIFT_out - não tem na video aula
        32'b0, // Data 5 - sign_ext_out_1->32 - não tem na video aula
        32'b0, // Data 6 - sign_ext_out_16->32 - não tem na video aula
        32'b0, // Data 7 - Merge Bytes Oute - não tem na video aula
        BREG_WRITE_DATA_IN // a saida do mux que vai pro banco de registradores e pra A e B
    );

    mux_ulaA M_ULA_A_ (
        M_ULAA,
        PC_out,
        A_out,
        ULAA_in
    );

    mux_ulaB M_ULA_B_ (
        M_ULAB,
        B_out,
        SXTND_out,
        1'b0,
        ULAB_in
    );

    mux_data_source M_DATA_SOURCE_ (
        MUX_DATA_SOURCE_SELECTOR,
        PC_out,
        REG_ALU_OUT_out,
        B_out,
        A_out,
        DATA_DATA_SOURCE_IN
    );

    // ---------------------------------------------------------------
    // Registradores

    Registrador PC_ (
        clk, // clock - declarado no modulo
        reset, // reset - declarado no modulo
        PC_w, // pc write pra escrita 
        ULA_out, // unico sinal q entra pra pc e a saida da ula
        PC_out // saida 
    );

    Registrador A_ (
        clk, // clock - declarado no modulo
        reset, // reset - declarado no modulo
        AB_w, // como vou escrever em A e B ao mesmo tempo chamo de AB
        RB_to_A, // entrada de A
        A_out // saida 
    );

    Registrador B_ (
        clk, // clock - declarado no modulo
        reset, // reset - declarado no modulo
        AB_w, // como vou escrever em A e B ao mesmo tempo chamo de AB
        RB_to_B, // entrada de B
        B_out // saida 
    );

    Registrador ALU_OUT_ (
        clk, // clock - declarado no modulo
        reset, // reset - declarado no modulo
        ALU_OUT_W, 
        ULA_out, 
        REG_ALU_OUT_out
    );

    //------------------------------------------------
    // COMPONENTES BASE
    Memoria MEM_(
        PC_out, // tem o endereco que é PC  
        clk, // o clock 
        
        MEM_w, // fio que diz se é escrita ou leitura - Wr  

        ULA_out, // fio de entrada na memoria pra leitura.
        
        MEM_to_IR// o fio de saida da mem que vai pra ir 
    );

    // Instanciar o Registrador de Instrucoes - IR 
    Instr_Reg IR_ (
        // fios
        clk,    
        reset,
        IR_w, // sinal pra dizer se vai escreve ou n 
        MEM_to_IR,    // entrada - mem to ir
        OPCODE, // Instr31_26
        RS,// Instr25_21
        RT,// Instr20_16
        OFFSET // o imediato Instr15_0 - ultimos 16 bits

    );

    Banco_reg REG_BASE_(
        clk,
        reset,
        Reg_w,// Reg Write - sinal de controle 
        RS,// read reg 1 - rs 
        RT,// read reg 2 - rt     
        WRITEREG_in,// WriteReg
        BREG_WRITE_DATA_IN, 
        // Agora, as saidas de a e b
        RB_to_A,
        RB_to_B
    );

    sign_xtend_16_32 SXTND_ (
        OFFSET,
        SXTND_out
    );

    ula32 ULA_(
        ULAA_in,
        ULAB_in,
        ULA_c,
        ULA_out,
        Of,
        Ng,
        Zr,
        Eq,
        Gt,
        Lt
    );

    ctrl_unit CTRL_(
        clk,
        reset,// reset de entrada
        // flags da ULA
        Of, // fio de overflow
        Ng, // negacao
        Zr, // zero
        Eq, // igual
        Gt, // maior
        Lt, // menor
        // fim   
        OPCODE, // opcode
        OFFSET, // offset - imediato | funct - pra instruções R-type, o opcode é 000000, então o funct é que determina a operação
        // sinais de controle pra todos os muxs e todas as unidades do controle
        PC_w, 
        MEM_w,
        IR_w,
        Reg_w,
        AB_w,
        RB_w,
        ALU_OUT_W,
        //
        ULA_c,
        M_WREG,
        M_ULAA,
        M_ULAB,

        // reset de saida
        reset,
        MEM_TO_REG_Selector
    );

    // Agora, instnaciar a Unidade de Controle, dai eu seleciono todos os fios que vou usar nela

endmodule