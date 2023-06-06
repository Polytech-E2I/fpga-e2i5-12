library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.PKG.all;


entity CPU_PC is
    generic(
        mutant: integer := 0
    );
    Port (
        -- Clock/Reset
        clk    : in  std_logic ;
        rst    : in  std_logic ;

        -- Interface PC to PO
        cmd    : out PO_cmd ;
        status : in  PO_status
    );
end entity;

architecture RTL of CPU_PC is
    type State_type is (
        S_Error,
        S_Init,
        S_Pre_Fetch,
        S_Fetch,
        S_Decode,
        S_LUI,
        S_ADDI,
        S_ADD,
        S_AUIPC,
        S_SLL,
        S_SLLI,
        S_SRL,
        S_SRLI,
        S_SRA,
        S_SRAI,
        S_ORI,
        S_ANDI,
        S_OR,
        S_AND,
        S_XOR,
        S_XORI,
        S_SUB,
        S_SLT,
        S_SLTI,
        S_SLTU,
        S_SLTIU,
        S_BRANCH,
        S_Pre_LW,
        S_LW,
        S_Post_LW,
        S_Pre_SW,
        S_SW,
        S_JAL,
        S_JALR,
        S_MRET,
        S_CSRR
    );

    signal state_d, state_q : State_type;

