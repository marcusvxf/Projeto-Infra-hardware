onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu/clk
add wave -noupdate /cpu/reset
add wave -noupdate -radix decimal /cpu/REG_BASE_/Cluster(20)
add wave -noupdate -radix decimal /cpu/REG_BASE_/Cluster(23)
add wave -noupdate -radix decimal /cpu/REG_BASE_/Cluster(25)
add wave -noupdate -radix unsigned /cpu/CTRL_/STATE
add wave -noupdate -radix unsigned /cpu/CTRL_/COUNTER
add wave -noupdate /cpu/CTRL_/funct
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 194
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
WaveRestoreZoom {1708 ps} {2647 ps}
