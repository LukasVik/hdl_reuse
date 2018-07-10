library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
use vunit_lib.random_pkg.all;
context vunit_lib.vunit_context;
context vunit_lib.data_types_context;

library osvvm;
use osvvm.RandomPkg.all;


entity tb_afifo is
  generic (
    width : integer;
    depth : integer;
    runner_cfg : string
  );
end entity;

architecture tb of tb_afifo is

  signal clk_read : std_logic := '0';
  signal clk_write : std_logic := '0';

  signal read_ready, read_valid : std_logic := '0';
  signal write_ready, write_valid : std_logic := '0';
  signal read_data, write_data : std_logic_vector(width - 1 downto 0) := (others => '0');

begin

  test_runner_watchdog(runner, 2 ms);
  clk_read <= not clk_read after 2 ns;
  clk_write <= not clk_write after 3 ns;


  ------------------------------------------------------------------------------
  main : process
    variable rnd : RandomPType;
    variable data : integer_vector_ptr_t := null_ptr;

    procedure write_vector is
    begin
      for i in 0 to length(data) - 1 loop
        write_valid <= '1';
        write_data <= std_logic_vector(to_unsigned(get(data, i), width));
        wait until (write_ready and write_valid) = '1' and rising_edge(clk_write);
      end loop;
      write_valid <= '0';
    end procedure;

    procedure read_vector is
    begin
      for i in 0 to length(data) - 1 loop
        read_ready <= '1';
        wait until (read_ready and read_valid) = '1' and rising_edge(clk_read);
        check_equal(to_integer(unsigned(read_data)), get(data, i));
      end loop;
      read_ready <= '0';
    end procedure;

  begin
    test_runner_setup(runner, runner_cfg);
    rnd.InitSeed(rnd'instance_name);

    if run("fill_afifo") then
      for i in 0 to 4 loop
        random_integer_vector_ptr(rnd, data, length=>depth, bits_per_word=>width, is_signed=>false);

        write_vector;
        wait until rising_edge(clk_write);
        check_equal(write_ready, '0', "Should be full");

        read_vector;
        wait until rising_edge(clk_read);
        check_equal(read_valid, '0', "Should be empty");
      end loop;
    end if;

    test_runner_cleanup(runner);
  end process;


  ------------------------------------------------------------------------------
  dut : entity work.afifo
    generic map (
      width => width,
      depth => depth
    )
    port map (
      clk_read => clk_read,

      read_ready => read_ready,
      read_valid => read_valid,
      read_data => read_data,

      clk_write => clk_write,

      write_ready => write_ready,
      write_valid => write_valid,
      write_data => write_data
    );

end architecture;
