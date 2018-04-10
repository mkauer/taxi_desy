
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name iceScint -dir "C:/Xilinx/projects/taxi_sp_last/firmware/iceScint/planAhead_run_3" -part xc6slx45fgg484-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
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