begin
    FSM_synchrone : process(clk)
    begin
        if clk'event and clk='1' then
            if rst='1' then
                state_q <= S_Init;
            else
                state_q <= state_d;
            end if;
        end if;
    end process FSM_synchrone;

    FSM_comb : process (state_q, status)
    begin

        -- Valeurs par défaut de cmd à définir selon les préférences de chacun
        cmd.ALU_op            <= ALU_plus;
        cmd.LOGICAL_op        <= LOGICAL_and;
        cmd.ALU_Y_sel         <= ALU_Y_rf_rs2;

        cmd.SHIFTER_op        <= SHIFT_ll;
        cmd.SHIFTER_Y_sel     <= SHIFTER_Y_rs2;

        cmd.RF_we             <= '0';
        cmd.RF_SIZE_sel       <= RF_SIZE_word;
        cmd.RF_SIGN_enable    <= '1';
        cmd.DATA_sel          <= DATA_from_alu;

        cmd.PC_we             <= '0';
        cmd.PC_sel            <= PC_from_pc;

        cmd.PC_X_sel          <= PC_X_pc;
        cmd.PC_Y_sel          <= PC_Y_cst_x04;

        cmd.TO_PC_Y_sel       <= TO_PC_Y_cst_x04;

        cmd.AD_we             <= '0';
        cmd.AD_Y_sel          <= AD_Y_immI;

        cmd.IR_we             <= '0';

        cmd.ADDR_sel          <= ADDR_from_pc;
        cmd.mem_we            <= '0';
        cmd.mem_ce            <= '0';

        cmd.cs.CSR_we            <= CSR_mstatus;

        cmd.cs.TO_CSR_sel        <= TO_CSR_from_imm;
        cmd.cs.CSR_sel           <= CSR_from_mip;
        cmd.cs.MEPC_sel          <= MEPC_from_pc;

        cmd.cs.MSTATUS_mie_set   <= '0';
        cmd.cs.MSTATUS_mie_reset <= '0';

        cmd.cs.CSR_WRITE_mode    <= WRITE_mode_simple;

        state_d <= state_q;

        case state_q is
            when S_Error =>
                -- Etat transitoire en cas d'instruction non reconnue
                -- Aucune action
                state_d <= S_Init;

            when S_Init =>
                -- PC <- RESET_VECTOR
                cmd.PC_we <= '1';
                cmd.PC_sel <= PC_rstvec;
                state_d <= S_Pre_Fetch;

            when S_Pre_Fetch =>
                -- mem[PC]
                cmd.mem_we   <= '0';
                cmd.mem_ce   <= '1';
                cmd.ADDR_sel <= ADDR_from_pc;
                state_d      <= S_Fetch;

            -- modification of S_Fetch
            when S_Fetch =>
                -- IR <- mem_datain
                cmd.IR_we <= '1';
                state_d <= S_Decode;
				--  add this
                cmd.cs.MEPC_sel <= MEPC_from_pc;
                cmd.PC_sel <= PC_mtvec;
                if status.it then
                    -- MEPC <- PC
                    cmd.cs.CSR_we <= CSR_MEPC;
                    -- MSTATUS(3) <- 0
                    cmd.cs.MSTATUS_mie_set <= '1';
                    -- PC <- 0x00001FFC
                    cmd.PC_we <= '1';
                    state_d <= S_Pre_Fetch;
                end if;
				-- end add this

            when S_Decode =>

                -- PC <= PC + 4
                cmd.TO_PC_Y_sel <= TO_PC_Y_cst_x04;
                cmd.PC_sel <= PC_from_pc;
                cmd.PC_we <= '1';

                -- Prochain état par défaut
                state_d <= S_Error;

                case status.IR(4 downto 2) is

                    -- Type U
                    -- lui / auipc
                    when "101" =>
                        case status.IR(6 downto 5) is
                            -- lui
                            when "01" =>
                                state_d <= S_LUI;
                            -- auipc
                            when "00" =>
                                cmd.PC_we <= '0';
                                state_d <= S_AUIPC;
                            -- Error
                            when others => null;
                        end case;

                    when "100" =>
                        case status.IR(6 downto 5) is
                            -- Type I starting from addi
                            when "00" =>
                                case status.IR(14 downto 12) is
                                    -- addi
                                    when "000" =>
                                        state_d <= S_ADDI;
                                    -- slli
                                    when "001" =>
                                        state_d <= S_SLLI;
                                    when "101" =>
                                        case status.IR(30) is
                                            -- srli
                                            when '0' =>
                                                state_d <= S_SRLI;
                                            -- srai
                                            when '1' =>
                                                state_d <= S_SRAI;

                                            -- Error
                                            when others => null;
                                        end case;
                                    -- xori
                                    when "100" =>
                                        state_d <= S_XORI;
                                    -- ori
                                    when "110" =>
                                        state_d <= S_ORI;
                                    -- andi
                                    when "111" =>
                                        state_d <= S_ANDI;

                                    when "010" =>
                                        state_d <= S_SLTI;
                                    when "011" =>
                                        state_d <= S_SLTIU;

                                    -- Error
                                    when others => null;
                                end case;
                            -- Type R starting from add
                            when "01" =>
                                case status.IR(14 downto 12) is
                                    when "000" =>
                                        case status.IR(30) is
                                            -- add
                                            when '0' =>
                                                state_d <= S_ADD;
                                            -- sub
                                            when '1' =>
                                                state_d <= S_SUB;

                                            -- Error
                                            when others => null;
                                        end case;
                                    -- sll
                                    when "001" =>
                                        state_d <= S_SLL;
                                    when "101" =>
                                        case status.IR(30) is
                                            -- srl
                                            when '0' =>
                                                state_d <= S_SRL;
                                            -- sra
                                            when '1' =>
                                                state_d <= S_SRA;

                                            -- Error
                                            when others => null;
                                        end case;

                                    -- xor
                                    when "100" =>
                                        state_d <= S_XOR;
                                    -- or
                                    when "110" =>
                                        state_d <= S_OR;
                                    -- and
                                    when "111" =>
                                        state_d <= S_AND;

                                    when "010" =>
                                        state_d <= S_SLT;
                                    when "011" =>
                                        state_d <= S_SLTU;

                                    -- Error
                                    when others => null;
                                end case;

                            -- Error
                            when others => null;
                        end case;

                    when "000" =>
                        case status.IR(6 downto 5) is
                            -- Branch
                            when "11" =>
                                cmd.PC_we <= '0';
                                state_d <= S_BRANCH;

                            when "00" =>
                                case status.IR(14 downto 12) is
                                    -- Load from memory
                                    when "010" =>
                                        -- lw
                                        state_d <= S_Pre_LW;

                                    when others => null;
                                end case;

                            when "01" =>
                                case status.IR(14 downto 12) is
                                    -- Store in memory
                                    when "010" =>
                                        -- sw
                                        state_d <= S_Pre_SW;

                                    when others => null;
                                end case;

                            when others => null;
                        end case;

                    when "011" =>
                        -- jal
                        cmd.PC_we   <= '0';
                        state_d <= S_JAL;

                    when "001" =>
                        -- jalr
                        cmd.PC_we   <= '0';
                        state_d <= S_JALR;

                    when "111" =>
                        case status.IR( 3 downto 0 ) is
                            when "0011" => -- CSR
                                case status.IR( 14 downto 12 ) is
                                    when "000" =>
                                        state_d <= S_Mret;
                                    when "001"|"010"|"011"|"101"|"110"|"111" =>
                                        state_d <= S_Csrr;
                                    when others => null;
                                end case;
                            when others => null;
                        end case;

                    -- Error
                    when others => null;
                end case;

