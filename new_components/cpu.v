module cpu(
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
    wire MDR_W;
    wire XCHG_CONTROL_1;
    wire XCHG_CONTROL_2;


// Fios de controle com mais de 1 bit 
    wire [2:0] ULA_c; 


// Controladores para os muxes 

    wire        M_REG_DST_SELECTOR; // sinal de controle do mux 3 
    wire        M_ULAA;
    wire [1:0]  M_ULAB;
    wire [3:0]  MEM_TO_REG_Selector; // controle do mux mem to reg
    wire [3:0]  MUX_DATA_SOURCE_SELECTOR;
    wire [3:0]  MUX_IORD_SELECTOR;
    wire [3:0]  MUX_PC_SOURCE_SELECTOR;


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

    wire AB_w; // controle de escrita de A e B ao mesmo tempo
    wire RB_w; // controle de escrita do banco de registradores, pra ler os dados e passar pra A e B
    
    // DECLARAR OS PC_w, ULA_out, PC_out 
  
    // Data_wires - fio de dados / sinais de dados
    wire [31:0] ULA_out;
   
    wire [31:0] PC_out;
    wire [31:0] MEM_to_IR;
   
    wire [31:0] RB_to_A; // sinal de dado
    wire [31:0] RB_to_B;  // sinal de dado
    wire [31:0] A_out;  // saida de B
    wire [31:0] B_out;  // saida de A  
    wire [31:0] REG_ALU_OUT_out;
    wire [31:0] SXTND_out;
    wire [31:0] ULAA_in;
    wire [31:0] ULAB_in;
    wire [31:0] ADDRESS_IORD_IN; // endereço de entrada do mux IorD, que vai pra memoria
    wire [31:0] DATA_DATA_SOURCE_IN;
    wire [31:0] BREG_WRITE_DATA_IN; 
    wire [31:0] PC_IN; 
    wire [31:0] XCHG_OUT_1;
    wire [31:0] XCHG_OUT_2;
    wire [31:0] MDR_REG_OUT;
    wire [31:0] SHIFT_LEFT_J_OUT;

    // instrução
    wire [5:0] funct;
    wire [2:0] ALU_op;
    wire [2:0] i_or_d;
    wire [7:0] MemtoReg;

    // Sinais para MULT, DIV, MFHI, MFLO
    wire [31:0] mult_hi, mult_lo;
    wire [31:0] div_hi, div_lo;
    wire div_zero;
    wire [31:0] HI_out, LO_out;
    wire HI_Write, LO_Write, HI_Control, LO_Control;
    wire rst_out;

    // ------------------------------------------------------------------
    // NOVOS FIOS PARA PARTE 4
    // ------------------------------------------------------------------
    wire [31:0] immediate_shifted;
    wire        branch_taken;
    wire [1:0]  byte_offset;
    wire [31:0] byte_merged_data;

    assign immediate_shifted = {SXTND_out[29:0], 2'b00};  // shift left 2 do imediato
    assign branch_taken = (OPCODE == 6'b000100) ? Eq :     // BEQ
                          (OPCODE == 6'b000101) ? ~Eq :    // BNE
                          1'b0;

    assign byte_offset = ADDRESS_IORD_IN[1:0];   // endereço calculado pela ULA
    assign byte_merged_data = (byte_offset == 2'b00) ? {MDR_REG_OUT[31:8], B_out[7:0]} :
                              (byte_offset == 2'b01) ? {MDR_REG_OUT[31:16], B_out[7:0], MDR_REG_OUT[7:0]} :
                              (byte_offset == 2'b10) ? {MDR_REG_OUT[31:24], B_out[7:0], MDR_REG_OUT[15:0]} :
                              {B_out[7:0], MDR_REG_OUT[23:0]};
    // ------------------------------------------------------------------

    // MUXES

    mux_regDst M_REG_DST_(
        M_REG_DST_SELECTOR,
        RT, // primeira entrada
        OFFSET, // segunda entrada 
        WRITEREG_in // a saida dele 
    );


    mux_mem_to_reg M_MEM_TO_REG_(
        MEM_TO_REG_Selector,
        REG_ALU_OUT_out, // Data 0
        32'b0,            // Data 1 - MDR
        HI_out,           // Data 2 - HI_out
        LO_out,           // Data 3 - LO_out
        32'b0,            // Data 4 - SHIFT_out
        32'b0,            // Data 5 - sign_ext_out_1->32
        32'b0,            // Data 6 - sign_ext_out_16->32
        32'b0,            // Data 7 - Merge Bytes
        BREG_WRITE_DATA_IN // a saida do mux que vai pro banco de registradores e pra A e B
    );

    mux_ulaA M_ULA_A_ (
        M_ULAA,
        PC_out,
        A_out,
        ULAA_in
    );

    // mux_ulaB atualizado com Data_3
    mux_ulaB M_ULA_B_ (
        M_ULAB,
        B_out,
        32'd4,
        SXTND_out,
        immediate_shifted,
        ULAB_in
    );

    // mux_data_source atualizado
    mux_data_source M_DATA_SOURCE_ (
        MUX_DATA_SOURCE_SELECTOR,
        A_out,
        B_out,
        XCHG_OUT_1,
        XCHG_OUT_2,
        byte_merged_data,
        DATA_DATA_SOURCE_IN
    );

    mux_iord M_IORD_ (
        MUX_IORD_SELECTOR,
        PC_out,
        REG_ALU_OUT_out,
        B_out,
        A_out,
        ADDRESS_IORD_IN
    );

    mux_pc_source M_PC_SOURCE_ (
        MUX_PC_SOURCE_SELECTOR, // controle do mux pc source
        ULA_out, // Data 0 - resultado da ULA
        A_out, // Data 1 - valor de $rs (para JR)   // CORRIGIDO: antes era REG_ALU_OUT_out
        SHIFT_LEFT_J_OUT, 
        32'b0, // exceptions
        PC_IN // a saida do mux que vai pro PC
    );

    // ---------------------------------------------------------------
    // Registradores

    Registrador PC_ (
        clk, // clock - declarado no modulo
        reset, // reset - declarado no modulo
        PC_w, // pc write pra escrita 
        PC_IN, // CORRIGIDO: antes era ULA_out
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

    Registrador MDR_REG_ (
        clk, // clock - declarado no modulo
        reset, // reset - declarado no modulo
        MDR_W, 
        MEM_to_IR, 
        MDR_REG_OUT
    );

    Registrador XCHG_1_ (
        clk, // clock - declarado no modulo
        reset, // reset - declarado no modulo
        XCHG_CONTROL_1, 
        MDR_REG_OUT, 
        XCHG_OUT_1
    );

    Registrador XCHG_2_ (
        clk, // clock - declarado no modulo
        reset, // reset - declarado no modulo
        XCHG_CONTROL_2, 
        MDR_REG_OUT, 
        XCHG_OUT_2
    );

    //------------------------------------------------
    // SHIFT LEFT
    calc_j_shift_left_2 SHIFT_LEFT_CALC_J_ (
        RS, // instr_25_21
        RT, // instr_20_16
        OFFSET, // instr_15_0
        PC_out, // pc_atual
        SHIFT_LEFT_J_OUT // jump_addr
    );

    //----------------------------------------------------
    // COMPONENTES BASE
    Memoria MEM_(
        ADDRESS_IORD_IN, // tem o endereco que é PC  
        clk, // o clock 
        
        MEM_w, // fio que diz se é escrita ou leitura - Wr  

        DATA_DATA_SOURCE_IN, // fio de entrada na memoria pra leitura.
        
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

    // --- MULT/DIV/MFHI/MFLO ---
    multiplier MULT_inst (
        A_out,
        B_out,
        mult_hi,
        mult_lo
    );

    divider DIV_inst (
        A_out,
        B_out,
        div_lo,
        div_hi,
        div_zero
    );

    wire [31:0] HI_input, LO_input;
    assign HI_input = (HI_Control) ? div_hi : mult_hi;
    assign LO_input = (LO_Control) ? div_lo : mult_lo;

    Registrador HI_reg (
        clk,
        reset,
        HI_Write,
        HI_input,
        HI_out
    );

    Registrador LO_reg (
        clk,
        reset,
        LO_Write,
        LO_input,
        LO_out
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
        Of, // fio de overflow
        Ng, // negacao
        Zr, // zero
        Eq, // igual
        Gt, // maior
        Lt, // menor
        OPCODE, // opcode
        OFFSET, // offset - imediato | funct - pra instruções R-type, o opcode é 000000, então o funct é que determina a operação
        div_zero,
        PC_w, 
        MEM_w,
        IR_w,
        Reg_w,
        AB_w,
        RB_w,
        ALU_OUT_W,
        MDR_W,
        XCHG_CONTROL_1,
        XCHG_CONTROL_2,
        ULA_c,
        M_REG_DST_SELECTOR,
        M_ULAA,
        M_ULAB,
        MUX_DATA_SOURCE_SELECTOR,
        MUX_IORD_SELECTOR,
        MUX_PC_SOURCE_SELECTOR,     
        reset,   
        MEM_TO_REG_Selector,
        HI_Write,
        LO_Write,
        HI_Control,
        LO_Control
    );
    // Agora, instanciar a Unidade de Controle, dai eu seleciono todos os fios que vou usar nela
 
endmodule
