library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.alu_pack.all;
use work.core_pack.all;
use work.comp_pack.all;
use work.control_pack.all;
use work.glue_pack.all;

entity mips is
    port (
        rst_i               : in  std_logic;
        ck_i                : in  std_logic;
        --instruction mem ports
        instr_mem_clk_o         : out std_logic;
        instr_mem_rdata_i       : in  std_logic_vector(31 downto 0);
        instr_mem_addr_o        : out std_logic_vector(31 downto 0);
        --data mem ports
        data_mem_clk_o          : out std_logic;
        data_mem_w_en_o         : out std_logic;
        data_mem_r_en_o         : out std_logic;
        data_mem_wdata_o        : out std_logic_vector(31 downto 0);
        data_mem_addr_o         : out std_logic_vector(31 downto 0);
        data_mem_rdata_i        : in  std_logic_vector(31 downto 0);
        --program counter register ports
        pc_clk_o            : out std_logic;
        pc_rst_o            : out std_logic;
        pc_d_o              : out std_logic_vector(31 downto 0);
        pc_w_en_o           : out std_logic;
        pc_q_i              : in  std_logic_vector(31 downto 0);
        --register file ports
        reg_file_clk_o      : out std_logic;                     
        reg_file_rst_o      : out std_logic;                     
        reg_file_r0_sel_o   : out std_logic_vector(4 downto 0);  
        reg_file_r1_sel_o   : out std_logic_vector(4 downto 0);  
        reg_file_rw_sel_o   : out std_logic_vector(4 downto 0);  
        reg_file_d_o        : out std_logic_vector(31 downto 0); 
        reg_file_w_en_o     : out std_logic;                     
        reg_file_q0_i       : in std_logic_vector(31 downto 0);
        reg_file_q1_i       : in std_logic_vector(31 downto 0);
        --internal signal expose output ports
        sig_pc_o            : out std_logic_vector(31 downto 0);
        sig_pc_next_o       : out std_logic_vector(31 downto 0);        
        sig_op_o            : out std_logic_vector(5 downto 0);
        sig_rs_o            : out std_logic_vector(4 downto 0);
        sig_rt_o            : out std_logic_vector(4 downto 0);
        sig_rd_o            : out std_logic_vector(4 downto 0);
        sig_funct_o         : out std_logic_vector(5 downto 0);
        sig_immed_o         : out std_logic_vector(15 downto 0);
        sig_reg_q0_o        : out std_logic_vector(31 downto 0);
        sig_reg_q1_o        : out std_logic_vector(31 downto 0);
        sig_reg_wdata_o     : out std_logic_vector(31 downto 0);
        sig_instr_rdata_o   : out std_logic_vector(31 downto 0);
        sig_instr_addr_o    : out std_logic_vector(31 downto 0);
        sig_data_w_en_o     : out std_logic;
        sig_data_r_en_o     : out std_logic;
        sig_data_wdata_o    : out std_logic_vector(31 downto 0);
        sig_data_addr_o     : out std_logic_vector(31 downto 0);
        sig_data_rdata_o    : out std_logic_vector(31 downto 0);
        sig_reg_wr_o        : out std_logic
    );
end mips;

