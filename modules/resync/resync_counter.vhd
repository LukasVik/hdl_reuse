-- @brief Synchronize a counter value between two domains
--
-- @details This module assumes that the input counter value only increments
-- and decrements in steps of one

library ieee;
use ieee.std_logic_1164.all;

library common;
use common.attribute_pkg.all;

library math;
use math.math_pkg.all;


entity resync_counter is
  generic (
    default_value   : integer := 0;
    counter_max     : integer := integer'high;
    pipeline_output : boolean := false
    );
  port (
    clk_in     : in  std_logic;
    counter_in : in integer range 0 to counter_max;

    clk_out     : in  std_logic;
    counter_out : out integer range 0 to counter_max := default_value
    );
end entity;

architecture a of resync_counter is
  signal counter_in_gray, counter_in_gray_p1, counter_out_gray : std_logic_vector(num_bits_needed(counter_max)-1 downto 0) := to_gray(default_value, num_bits_needed(counter_max));

  attribute async_reg of counter_in_gray_p1 : signal is "true";
  attribute async_reg of counter_out_gray   : signal is "true";
begin

  assert is_power_of_two(counter_max+1) report "Counter range must be a power of two";

  clk_in_process : process
  begin
    wait until rising_edge(clk_in);
    counter_in_gray <= to_gray(counter_in, num_bits_needed(counter_max));
  end process;

  clk_out_process : process
  begin
    wait until rising_edge(clk_out);
    counter_out_gray   <= counter_in_gray_p1;
    counter_in_gray_p1 <= counter_in_gray;
  end process;

  output_pipe : if pipeline_output generate
    pipe : process
    begin
      wait until rising_edge(clk_out);
      counter_out <= from_gray(counter_out_gray);
    end process;
  end generate;

  no_output_pipe : if not pipeline_output generate
  begin
    counter_out <= from_gray(counter_out_gray);
  end generate;

end architecture;