---------- Instructions avec immediat de type U ----------

            when S_LUI =>
                -- rd <- ImmU + 0
                cmd.PC_X_sel    <= PC_X_cst_x00;
                cmd.PC_Y_sel    <= PC_Y_immU;
                cmd.RF_we       <= '1';
                cmd.DATA_sel    <= DATA_from_pc;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;
            when S_AUIPC =>
                -- rd <- immU + pc
                cmd.PC_X_sel    <= PC_X_pc;
                cmd.PC_Y_sel    <= PC_Y_immU;
                cmd.RF_we       <= '1';
                cmd.DATA_sel    <= DATA_from_pc;

                -- next state
                cmd.PC_we       <= '1';
                state_d         <= S_Pre_Fetch;

---------- Instructions avec immediat de type I ----------

            when S_ADDI =>
                -- rd <- immI + rs1
                cmd.ALU_Y_sel   <= ALU_Y_immI;
                cmd.ALU_op      <= ALU_plus;
                cmd.RF_we       <= '1';
                cmd.DATA_sel    <= DATA_from_alu;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

---------- Instructions arithmétiques et logiques ----------

            when S_ADD =>
                -- rd <- rs1 + rs2
                cmd.ALU_Y_sel   <= ALU_Y_rf_rs2;
                cmd.ALU_op      <= ALU_plus;
                cmd.RF_we       <= '1';
                cmd.DATA_sel    <= DATA_from_alu;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_SUB =>
                -- rd <- rs1 - rs2
                cmd.ALU_Y_sel   <= ALU_Y_rf_rs2;
                cmd.ALU_op      <= ALU_minus;
                cmd.RF_we       <= '1';
                cmd.DATA_sel    <= DATA_from_alu;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_SLL =>
                -- rd <- rs1 SLL rs2
                cmd.SHIFTER_Y_sel   <= SHIFTER_Y_rs2;
                cmd.SHIFTER_op      <= SHIFT_ll;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_shifter;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_SLLI =>
                -- rd <- rs1 SLL imm
                cmd.SHIFTER_Y_sel   <= SHIFTER_Y_ir_sh;
                cmd.SHIFTER_op      <= SHIFT_ll;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_shifter;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_SRL =>
                -- rd <- rs1 SRL rs2
                cmd.SHIFTER_Y_sel   <= SHIFTER_Y_rs2;
                cmd.SHIFTER_op      <= SHIFT_rl;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_shifter;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_SRLI =>
                -- rd <- rs1 SRL imm
                cmd.SHIFTER_Y_sel   <= SHIFTER_Y_ir_sh;
                cmd.SHIFTER_op      <= SHIFT_rl;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_shifter;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_SRA =>
                -- rd <- rs1 SRA rs2
                cmd.SHIFTER_Y_sel   <= SHIFTER_Y_rs2;
                cmd.SHIFTER_op      <= SHIFT_ra;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_shifter;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_SRAI =>
                -- rd <- rs1 SRL imm
                cmd.SHIFTER_Y_sel   <= SHIFTER_Y_ir_sh;
                cmd.SHIFTER_op      <= SHIFT_ra;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_shifter;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_AND =>
                -- rd <- rs1 & rs2
                cmd.ALU_Y_sel       <= ALU_Y_rf_rs2;
                cmd.LOGICAL_op      <= LOGICAL_and;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_logical;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_ANDI =>
                -- rd <- rs1 & immI
                cmd.ALU_Y_sel       <= ALU_Y_immI;
                cmd.LOGICAL_op      <= LOGICAL_and;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_logical;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_OR =>
                -- rd <- rs1 | rs2
                cmd.ALU_Y_sel       <= ALU_Y_rf_rs2;
                cmd.LOGICAL_op      <= LOGICAL_or;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_logical;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_ORI =>
                -- rd <- rs1 | immI
                cmd.ALU_Y_sel       <= ALU_Y_immI;
                cmd.LOGICAL_op      <= LOGICAL_or;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_logical;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_XOR =>
                -- rd <- rs1 XOR rs2
                cmd.ALU_Y_sel       <= ALU_Y_rf_rs2;
                cmd.LOGICAL_op      <= LOGICAL_xor;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_logical;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_XORI =>
                -- rd <- rs1 XOR immI
                cmd.ALU_Y_sel       <= ALU_Y_immI;
                cmd.LOGICAL_op      <= LOGICAL_xor;
                cmd.RF_we           <= '1';
                cmd.DATA_sel        <= DATA_from_logical;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_SLT =>
                cmd.DATA_sel        <= DATA_from_slt;
                cmd.RF_we           <= '1';
                cmd.ALU_Y_sel       <= ALU_Y_rf_rs2;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_SLTU =>
                cmd.DATA_sel        <= DATA_from_slt;
                cmd.RF_we           <= '1';
                cmd.ALU_Y_sel       <= ALU_Y_rf_rs2;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_SLTI =>
                cmd.DATA_sel        <= DATA_from_slt;
                cmd.RF_we           <= '1';
                cmd.ALU_Y_sel       <= ALU_Y_immI;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

            when S_SLTIU =>
                cmd.DATA_sel        <= DATA_from_slt;
                cmd.RF_we           <= '1';
                cmd.ALU_Y_sel       <= ALU_Y_immI;
                -- lecture mem[PC]
                cmd.ADDR_sel    <= ADDR_from_pc;
                cmd.mem_ce      <= '1';
                cmd.mem_we      <= '0';
                -- next state
                state_d         <= S_Fetch;

