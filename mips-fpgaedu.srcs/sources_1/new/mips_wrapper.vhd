library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mips_signal_wrapper is
    port (
        clk                     : in std_logic;
        exp_clk                 : in std_logic;
        exp_clk_en              : in std_logic;
        reset                   : in std_logic;
        addr                    : in std_logic_vector(31 downto 0);
        din                     : in std_logic_vector(31 downto 0);
        dout                    : out std_logic_vector(31 downto 0);
        wen                     : in std_logic;
            
        mips_sig_pc_i           : in std_logic_vector(31 downto 0);
        mips_sig_pc_next_i      : in std_logic_vector(31 downto 0);        
        mips_sig_op_i           : in std_logic_vector(5 downto 0);
        mips_sig_rs_i           : in std_logic_vector(4 downto 0);
        mips_sig_rt_i           : in std_logic_vector(4 downto 0);
        mips_sig_rd_i           : in std_logic_vector(4 downto 0);
        mips_sig_funct_i        : in std_logic_vector(5 downto 0);
        mips_sig_immed_i        : in std_logic_vector(15 downto 0);
        mips_sig_reg_q0_i       : in std_logic_vector(31 downto 0);
        mips_sig_reg_q1_i       : in std_logic_vector(31 downto 0);
        mips_sig_reg_wdata_i    : in std_logic_vector(31 downto 0);
        
        mips_sig_instr_rdata_i  : in std_logic_vector(31 downto 0);
        mips_sig_instr_addr_i   : in std_logic_vector(31 downto 0);
        
        mips_sig_data_w_en_i    : in std_logic;
        mips_sig_data_r_en_i    : in std_logic;
        mips_sig_data_wdata_i   : in std_logic_vector(31 downto 0);
        mips_sig_data_addr_i    : in std_logic_vector(31 downto 0);
        mips_sig_data_rdata_i   : in std_logic_vector(31 downto 0)
    );
end mips_signal_wrapper;

architecture Behavioral of mips_signal_wrapper is
    
begin
    process(clk)
    begin
        dout <= (others => '0');
        if rising_edge(clk) then
            case to_integer(unsigned(addr)) is
                when 0 => 
                    dout <= mips_sig_pc_i;
                when 1 => 
                    dout <= mips_sig_pc_next_i;
                when 2 => 
                    dout(5 downto 0) <= mips_sig_op_i;
                when 3 => 
                    dout(4 downto 0) <= mips_sig_rs_i;
                when 4 => 
                    dout(4 downto 0) <= mips_sig_rt_i;
                when 5 => 
                    dout(4 downto 0) <= mips_sig_rd_i;
                when 6 => 
                    dout(5 downto 0) <= mips_sig_funct_i;
                when 7 => 
                    dout(15 downto 0) <= mips_sig_immed_i;
                when 8 => 
                    dout <= mips_sig_reg_q0_i;
                when 9 => 
                    dout <= mips_sig_reg_q1_i;
                when 10 => 
                    dout <= mips_sig_reg_wdata_i;
                when 11 => 
                    dout <= mips_sig_instr_rdata_i;
                when 12 => 
                    dout <= mips_sig_instr_addr_i;
                when 13 => 
                    dout <= (0 => mips_sig_data_w_en_i, others => '0');
                when 14 => 
                    dout <= (0 => mips_sig_data_r_en_i, others => '0');
                when 15 => 
                    dout <= mips_sig_data_wdata_i;
                when 16 => 
                    dout <= mips_sig_data_addr_i;
                when 17 => 
                    dout <= mips_sig_data_rdata_i;
                when others =>
                    dout <= (others => '0');
            end case;
        end if;
    end process;
end Behavioral;
