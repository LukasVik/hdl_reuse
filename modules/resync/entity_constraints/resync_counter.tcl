set first_resync_registers [get_cells counter_in_gray_p1_reg*]

set_false_path -hold -to ${first_resync_registers}
set_max_delay -datapath_only [get_property -min PERIOD [get_clocks clk_out]] -from [get_clocks clk_out] -to ${first_resync_registers}
