onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cache_tb/clk
add wave -noupdate /cache_tb/rst
add wave -noupdate /cache_tb/pr_addr
add wave -noupdate /cache_tb/pr_rd
add wave -noupdate /cache_tb/pr_wr
add wave -noupdate /cache_tb/pr_din
add wave -noupdate /cache_tb/pr_dout
add wave -noupdate /cache_tb/pr_done
add wave -noupdate /cache_tb/bus_dout
add wave -noupdate /cache_tb/bus_rd
add wave -noupdate /cache_tb/bus_wr
add wave -noupdate /cache_tb/bus_addr
add wave -noupdate /cache_tb/bus_din
add wave -noupdate /cache_tb/bus_done
add wave -noupdate -radix ascii /cache_tb/state_string
add wave -noupdate /cache_tb/cache/tag
add wave -noupdate /cache_tb/cache/data
add wave -noupdate /cache_tb/cache/valid
add wave -noupdate /cache_tb/cache/dirty
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {55900 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {140300 ps} {245300 ps}
