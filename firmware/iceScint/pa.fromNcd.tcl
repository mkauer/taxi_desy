
# PlanAhead Launch Script for Post PAR Floorplanning, created by Project Navigator

create_project -name iceScint -dir "C:/Xilinx/projects/taxi_sp_last/firmware/iceScint/planAhead_run_4" -part xc6slx45fgg484-3
set srcset [get_property srcset [current_run -impl]]
set_property design_mode GateLvl $srcset
set_property edif_top_file "C:/Xilinx/projects/taxi_sp_last/firmware/iceScint/taxiTop.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Xilinx/projects/taxi_sp_last/firmware/iceScint} {ipcore_dir} }
add_files [list {ipcore_dir/delayFifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/drs4FrontEndFifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/drs4OffsetCorrectionRam.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/eventFifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/histogramRam.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/rs485fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/testRam.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/triggerLogicDelayFifo.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "taxi.ucf" [current_fileset -constrset]
add_files [list {taxi.ucf}] -fileset [get_property constrset [current_run]]
link_design
read_xdl -file "C:/Xilinx/projects/taxi_sp_last/firmware/iceScint/taxiTop.ncd"
if {[catch {read_twx -name results_1 -file "C:/Xilinx/projects/taxi_sp_last/firmware/iceScint/taxiTop.twx"} eInfo]} {
   puts "WARNING: there was a problem importing \"C:/Xilinx/projects/taxi_sp_last/firmware/iceScint/taxiTop.twx\": $eInfo"
}
