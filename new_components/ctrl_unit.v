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
    output reg    rst_out
);

// Variaveis
reg [1:0] STATE = 2'b00; // estado da maquina de estados atualizar ao adicionar estados
reg [2:0] COUNTER;

// Estados principais da maquina 
parameter ST_COMMON = 2'b00;
parameter ST_ADD = 2'b01;
parameter ST_ADDI = 2'b10;
parameter ST_RESET = 2'b11;

// Opcode
parameter ADD = 6'b000000;
parameter ADDI = 6'b001000;
parameter RESET = 6'b111111;

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
                end 
                else if (COUNTER == 3'b101) begin
                    // Inicio das instruções
                    case (OPCODE)
                        ADD: begin
                            STATE = ST_ADD;
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
            // Estado de adição imediata, addi
            ST_ADDI: begin
                if(COUNTER == 3'b000) begin
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