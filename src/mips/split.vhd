library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addr_space_split is
    generic (
        SPLIT_ADDR: integer := 0;
        ADDR_WIDTH: integer := 32;
        DATA_WIDTH: integer := 8
    );
    port(
        master_clk_i : in std_logic;
        master_rst_i: in std_logic;
        master_addr_i: in std_logic_vector(ADDR_WIDTH-1 downto 0);
        master_data_in_i: in std_logic_vector(DATA_WIDTH-1 downto 0);
        master_w_en_i: in std_logic;
        master_r_en_i: in std_logic;
        master_data_out_o: out std_logic_vector(DATA_WIDTH-1 downto 0);

        slave_0_clk_o: out std_logic;
        slave_0_rst_o: out std_logic;
        slave_0_addr_o: out std_logic_vector(ADDR_WIDTH-1 downto 0);
        slave_0_data_in_o: out std_logic_vector(DATA_WIDTH-1 downto 0);
        slave_0_w_en_o: out std_logic;
        slave_0_r_en_o: out std_logic;
        slave_0_data_out_i: in std_logic_vector(DATA_WIDTH-1 downto 0);

        slave_1_clk_o: out std_logic;
        slave_1_rst_o: out std_logic;
        slave_1_addr_o: out std_logic_vector(ADDR_WIDTH-1 downto 0);
        slave_1_data_in_o: out std_logic_vector(DATA_WIDTH-1 downto 0);
        slave_1_w_en_o: out std_logic;
        slave_1_r_en_o: out std_logic;
        slave_1_data_out_i: in std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity addr_space_split;

architecture structural of addr_space_split is
    constant SPLIT_ADDR_UNSIGNED: unsigned(ADDR_WIDTH-1 downto 0) := to_unsigned(SPLIT_ADDR, ADDR_WIDTH);
    signal selector: std_logic := '0';
    signal selector_reg: std_logic := '0';
begin
    slave_0_clk_o <= master_clk_i;
    slave_1_clk_o <= master_clk_i;
    slave_0_rst_o <= master_rst_i;
    slave_1_rst_o <= master_rst_i;

    selector <= '0' when unsigned(master_addr_i) < SPLIT_ADDR_UNSIGNED else
                '1';
    process(master_clk_i)
    begin
        if rising_edge(master_clk_i) then
            selector_reg <= selector;
        end if;
    end process;

    process(selector, master_rst_i)
    begin
        slave_0_addr_o <= (others => '0');
        slave_0_data_in_o <= (others => '0');
        slave_0_w_en_o <= '0';
        slave_0_r_en_o <= '0';

        slave_1_addr_o <= (others => '0');
        slave_1_data_in_o <= (others => '0');
        slave_1_w_en_o <= '0';
        slave_1_r_en_o <= '0';

        if master_rst_i = '0' then
            if selector = '0' then
                slave_0_addr_o <= master_addr_i;
                slave_0_data_in_o <= master_data_in_i;
                slave_0_w_en_o <= master_w_en_i;
                slave_0_r_en_o <= master_r_en_i;
            elsif selector = '1' then 
                slave_1_addr_o <= std_logic_vector(unsigned(master_addr_i)-SPLIT_ADDR_UNSIGNED);
                slave_1_data_in_o <= master_data_in_i;
                slave_1_w_en_o <= master_w_en_i;
                slave_1_r_en_o <= master_r_en_i;
            end if; -- selector_reg
        end if; -- reset
    end process;

    process(selector_reg)
    begin
        if master_rst_i = '1' then
            master_data_out_o <= (others => '0');
        elsif selector_reg = '0' then
            master_data_out_o <= slave_0_data_out_i;
        else
            master_data_out_o <= slave_1_data_out_i;
        end if;
    end process;
end architecture;
