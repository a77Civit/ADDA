onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ADDAtest/i1/i_rest_n
add wave -noupdate /ADDAtest/i1/sysclk_50
add wave -noupdate /ADDAtest/i1/drdy_n
add wave -noupdate /ADDAtest/i1/wrreq
add wave -noupdate /ADDAtest/i1/i_fifo
add wave -noupdate /ADDAtest/i1/adc_data
add wave -noupdate /ADDAtest/i1/wrusedw
add wave -noupdate /ADDAtest/i1/adc_data
add wave -noupdate /ADDAtest/i1/mclk
add wave -noupdate /ADDAtest/i1/cs_n
add wave -noupdate /ADDAtest/i1/r_n_w
add wave -noupdate /ADDAtest/i1/o_rest_n
add wave -noupdate /ADDAtest/i1/current_sta
add wave -noupdate /ADDAtest/i1/next_sta
add wave -noupdate /ADDAtest/i1/rest_cnt
add wave -noupdate /ADDAtest/i1/time_cnt
add wave -noupdate /ADDAtest/i1/adcdata
add wave -noupdate /ADDAtest/i1/wait_six_flg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7261356 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {6344884 ps} {8392884 ps}
