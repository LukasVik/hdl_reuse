library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;


entity tb_resync_counter is
  generic (
    runner_cfg : string
    );
end entity;

architecture tb of tb_resync_counter is
  constant clk_period  : time    := 4 ns;
  constant counter_max : integer := 255;

  signal clk_out                 : std_logic                      := '0';
  signal counter_in, counter_out : integer range 0 to counter_max := 0;
begin

  test_runner_watchdog(runner, 10 ms);
  clk_out <= not clk_out after clk_period/2;


  ------------------------------------------------------------------------------
  main : process
    procedure wait_cycles(signal clk : std_logic; num_cycles : in integer) is
    begin
      for i in 0 to num_cycles-1 loop
        wait until rising_edge(clk);
      end loop;
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);

    loop_twice_to_wrap_counter : for i in 1 to 2 loop
      count_up : for value in 0 to counter_max loop
        wait until rising_edge(clk_out);
        counter_in <= value;
        wait until counter_out'event for 3*clk_period;
        check_equal(counter_out, value);
        wait until counter_out'event for 40*clk_period;
        assert not counter_out'event;
      end loop;
    end loop;

    count_down : for value in counter_max to 0 loop
      wait until rising_edge(clk_out);
      counter_in <= value;
      wait until counter_out'event for 3*clk_period;
      check_equal(counter_out, value);
      wait until counter_out'event for 40*clk_period;
      assert not counter_out'event;
    end loop;

    test_runner_cleanup(runner);
  end process;


  ------------------------------------------------------------------------------
  dut : entity work.resync_counter
    generic map (
      default_value   => 0,
      counter_max     => counter_max,
      pipeline_output => false)
    port map (
      clk_in     => clk_out,
      counter_in => counter_in,

      clk_out     => clk_out,
      counter_out => counter_out);

end architecture;
