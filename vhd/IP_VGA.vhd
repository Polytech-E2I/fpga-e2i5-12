library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.PKG.all;

entity IP_VGA is
    generic (
        IMAGE_FILE : string := "none"
    );
    port (
        -- Clock/Reset
        clk_bus : in  std_logic ;
        clk_io  : in  std_logic ;
        rst     : in  std_logic ;

        -- Memory slave interface
        addr : in  waddr ;
        size : in  RF_SIZE_select ;
        di   : in  w32 ;
        do   : out w32 ;
        we   : in  std_logic ;
        ce   : in  std_logic ;

        -- VGA
        vga_R  : out unsigned ( 4 downto 0 ) ;
        vga_G  : out unsigned ( 5 downto 0 ) ;
        vga_B  : out unsigned ( 4 downto 0 ) ;
        vga_hs : out std_logic ;
        vga_vs : out std_logic
    );
end entity;


architecture RTL of IP_VGA is
    component VGA_GeneSync
        port (
            -- Clock
            clk   : in  std_logic ;

            -- Outputs
            hsync : out std_logic ;
            vsync : out std_logic ;
            blank : out std_logic ;
            x     : out unsigned ( 9 downto 0 ) ;
            y     : out unsigned ( 8 downto 0 )
        );
    end component;

    -- Memory Bus : port video
    signal s_video_index : integer ;
    signal s_video_addr  : waddr ;
    signal s_video_data  : w16 ;
    signal s_do16, s_di16 : w16 ;

    signal s_blank : std_logic;
    signal s_sync_blank : std_logic;
    signal s_sync_hs, s_sync_vs : std_logic ;
    signal s_sync_x : unsigned ( 9 downto 0 ) ;
    signal s_sync_y : unsigned ( 8 downto 0 ) ;
begin

    C_RAM_VIDEO : RAM16DP
        generic map (
            -- Memory configuration: (320 * 240) px * 2 byte/px
            MEMORY_SIZE => (320 * 240) * 2,

            -- Memory initialization
            FILE_NAME   => IMAGE_FILE
        )
        port map (
            -- Clock/Reset
            clkA => clk_bus,
            clkB => clk_io,
            rstA => rst,
            rstB => '0',

            -- Port A: Memory slave interface
            addrA => addr,
            doA   => s_do16,
            diA   => s_di16,
            weA   => we,
            ceA   => ce,

            -- Port B: Memory slave interface
            addrB => s_video_addr,
            doB   => s_video_data,
            diB   => w16_zero,     -- Read only
            weB   => '0',          -- Read only
            ceB   => '1'           -- Always read
        );

    -- 32 bits -> 16 bits
    do     <= X"0000" & s_do16;
    s_di16 <= di(15 downto 0);

    C_VGA_GeneSync : VGA_GeneSync
        port map (
            clk   => clk_io,
            hsync => s_sync_hs,
            vsync => s_sync_vs,
            blank => s_sync_blank,
            x     => s_sync_x, -- coordonnée sur 640
            y     => s_sync_y  -- coordonnée sur 480
        );

    -- Les coordonnées 640*480px sont convertis en coordonnées 320*240px.
    s_video_index <= to_integer(s_sync_y)/2 * 320 + to_integer(s_sync_x)/2;
    s_video_addr  <= to_unsigned(s_video_index , waddr'length - 2) & "00";


    -- Bascule de synchronisation
    process (clk_io)
    begin
        if rising_edge(clk_io) then
            s_blank <= s_sync_blank;
            vga_hs <= s_sync_hs;
            vga_vs <= s_sync_vs;
        end if;
    end process;

    process (s_video_data, s_blank)
    begin
        if s_blank = '0' then
            vga_R <= s_video_data ( 15 downto 11 );
            vga_G <= s_video_data ( 10 downto  5 );
            vga_B <= s_video_data (  4 downto  0 );
        else
            vga_R <= (others => '0');
            vga_G <= (others => '0');
            vga_B <= (others => '0');
        end if;
    end process;


end architecture;
