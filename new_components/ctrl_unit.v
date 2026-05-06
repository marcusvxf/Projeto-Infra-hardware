module ctrl_unit( 
    input wire      clk,
    input wire    reset,
    // flags da ULA
    input wire    Of, // fio de overflow
    input wire    Ng, // negacao
    input wire    Zr, // zero
    input wire    Eq, // igual
    input wire    Gt, // maior
    input wire    Lt, // menor
    // ------------------------------------------

    input wire  [5:0]    OPCODE,
    input wire  [15:0]    OFFSET, // para instruções R-type, o opcode é 000000, então o funct é que determina a operação
    input wire div_zero, // exceção div por zero
    // Controllers com 1 bit - W => WRITE
    output reg    PC_w, 
    output reg    MEM_w,
    output reg    IR_w,
    output reg    Reg_w,
    output reg    AB_w,
    output reg    RB_w,

   
    // Controladores com mais de 1 bit
    output reg [2:0]    ULA_c,

    
    // Controlador pra os multiplexadores  
    output reg    M_WREG, // RegDst
    output reg    M_ULAA,
    output reg  [1:0]    M_ULAB,

    // Funciona de acordo com o Clock - sincronamente com o clock
    output reg    rst_out,

    output reg [2:0] MEM_TO_REG_Selector, // controle do mux mem to reg
    // saidas mult/div
    output reg HI_Write,
    output reg LO_Write,
    output reg HI_Control,
    output reg LO_Control
);

// Variaveis
reg [3:0] STATE = 4'b0000; // estado da maquina de estados atualizar ao adicionar estados
reg [2:0] COUNTER;
reg [5:0] funct; // para instruções R-type, o opcode é 000000, então o funct é que determina a operação

// Estados principais da maquina 
parameter ST_COMMON = 4'b0000;
parameter ST_ADD = 4'b0001;
parameter ST_ADDI = 4'b0010;
parameter ST_RESET = 4'b0011;
parameter ST_SUB = 4'b0100; // Reutilizando o mesmo estado do ADD, pois a diferença entre as instruções R-type é apenas o controle da ULA, que é determinado pelo funct
parameter ST_AND = 4'b0101; // Novo estado para AND
parameter ST_JR = 4'b0110; // Novo estado para JR
parameter ST_MULT = 4'b0111;
parameter ST_DIV  = 4'b1000;
parameter ST_MFHI = 4'b1001;
parameter ST_MFLO = 4'b1010;


// Opcode
parameter ADD   = 6'b100000;
parameter SUB   = 6'b100010;
parameter AND_OP = 6'b100100;
parameter JR    = 6'b001000;
parameter R_TYPE = 6'b000000;
parameter ADDI = 6'b001000;
parameter RESET = 6'b111111;
parameter MULT  = 6'b011000;   // funct 24
parameter DIV   = 6'b011010;   // funct 26
parameter MFHI  = 6'b010000;   // funct 16
parameter MFLO  = 6'b010010;   // funct 18

initial begin
    rst_out = 1'b1;
end

