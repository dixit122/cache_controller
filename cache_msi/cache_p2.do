onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cache_tb2/clk
add wave -noupdate /cache_tb2/rst
add wave -noupdate /cache_tb2/i
add wave -noupdate /cache_tb2/pr_addr
add wave -noupdate /cache_tb2/pr_rd
add wave -noupdate /cache_tb2/pr_wr
add wave -noupdate /cache_tb2/pr_din
add wave -noupdate /cache_tb2/pr_dout
add wave -noupdate /cache_tb2/pr_done
add wave -noupdate /cache_tb2/cache/needToReqBus
add wave -noupdate /cache_tb2/cache/needToServiceBusUpgr
add wave -noupdate /cache_tb2/cache/needToServiceBusReq
add wave -noupdate /cache_tb2/cache/startWB
add wave -noupdate /cache_tb2/cache/startBusRd
add wave -noupdate /cache_tb2/cache/startBusRdX
add wave -noupdate /cache_tb2/cache/startBusUpgr
add wave -noupdate /cache_tb2/cache/pr_hit
add wave -noupdate /cache_tb2/cache/bus_hit
add wave -noupdate /cache_tb2/cache/state
add wave -noupdate -radix ascii /cache_tb2/state_string
add wave -noupdate /cache_tb2/cache/msi_state
add wave -noupdate /cache_tb2/cache/data
add wave -noupdate /cache_tb2/bus_request
add wave -noupdate /cache_tb2/bus_grant
add wave -noupdate /cache_tb2/bus_op_in
add wave -noupdate -radix ascii /cache_tb2/bus_op_in_string
add wave -noupdate /cache_tb2/bus_op_out
add wave -noupdate -radix ascii /cache_tb2/bus_op_out_string
add wave -noupdate /cache_tb2/bus_addr_in
add wave -noupdate /cache_tb2/bus_addr_out
add wave -noupdate /cache_tb2/bus_din
add wave -noupdate /cache_tb2/bus_dout
add wave -noupdate /cache_tb2/bus_done_in
add wave -noupdate /cache_tb2/bus_done_out
add wave -noupdate /cache_tb2/dmem/mem
add wave -noupdate /cache_tb2/mem_rd
add wave -noupdate /cache_tb2/mem_wr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {193000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 244
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {177400 ps} {208600 ps}
