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
    default_value : integer := 0;
    counter_max   : integer := integer'high
    );
  port (
    clk_in     : in std_logic;
    counter_in : in integer range 0 to counter_max;

    clk_out     : in  std_logic;
    counter_out : out integer range 0 to counter_max := default_value
    );
end entity;

architecture a of resync_counter is
  signal counter_in_gray  : std_logic_vector(num_bits_needed(counter_max)-1 downto 0);
  signal counter_out_gray : std_logic_vector(num_bits_needed(counter_max)-1 downto 0);
begin

  assert is_power_of_two(counter_max+1) report "Counter range must be a power of two";


  counter_in_gray <= to_gray(counter_in, counter_in_gray'length);
  resync_slv : entity work.resync_slv
    generic map (
      default_value => '0')
    port map (
      data_in  => counter_in_gray,
      clk_out  => clk_out,
      data_out => counter_out_gray
      );

  counter_out <= from_gray(counter_out_gray);

end architecture;
