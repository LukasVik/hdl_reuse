library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library common;
use common.math_pkg.all;

library axi;
use axi.axi_pkg.all;

library vunit_lib;
use vunit_lib.bus_master_pkg.all;
use vunit_lib.axi_pkg.all;
context vunit_lib.vunit_context;


entity axi_slave is
  generic (
    axi_slave : axi_slave_t;
    data_width : integer
  );
  port (
    clk : in std_logic;

    axi_read_m2s : in axi_read_m2s_t := axi_read_m2s_init;
    axi_read_s2m : out axi_read_s2m_t := axi_read_s2m_init;

    axi_write_m2s : in axi_write_m2s_t := axi_write_m2s_init;
    axi_write_s2m : out axi_write_s2m_t := axi_write_s2m_init
  );
end entity;

architecture a of axi_slave is
  signal bid, rid, aid : std_logic_vector(8 - 1 downto 0) := (others => '0'); -- Using "open" not ok in GHDL: unconstrained port "rid" must be connected
begin

  ------------------------------------------------------------------------------
  axi_write_slave_inst : entity vunit_lib.axi_write_slave
    generic map (
      axi_slave => axi_slave
    )
    port map (
      aclk => clk,

      awvalid => axi_write_m2s.aw.valid,
      awready => axi_write_s2m.aw.ready,
      awid => aid,
      awaddr => axi_write_m2s.aw.addr,
      awlen => axi_write_m2s.aw.len,
      awsize => axi_write_m2s.aw.size,
      awburst => axi_write_m2s.aw.burst,

      wvalid => axi_write_m2s.w.valid,
      wready => axi_write_s2m.w.ready,
      wid => aid,
      wdata => axi_write_m2s.w.data(data_width - 1 downto 0),
      wstrb => axi_write_m2s.w.strb,
      wlast => axi_write_m2s.w.last,

      bvalid => axi_write_s2m.b.valid,
      bready => axi_write_m2s.b.ready,
      bid => bid,
      bresp => axi_write_s2m.b.resp
    );


  ------------------------------------------------------------------------------
  axi_read_slave_inst : entity vunit_lib.axi_read_slave
    generic map (
      axi_slave => axi_slave
    )
    port map (
      aclk => clk,

      arvalid => axi_read_m2s.ar.valid,
      arready => axi_read_s2m.ar.ready,
      arid => aid,
      araddr => axi_read_m2s.ar.addr,
      arlen => axi_read_m2s.ar.len,
      arsize => axi_read_m2s.ar.size,
      arburst => axi_read_m2s.ar.burst,

      rvalid => axi_read_s2m.r.valid,
      rready => axi_read_m2s.r.ready,
      rid => rid,
      rdata => axi_read_s2m.r.data(data_width - 1 downto 0),
      rresp => axi_read_s2m.r.resp,
      rlast => axi_read_s2m.r.last
    );

end architecture;