---------- Instructions de saut ----------

            when S_BRANCH =>

                if status.JCOND then
                    cmd.TO_PC_Y_sel     <= TO_PC_Y_immB;
                else
                    cmd.TO_PC_Y_sel     <= TO_PC_Y_cst_x04;
                end if;

                cmd.PC_sel          <= PC_from_pc;
                cmd.ADDR_sel        <= ADDR_from_pc;
                cmd.ALU_Y_sel       <= ALU_Y_rf_rs2;

                cmd.PC_we           <= '1';
                state_d             <= S_Pre_Fetch;

            when S_JAL =>
                cmd.PC_X_sel        <= PC_X_pc;
                cmd.PC_Y_sel        <= PC_Y_cst_x04;
                cmd.DATA_sel        <= DATA_from_pc;
                cmd.RF_we           <= '1';

                cmd.TO_PC_Y_sel     <= TO_PC_Y_immJ;
                cmd.PC_sel          <= PC_from_pc;
                cmd.PC_we           <= '1';
                cmd.ADDR_sel        <= ADDR_from_pc;
                cmd.mem_ce          <= '1';
                cmd.mem_we          <= '0';


                state_d             <= S_Pre_Fetch;

            when S_JALR =>
                cmd.PC_X_sel        <= PC_X_pc;
                cmd.PC_Y_sel        <= PC_Y_cst_x04;
                cmd.DATA_sel        <= DATA_from_pc;
                cmd.RF_we           <= '1';

                cmd.TO_PC_Y_sel     <= TO_PC_Y_immJ;
                cmd.ALU_op          <= ALU_plus;
                cmd.ALU_Y_sel       <= ALU_Y_immI;
                cmd.PC_sel          <= PC_from_alu;
                cmd.PC_we           <= '1';
                cmd.ADDR_sel        <= ADDR_from_pc;
                cmd.mem_ce          <= '1';
                cmd.mem_we          <= '0';


                state_d             <= S_Pre_Fetch;

