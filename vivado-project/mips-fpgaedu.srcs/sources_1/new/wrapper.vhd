library ieee;
use ieee.std_logic_1164.all;

entity wrapper is
    port (
        clk         : in std_logic;
        exp_clk     : in std_logic;
        exp_clk_en  : in std_logic;
        reset       : in std_logic;
        addr        : in std_logic_vector(31 downto 0);
        din         : in std_logic_vector(31 downto 0);
        dout        : out std_logic_vector(31 downto 0);
        wen         : in std_logic
    );  
end wrapper;

architecture Behavioral of wrapper is
    -- constant declarations
    constant ADDR_WIDTH             : integer := 32;
    constant DATA_WIDTH             : integer := 32;
    
    constant SLAVE_0_ADDR_FROM      : integer := 0;
    constant SLAVE_0_ADDR_TO        : integer := 98;
    constant SLAVE_1_ADDR_FROM      : integer := 99;
    constant SLAVE_1_ADDR_TO        : integer := 99;
    constant SLAVE_2_ADDR_FROM      : integer := 100;
    constant SLAVE_2_ADDR_TO        : integer := 131;
    constant SLAVE_3_ADDR_FROM      : integer := 10000;
    constant SLAVE_3_ADDR_TO        : integer := 11023;
    constant SLAVE_4_ADDR_FROM      : integer := 20000;
    constant SLAVE_4_ADDR_TO        : integer := 21023;
    
    -- mmap split interconnect signals    
    signal split_0_to_1_clk         : std_logic;                     
    signal split_0_to_1_exp_clk     : std_logic;                     
    signal split_0_to_1_exp_clk_en  : std_logic;                     
    signal split_0_to_1_reset       : std_logic;                     
    signal split_0_to_1_addr        : std_logic_vector(31 downto 0); 
    signal split_0_to_1_din         : std_logic_vector(31 downto 0); 
    signal split_0_to_1_dout        : std_logic_vector(31 downto 0);
    signal split_0_to_1_wen         : std_logic;                      

    signal split_1_to_2_clk         : std_logic;                     
    signal split_1_to_2_exp_clk     : std_logic;                     
    signal split_1_to_2_exp_clk_en  : std_logic;                     
    signal split_1_to_2_reset       : std_logic;                     
    signal split_1_to_2_addr        : std_logic_vector(31 downto 0); 
    signal split_1_to_2_din         : std_logic_vector(31 downto 0); 
    signal split_1_to_2_dout        : std_logic_vector(31 downto 0);
    signal split_1_to_2_wen         : std_logic;              
    
    signal split_2_to_3_clk         : std_logic;                     
    signal split_2_to_3_exp_clk     : std_logic;                     
    signal split_2_to_3_exp_clk_en  : std_logic;                     
    signal split_2_to_3_reset       : std_logic;                     
    signal split_2_to_3_addr        : std_logic_vector(31 downto 0); 
    signal split_2_to_3_din         : std_logic_vector(31 downto 0); 
    signal split_2_to_3_dout        : std_logic_vector(31 downto 0);
    signal split_2_to_3_wen         : std_logic;
    
    signal slave_0_clk              : std_logic;
    signal slave_0_exp_clk          : std_logic;
    signal slave_0_exp_clk_en       : std_logic;
    signal slave_0_rst              : std_logic;
    signal slave_0_addr             : std_logic_vector(31 downto 0);
    signal slave_0_din              : std_logic_vector(31 downto 0);
    signal slave_0_dout             : std_logic_vector(31 downto 0);
    signal slave_0_w_en             : std_logic;
        
    signal mips_sig_pc              : std_logic_vector(31 downto 0);
    signal mips_sig_pc_next         : std_logic_vector(31 downto 0);
    signal mips_sig_op              : std_logic_vector(5 downto 0);
    signal mips_sig_rs              : std_logic_vector(4 downto 0);
    signal mips_sig_rt              : std_logic_vector(4 downto 0);
    signal mips_sig_rd              : std_logic_vector(4 downto 0);
    signal mips_sig_funct           : std_logic_vector(5 downto 0);
    signal mips_sig_immed           : std_logic_vector(15 downto 0);
    signal mips_sig_reg_q0          : std_logic_vector(31 downto 0);
    signal mips_sig_reg_q1          : std_logic_vector(31 downto 0);
    signal mips_sig_reg_wdata       : std_logic_vector(31 downto 0);
    signal mips_sig_instr_rdata     : std_logic_vector(31 downto 0);
    signal mips_sig_instr_addr      : std_logic_vector(31 downto 0);
    signal mips_sig_data_w_en       : std_logic;
    signal mips_sig_data_r_en       : std_logic;
    signal mips_sig_data_rdata      : std_logic_vector(31 downto 0);
    signal mips_sig_data_wdata      : std_logic_vector(31 downto 0);
    signal mips_sig_data_addr       : std_logic_vector(31 downto 0);
    signal mips_sig_reg_wr          : std_logic;        

    signal slave_1_clk              : std_logic;
    signal slave_1_exp_clk          : std_logic;
    signal slave_1_exp_clk_en       : std_logic;
    signal slave_1_rst              : std_logic;
    signal slave_1_addr             : std_logic_vector(31 downto 0);
    signal slave_1_din              : std_logic_vector(31 downto 0);
    signal slave_1_dout             : std_logic_vector(31 downto 0);
    signal slave_1_w_en             : std_logic;
    
    signal mips_pc_clk              : std_logic;
    signal mips_pc_rst              : std_logic;
    signal mips_pc_d                : std_logic_vector(31 downto 0);
    signal mips_pc_w_en             : std_logic;
    signal mips_pc_q                : std_logic_vector(31 downto 0);
    
    signal slave_2_clk              : std_logic;
    signal slave_2_exp_clk          : std_logic;
    signal slave_2_exp_clk_en       : std_logic;
    signal slave_2_rst              : std_logic;
    signal slave_2_addr             : std_logic_vector(31 downto 0);
    signal slave_2_din              : std_logic_vector(31 downto 0);
    signal slave_2_dout             : std_logic_vector(31 downto 0);
    signal slave_2_w_en             : std_logic;
    
    -- mips register file interface
    signal mips_reg_file_clk        : std_logic;
    signal mips_reg_file_rst        : std_logic;
    signal mips_reg_file_r0_sel     : std_logic_vector(4 downto 0);
    signal mips_reg_file_r1_sel     : std_logic_vector(4 downto 0);
    signal mips_reg_file_rw_sel     : std_logic_vector(4 downto 0);
    signal mips_reg_file_d          : std_logic_vector(31 downto 0);
    signal mips_reg_file_w_en       : std_logic;
    signal mips_reg_file_q0         : std_logic_vector(31 downto 0); 
    signal mips_reg_file_q1         : std_logic_vector(31 downto 0);

    
    signal slave_3_clk              : std_logic;
    signal slave_3_exp_clk          : std_logic;
    signal slave_3_exp_clk_en       : std_logic;
    signal slave_3_rst              : std_logic;
    signal slave_3_addr             : std_logic_vector(31 downto 0);
    signal slave_3_din              : std_logic_vector(31 downto 0);
    signal slave_3_dout             : std_logic_vector(31 downto 0);
    signal slave_3_w_en             : std_logic;
    
    signal mips_instr_mem_clk       : std_logic;                    
    signal mips_instr_mem_rdata     : std_logic_vector(31 downto 0);
    signal mips_instr_mem_addr      : std_logic_vector(31 downto 0);
    
    signal slave_4_clk              : std_logic;
    signal slave_4_exp_clk          : std_logic;
    signal slave_4_exp_clk_en       : std_logic;
    signal slave_4_rst              : std_logic;
    signal slave_4_addr             : std_logic_vector(31 downto 0);
    signal slave_4_din              : std_logic_vector(31 downto 0);
    signal slave_4_dout             : std_logic_vector(31 downto 0);
    signal slave_4_w_en             : std_logic;
    
    signal mips_data_mem_clk        : std_logic;    
    signal mips_data_mem_w_en       : std_logic;
    signal mips_data_mem_r_en       : std_logic;
    signal mips_data_mem_wdata      : std_logic_vector(31 downto 0);
    signal mips_data_mem_addr       : std_logic_vector(31 downto 0);
    signal mips_data_mem_rdata      : std_logic_vector(31 downto 0);
    
