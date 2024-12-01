library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity mono is
    port(
        clock    : in std_logic;
        reset    : in std_logic;
        en_write : in std_logic
    );
end entity;

architecture behavior of mono is
type mem is array (integer range 0 to 255) of std_logic_vector(31 downto 0);
type reg is array (integer range 0 to 15) of std_logic_vector(31 downto 0);
signal registers                        : reg;
signal memory_inst                      : mem;
signal memory_data                      : mem;
signal pc                               : std_logic_vector(31 downto 0);
signal mem_out                          : std_logic_vector(31 downto 0);
signal opcode, funct                    : std_logic_vector(5 downto 0);
signal imediato                         : std_logic_vector(15 downto 0);
signal desvio                           : std_logic;
signal igual                            : std_logic;
signal RS_addr, RT_addr, RD_addr, shamt : std_logic_vector(4 downto 0);
signal RS_data, RT_data, RD_data        : std_logic_vector(31 downto 0);


begin
    memory_inst(0) <= "00111100001000000000000000000001";  -- LDI para Reg 1 (Valor 1)
    memory_inst(1) <= "00111100010000000000000000000010";  -- LDI para Reg 2 (Valor 2)
    memory_inst(2) <= "00000000001000100001100000000000";  -- ADD de Reg 1 e Reg 2 para Reg 3
    memory_inst(3) <= "10101100011000110000000000000000";  -- SW de Reg 3 para a memória (Endereço 4)
    memory_inst(4) <= "10001100000001000000000000000011";  -- LW para Reg 4 a partir da Memória (Endereço 4)
    memory_inst(5) <= "00000100001001000010100000000000";  -- SUB de Reg 1 e Reg 4 para Reg 5
    memory_inst(6) <= "00100000001000010000000000000101"; -- ADDI para Reg 1 (Valor 5)
    memory_inst(7) <= "00100000010000100000000000000010"; -- ADDI para Reg 2 (Valor 2)
    memory_inst(8) <= "00010000001000100000000000000001"; -- BEQ se Reg 2 tiver Valor 6 para instrução 9
    memory_inst(9) <= "00011000000000000000000000000111"; -- JMP para instrução 7
    memory_inst(10) <= "10101100010000100000000000000000"; -- SW de Reg 2 para a memória (Endereço 3)
    memory_inst(11) <= "00001000010000110001000000011000";-- MULT Reg 2 com Reg 3
    memory_inst(12) <= "00100100010000100000000000001010";-- SUBI para Reg 2 (Valor 10)
    memory_inst(13) <= "00101000010001100000000000000101";-- MULI para Reg 2 e armazena em Reg 6 (Valor 2)

    desvio <= '1' when (opcode = "000100" and igual = '1') or (opcode = "000101" and igual = '0') or (opcode = "000110") else '0';
    igual  <= '1' when RS_data = RT_data else '0';

    -- busca 
    mem_out <= memory_inst(conv_integer(pc)); 

    -- decode da instrução
    opcode <= mem_out(31 downto 26);
    RS_addr <= mem_out(25 downto 21);
    RT_addr <= mem_out(20 downto 16);
    RD_addr <= mem_out(15 downto 11);
    shamt <= mem_out(10 downto 6);
    funct <= mem_out(5 downto 0);
    imediato <= mem_out(15 downto 0);

    -- leitura dos regs
    RS_data <= registers(conv_integer(RS_addr));
    RT_data <= registers(conv_integer(RT_addr));
    RD_data <= registers(conv_integer(RD_addr));


process (reset, clock)
begin
    if (reset = '1') then
        pc     <= (others => '0');
        for i in registers'range loop
            registers(i) <= (others => '0');
        end loop;
    elsif (clock = '1' and clock'event) then
        if (desvio = '1') then
            if(igual = '1') then -- Salto Condicional
                pc <= pc + imediato;
            else -- Salto Incondicional
                pc <= (pc(31 downto 26) & mem_out(25 downto 0));
            end if;
		else
            pc <= pc + 1;
            case opcode is
                when "000000" => -- ADD
                    if(en_write = '1') then
                        registers(conv_integer(RD_addr)) <= RS_data + RT_data;
                    end if;
                when "000001" => -- SUBT
                    if(en_write = '1') then
                        registers(conv_integer(RD_addr)) <= RS_data - RT_data;
                    end if;
                when "000010" => -- MULT
                    if(en_write = '1') then
                        registers(conv_integer(RD_addr)) <= RS_data(15 downto 0) * RT_data(15 downto 0);
                    end if;
                when "001000" =>  -- ADDI
                    if(en_write = '1') then
                        registers(conv_integer(RT_addr)) <= RS_data + imediato;
                    end if;
                when "001001" =>  -- SUBI
                    if(en_write = '1') then
                        registers(conv_integer(RT_addr)) <= RS_data - imediato;
                    end if;
                when "001010" => -- MULI
                    if (en_write = '1') then
                        registers(conv_integer(RT_addr)) <= RS_data(15 downto 0) * imediato;
                    end if;
                when "001111" => -- LDI
                    if(en_write = '1') then
                        registers(conv_integer(RS_addr)) <= "0000000000000000" & imediato;
                    end if;
                when "100011" =>  -- LW 
                    if (en_write = '1') then
                        registers(conv_integer(RT_addr)) <= memory_data(conv_integer(RS_addr) + conv_integer(imediato));
                    end if;
                when "101011" =>  -- SW
                    memory_data(conv_integer(RS_addr) + conv_integer(imediato)) <= registers(conv_integer(RT_addr));
                when others => 
                    registers(conv_integer(RD_addr)) <= (others => '0');
            end case;
        end if;
    end if;
end process;
end architecture;