library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mmap_mips_register_file is
    port (
        -- data mem interface
        clk                     : in std_logic;
        exp_clk                 : in std_logic;
        exp_clk_en              : in std_logic;
        reset                   : in std_logic;
        addr                    : in std_logic_vector(31 downto 0);
        din                     : in std_logic_vector(31 downto 0);
        dout                    : out std_logic_vector(31 downto 0);
        wen                     : in std_logic;
        -- mips register file interface
        mips_reg_file_clk_i     : in std_logic;
        mips_reg_file_rst_i     : in std_logic;
        mips_reg_file_r0_sel_i  : in std_logic_vector(4 downto 0);
        mips_reg_file_r1_sel_i  : in std_logic_vector(4 downto 0);
        mips_reg_file_rw_sel_i  : in std_logic_vector(4 downto 0);
        mips_reg_file_d_i       : in std_logic_vector(31 downto 0);
        mips_reg_file_w_en_i    : in std_logic;
        mips_reg_file_q0_o      : out std_logic_vector(31 downto 0); 
        mips_reg_file_q1_o      : out std_logic_vector(31 downto 0)
    );

end mmap_mips_register_file;

architecture Behavioral of mmap_mips_register_file is
    type registers_t is array (31 downto 0) of std_logic_vector(31 downto 0);

    signal registers: registers_t := (others => (others => '0'));
begin
    
    mips_reg_file_q0_o <= registers(to_integer(unsigned(mips_reg_file_r0_sel_i)));
    mips_reg_file_q1_o <= registers(to_integer(unsigned(mips_reg_file_r1_sel_i)));
    
    process(clk, reset, mips_reg_file_rst_i)
    begin
        if reset = '1' or mips_reg_file_rst_i = '1' then
            registers <= (others => (others => '0'));
        elsif rising_edge(clk) then
            -- set mem interface dout
            if to_integer(unsigned(addr)) < 32 then
                dout <= registers(to_integer(unsigned(addr)));
            else
                dout <= (others => '0');
            end if;
        
            if mips_reg_file_w_en_i = '1' and exp_clk_en = '1' then
                registers(to_integer(unsigned(mips_reg_file_rw_sel_i))) <= mips_reg_file_d_i;
            elsif wen = '1' and exp_clk_en = '0' then
                registers(to_integer(unsigned(addr))) <= din;
            end if;
        end if;
    end process;
    

end Behavioral;