begin

    mmap_split_inst_0: entity work.mmap_split(structural)
        generic map (
            SLAVE_A_ADDR_SUBTRACT   => SLAVE_0_ADDR_FROM,
            SLAVE_A_ADDR_FROM       => SLAVE_0_ADDR_FROM,
            SLAVE_A_ADDR_TO         => SLAVE_0_ADDR_TO,
            SLAVE_B_ADDR_SUBTRACT   => 0,
            SLAVE_B_ADDR_FROM       => SLAVE_1_ADDR_FROM,
            SLAVE_B_ADDR_TO         => integer'high,
            ADDR_WIDTH              => ADDR_WIDTH,
            DATA_WIDTH              => DATA_WIDTH
        )
        port map (
            master_clk_i            => clk,
            master_exp_clk_i        => exp_clk,
            master_exp_clk_en_i     => exp_clk_en,
            master_rst_i            => reset,
            master_addr_i           => addr,
            master_data_in_i        => din,
            master_data_out_o       => dout,
            master_w_en_i           => wen,

            slave_a_clk_o           =>  slave_0_clk,       
            slave_a_exp_clk_o       =>  slave_0_exp_clk,   
            slave_a_exp_clk_en_o    =>  slave_0_exp_clk_en,
            slave_a_rst_o           =>  slave_0_rst,       
            slave_a_addr_o          =>  slave_0_addr,      
            slave_a_data_in_o       =>  slave_0_din,       
            slave_a_data_out_i      =>  slave_0_dout,      
            slave_a_w_en_o          =>  slave_0_w_en,     
 
            slave_b_clk_o           => split_0_to_1_clk,       
            slave_b_exp_clk_o       => split_0_to_1_exp_clk,   
            slave_b_exp_clk_en_o    => split_0_to_1_exp_clk_en,
            slave_b_rst_o           => split_0_to_1_reset,     
            slave_b_addr_o          => split_0_to_1_addr,      
            slave_b_data_in_o       => split_0_to_1_din,       
            slave_b_data_out_i      => split_0_to_1_dout,      
            slave_b_w_en_o          => split_0_to_1_wen              
        );

    mmap_split_inst_1: entity work.mmap_split(structural)
        generic map (
            SLAVE_A_ADDR_SUBTRACT   => SLAVE_1_ADDR_FROM,
            SLAVE_A_ADDR_FROM       => SLAVE_1_ADDR_FROM,
            SLAVE_A_ADDR_TO         => SLAVE_1_ADDR_TO,
            SLAVE_B_ADDR_SUBTRACT   => 0,
            SLAVE_B_ADDR_FROM       => SLAVE_2_ADDR_FROM,
            SLAVE_B_ADDR_TO         => integer'high,
            ADDR_WIDTH              => ADDR_WIDTH,
            DATA_WIDTH              => DATA_WIDTH
        )
        port map (
            master_clk_i            => split_0_to_1_clk,       
            master_exp_clk_i        => split_0_to_1_exp_clk,   
            master_exp_clk_en_i     => split_0_to_1_exp_clk_en,
            master_rst_i            => split_0_to_1_reset,     
            master_addr_i           => split_0_to_1_addr,      
            master_data_in_i        => split_0_to_1_din,       
            master_data_out_o       => split_0_to_1_dout,      
            master_w_en_i           => split_0_to_1_wen,       

            slave_a_clk_o           =>  slave_1_clk,       
            slave_a_exp_clk_o       =>  slave_1_exp_clk,   
            slave_a_exp_clk_en_o    =>  slave_1_exp_clk_en,
            slave_a_rst_o           =>  slave_1_rst,       
            slave_a_addr_o          =>  slave_1_addr,      
            slave_a_data_in_o       =>  slave_1_din,       
            slave_a_data_out_i      =>  slave_1_dout,      
            slave_a_w_en_o          =>  slave_1_w_en,     
 
            slave_b_clk_o           => split_1_to_2_clk,       
            slave_b_exp_clk_o       => split_1_to_2_exp_clk,   
            slave_b_exp_clk_en_o    => split_1_to_2_exp_clk_en,
            slave_b_rst_o           => split_1_to_2_reset,     
            slave_b_addr_o          => split_1_to_2_addr,      
            slave_b_data_in_o       => split_1_to_2_din,       
            slave_b_data_out_i      => split_1_to_2_dout,      
            slave_b_w_en_o          => split_1_to_2_wen           
        );

    mmap_split_inst_2: entity work.mmap_split(structural)
        generic map (
            SLAVE_A_ADDR_SUBTRACT   => SLAVE_2_ADDR_FROM,
            SLAVE_A_ADDR_FROM       => SLAVE_2_ADDR_FROM,
            SLAVE_A_ADDR_TO         => SLAVE_2_ADDR_TO,
            SLAVE_B_ADDR_SUBTRACT   => 0,
            SLAVE_B_ADDR_FROM       => SLAVE_3_ADDR_FROM,
            SLAVE_B_ADDR_TO         => integer'high,
            ADDR_WIDTH              => ADDR_WIDTH,
            DATA_WIDTH              => DATA_WIDTH
        )
        port map (
            master_clk_i            => split_1_to_2_clk,       
            master_exp_clk_i        => split_1_to_2_exp_clk,   
            master_exp_clk_en_i     => split_1_to_2_exp_clk_en,
            master_rst_i            => split_1_to_2_reset,     
            master_addr_i           => split_1_to_2_addr,      
            master_data_in_i        => split_1_to_2_din,       
            master_data_out_o       => split_1_to_2_dout,      
            master_w_en_i           => split_1_to_2_wen,       

            slave_a_clk_o           =>  slave_2_clk,       
            slave_a_exp_clk_o       =>  slave_2_exp_clk,   
            slave_a_exp_clk_en_o    =>  slave_2_exp_clk_en,
            slave_a_rst_o           =>  slave_2_rst,       
            slave_a_addr_o          =>  slave_2_addr,      
            slave_a_data_in_o       =>  slave_2_din,       
            slave_a_data_out_i      =>  slave_2_dout,      
            slave_a_w_en_o          =>  slave_2_w_en,     
 
            slave_b_clk_o           => split_2_to_3_clk,       
            slave_b_exp_clk_o       => split_2_to_3_exp_clk,   
            slave_b_exp_clk_en_o    => split_2_to_3_exp_clk_en,
            slave_b_rst_o           => split_2_to_3_reset,     
            slave_b_addr_o          => split_2_to_3_addr,      
            slave_b_data_in_o       => split_2_to_3_din,       
            slave_b_data_out_i      => split_2_to_3_dout,      
            slave_b_w_en_o          => split_2_to_3_wen              
        );

    mmap_split_inst_3: entity work.mmap_split(structural)
        generic map (
            SLAVE_A_ADDR_SUBTRACT   => SLAVE_3_ADDR_FROM,
            SLAVE_A_ADDR_FROM       => SLAVE_3_ADDR_FROM,
            SLAVE_A_ADDR_TO         => SLAVE_3_ADDR_TO,
            SLAVE_B_ADDR_SUBTRACT   => SLAVE_4_ADDR_FROM,
            SLAVE_B_ADDR_FROM       => SLAVE_4_ADDR_FROM,
            SLAVE_B_ADDR_TO         => SLAVE_4_ADDR_TO,
            ADDR_WIDTH              => ADDR_WIDTH,
            DATA_WIDTH              => DATA_WIDTH
        )
        port map (
            master_clk_i            => split_2_to_3_clk,       
            master_exp_clk_i        => split_2_to_3_exp_clk,   
            master_exp_clk_en_i     => split_2_to_3_exp_clk_en,
            master_rst_i            => split_2_to_3_reset,     
            master_addr_i           => split_2_to_3_addr,      
            master_data_in_i        => split_2_to_3_din,       
            master_data_out_o       => split_2_to_3_dout,      
            master_w_en_i           => split_2_to_3_wen,       

            slave_a_clk_o           =>  slave_3_clk,       
            slave_a_exp_clk_o       =>  slave_3_exp_clk,   
            slave_a_exp_clk_en_o    =>  slave_3_exp_clk_en,
            slave_a_rst_o           =>  slave_3_rst,       
            slave_a_addr_o          =>  slave_3_addr,      
            slave_a_data_in_o       =>  slave_3_din,       
            slave_a_data_out_i      =>  slave_3_dout,      
            slave_a_w_en_o          =>  slave_3_w_en,     
 
            slave_b_clk_o           =>  slave_4_clk,       
            slave_b_exp_clk_o       =>  slave_4_exp_clk,   
            slave_b_exp_clk_en_o    =>  slave_4_exp_clk_en,
            slave_b_rst_o           =>  slave_4_rst,       
            slave_b_addr_o          =>  slave_4_addr,      
            slave_b_data_in_o       =>  slave_4_din,       
            slave_b_data_out_i      =>  slave_4_dout,      
            slave_b_w_en_o          =>  slave_4_w_en             
        );
        
    -- MIPS instance
    mips_inst: entity work.mips(structural)
        port map (
            rst_i               => reset,
            ck_i                => exp_clk,
            -- Instruction memory, interface b-side
            instr_mem_clk_o     => mips_instr_mem_clk,  
            instr_mem_rdata_i   => mips_instr_mem_rdata,
            instr_mem_addr_o    => mips_instr_mem_addr, 
            -- data memory, interface b-side
            data_mem_clk_o      => mips_data_mem_clk,  
            data_mem_w_en_o     => mips_data_mem_w_en, 
            data_mem_r_en_o     => mips_data_mem_r_en, 
            data_mem_wdata_o    => mips_data_mem_wdata,
            data_mem_rdata_i    => mips_data_mem_rdata, 
            data_mem_addr_o     => mips_data_mem_addr,
            -- PC reg
            pc_clk_o            => mips_pc_clk, 
            pc_rst_o            => mips_pc_rst,
            pc_d_o              => mips_pc_d,
            pc_w_en_o           => mips_pc_w_en,
            pc_q_i              => mips_pc_q,
            -- Register File
            reg_file_clk_o      => mips_reg_file_clk,          
            reg_file_rst_o      => mips_reg_file_rst,    
            reg_file_r0_sel_o   => mips_reg_file_r0_sel, 
            reg_file_r1_sel_o   => mips_reg_file_r1_sel, 
            reg_file_rw_sel_o   => mips_reg_file_rw_sel, 
            reg_file_d_o        => mips_reg_file_d,      
            reg_file_w_en_o     => mips_reg_file_w_en,   
            reg_file_q0_i       => mips_reg_file_q0,     
            reg_file_q1_i       => mips_reg_file_q1,                
            -- Signals, connectoed to wrapper
            sig_pc_o            => mips_sig_pc,       
            sig_pc_next_o       => mips_sig_pc_next,  
            sig_op_o            => mips_sig_op,       
            sig_rs_o            => mips_sig_rs,       
            sig_rt_o            => mips_sig_rt,       
            sig_rd_o            => mips_sig_rd,       
            sig_funct_o         => mips_sig_funct,    
            sig_immed_o         => mips_sig_immed,    
            sig_reg_q0_o        => mips_sig_reg_q0,   
            sig_reg_q1_o        => mips_sig_reg_q1,   
            sig_reg_wdata_o     => mips_sig_reg_wdata,
            sig_instr_rdata_o   => mips_sig_instr_rdata,
            sig_instr_addr_o    => mips_sig_instr_addr,
            sig_data_w_en_o     => mips_sig_data_w_en,
            sig_data_r_en_o     => mips_sig_data_r_en,
            sig_data_wdata_o    => mips_sig_data_wdata,
            sig_data_addr_o     => mips_sig_data_addr,
            sig_data_rdata_o    => mips_sig_data_rdata,
            sig_reg_wr_o        => mips_sig_reg_wr            
        );
        
    -- MIPS signal wrapper
    mmap_mips_signal_wrapper_inst: entity work.mmap_mips_signal_wrapper(Behavioral)
        port map (
            -- mem interface signals
            clk                     => slave_0_clk,
            exp_clk                 => slave_0_exp_clk,
            exp_clk_en              => slave_0_exp_clk_en,
            reset                   => slave_0_rst,
            addr                    => slave_0_addr,
            din                     => slave_0_din,
            dout                    => slave_0_dout,
            wen                     => slave_0_w_en,
            -- mips exposed signals
            mips_sig_pc_i           => mips_sig_pc,
            mips_sig_pc_next_i      => mips_sig_pc_next,
            mips_sig_op_i           => mips_sig_op,
            mips_sig_rs_i           => mips_sig_rs,
            mips_sig_rt_i           => mips_sig_rt,
            mips_sig_rd_i           => mips_sig_rd,
            mips_sig_funct_i        => mips_sig_funct,
            mips_sig_immed_i        => mips_sig_immed,
            mips_sig_reg_q0_i       => mips_sig_reg_q0,
            mips_sig_reg_q1_i       => mips_sig_reg_q1,
            mips_sig_reg_wdata_i    => mips_sig_reg_wdata,
            mips_sig_instr_rdata_i  => mips_sig_instr_rdata,
            mips_sig_instr_addr_i   => mips_sig_instr_addr,
            mips_sig_data_w_en_i    => mips_sig_data_w_en,
            mips_sig_data_r_en_i    => mips_sig_data_r_en,
            mips_sig_data_wdata_i   => mips_sig_data_wdata,
            mips_sig_data_addr_i    => mips_sig_data_addr,
            mips_sig_data_rdata_i   => mips_sig_data_rdata,
            mips_sig_reg_wr_i       => mips_sig_reg_wr
        );
        
    mmap_mips_pc_register_inst: entity work.mmap_mips_pc_register(Behavioral)
        port map (
            -- mem interface signals
            clk             => slave_1_clk,
            exp_clk         => slave_1_exp_clk,
            exp_clk_en      => slave_1_exp_clk_en,
            reset           => slave_1_rst,
            addr            => slave_1_addr,
            din             => slave_1_din,
            dout            => slave_1_dout,
            wen             => slave_1_w_en,
            -- mips pc reg signals
            mips_pc_clk_i   => mips_pc_clk,
            mips_pc_rst_i   => mips_pc_rst,
            mips_pc_d_i     => mips_pc_d,
            mips_pc_w_en_i  => mips_pc_w_en,
            mips_pc_q_o     => mips_pc_q
        );
        
    mmap_mips_register_file_inst: entity work.mmap_mips_register_file(Behavioral)
        port map (
            -- data mem interface
            clk                     => slave_2_clk,
            exp_clk                 => slave_2_exp_clk,
            exp_clk_en              => slave_2_exp_clk_en,
            reset                   => slave_2_rst,
            addr                    => slave_2_addr,
            din                     => slave_2_din,
            dout                    => slave_2_dout,
            wen                     => slave_2_w_en,
            -- mips register file in=> 
            mips_reg_file_clk_i     => mips_reg_file_clk,
            mips_reg_file_rst_i     => mips_reg_file_rst,
            mips_reg_file_r0_sel_i  => mips_reg_file_r0_sel,
            mips_reg_file_r1_sel_i  => mips_reg_file_r1_sel,
            mips_reg_file_rw_sel_i  => mips_reg_file_rw_sel,
            mips_reg_file_d_i       => mips_reg_file_d,
            mips_reg_file_w_en_i    => mips_reg_file_w_en,  
            mips_reg_file_q0_o      => mips_reg_file_q0,
            mips_reg_file_q1_o      => mips_reg_file_q1             
        );
        
    mmap_mips_instr_mem_inst: entity work.mmap_mips_instr_mem(Behavioral)
        port map (
            -- data mem interface
            clk                     => slave_3_clk,
            exp_clk                 => slave_3_exp_clk,
            exp_clk_en              => slave_3_exp_clk_en,
            reset                   => slave_3_rst,
            addr                    => slave_3_addr,
            din                     => slave_3_din,
            dout                    => slave_3_dout,
            wen                     => slave_3_w_en,
            -- MIPS data mem ports
            mips_instr_mem_clk_i    => mips_instr_mem_clk,      
            mips_instr_mem_rdata_o  => mips_instr_mem_rdata,     
            mips_instr_mem_addr_i   => mips_instr_mem_addr      
        );
    mmap_mips_data_mem_inst: entity work.mmap_mips_data_mem(Behavioral)
        port map (
            -- data mem interface
            clk                     => slave_4_clk,
            exp_clk                 => slave_4_exp_clk,
            exp_clk_en              => slave_4_exp_clk_en,
            reset                   => slave_4_rst,
            addr                    => slave_4_addr,
            din                     => slave_4_din,
            dout                    => slave_4_dout,
            wen                     => slave_4_w_en,
            -- MIPS data mem ports
            mips_data_mem_clk_i     => mips_data_mem_clk,  
            mips_data_mem_w_en_i    => mips_data_mem_w_en, 
            mips_data_mem_r_en_i    => mips_data_mem_r_en, 
            mips_data_mem_wdata_i   => mips_data_mem_wdata,
            mips_data_mem_addr_i    => mips_data_mem_addr, 
            mips_data_mem_rdata_o   => mips_data_mem_rdata
        );
     
end Behavioral;
