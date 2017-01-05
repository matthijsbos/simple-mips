library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mmap_mips_data_mem is
    port (
        --mmap interface ports
        clk                     : in  std_logic;
        exp_clk                 : in  std_logic;
        exp_clk_en              : in  std_logic;
        reset                   : in  std_logic;
        addr                    : in  std_logic_vector(31 downto 0);
        din                     : in  std_logic_vector(31 downto 0);
        dout                    : out std_logic_vector(31 downto 0);
        wen                     : in  std_logic;
        --instruction mem ports                                     
        mips_data_mem_clk_i     : in  std_logic;                    
        mips_data_mem_w_en_i    : in  std_logic;                    
        mips_data_mem_r_en_i    : in  std_logic;                    
        mips_data_mem_wdata_i   : in  std_logic_vector(31 downto 0);
        mips_data_mem_addr_i    : in  std_logic_vector(31 downto 0);
        mips_data_mem_rdata_o   : out std_logic_vector(31 downto 0)
    );
end mmap_mips_data_mem;

architecture Behavioral of mmap_mips_data_mem is

    component data_mem
        port (
            clka:   IN STD_LOGIC;
            rsta:   IN STD_LOGIC;
            ena:    IN STD_LOGIC;
            wea:    IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra:  IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina:   IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            douta:  OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            clkb:   IN STD_LOGIC;
            rstb:   IN STD_LOGIC;
            enb:    IN STD_LOGIC;
            web:    IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addrb:  IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dinb:   IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            doutb:  OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    end component;
    
    signal ena_internal: std_logic := '0';
    signal enb_internal: std_logic := '0';
    signal wea_internal: std_logic := '0';
    signal web_internal: std_logic := '0';
begin

    data_mem_inst : data_mem
        port map (
            -- Controller ports
            clka    => clk,
            rsta    => reset,
            ena     => not exp_clk_en,
            wea(0)  => wen,
            addra   => addr(9 downto 0),
            dina    => din,
            douta   => dout,
            -- MIPS ports
            clkb    => clk,
            rstb    => '0',
            enb     => mips_data_mem_r_en_i or mips_data_mem_w_en_i,
            web(0)  => exp_clk_en and mips_data_mem_w_en_i,
            addrb   => mips_data_mem_addr_i(9 downto 0),
            dinb    => mips_data_mem_wdata_i,
            doutb   => mips_data_mem_rdata_o
        );
    
end architecture;