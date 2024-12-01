library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity tb_mono is
end entity;

architecture behavior of tb_mono is
component mono is
    port(
        clock        : in std_logic;
        reset        : in std_logic;
        en_write     : in std_logic
    );
end component; 

signal reset_sg    : std_logic := '1';
signal clock_sg    : std_logic := '0';
signal en_write_sg : std_logic := '0';

begin
inst_mono : mono
    port map(
        clock    => clock_sg,
        reset    => reset_sg,
        en_write => en_write_sg
    );
clock_sg <= not clock_sg after 10 ns;

process
begin
    wait for 20 ns;
        reset_sg    <= '0';
        en_write_sg <= '1';
    wait;
end process;
end architecture;