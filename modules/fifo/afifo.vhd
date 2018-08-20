-- @brief Asynchronous FIFO.
--
-- @details Vivado synthesis example with Zynq 7020 and the following generics
--   width: 64, depth: 1024, almost_full_level: 512, almost_empty_level: 40
-- resulted in resource utilization
--   RAMB36: , LUT: , FF:

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
    width : integer := 64;
    depth : integer := 1024;
    almost_full_level : integer range 0 to depth := 0;
    almost_empty_level : integer range 0 to depth := 0
    );
  port (
    clk_read : in std_logic;

    read_ready : in  std_logic;
    read_valid : out std_logic := '0';  -- '1' if FIFO is not empty
    read_data  : out std_logic_vector(width - 1 downto 0);
    almost_empty : out std_logic;

    clk_write : in std_logic;

    write_ready : out std_logic := '1';  -- '1' if FIFO is not full
    write_valid : in  std_logic;
    write_data  : in  std_logic_vector(width - 1 downto 0);
    almost_full : out std_logic
    );
end entity;

architecture a of afifo is

  signal read_addr, read_addr_plus_1_reg, read_addr_reg, write_addr, read_addr_resync, write_addr_resync : integer range 0 to depth - 1 := 0;
  signal clk_write_level, clk_read_level : integer range 0 to depth := 0;

begin

  assert is_power_of_two(depth) report "Depth must be a power of two, to make counter synchronization convenient";

  write_ready <= not to_sl(clk_write_level > depth-1);
  almost_full <= to_sl(clk_write_level > almost_full_level - 1);
  almost_empty <= to_sl(clk_read_level < almost_empty_level);


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
    variable write_addr_plus_1 : integer range 0 to depth-1;
  begin
    wait until rising_edge(clk_write);
    if write_addr /= depth-1 then
      write_addr_plus_1 := write_addr + 1;
    else
      write_addr_plus_1 := 0;
    end if;

    if write_ready and write_valid then
      clk_write_level <= (depth + write_addr - read_addr_resync) rem depth + 1;
      write_addr <= write_addr_plus_1;
    -- TODO: add catch for the case when all words were read on one clk_write cycle
    elsif write_addr /= read_addr_resync then
      clk_write_level <= (depth + write_addr - read_addr_resync) rem depth;
    end if;
  end process;

  resync_write_addr : entity resync.resync_counter
    generic map (
      counter_max => depth-1)
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
      -- TODO: Add check for case when all fifo is written on one clk_read cycle.
    else
      read_valid <= '0';
    end if;

    clk_read_level <= (depth + write_addr_resync - read_addr) rem depth;
  end process;

  resync_read_addr : entity resync.resync_counter
    generic map (
      counter_max => depth-1)
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
