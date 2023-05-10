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

    subtype w33   is unsigned(32 downto 0);

    signal sign_ext : std_logic;
    signal z        : std_logic;
    signal s        : std_logic;
    signal sum      : w33;

begin

    CPU_CND: process(IR, rs1, alu_y) is
    begin

        if rs1 = alu_y then
            z <= '1';
        else
            z <= '0';
        end if;

        sum <= rs1 + alu_y;

        s <= sum(32);

        sign_ext <= ( ( not IR(12) ) and ( not IR(6) ) )
                        or
                    ( IR(6) and ( not IR(13) ) )
        ;

        jcond <=    ( ( not IR(14) ) and ( IR(12) xor z ) )
                        or
                    ( IR(14) and ( IR(12) xor s ) )
        ;

        slt <= s;

    end process;

    -- jcond <= '0';
    -- slt <= '0';

end architecture;
