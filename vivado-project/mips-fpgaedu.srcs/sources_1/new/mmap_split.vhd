library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mmap_split is
    generic (
        SLAVE_A_ADDR_SUBTRACT   : integer := 0;
        SLAVE_A_ADDR_FROM       : integer;
        SLAVE_A_ADDR_TO         : integer;
        SLAVE_B_ADDR_SUBTRACT   : integer := 0;
        SLAVE_B_ADDR_FROM       : integer;
        SLAVE_B_ADDR_TO         : integer;
        ADDR_WIDTH              : integer := 32;
        DATA_WIDTH              : integer := 32
    );
    port(
        master_clk_i            : in  std_logic;
        master_exp_clk_i        : in  std_logic;
        master_exp_clk_en_i     : in  std_logic;
        master_rst_i            : in  std_logic;
        master_addr_i           : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        master_data_in_i        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        master_data_out_o       : out std_logic_vector(DATA_WIDTH-1 downto 0);
        master_w_en_i           : in  std_logic;

        slave_a_clk_o           : out std_logic;
        slave_a_exp_clk_o       : out std_logic;
        slave_a_exp_clk_en_o    : out std_logic;
        slave_a_rst_o           : out std_logic;
        slave_a_addr_o          : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        slave_a_data_in_o       : out std_logic_vector(DATA_WIDTH-1 downto 0);
        slave_a_data_out_i      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        slave_a_w_en_o          : out std_logic;

        slave_b_clk_o           : out std_logic;
        slave_b_exp_clk_o       : out std_logic;
        slave_b_exp_clk_en_o    : out std_logic;
        slave_b_rst_o           : out std_logic;
        slave_b_addr_o          : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        slave_b_data_in_o       : out std_logic_vector(DATA_WIDTH-1 downto 0);
        slave_b_data_out_i      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        slave_b_w_en_o          : out std_logic
    );
end entity mmap_split;

architecture structural of mmap_split is
    constant SELECT_A       : std_logic_vector(1 downto 0) := "01";
    constant SELECT_B       : std_logic_vector(1 downto 0) := "10";
    constant SELECT_NONE    : std_logic_vector(1 downto 0) := "00";
    
    signal selector         : std_logic_vector(1 downto 0) := SELECT_NONE;
    signal selector_reg     : std_logic_vector(1 downto 0) := SELECT_NONE;
    signal master_addr_int  : integer                      := 0;
begin
    
    
    slave_a_clk_o           <= master_clk_i;
    slave_a_exp_clk_o       <= master_exp_clk_i;
    slave_a_exp_clk_en_o    <= master_exp_clk_en_i;
    slave_a_rst_o           <= master_rst_i;

    slave_b_clk_o           <= master_clk_i;
    slave_b_exp_clk_o       <= master_exp_clk_i;
    slave_b_exp_clk_en_o    <= master_exp_clk_en_i;
    slave_b_rst_o           <= master_rst_i;

    master_addr_int         <= to_integer(unsigned(master_addr_i));

    selector <= SELECT_NONE when master_rst_i = '1' else 
                SELECT_A    when master_addr_int >= SLAVE_A_ADDR_FROM and master_addr_int <= SLAVE_A_ADDR_TO else
                SELECT_B    when master_addr_int >= SLAVE_B_ADDR_FROM and master_addr_int <= SLAVE_B_ADDR_TO else
                SELECT_NONE;

    process(master_clk_i)
    begin
        if rising_edge(master_clk_i) then
            selector_reg <= selector;
        end if;
    end process;

    process(selector, master_rst_i, master_addr_i, master_data_in_i, master_w_en_i, master_rst_i)
    begin
        slave_a_addr_o <= (others => '0');
        slave_a_data_in_o <= (others => '0');
        slave_a_w_en_o <= '0';

        slave_b_addr_o <= (others => '0');
        slave_b_data_in_o <= (others => '0');
        slave_b_w_en_o <= '0';

        if master_rst_i = '0' then
            if selector = SELECT_A then
                slave_a_addr_o      <= std_logic_vector(unsigned(master_addr_i)-to_unsigned(SLAVE_A_ADDR_SUBTRACT, ADDR_WIDTH));
                slave_a_data_in_o   <= master_data_in_i;
                slave_a_w_en_o      <= master_w_en_i;
            elsif selector = SELECT_B then 
                slave_b_addr_o      <= std_logic_vector(unsigned(master_addr_i)-to_unsigned(SLAVE_B_ADDR_SUBTRACT, ADDR_WIDTH));
                slave_b_data_in_o   <= master_data_in_i;
                slave_b_w_en_o      <= master_w_en_i;
            end if; -- selector_reg
        end if; -- reset
    end process;

    master_data_out_o <= slave_a_data_out_i when selector_reg = SELECT_A else
                         slave_b_data_out_i when selector_reg = SELECT_B else
                         (others => '0'); 
end architecture;
