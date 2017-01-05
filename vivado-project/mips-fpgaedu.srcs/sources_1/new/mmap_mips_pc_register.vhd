library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mmap_mips_pc_register is
    port (
        clk             : in std_logic;
        exp_clk         : in std_logic;
        exp_clk_en      : in std_logic;
        reset           : in std_logic;
        addr            : in std_logic_vector(31 downto 0);
        din             : in std_logic_vector(31 downto 0);
        dout            : out std_logic_vector(31 downto 0);
        wen             : in std_logic;
    
        mips_pc_clk_i   : in std_logic;
        mips_pc_rst_i   : in std_logic;
        mips_pc_d_i     : in std_logic_vector(31 downto 0);
        mips_pc_w_en_i  : in std_logic;
        mips_pc_q_o     : out std_logic_vector(31 downto 0)
    );
end mmap_mips_pc_register;

architecture Behavioral of mmap_mips_pc_register is
    signal reg: std_logic_vector(31 downto 0) := (others => '0');
begin
    mips_pc_q_o <= reg;
    
    process(clk, reset, mips_pc_rst_i)
    begin
        if reset = '1' or mips_pc_rst_i = '1' then
            reg <= (others => '0');
        elsif rising_edge(clk) then
            if to_integer(unsigned(addr)) = 0 then
                dout <= reg;
            else
                dout <= (others => '0');
            end if;

            if exp_clk_en = '1' and mips_pc_w_en_i = '1' then
                reg <= mips_pc_d_i;
            elsif exp_clk_en = '0' and wen = '1' then
                reg <= din;
            end if;
        end if;
    end process;
end Behavioral;
