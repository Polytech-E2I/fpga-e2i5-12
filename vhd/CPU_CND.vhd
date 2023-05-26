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
    signal rs1_33   : w33;
    signal alu_y_33 : w33;
    signal diff     : w33;

begin

    z <= '1' when rs1 = alu_y else '0';

    sign_ext <= ( ( not IR(12) ) and ( not IR(6) ) )
                    or
                ( IR(6) and ( not IR(13) ) )
    ;

    rs1_33      <= (rs1(31)     and sign_ext) & rs1;
    alu_y_33    <= (alu_y(31)   and sign_ext) & alu_y;

    diff <= rs1_33 - alu_y_33;

    s <= diff(32);

    jcond <=    ( ( not IR(14) ) and ( IR(12) xor z ) )
                    or
                ( IR(14) and ( IR(12) xor s ) )
    ;

    slt <= s;

end architecture;