// Mapeia a maquina de estados
always @(posedge clk) begin
    if (reset == 1'b1) begin
        if (STATE != ST_RESET) begin
            STATE = ST_RESET;
            // Resetar os sinais de controle
            PC_w = 1'b0;
            MEM_w = 1'b0;
            IR_w = 1'b0;
            Reg_w = 1'b0;
            AB_w = 1'b0;
            RB_w = 1'b0;
            ULA_c = 3'b000;
            M_WREG = 1'b0;
            M_ULAA = 1'b0;
            M_ULAB = 2'b00;
            rst_out = 1'b1; // Sinal de reset para o processador
            COUNTER = 3'b000;
            MEM_TO_REG_Selector = 3'b000; // Resetar o seletor do mux mem to reg
        end
        else begin
            STATE = ST_COMMON; // Volta para o estado comum após o reset
            PC_w = 1'b0;
            MEM_w = 1'b0;
            IR_w = 1'b0;
            Reg_w = 1'b0;
            AB_w = 1'b0;
            RB_w = 1'b0;
            ULA_c = 3'b000;
            M_WREG = 1'b0;
            M_ULAA = 1'b0;
            M_ULAB = 2'b00;
            rst_out = 1'b0; // Sinal de reset para o processador
            COUNTER = 3'b000;
            MEM_TO_REG_Selector = 3'b000; // Resetar o seletor do mux mem to reg
        end
    end else begin 

        case (STATE)
            ST_COMMON: begin

                // Processo de somar PC + 4
                if(COUNTER == 3'b000 || COUNTER == 3'b001 || COUNTER == 3'b010) begin
                    STATE = ST_COMMON;
                    PC_w = 1'b0;
                    MEM_w = 1'b0;
                    IR_w = 1'b0;
                    Reg_w = 1'b0;
                    AB_w = 1'b0;
                    RB_w = 1'b0;
                    ULA_c = 3'b001;
                    M_WREG = 1'b0;
                    M_ULAA = 1'b0;
                    M_ULAB = 2'b01;
                    rst_out = 1'b0; 
                    COUNTER = COUNTER + 1;
                    MEM_TO_REG_Selector = 3'b000;

                end 
                else if (COUNTER == 3'b011) begin
                    STATE = ST_COMMON;
                    PC_w = 1'b1; // Escreve o resultado de PC + 4 no PC
                    MEM_w = 1'b0;
                    IR_w = 1'b1; // Escreve a instrução lida da memória no registrador de instrução
                    Reg_w = 1'b0;
                    AB_w = 1'b0;
                     RB_w = 1'b0;

                    ULA_c = 3'b001; // Controla a ULA para somar PC + 4
                    M_WREG = 1'b0;
                    M_ULAA = 1'b0;
                    M_ULAB = 2'b01;
                    rst_out = 1'b0; 
                    COUNTER = COUNTER + 1;
                    MEM_TO_REG_Selector = 3'b000;

                end 
                // PC e IR já foram atualizados, agora é hora de preparar os sinais de controle para a próxima instrução 
                else if (COUNTER == 3'b100 ) begin
                    STATE = ST_COMMON;
                    PC_w = 1'b0; 
                    MEM_w = 1'b0;
                    IR_w = 1'b1; 
                    Reg_w = 1'b0;
                    AB_w = 1'b1;
                    RB_w = 1'b0;
                    ULA_c = 3'b000; 
                    M_WREG = 1'b0;
                    M_ULAA = 1'b0;
                    M_ULAB = 2'b00;
                    rst_out = 1'b0; 
                    COUNTER = COUNTER + 1;
                    MEM_TO_REG_Selector = 3'b000;
                end 
                else if (COUNTER == 3'b101) begin
                    // Inicio das instruções
                    case (OPCODE)
                        R_TYPE: begin
                            funct = OFFSET[5:0];
                            if (funct == ADD)
                                STATE = ST_ADD;
                            else if (funct == SUB)
                                STATE = ST_SUB;
                            else if (funct == AND_OP)
                                STATE = ST_AND;
                            else if (funct == JR)
                                STATE = ST_JR;
                            else if (funct == MULT)
                                STATE = ST_MULT;
                            else if (funct == DIV)
                                STATE = ST_DIV;
                            else if (funct == MFHI)
                                STATE = ST_MFHI;
                            else if (funct == MFLO)
                                STATE = ST_MFLO;
                        end
                        ADDI: begin
                            STATE = ST_ADDI;
                        end
                        RESET: begin
                            STATE = ST_RESET;
                        end
                    endcase
                    PC_w = 1'b0; 
                    MEM_w = 1'b0;
                    IR_w = 1'b0; 
                    Reg_w = 1'b0;
                    AB_w = 1'b0;
                    RB_w = 1'b0;
                    ULA_c = 3'b000; 
                    M_WREG = 1'b0;
                    M_ULAA = 1'b0;
                    M_ULAB = 2'b00;
                    rst_out = 1'b0; 
                    COUNTER = 3'b000;

                end
            end
            // Estado de adição, add
            ST_ADD: begin
                if(COUNTER == 3'b000) begin
                    MEM_TO_REG_Selector = 3'b000;

                    STATE = ST_ADD;
                    PC_w = 1'b0;
                    MEM_w = 1'b0;
                    IR_w = 1'b0;
                    Reg_w = 1'b0;
                    AB_w = 1'b0;
                    RB_w = 1'b1;
                    ULA_c = 3'b001; // Controla a ULA para somar os operandos
                    M_WREG = 1'b1; 
                    M_ULAA = 1'b1;
                    M_ULAB = 2'b00;
                    rst_out = 1'b0;
                    COUNTER = COUNTER + 1;

                end

                else if(COUNTER == 3'b001) begin
                    MEM_TO_REG_Selector = 3'b000;

                    STATE = ST_COMMON;
                    PC_w = 1'b0;
                    MEM_w = 1'b0;
                    IR_w = 1'b0;
                    Reg_w = 1'b1; // Escreve o resultado da ULA no registrador de destino
                    AB_w = 1'b0;
                    RB_w = 1'b0;
                    ULA_c = 3'b001; // Controla a ULA para somar os operandos
                    M_WREG = 1'b1; 
                    M_ULAA = 1'b1;
                    M_ULAB = 2'b00;
                    rst_out = 1'b0;
                    COUNTER = 3'b000; // Volta para o estado comum após a execução da instrução

                end
            end
            ST_SUB: begin
                if(COUNTER == 3'b000) begin
                    MEM_TO_REG_Selector = 3'b000;

                    STATE = ST_SUB;
                    PC_w = 1'b0;
                    MEM_w = 1'b0;
                    IR_w = 1'b0;
                    Reg_w = 1'b0;
                    AB_w = 1'b0;
                    RB_w = 1'b1;    
                    ULA_c = 3'b010; // Controla a ULA para subtrair os operandos
                    M_WREG = 1'b1; 
                    M_ULAA = 1'b1;
                    M_ULAB = 2'b00;
                    rst_out = 1'b0;
                    COUNTER = COUNTER + 1;

                end

                else if(COUNTER == 3'b001) begin
                    MEM_TO_REG_Selector = 3'b000;

                    STATE = ST_COMMON;
                    PC_w = 1'b0;
                    MEM_w = 1'b0;
                    IR_w = 1'b0;
                    Reg_w = 1'b1; // Escreve o resultado da ULA no registrador de destino
                    AB_w = 1'b0;
                    RB_w = 1'b0;
                    ULA_c = 3'b010; // Controla a ULA para subtrair os operandos
                    M_WREG = 1'b1; 
                    M_ULAA = 1'b1;
                    M_ULAB = 2'b00;
                    rst_out = 1'b0;
                    COUNTER = 3'b000; // Volta para o estado comum após a execução da instrução
                end
            end
            ST_AND: begin
                if(COUNTER == 3'b000) begin
                    MEM_TO_REG_Selector = 3'b000;

                    STATE = ST_AND;
                    PC_w = 1'b0;
                    MEM_w = 1'b0;
                    IR_w = 1'b0;
                    Reg_w = 1'b0;
                    AB_w = 1'b0;
                    RB_w = 1'b1;
                    ULA_c = 3'b011; // Controla a ULA para somar os operandos
                    M_WREG = 1'b1; 
                    M_ULAA = 1'b1;
                    M_ULAB = 2'b00;
                    rst_out = 1'b0;
                    COUNTER = COUNTER + 1;
                end

                else if(COUNTER == 3'b001) begin
                    MEM_TO_REG_Selector = 3'b000;

                    STATE = ST_COMMON;
                    PC_w = 1'b0;
                    MEM_w = 1'b0;
                    IR_w = 1'b0;
                    Reg_w = 1'b1; // Escreve o resultado da ULA no registrador de destino
                    AB_w = 1'b0;
                    RB_w = 1'b0;
                    ULA_c = 3'b011; // Controla a ULA para somar os operandos
                    M_WREG = 1'b1; 
                    M_ULAA = 1'b1;
                    M_ULAB = 2'b00;
                    rst_out = 1'b0;
                    COUNTER = 3'b000; // Volta para o estado comum após a execução da instrução
                end
            end

            // JR
            ST_JR: begin
                if(COUNTER == 3'b000) begin
                    MEM_TO_REG_Selector = 3'b000;

                    STATE = ST_JR;
                    PC_w = 1'b0;
                    MEM_w = 1'b0;
                    IR_w = 1'b0;
                    Reg_w = 1'b0;
                    AB_w = 1'b0;  
                    ULA_c = 3'b000; // Controla a ULA para subtrair os operandos
                    M_WREG = 1'b1; 
                    M_ULAA = 1'b1;
                    M_ULAB = 2'b00;
                    rst_out = 1'b0;
                    COUNTER = COUNTER + 1;

                end
                else if(COUNTER == 3'b001) begin
                    MEM_TO_REG_Selector = 3'b000;

                    STATE = ST_COMMON;
                    PC_w = 1'b0;
                    MEM_w = 1'b0;
                    IR_w = 1'b0;
                    Reg_w = 1'b0;
                    AB_w = 1'b0;  
                    ULA_c = 3'b000; // Controla a ULA para subtrair os operandos
                    M_WREG = 1'b1; 
                    M_ULAA = 1'b1;
                    M_ULAB = 2'b00;
                    rst_out = 1'b0;
                    COUNTER = 3'b000; // Volta para o estado comum após a execução da instrução
                end
            end
            // Estado de adição imediata, addi
            ST_ADDI: begin
                if(COUNTER == 3'b000) begin
                    MEM_TO_REG_Selector = 3'b000;

                    STATE = ST_ADDI;
                    PC_w = 1'b0;
                    MEM_w = 1'b0;
                    IR_w = 1'b0;
                    Reg_w = 1'b1;
                    AB_w = 1'b0;
                    RB_w = 1'b1;
                    ULA_c = 3'b001; // Controla a ULA para somar os operandos
                    M_WREG = 1'b1; 
                    M_ULAA = 1'b1;
                    M_ULAB = 2'b10;
                    rst_out = 1'b0;
                    COUNTER = COUNTER + 1;
                end

                else if(COUNTER == 3'b001) begin
                    MEM_TO_REG_Selector = 3'b000;

                    STATE = ST_COMMON;
                    PC_w = 1'b0;
                    MEM_w = 1'b0;
                    IR_w = 1'b0;
                    Reg_w = 1'b1; // Escreve o resultado da ULA no registrador de destino
                    AB_w = 1'b0;
                    RB_w = 1'b1;
                    ULA_c = 3'b001; // Controla a ULA para somar os operandos
                    M_WREG = 1'b0; 
                    M_ULAA = 1'b1;
                    M_ULAB = 2'b10;
                    rst_out = 1'b0;
                    COUNTER = 3'b000; // Volta para o estado comum após a execução da instrução
                end
            end

            ST_MULT: begin
                if (COUNTER == 3'b000) begin
                    HI_Write = 1'b0;
                    LO_Write = 1'b0;
                    HI_Control = 1'b0;  // saida do multiplier
                    LO_Control = 1'b0;
                    Reg_w = 1'b0;
                    MEM_TO_REG_Selector = 3'b000;
                    // manter outros sinais em valores padrão
                    PC_w = 1'b0; MEM_w = 1'b0; IR_w = 1'b0;
                    AB_w = 1'b0; RB_w = 1'b0;
                    M_WREG = 1'b0; M_ULAA = 1'b0; M_ULAB = 2'b00;
                    STATE = ST_MULT;
                    COUNTER = COUNTER + 1;
                end else if (COUNTER == 3'b001) begin
                    HI_Write = 1'b1;
                    LO_Write = 1'b1;
                    HI_Control = 1'b0;
                    LO_Control = 1'b0;
                    STATE = ST_COMMON;
                    COUNTER = 3'b000;
                    // desligar escrita do banco
                    Reg_w = 1'b0;
                end
            end

            ST_DIV: begin
                if (COUNTER == 3'b000) begin
                    HI_Write = 1'b0;
                    LO_Write = 1'b0;
                    HI_Control = 1'b1;  // saida do divisor
                    LO_Control = 1'b1;
                    Reg_w = 1'b0;
                    MEM_TO_REG_Selector = 3'b000;
                    PC_w = 1'b0; MEM_w = 1'b0; IR_w = 1'b0;
                    AB_w = 1'b0; RB_w = 1'b0;
                    M_WREG = 1'b0; M_ULAA = 1'b0; M_ULAB = 2'b00;
                    STATE = ST_DIV;
                    COUNTER = COUNTER + 1;
                end else if (COUNTER == 3'b001) begin
                    if (div_zero) begin
                        // Se divisão por zero, não escreve (ou escreve 255 em HI/LO)
                        HI_Write = 1'b0;
                        LO_Write = 1'b0;
                    end else begin
                        HI_Write = 1'b1;
                        LO_Write = 1'b1;
                    end
                    STATE = ST_COMMON;
                    COUNTER = 3'b000;
                end
            end

            ST_MFHI: begin
                // Um único ciclo
                HI_Write = 1'b0;
                LO_Write = 1'b0;
                Reg_w = 1'b1;
                M_WREG = 1'b1;            // destino = rd (campo 15:11)
                MEM_TO_REG_Selector = 3'b010;  // seleciona HI_out no mux
                PC_w = 1'b0; MEM_w = 1'b0; IR_w = 1'b0;
                AB_w = 1'b0; RB_w = 1'b0;
                ULA_c = 3'b000;
                M_ULAA = 1'b0; M_ULAB = 2'b00;
                STATE = ST_COMMON;
                COUNTER = 3'b000;
            end

            ST_MFLO: begin
                HI_Write = 1'b0;
                LO_Write = 1'b0;
                Reg_w = 1'b1;
                M_WREG = 1'b1;
                MEM_TO_REG_Selector = 3'b011;  // LO_out
                PC_w = 1'b0; MEM_w = 1'b0; IR_w = 1'b0;
                AB_w = 1'b0; RB_w = 1'b0;
                ULA_c = 3'b000;
                M_ULAA = 1'b0; M_ULAB = 2'b00;
                STATE = ST_COMMON;
                COUNTER = 3'b000;
            end
             
            ST_RESET: begin
                STATE = ST_COMMON; // Volta para o estado comum após o reset
                PC_w = 1'b0;
                MEM_w = 1'b0;
                IR_w = 1'b0;
                Reg_w = 1'b0;
                AB_w = 1'b0;
                RB_w = 1'b0;
                ULA_c = 3'b000;
                M_WREG = 1'b0;
                M_ULAA = 1'b0;
                M_ULAB = 2'b00;
                rst_out = 1'b1; // Sinal de reset para o processador
                COUNTER = 3'b000;
            end

        endcase
    end

end


endmodule