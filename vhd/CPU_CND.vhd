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
    -- signal sign_ext : std_logic;
    -- signal z        : std_logic;
    -- signal s        : std_logic;

begin

    -- process(IR, rs1, alu_y) is
    -- begin
    --     sign_ext <= (IR(6) and not IR(13)) or (IR(12) nor IR(6)) ;
    --     if rs1 = alu_y then
    --         z <= '1';
    --     else
    --         z <= '0';
    --     end if;

    --     if sign_ext and IR(31) then
    --         if rs1 > alu_y then
    --             s <= '1';
    --         else
    --             s <= '0';
    --         end if;
    --     else
    --         if rs1 < alu_y then
    --             s <= '1';
    --         else
    --             s <= '0';
    --         end if;
    --     end if;

    --     jcond <= (not IR(14) and (IR(12) xor (z))) or (IR(14) and (IR(12) xor s));
    --     slt <= s;
    -- end process;



    jcond <= '0';
    slt <= '0';

end architecture;
