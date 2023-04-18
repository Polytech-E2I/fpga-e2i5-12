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
                        if rs1 < alu_y then
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
