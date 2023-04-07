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
        S_ADD
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
        cmd.ALU_op            <= UNDEFINED;
        cmd.LOGICAL_op        <= UNDEFINED;
        cmd.ALU_Y_sel         <= UNDEFINED;

        cmd.SHIFTER_op        <= UNDEFINED;
        cmd.SHIFTER_Y_sel     <= UNDEFINED;

        cmd.RF_we             <= 'U';
        cmd.RF_SIZE_sel       <= UNDEFINED;
        cmd.RF_SIGN_enable    <= 'U';
        cmd.DATA_sel          <= UNDEFINED;

        cmd.PC_we             <= 'U';
        cmd.PC_sel            <= UNDEFINED;

        cmd.PC_X_sel          <= UNDEFINED;
        cmd.PC_Y_sel          <= UNDEFINED;

        cmd.TO_PC_Y_sel       <= UNDEFINED;

        cmd.AD_we             <= 'U';
        cmd.AD_Y_sel          <= UNDEFINED;

        cmd.IR_we             <= 'U';

        cmd.ADDR_sel          <= UNDEFINED;
        cmd.mem_we            <= 'U';
        cmd.mem_ce            <= 'U';

        cmd.cs.CSR_we            <= UNDEFINED;

        cmd.cs.TO_CSR_sel        <= UNDEFINED;
        cmd.cs.CSR_sel           <= UNDEFINED;
        cmd.cs.MEPC_sel          <= UNDEFINED;

        cmd.cs.MSTATUS_mie_set   <= 'U';
        cmd.cs.MSTATUS_mie_reset <= 'U';

        cmd.cs.CSR_WRITE_mode    <= UNDEFINED;

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

            when S_Fetch =>
                -- IR <- mem_datain
                cmd.IR_we <= '1';
                state_d <= S_Decode;

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
                            -- when "00" =>
                            --     state_d <= S_AUIPC;
                            -- Error
                            when others => null;
                        end case;

                    when "100" =>
                        case status.IR(6 downto 5) is
                            -- Type I starting from addi
                            when "00" =>
                                case status.IR(14 downto 12) is
                                    when "000" =>
                                        state_d <= S_ADDI;

                                    when others => null;
                                end case;
                            when "01" =>
                                case status.IR(14 downto 12) is
                                    when "000" =>
                                        state_d <= S_ADD;

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

            when S_ADD =>
                -- rd <- immI + rs1
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





---------- Instructions arithmétiques et logiques ----------

---------- Instructions de saut ----------

---------- Instructions de chargement à partir de la mémoire ----------

---------- Instructions de sauvegarde en mémoire ----------
---------- Instructions d'accès aux CSR ----------

            when others => null;
        end case;

    end process FSM_comb;

end architecture;
