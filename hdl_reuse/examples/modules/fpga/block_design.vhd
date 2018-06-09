library ieee;
use ieee.std_logic_1164.all;

library axi;
use axi.axi_pkg.all;

library common;
use common.common_pkg.all;


entity block_design is
  port (
    clk_hpm0 : out std_logic;
    hpm0_m2s : out axi_m2s_t;
    hpm0_s2m : in axi_s2m_t
  );
end entity;

architecture a of block_design is

begin

  block_design_inst : if in_simulation generate
    block_design_mock_inst : entity work.block_design_mock
    port map (
      clk_hpm0 => clk_hpm0,
      hpm0_m2s => hpm0_m2s,
      hpm0_s2m => hpm0_s2m
    );

  else generate

    -- Inst real block_design_wrapper from Vivado

  end generate;

end architecture;
