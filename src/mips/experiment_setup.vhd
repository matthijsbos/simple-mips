library ieee;
use ieee.std_logic_1164.all;

entity experiment_setup is
    port (
        clk: in std_logic;
        exp_clk: in std_logic;
        reset: in std_logic;
        addr: out std_logic_vector(31 downto 0);
        din: in std_logic_vector(7 downto 0);
        dout: out std_logic_vector(7 downto 0);
        wen: in std_logic;
    );
end entity experiment_setup;

architecture structural of experiment_setup is
    
begin

    mips: entity work.mips(
        --input signals
        rst_i => TODO,
        ck_i => TODO,
        instr_rdata_i => TODO,
        data_rdata_i TODO,
        --output signals
        data_w_en_o => TODO,
        data_r_en_o => TODO,
        data_wdata_o => TODO,
        
end architecture;