architecture structural of mips is
  -- Decoded from instruction
  signal op          : opcode_t;
  signal rs          : reg_id_t;
  signal rt          : reg_id_t;
  signal rd          : reg_id_t;
  signal funct       : funct_t;
  signal immed       : immed_t;
  signal j_targ      : j_targ_t;

  -- Write register selector
  signal rw_sel      : reg_id_t;

  -- Extended and shifted immed
  signal immed_ext   : dw_t;
  signal immed_sl2   : dw_t;

  -- PC
  signal pc_d        : dw_t; -- PC in
  signal pc_q        : dw_t; -- PC out
  signal pc_p4       : dw_t; -- PC + 4
  signal pc_branch   : dw_t; -- PC + immed_sl2 (for branching)
  signal pc_nojump   : dw_t; -- Target addr after branch_mux
  signal pc_jump     : dw_t; -- Computed Jump Addr

  -- Control unit signals
  signal reg_dst     : std_logic;
  signal branch      : std_logic;
  signal mem_to_reg  : std_logic;
  signal alup        : std_logic;
  signal mem_r       : std_logic;
  signal mem_wr      : std_logic;
  signal alu_src     : std_logic;
  signal reg_wr      : std_logic;
  signal jump        : std_logic;
  signal alucontrol  : instruction_t;

  -- Register bank
  signal reg_q0      : dw_t; -- Port 0 output
  signal reg_q1      : dw_t; -- Port 1 output
  signal reg_w_data  : dw_t; -- Write data

  -- ALU
  signal aluop       : alu_op_t;  -- ALU operation selector
  signal alu_oper2   : dw_t;      -- Second ALU operand
  signal alu_res     : dw_t;      -- ALU result
  signal zf          : std_logic; -- Zero flag
  signal bf          : std_logic; -- Borrow flag

  signal branch_mux_sel : std_logic;
begin
--------------------------------------------------------------------------------
-- Muxes
--------------------------------------------------------------------------------
  branch_mux: mux_2port
    generic map (
      bus_width_g => dw_t'length
    )
    port map (
      d0_i  => pc_p4,
      d1_i  => pc_branch,
      sel_i => branch_mux_sel,

      q_o   => pc_nojump
    );

  jump_mux: mux_2port
    generic map (
      bus_width_g => dw_t'length
    )
    port map (
      d0_i  => pc_nojump,
      d1_i  => pc_jump,
      sel_i => jump,

      q_o   => pc_d
    );
    

  reg_dst_mux: mux_2port
    generic map (
      bus_width_g => rt'length
    )
    port map (
      d0_i  => rt,
      d1_i  => rd,
      sel_i => reg_dst,

      q_o   => rw_sel
    );

  alu_src_mux: mux_2port
    generic map (
      bus_width_g => dw_t'length
    )
    port map (
      d0_i  => reg_q1,
      d1_i  => immed_ext,
      sel_i => alu_src,

      q_o   => alu_oper2
    );

  mem_to_reg_mux: mux_2port
    generic map (
      bus_width_g => dw_t'length
    )
    port map (
      d0_i  => alu_res,
      d1_i  => data_mem_rdata_i,
      sel_i => mem_to_reg,

      q_o   => reg_w_data
    );

--------------------------------------------------------------------------------
-- Instruction decoder
--------------------------------------------------------------------------------
  instr_dec: intruction_decoder
    port map (
      instr_i => instr_mem_rdata_i,
      op_o    => op,
      rs_o    => rs,
      rt_o    => rt,
      rd_o    => rd,
      funct_o => funct,
      immed_o => immed,
      j_targ_o=> j_targ
    );

--------------------------------------------------------------------------------
-- Registers
--------------------------------------------------------------------------------
--  the_pc: reg_g
--    generic map (
--      nbits_g => dw_t'length
--    )
--    port map (
--      d_i     => pc_d,
--      ck_i    => ck_i,
--      rst_i   => rst_i,
--      wr_en_i => '1',
--      q_o     => pc_q
--    );

    pc_clk_o    <= ck_i;
    pc_rst_o    <= rst_i;
    pc_d_o      <= pc_d;
    pc_w_en_o   <= '1';
    pc_q        <= pc_q_i;

--  reg_bank: reg_bank_3port
--    generic map (
--      sel_bits_g => 5
--    )
--    port map (
--       r0_sel => rs,
--       r1_sel => rt,
--       rw_sel => rw_sel,
--       d_i    => reg_w_data,
--       we_i   => reg_wr,
--       ck_i   => ck_i,
--       rst_i  => rst_i,

--       q0_o   => reg_q0,
--       q1_o   => reg_q1
--  );

    reg_file_clk_o    <= ck_i;
    reg_file_rst_o    <= rst_i;
    reg_file_r0_sel_o <= rs;
    reg_file_r1_sel_o <= rt;
    reg_file_rw_sel_o <= rw_sel;
    reg_file_d_o      <= reg_w_data;
    reg_file_w_en_o   <= reg_wr;
    reg_q0            <= reg_file_q0_i;
    reg_q1            <= reg_file_q1_i;

