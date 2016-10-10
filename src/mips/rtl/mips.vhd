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

    instr_r_data_i      : in  dw_t;
    instr_addr_o        : out dw_t
    instr_r_en_o        : out std_logic;
    instr_clk_o         : out std_logic;
    instr_reset_o       : out std_logic;

    data_r_data_i       : in  dw_t;
    data_w_en_o         : out std_logic;
    data_r_en_o         : out std_logic;
    data_w_data_o       : out dw_t;
    data_addr_o         : out dw_t;
    data_clk_o          : out std_logic;
    data_reset_o        : out std_logic;

    pc_r_data_i         : in  dw_t;
    pc_w_data_o         : out dw_t;
    pc_w_en_o:          : out std_logic;
    pc_clk_o:           : out std_logic;

    reg_rs_o            : out reg_id_t;
    reg_rt_o            : out reg_id_t;
    reg_rw_o            : out reg_id_t;
    reg_w_data_o        : out dw_t;
    reg_w_en_o          : out std_logic;
    reg_r_data_0_i      : in dw_t;
    reg_r_data_1_i      : in dw_t;
    reg_reset_o:        : out std_logic;
    reg_clk_o:          : out std_logic;
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
      d0_i  => reg_r_data_1_i,
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
      d1_i  => data_rdata_i,
      sel_i => mem_to_reg,

      q_o   => reg_w_data
    );

--------------------------------------------------------------------------------
-- Instruction decoder
--------------------------------------------------------------------------------
  instr_dec: intruction_decoder
    port map (
      instr_i => instr_r_data_i,
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
--
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
--
--       q0_o   => reg_q0,
--       q1_o   => reg_q1
--  );

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
      op1_i  => reg_r_data_0_i,
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
      d1_i => pc_r_data_i,
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
      pc_i            => pc_r_data_i,
      targ_addr_i     => j_targ, 

      addr_o          => pc_jump
    );


  branch_mux_sel <= branch and zf;

--------------------------------------------------------------------------------
-- Output signals
--------------------------------------------------------------------------------

  instr_addr_o <= pc_r_data_i;
  instr_r_en_o <= '1'
  instr_clk_o <= ck_i
  instr_reset_o <= '0'

  data_w_en_o  <= mem_wr;
  data_r_en_o  <= mem_r;
  data_addr_o  <= alu_res;
  data_w_data_o <= reg_r_data_1_i;
  data_clk_o <= ck_i;
  data_reset_o <= '0'

  pc_w_data_o <= pc_d;
  pc_w_en_o <= '1';
  pc_clk_o <= ck_i;

  reg_rs_o <= rs;
  reg_rt_o <= rt;
  reg_rw_o <= rw_sel;
  reg_w_data_o <= reg_w_data;
  reg_w_en_o <= reg_wr;
  reg_reset_o <= rst_i;
  reg_clk_o <= ck_i;

end architecture;
