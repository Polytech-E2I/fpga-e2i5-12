library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.PKG.all;

entity CPU_CND is
    generic (
        mutant      : integer := 0
    );
    port (
        rs1         : in w32;
        alu_y       : in w32;
        IR          : in w32;
        slt         : out std_logic;
        jcond       : out std_logic
    );
end entity;

architecture RTL of CPU_CND is

begin
    process(IR) is
    begin

        case IR(6 downto 0) is
            when "0110011" =>
                case IR(14 downto 12) is
                    -- slt
                    when "010" =>
                        -- Comparaison signée à faire à la main...
                        -- if rs1(32) = '0' and alu_y(32) = '0' and rs1 < alu_y then
                        --     slt <= '1';
                        -- elsif rs1(32) = '0' and alu_y(32) = '0' and rs1 >= alu_y then
                        --     slt <= '0';
                        -- elsif rs1(32) = '1' and alu_y(32) = '1' and rs1 < alu_y then
                        --     slt <= '0';
                        -- elsif rs1(32) = '1' and alu_y(32) = '1' and rs1 >= alu_y then
                        --     slt <= '1';
                        -- elsif rs1(32) = '1' and alu_y(32) = '0' then
                        --     slt <= '1';
                        -- else
                        --     slt <= '0';
                        -- end if;
                        if rs1 < alu_y then
                            slt <= '1';
                        else
                            slt <= '0';
                        end if;

                    when others => null;
                end case;

            when "0010011" =>
                case IR(14 downto 12) is
                    -- slti
                    when "010" =>
                        if signed(rs1) < signed(alu_y) then
                            slt <= '1';
                        else
                            slt <= '0';
                        end if;

                    when others => null;
                end case;
            when others => null;
        end case;

    end process;

    jcond   <= '0';

end architecture;