--------------------------------------------------------------------------------
-- ALU
--------------------------------------------------------------------------------
  alu_cnt: alu_control
    port map (
      alucontrol_i => alucontrol,
      funct_i      => funct,

      aluop_o      => aluop
     );

  the_alu: alu
    port map (
      op1_i  => reg_q0,
      op2_i  => alu_oper2,
      func_i => aluop,

      res_o  => alu_res,
      zf_o   => zf,
      bf_o   => bf
    );

  control: control_unit
    port map (
      op_i         => op,

      reg_dst_o    => reg_dst,
      branch_o     => branch,
      mem_to_reg_o => mem_to_reg,
      mem_r_o      => mem_r,
      mem_wr_o     => mem_wr,
      alu_src_o    => alu_src,
      reg_wr_o     => reg_wr,
      jump_o       => jump,
      alucontrol_o => alucontrol
     );
--------------------------------------------------------------------------------
-- Glue Logic
--------------------------------------------------------------------------------
  pc_adder: adder_g
    generic map (
      bus_width_g => dw_t'length
    )
    port map (
      d1_i => pc_q,
      d2_i => std_logic_vector(to_unsigned(4, dw_t'length)),

      q_o  => pc_p4
    );

  branch_adder: adder_g
    generic map (
      bus_width_g => dw_t'length
    )
    port map (
      d1_i => pc_p4,
      d2_i => immed_sl2,

      q_o  => pc_branch
    );

  immed_extender: sign_extender
    generic map (
      inp_width_g   => immed'length,
      outp_width_g  => dw_t'length
    )
    port map (
      d_i => immed,

      q_o => immed_ext
     );

  immed_shifter: left_shifter
    generic map (
      shift_amount_g => 2,
      bus_width_g    => dw_t'length
    )
    port map (
      d_i => immed_ext,
      q_o => immed_sl2
    );

  jump_comb: jump_combiner
    port map (
      pc_i            => pc_q,
      targ_addr_i     => j_targ, 

      addr_o          => pc_jump
    );

--------------------------------------------------------------------------------
-- Output signals
--------------------------------------------------------------------------------
  data_mem_clk_o   <= ck_i;
  data_mem_w_en_o  <= mem_wr;
  data_mem_r_en_o  <= mem_r;
  data_mem_addr_o  <= alu_res;
  data_mem_wdata_o <= reg_q1;
  
  instr_mem_clk_o <= ck_i;
  instr_mem_addr_o <= pc_q;
  branch_mux_sel <= branch and zf;

--------------------------------------------------------------------------------
-- Exposed output signals
--------------------------------------------------------------------------------
    sig_pc_o <= pc_q; 
    sig_pc_next_o <= pc_d;
    sig_op_o <= op;
    sig_rs_o <= rs;
    sig_rt_o <= rt;
    sig_rd_o <= rd;
    sig_funct_o <= funct;
    sig_immed_o <= immed;
    sig_reg_q0_o <= reg_q0;
    sig_reg_q1_o <= reg_q1;
    sig_reg_wdata_o <= reg_w_data;
    sig_reg_wr_o <= reg_wr;
    
    sig_instr_rdata_o <= instr_mem_rdata_i;
    sig_instr_addr_o <= pc_q;
    
    sig_data_w_en_o <= mem_wr;
    sig_data_r_en_o <= mem_r;
    sig_data_addr_o <= alu_res;
    sig_data_wdata_o <= reg_q1;
    sig_data_rdata_o <= data_mem_rdata_i;
    
end architecture;