---------- Instructions de chargement à partir de la mémoire ----------

            when S_Pre_LW =>
                cmd.AD_Y_sel        <= AD_Y_immI;
                cmd.AD_we           <= '1';

                state_d         <= S_LW;

            when S_LW =>
                cmd.ADDR_sel        <= ADDR_from_ad;
                cmd.mem_ce          <= '1';
                cmd.mem_we          <= '0';

                state_d         <= S_Post_LW;

            when S_Post_LW =>
                cmd.DATA_sel        <= DATA_from_mem;
                cmd.RF_we           <= '1';
                cmd.RF_SIZE_sel     <= RF_SIZE_word;
                cmd.RF_SIGN_enable  <= '1';

                state_d         <= S_Pre_Fetch;


---------- Instructions de sauvegarde en mémoire ----------

            when S_Pre_SW =>
                cmd.AD_Y_sel        <= AD_Y_immS;
                cmd.AD_we           <= '1';

                state_d         <= S_SW;

            when S_SW =>
                cmd.ADDR_sel        <= ADDR_from_ad;
                cmd.RF_we           <= '0';
                cmd.RF_SIZE_sel     <= RF_SIZE_word;
                cmd.RF_SIGN_enable  <= '1';
                cmd.mem_ce          <= '1';
                cmd.mem_we          <= '1';

                state_d         <= S_Pre_Fetch;

---------- Instructions d'accès aux CSR ----------
            when S_Mret =>
                -- PC <- MEPC
                cmd.PC_sel <= PC_from_mepc;
                cmd.PC_we <= '1';
                cmd.cs.MSTATUS_mie_reset <= '1';
                state_d <= S_Pre_Fetch;

            when S_Csrr =>
                -- Immédiat ou registre
                if status.IR(14) = '0' then
                    cmd.cs.TO_CSR_sel <= TO_CSR_from_rs1;
                else
                    cmd.cs.TO_CSR_sel <= TO_CSR_from_imm;
                end if;
                -- Mode d'écriture
                case status.IR( 13 downto 12 ) is
                    when "01" => cmd.cs.CSR_WRITE_mode <= WRITE_mode_simple;
                    when "10" => cmd.cs.CSR_WRITE_mode <= WRITE_mode_set;
                    when "11" => cmd.cs.CSR_WRITE_mode <= WRITE_mode_clear;
                    when others => null;
                end case;
                -- Registre CSR d'écriture
                case status.IR( 31 downto 20 ) is
                    when x"300" => -- MSTATUS
                        cmd.cs.CSR_we <= CSR_MSTATUS;
                        cmd.cs.CSR_sel    <= CSR_from_mstatus;
                    when x"304" => -- MIE
                        cmd.cs.CSR_we <= CSR_MIE;
                        cmd.cs.CSR_sel <= CSR_from_mie;
                    when x"305" => -- MTVEC
                        cmd.cs.CSR_we <= CSR_MTVEC;
                        cmd.cs.CSR_sel  <= CSR_from_mtvec;
                    when x"341" => -- MEPC
                        cmd.cs.CSR_we <= CSR_MEPC;
                        cmd.cs.CSR_sel <= CSR_from_mepc;
                    when x"342" => -- MCAUSE
                        cmd.cs.CSR_sel   <= CSR_from_mcause;
                    when x"344" => -- MIP
                        cmd.cs.CSR_sel <= CSR_from_mip;
                    when others => null;
                end case;
                cmd.cs.MEPC_sel <= MEPC_from_csr;
                cmd.DATA_sel <= DATA_from_csr;
                cmd.RF_we <= '1';
                state_d <= S_Fetch;
                -- mem[PC]
                cmd.mem_ce <= '1';


            when others => null;
        end case;

    end process FSM_comb;

end architecture;
