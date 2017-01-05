library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity compose is
    port (
        clk:    in std_logic;
        reset:  in std_logic;
        rx:     in std_logic;
        tx:     out std_logic
    );
end compose;

architecture Behavioral of compose is
    signal exp_clk: std_logic;
    signal exp_clk_en: std_logic;
    signal exp_reset: std_logic;
    signal exp_addr: std_logic_vector(31 downto 0) := (others => '0');
    signal exp_din: std_logic_vector(31 downto 0) := (others => '0');
    signal exp_dout: std_logic_vector(31 downto 0) := (others => '0');
    signal exp_wen: std_logic;
begin
    nexys4_inst: entity work.nexys4(MyHDL) 
        port map (
            clk             => clk,
            reset           => reset,
            rx              => rx,
            tx              => tx,
            exp_addr        => exp_addr,
            exp_data_write  => exp_din,
            exp_data_read   => exp_dout,
            exp_wen         => exp_wen,
            exp_clk         => exp_clk,
            exp_clk_en      => exp_clk_en,
            exp_reset       => exp_reset
        );

    wrapper_inst: entity work.wrapper(Behavioral)
        port map (
            clk => clk,
            exp_clk => exp_clk,
            exp_clk_en => exp_clk_en,
            reset => exp_reset,
            addr => exp_addr,
            din => exp_din,
            dout => exp_dout,
            wen => exp_wen
        );

end Behavioral;
