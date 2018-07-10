-- @brief Asynchronous FIFO.
--
-- @details Vivado synthesis example with Zynq 7020 and the following generics
--   width: 64, depth: 1024
-- resulted in resource utilization
--   RAMB36: TODO, LUT: TODO, FF: TODO
-- with en estimated max frequency of TODO.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library common;
use common.types_pkg.all;

library math;
use math.math_pkg.all;

library resync;


entity afifo is
  generic (
    width : integer;
    depth : integer
    );
  port (
    clk_read : in std_logic;

    read_ready : in  std_logic;
    read_valid : out std_logic := '0';  -- '1' if FIFO is not empty
    read_data  : out std_logic_vector(width - 1 downto 0);

    clk_write : in std_logic;

    write_ready : out std_logic := '1';  -- '1' if FIFO is not full
    write_valid : in  std_logic;
    write_data  : in  std_logic_vector(width - 1 downto 0)
    );
end entity;

architecture a of afifo is

  signal level                                                      : integer range 0 to depth     := 0;
  signal read_addr, read_addr_plus_1_reg, read_addr_reg, write_addr, read_addr_resync, write_addr_resync : integer range 0 to depth - 1 := 0;

begin

  assert is_power_of_two(depth) report "Depth must be a power of two, to make counter synchronization convenient";

  ------------------------------------------------------------------------------
  read_addr_handling : process
  begin
    wait until rising_edge(clk_read);

    read_addr_reg <= read_addr;

    if read_addr = depth - 1 then
      read_addr_plus_1_reg <= 0;
    else
      read_addr_plus_1_reg <= read_addr + 1;
    end if;
  end process;

  read_addr <= read_addr_plus_1_reg when (read_ready and read_valid) = '1' else read_addr_reg;


  ------------------------------------------------------------------------------
  write_status : process
    variable write_addr_plus_1 : integer range 0 to depth - 1 := 0;
  begin
    wait until rising_edge(clk_write);

    if write_addr = depth - 1 then
      write_addr_plus_1 := 0;
    else
      write_addr_plus_1 := write_addr + 1;
    end if;

    if read_addr_resync = write_addr_plus_1 then
      write_ready <= '0';
    else
      write_ready <= '1';
    end if;

    if write_ready and write_valid then
      write_addr <= write_addr_plus_1;
    end if;
  end process;

  resync_write_addr : entity resync.resync_counter
    generic map (
      counter_max   => depth-1)
    port map (
      clk_in      => clk_write,
      counter_in  => write_addr,
      clk_out     => clk_read,
      counter_out => write_addr_resync
      );


  ------------------------------------------------------------------------------
  read_status : process
  begin
    wait until rising_edge(clk_read);
    if write_addr_resync /= read_addr then
      read_valid <= '1';
    else
      read_valid <= '0';
    end if;
  end process;

  resync_read_addr : entity resync.resync_counter
    generic map (
      counter_max   => depth-1)
    port map (
      clk_in      => clk_read,
      counter_in  => read_addr,
      clk_out     => clk_write,
      counter_out => read_addr_resync
      );


  ------------------------------------------------------------------------------
  memory : block
    subtype word_t is std_logic_vector(width - 1 downto 0);
    type mem_t is array (integer range <>) of word_t;
    signal mem : mem_t(0 to depth - 1) := (others => (others => '0'));
  begin
    write_memory : process
    begin
      wait until rising_edge(clk_write);

      if write_ready and write_valid then
        mem(write_addr) <= write_data;
      end if;
    end process;

    read_memory : process
    begin
      wait until rising_edge(clk_read);

      read_data <= mem(read_addr);
    end process;
  end block;

end architecture;
