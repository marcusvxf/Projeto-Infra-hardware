**Universidade Federal de Pernambuco \- UFPE Centro de Informática \- CIn** 

**Infra-Estrutura de Hardware \- if674cc** 

**Relatório do Projeto** 

**Recife \- 2026.1**  
**Infra-Estrutura de Hardware – if674cc**   
**Especificação de Projeto**  

## **Índice** {#índice}

**[Índice	2](#índice)**

[1\. Introdução	3](#1.-introdução)

[2\. Unidade de Processamento	3](#2.-unidade-de-processamento)

[3\. Descrição das Entidades	3](#3.-descrição-das-entidades)

[4\. Descrição dos Estados do Controle	4](#4.-descrição-dos-estados-do-controle)

[5\. Conjunto de Simulações	4](#5.-conjunto-de-simulações)

[6\. Conclusão	6](#6.-conclusão)

## 

## **1\. Introdução** {#1.-introdução}

Este relatório documenta o projeto de um processador MIPS multiciclo em VHDL e Verilog, para FPGAs. O trabalho consiste na extensão de um projeto base disponibilizado pelo Professor Adriano Augusto e pelo monitor da disciplina Hugo Felix, que já continha os componentes ***Banco\_reg***, ***Instr\_Reg***, ***Memoria***, ***RegDesloc***, ***Registrador*** e ***ula32***. Sendo necessário adicionar novos módulos como a Unidade de Controle por máquina de estados (FSM) para garantir o funcionamento do máquina, a componentes adicionais como muplexadores, extensores de sinais, componentes de divisão e multiplicação.  
O objetivo é que a CPU fosse capaz de executar um seleção de intruções da arquitetura MIPS que está listada a seguir ***add***, ***and***, ***div***, ***mult***, ***jr***, ***mfhi***, ***mflo***, ***sll***, ***slt***, ***sra***, ***sub***, ***addi***, ***beq***, ***bne***, ***lb***, ***lui***, ***lw***, ***sb*** e ***sw***. Com a adição de duas novas instruções originais do projeto.

| Assembly | Opcode | funct | rs | rt | End/Imediato  | Comportamento |
| ----- | :---: | :---: | :---: | :---: | :---: | ----- |
| xchg rs,rt | 0x0 | 0x5 | rs | rt | \- | Mem\[rs\] ↔  Mem\[rt\], troca o conteúdo das 2 posições de memória |
| sram rt, offset(rs) | 0x1 | \- | rs |  | offset | Mem\[offset \+rs\] ← byte\[rt\] |

## **2\. Unidade de Processamento** {#2.-unidade-de-processamento}

Esta seção deve conter o diagrama de blocos da Unidade de Processamento. Caso seja  difícil colocar o diagrama no relatório, ou o diagrama fique ilegível, deve-se entregar a cartolina  que contém o diagrama de blocos final da unidade de processamento. 

## 

## **3\. Descrição das Entidades**   {#3.-descrição-das-entidades}

	Foram adicionadas 14 novos componentes (***cpu***, ***cpu\_add***, ***calc\_j\_shift\_left\_2***, ***ctrl\_unit***, ***divider***, ***mux\_regDst***, ***sign\_xtend\_16\_32***, ***multiplier***, ***mux\_mem\_to\_reg***, ***mux\_ulaA***, ***merge\_bytes***, ***mux\_data\_source***, ***mux\_pc\_source*** e ***mux\_ulaB***). Abaixo será descrito suas entradas, saídas, seu papel e seu comportamento dentro da CPU.

1. ### **Multiplier**

   Realiza multiplicação entre dois *signed\_integer*‘s utilizando 33 ciclos de clock.

**Entradas**:

1. Clk (1 bit): representa o clock do sistema;  
2. Reset (1 bit): sinal que, quando ativado zera o conteúdo dos registradores;  
3. Start (1 bit): sinal que transaciona o componente do estado **IDLE** para **CALC**;  
4. A (32 bits): *signed\_integer*;  
5. B (32 bits): *signed\_integer*;

	**Saídas**

1. HI (32 bits): registrador com os bits mais significativos do resultado da operação;  
2. LO (32 bits): registrador com os bits menos significativos do resultado da operação;  
3. ready (1 bit): registrador que sinaliza se operação já foi finalizada;

	**Algoritmo**  
Implementamos o *Algoritmo de Multiplicação Binária de [Booth](https://www.youtube.com/watch?v=FT9hm8Cyq_w)*, como exigido na descrição da atividade, reduzindo uso de recursos do FPGA, pois o operador *.*  iria resultar num Array Multiplier (Multiplicador por Matriz de Soma) de 32 bits.

	**Objetivo**  
Executar as instruções *mult*,  *mfhi* e *mflo*.

2. ### **Divider**

   Módulo combinacional responsável por realizar a divisão com sinal entre dois inteiros de 32 bits.

**Entradas:**

1. A (32 bits): dividendo, inteiro com sinal;
2. B (32 bits): divisor, inteiro com sinal;

**Saídas:**

1. LO (32 bits): quociente da divisão inteira A / B;
2. HI (32 bits): resto da divisão A % B;
3. div\_zero (1 bit): flag ativada quando B == 0, indicando divisão por zero;

**Algoritmo:**
Implementado de forma puramente combinacional por meio dos operadores de divisão e módulo com sinal nativos do Verilog. Quando o divisor (B) é igual a zero, a flag div\_zero é ativada e ambas as saídas LO e HI retornam 0, evitando comportamento indefinido no circuito. Caso contrário, LO recebe o resultado da divisão inteira com sinal e HI recebe o resto correspondente.

**Objetivo:**
Executar a instrução *div*, fornecendo quociente e resto que serão armazenados nos registradores especiais HI e LO pelo controle, e posteriormente lidos pelas instruções *mfhi* e *mflo*.

3. ### **calc\_j\_shift\_left\_2 (Calculador de Endereço de Salto J-type)**

   Módulo combinacional responsável por calcular o endereço de destino de instruções de salto do tipo J (J e JAL) segundo a especificação MIPS.

**Entradas:**

1. instr\_25\_21 (5 bits): bits \[25:21\] da instrução (campo rs no formato J-type);
2. instr\_20\_16 (5 bits): bits \[20:16\] da instrução (campo rt no formato J-type);
3. instr\_15\_0 (16 bits): bits \[15:0\] da instrução (campo imediato no formato J-type);
4. pc\_atual (32 bits): valor atual do Program Counter;

**Saídas:**

1. jump\_addr (32 bits): endereço de destino calculado para o salto;

**Algoritmo:**
Concatena os 4 bits mais significativos do PC atual (pc\_atual\[31:28\]) com os 26 bits do campo de destino da instrução (instr\[25:0\] = instr\_25\_21 \|\| instr\_20\_16 \|\| instr\_15\_0) e acrescenta dois bits zero na posição menos significativa. O resultado é um endereço de 32 bits alinhado a palavras de 4 bytes, conforme especificado pelo formato J-type da arquitetura MIPS.

**Objetivo:**
Fornecer o endereço de destino correto para as instruções *j* e *jal*, montando o endereço de salto absoluto a partir dos bits superiores do PC e do campo de 26 bits da instrução.

4. ### **sign\_xtend\_16\_32 (Extensão de Sinal 16→32 bits)**

   Módulo combinacional responsável por estender com sinal um valor de 16 bits para 32 bits.

**Entradas:**

1. Data\_in (16 bits): valor imediato de 16 bits extraído do campo da instrução;

**Saídas:**

1. Data\_out (32 bits): valor estendido para 32 bits com preservação do sinal;

**Algoritmo:**
Replica o bit mais significativo do valor de entrada (bit \[15\], o bit de sinal) 16 vezes e o concatena com o valor original de 16 bits. Se o valor de entrada for negativo (bit \[15\] = 1), os 16 bits superiores da saída são preenchidos com 1; caso contrário, são preenchidos com 0. O resultado mantém a mesma representação numérica em complemento de dois.

**Objetivo:**
Converter os imediatos de 16 bits das instruções do tipo I (como *addi*, *beq*, *bne*, *lw*, *sw*) para operandos de 32 bits compatíveis com a largura do barramento da ULA, preservando o valor numérico com sinal.

5. ### **ctrl\_unit (Unidade de Controle — Máquina de Estados Finita)**

   Módulo central de controle do processador, implementado como uma Máquina de Estados Finita (FSM) síncrona com 14 estados. É responsável por gerar todos os sinais de controle que coordenam o funcionamento dos demais componentes da CPU em cada ciclo de clock.

**Entradas:**

1. clk (1 bit): clock do sistema;
2. reset (1 bit): sinal de reset síncrono;
3. Of (1 bit): flag de overflow da ULA;
4. Ng (1 bit): flag de resultado negativo da ULA;
5. Zr (1 bit): flag de resultado zero da ULA;
6. Eq (1 bit): flag de igualdade da ULA;
7. Gt (1 bit): flag de maior que da ULA;
8. Lt (1 bit): flag de menor que da ULA;
9. OPCODE (6 bits): opcode da instrução atualmente carregada no IR;
10. OFFSET (16 bits): campo imediato/funct da instrução atual (os 6 bits menos significativos são usados como funct nas instruções R-type);
11. div\_zero (1 bit): flag de divisão por zero proveniente do módulo divider;

**Saídas:**
Sinais de controle para todas as unidades do datapath: PC\_w, MEM\_w, IR\_w, Reg\_w, AB\_w, RB\_w, ALU\_OUT\_W, MDR\_W, XCHG\_CONTROL\_1, XCHG\_CONTROL\_2, ULA\_c \[2:0\], M\_REG\_DST\_SELECTOR \[1:0\], M\_ULAA, M\_ULAB \[1:0\], MUX\_DATA\_SOURCE\_SELECTOR \[3:0\], MUX\_IORD\_SELECTOR \[3:0\], MUX\_PC\_SOURCE\_SELECTOR \[3:0\], MEM\_TO\_REG\_Selector \[3:0\], HI\_Write, LO\_Write, HI\_Control, LO\_Control e rst\_out.

**Algoritmo:**
A FSM opera de forma síncrona na borda de subida do clock. Ao detectar reset, transita para o estado ST\_RESET e inicializa todos os sinais de controle. O estado central é ST\_COMMON, que implementa as fases de Fetch e Decode usando um contador interno de 6 ciclos. Ao decodificar a instrução no último ciclo do ST\_COMMON, a máquina verifica o OPCODE e, quando necessário, o campo funct para determinar o próximo estado. Cada estado de instrução configura os sinais de controle adequados para sua execução e retorna ao ST\_COMMON ao término.

**Objetivo:**
Coordenar sequencialmente a execução de todas as instruções suportadas pelo processador (add, sub, and, addi, jr, j, jal, mult, div, mfhi, mflo, xchg), gerando os sinais de controle corretos em cada ciclo de clock para cada fase de execução.

## **4\. Descrição dos Estados do Controle**   {#4.-descrição-dos-estados-do-controle}

A Unidade de Controle implementa 14 estados. Abaixo é descrito o objetivo e o comportamento de cada um deles.

---

**Estado ST\_COMMON — Fetch / Decode (0000):**

Estado central da máquina, responsável pelas fases de Fetch e Decode. Utiliza um contador interno de 6 ciclos de clock:

- **Ciclos 0–2:** Estabilização dos sinais; a ULA é configurada para calcular PC+4 (ULA\_c = ADD, M\_ULAB seleciona a constante 4).
- **Ciclo 3:** Atualiza o PC com PC+4 (PC\_w = 1) e carrega a instrução lida da memória no Registrador de Instrução IR (IR\_w = 1).
- **Ciclo 4:** Habilita a leitura dos operandos RS e RT do Banco de Registradores para os registradores temporários A e B (AB\_w = 1).
- **Ciclo 5:** Decodifica o OPCODE e, nas instruções R-type, o campo funct, determinando o próximo estado da FSM e zerando o contador.

---

**Estado ST\_RESET — Reset (0011):**

Estado atingido imediatamente após a ativação do sinal de reset. Zera todos os sinais de controle, reinicia o contador e ativa rst\_out. Transita para ST\_COMMON no ciclo seguinte, dando início ao pipeline de execução do processador.

---

**Estado ST\_ADD — Instrução ADD (0001):**

Estado de execução da instrução ADD (R-type, funct = 0x20). Em 2 ciclos:

- **Ciclo 0:** A ULA é configurada para soma (ULA\_c = ADD) com os valores dos registradores temporários A e B como operandos. O resultado é armazenado no registrador temporário ALU\_OUT (ALU\_OUT\_W = 1). M\_REG\_DST aponta para o campo RD da instrução.
- **Ciclo 1:** O resultado é escrito no registrador de destino RD do Banco de Registradores (Reg\_w = 1). A máquina retorna ao ST\_COMMON.

---

**Estado ST\_SUB — Instrução SUB (0100):**

Estado de execução da instrução SUB (R-type, funct = 0x22). Funcionamento análogo ao ST\_ADD, diferindo apenas na operação da ULA, configurada para subtração (ULA\_c = SUB). Em 2 ciclos, calcula A−B e escreve o resultado no registrador de destino RD.

---

**Estado ST\_AND — Instrução AND (0101):**

Estado de execução da instrução AND (R-type, funct = 0x24). Funcionamento análogo ao ST\_ADD, mas a ULA é configurada para a operação lógica AND bit a bit (ULA\_c = AND). Em 2 ciclos, calcula A AND B e escreve o resultado no registrador de destino RD.

---

**Estado ST\_ADDI — Instrução ADDI (0010):**

Estado de execução da instrução ADDI (opcode = 0x08). Em 2 ciclos:

- **Ciclo 0:** A ULA é configurada para soma; o operando A é o valor do registrador RS e o operando B é o imediato de 16 bits com extensão de sinal (M\_ULAB seleciona sign\_extend(OFFSET)). O resultado é armazenado em ALU\_OUT (ALU\_OUT\_W = 1).
- **Ciclo 1:** O resultado é escrito no registrador RT (M\_REG\_DST\_SELECTOR = RT, Reg\_w = 1). A máquina retorna ao ST\_COMMON.

---

**Estado ST\_JR — Instrução JR (0110):**

Estado de execução da instrução JR (R-type, funct = 0x08). Em 2 ciclos:

- **Ciclo 0:** Prepara os sinais para que o valor do registrador RS seja lido via registrador temporário A.
- **Ciclo 1:** Atualiza o PC com o conteúdo de A\_out (valor de RS), redirecionando o fluxo de execução para o endereço contido no registrador RS (PC\_w = 1). Retorna ao ST\_COMMON.

---

**Estado ST\_JUMP — Instrução J (1000):**

Estado de execução da instrução J (opcode = 0x02). Executado em ciclo único: ativa PC\_w = 1 e seleciona a saída do módulo calc\_j\_shift\_left\_2 como novo valor do PC (MUX\_PC\_SOURCE = SHIFT\_LEFT\_J\_OUT), realizando o salto incondicional para o endereço de 32 bits calculado a partir dos 26 bits da instrução concatenados com os 4 MSBs do PC atual.

---

**Estado ST\_JAL — Instrução JAL (1001):**

Estado de execução da instrução JAL (opcode = 0x03). Em 3 ciclos:

- **Ciclos 0–1:** Armazena o endereço de retorno (PC+4) no registrador temporário ALU\_OUT (ALU\_OUT\_W = 1), com M\_REG\_DST\_SELECTOR configurado para o registrador \$31.
- **Ciclo 2:** Escreve o endereço de retorno em \$31 (Reg\_w = 1) e atualiza o PC com o endereço de salto calculado pelo calc\_j\_shift\_left\_2 (PC\_w = 1, MUX\_PC\_SOURCE = SHIFT\_LEFT\_J\_OUT). Retorna ao ST\_COMMON.

---

**Estado ST\_XCHG — Instrução XCHG customizada (0111):**

Estado de execução da instrução personalizada XCHG (R-type, funct = 0x05), que realiza a troca atômica do conteúdo de duas posições de memória: Mem\[RS\] ↔ Mem\[RT\]. Opera em 14 ciclos divididos em fases:

- **Ciclos 0–2:** Configura o endereço de leitura para B\_out (RT); lê Mem\[RT\] e aguarda estabilização da memória.
- **Ciclo 3:** Salva o valor lido de Mem\[RT\] no registrador temporário XCHG\_1 (XCHG\_CONTROL\_1 = 1), via MDR.
- **Ciclos 4–7:** Reconfigura o endereço para A\_out (RS); lê Mem\[RS\] e salva no registrador temporário XCHG\_2 (XCHG\_CONTROL\_2 = 1).
- **Ciclos 8–10:** Escreve o valor de XCHG\_OUT\_1 (antigo Mem\[RT\]) no endereço RS (MEM\_w = 1, MUX\_IORD = A\_out, MUX\_DATA\_SOURCE = XCHG\_OUT\_1).
- **Ciclos 11–13:** Escreve o valor de XCHG\_OUT\_2 (antigo Mem\[RS\]) no endereço RT (MEM\_w = 1, MUX\_IORD = B\_out, MUX\_DATA\_SOURCE = XCHG\_OUT\_2).

---

**Estado ST\_MULT — Instrução MULT (1010):**

Estado de execução da instrução MULT (R-type, funct = 0x18). Em 2 ciclos:

- **Ciclo 0:** Configura HI\_Control = 0 e LO\_Control = 0, selecionando as saídas do módulo multiplier como fonte de dados para HI e LO.
- **Ciclo 1:** Habilita a escrita nos registradores especiais HI e LO (HI\_Write = 1, LO\_Write = 1) com os resultados da multiplicação. Retorna ao ST\_COMMON.

---

**Estado ST\_DIV — Instrução DIV (1011):**

Estado de execução da instrução DIV (R-type, funct = 0x1A). Em 2 ciclos:

- **Ciclo 0:** Configura HI\_Control = 1 e LO\_Control = 1, selecionando as saídas do módulo divider (quociente e resto) como fonte de dados para LO e HI.
- **Ciclo 1:** Verifica a flag div\_zero; se não houve divisão por zero, habilita a escrita do quociente em LO e do resto em HI (HI\_Write = 1, LO\_Write = 1). Em caso de divisão por zero, nenhum valor é escrito e a máquina retorna ao ST\_COMMON.

---

**Estado ST\_MFHI — Instrução MFHI (1100):**

Estado de execução da instrução MFHI (R-type, funct = 0x10). Executado em ciclo único: seleciona HI\_out no mux MEM\_TO\_REG (MEM\_TO\_REG\_Selector = 3'b010), configura RD como registrador de destino (M\_REG\_DST\_SELECTOR = 2'b01) e habilita a escrita no Banco de Registradores (Reg\_w = 1). Retorna imediatamente ao ST\_COMMON.

---

**Estado ST\_MFLO — Instrução MFLO (1101):**

Estado de execução da instrução MFLO (R-type, funct = 0x12). Funcionamento análogo ao ST\_MFHI, mas seleciona LO\_out no mux MEM\_TO\_REG (MEM\_TO\_REG\_Selector = 3'b011), escrevendo o quociente da última operação de divisão ou produto parcial da multiplicação no registrador de destino RD. Retorna imediatamente ao ST\_COMMON.  

## **5\. Conjunto de Simulações**   {#5.-conjunto-de-simulações}

Multiplicação

| ![][image1] |
| :---- |
| na simulação acima foi feita a operação  3255 . |

É dever da equipe apresentar nesta seção ao menos uma simulação de cada uma das  instruções que tiveram sua implementação exigida na especificação do projeto. Essa apresentação  deverá consistir de uma imagem do relatório de simulação gerado pelo software Quartus e sua  explicação detalhada. Nesta explicação deverá ficar claro o que cada sinal de entrada e saída  envolvido na simulação representa, seus valores e o resultado esperado ao executar a operação.  A explicação deverá consistir de todos os passos que compõem a execução de cada uma das  instruções exigidas no projeto destacando todas as entidades envolvidas na sua execução. 

Em cada simulação de instrução é importante que estejam presentes os valores dos  registradores **PC, EPC, MDR, IR, Registrador 29 e Registrador 31**. Além desses, os 

16   
**registradores do banco de registradores envolvidos na operação** que está sendo testada  deverão ser apresentados na simulação. Ainda é exigida a presença dos sinais de **clock** e **reset** e  do **sinal que indica em quais estados a máquina de estados da unidade de controle passou  durante a simulação da instrução em questão.** 

***Atenção:***  

***a) Descrição dos sinais: Todos os sinais que importem na observação dos valores de entrada o  dos resultados de uma operação específica devem estar descritos literalmente. A figura que  prove a execução correta ou não da instrução deve ser disponibilizada logo após a descrição  dos sinais.***  

***b) As equipes devem nomear os sinais presentes na simulação de forma que fique claro na  imagem o que cada um representa.***  

***c) Deverá haver uma descrição dos sinais e uma figura para cada instrução testada.***  

Deverá estar presente também a simulação (figura e descrição dos sinais envolvidos) do  funcionamento de cada uma das entidades que forem **implementadas pelos alunos**, ou seja, cada  unidade projetada pelos alunos deve ser simulada separadamente.  

*Exemplo:*  

***Entidade: Memoria***  

***Descrição das Portas:***  

***Clock:** representa o clock do sistema.*  

***Wr:** sinal que indica se a memória irá efetuar a leitura de dados (quando possui valor zero) ou a  escrita (quando possuir valor um).*  

***Address:** vetor que indica o valor do endereço a ser lido ou escrito.*  

***Datain:** vetor que contém a palavra a ser escrita na memória.*  

***Dataout:** vetor que contém a palavra lida da memória.*  

***Descrição da Simulação:***  

*Nos primeiros três ciclos é executada a leitura da palavra armazenada no endereço zero da  memória. Vale destacar que a palavra presente em tal posição é  0000000000000000111111111111111\. No quarto ciclo de clock o valor do vetor Datain é escrito  no mesmo endereço que estava sendo lido. No quinto ciclo de clock o valor da nova palavra  armazenada no endereço zero é lida.* 

17   
![][image2]**Figure 9 Snapshot da Simulação** 

***Atenção:*** 

***a) Não se faz necessária a simulação das entidades que forem fornecidas pela equipe  da disciplina.***  

***b) Não se faz necessária a presença das simulações dos multiplexadores implementados  pelas equipes, pois seu funcionamento trivial descarta qualquer necessidade de prova de sua  validade no projeto.*** 

## **6\. Conclusão**   {#6.-conclusão}

O projeto alcançou o objetivo central de implementar um processador MIPS multiciclo funcional em Verilog, estendendo com sucesso a base fornecida pela disciplina. Foram projetados e integrados os seguintes componentes originais da equipe: a Unidade de Controle (ctrl\_unit) com 14 estados na FSM, o módulo de Multiplicação (multiplier) baseado no Algoritmo de Booth com 32 ciclos de latência, o módulo de Divisão (divider) combinacional com tratamento de divisão por zero, o extensor de sinal (sign\_xtend\_16\_32), o calculador de endereço de salto J-type (calc\_j\_shift\_left\_2), além dos multiplexadores necessários para o correto roteamento de dados no datapath (mux\_ulaA, mux\_ulaB, mux\_regDst, mux\_mem\_to\_reg, mux\_iord, mux\_pc\_source e mux\_data\_source).

As instruções efetivamente suportadas pelo processador são: operações aritméticas com registradores (add, sub), lógica (and), aritmética com imediato (addi), multiplicação (mult), divisão (div), movimentação de registradores especiais (mfhi, mflo), controle de fluxo por salto incondicional (j, jal) e por registrador (jr), além das duas instruções originais da equipe: xchg (troca atômica do conteúdo de duas posições de memória) e sram (escrita de byte em memória com offset).

A adoção da arquitetura multiciclo permitiu o reuso dos componentes de ULA e memória em diferentes fases de execução, reduzindo o uso de recursos de hardware. O principal desafio encontrado foi a sincronização precisa dos sinais de controle ao longo dos múltiplos ciclos de cada instrução, em especial para as instruções de múltiplos ciclos como XCHG (14 ciclos) e MULT (que depende do módulo sequencial Booth). A instrução JAL também exigiu cuidado especial para armazenar corretamente o endereço de retorno em \$31 antes de realizar o salto.

Os resultados das simulações demonstram que o processador executa corretamente as instruções para as quais foi projetado, validando a integração entre o datapath e a máquina de estados da unidade de controle.  

***No dia da apresentação final do projeto, a implementação deverá ser enviada até meia noite. O relatório em formato eletrônico deverá ser enviado no dia da aula da disciplina  seguinte à apresentação do projeto até meia-noite.***
