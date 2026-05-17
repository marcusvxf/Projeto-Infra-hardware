module multiplier (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire [31:0] A,
    input  wire [31:0] B,
    output reg  [31:0] HI,
    output reg  [31:0] LO,
    output reg         ready      // Sinaliza que a multiplicação terminou
);
    reg [31:0] M;                 // Armazena o Multiplicando
    reg [64:0] AQ_Q1;             // Acumulador (A) + Multiplicador (Q) + Bit extra Booth (Q_-1)
    reg [5:0]  contador;          // Contador de 0 a 32
    reg        estado;            // Estado  | 0-IDLE | 1-CALC

    parameter IDLE = 1'b0;
    parameter CALC = 1'b1;

    // Fatias do registrador AQ_Q1 para facilitar a leitura lógica
    wire [31:0] acum       = AQ_Q1[64:33];
    wire [1:0]  booth_bits = AQ_Q1[1:0];   // bits {Q_0, Q_-1}

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado   <= IDLE;
            contador <= 6'd0;
            AQ_Q1    <= 65'd0;
            M        <= 32'd0;
            HI       <= 32'd0;
            LO       <= 32'd0;
            ready    <= 1'b0;
        end else begin
            case (estado)
                IDLE: begin
                    if (start) begin
                        ready    <= 1'b0;
                        M        <= A;
                        AQ_Q1    <= {32'd0, B, 1'b0}; 
                        contador <= 6'd0;
                        estado   <= CALC;
                    end
                end

                CALC: begin
                    if (contador < 6'd32) begin
                        contador <= contador + 1'b1;
                        
                        case (booth_bits)
                            2'b01: begin // 01 - Adiciona M ao acumulador
                                AQ_Q1[64:33] <= acum + M;
                                AQ_Q1 <= $signed({acum + M, AQ_Q1[32:0]}) >>> 1;
                            end
                            2'b10: begin // 10 - Subtrai M do acumulador
                                AQ_Q1[64:33] <= acum - M;
                                AQ_Q1 <= $signed({acum - M, AQ_Q1[32:0]}) >>> 1;
                            end
                            default: begin // 00 e 11 - So desloca
                                AQ_Q1 <= $signed(AQ_Q1) >>> 1;
                            end
                        endcase
                    end else begin // FIM
                        HI     <= AQ_Q1[64:33];
                        LO     <= AQ_Q1[32:1];
                        ready  <= 1'b1;
                        estado <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
