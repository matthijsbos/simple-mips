library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- https://danstrother.com/2010/09/11/inferring-rams-in-fpgas/

entity dual_ram is
    generic (
        DATA_WIDTH: integer := 8;
        ADDR_WIDTH: integer := 32
    );
    port (
        clk_i:        in std_logic;

        addr_a_i:       in std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_in_a_i:    in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_a_o:   out std_logic_vector(DATA_WIDTH-1 downto 0);
        w_en_a_i:       in std_logic;
        r_en_a_i:       in std_logic;

        addr_b_i:       in std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_in_b_i:    in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_b_o:   out std_logic_vector(DATA_WIDTH-1 downto 0);
        w_en_b_i:       in std_logic;
        r_en_b_i:       in std_logic
    );
end entity dual_ram;

architecture rtl of dual_ram is
    type mem_type is array((2**ADDR_WIDTH)-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mem: mem_type;
    signal addr_a_i_int: integer;
    signal addr_b_i_int: integer;
begin
    
    addr_a_i_int <= to_integer(unsigned(addr_a_i));
    addr_b_i_int <= to_integer(unsigned(addr_b_i));

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if w_en_a_i = '1' then
                mem(addr_a_i_int) <= data_in_a_i;
                data_out_a_o <= mem(addr_a_i_int);
            elsif r_en_a_i = '1' then
                data_out_a_o <= mem(addr_a_i_int);
            end if;
        end if;
    end process;

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if w_en_b_i = '1' then
                mem(addr_b_i_int) <= data_in_b_i;
                data_out_b_o <= mem(addr_b_i_int);
            elsif r_en_b_i = '1' then 
                data_out_b_o <= mem(addr_b_i_int);
            end if;
        end if;
    end process;

end architecture;


