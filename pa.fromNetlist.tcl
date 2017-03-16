
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name SVA -dir "C:/Xilinx/projects/taxi_test/SVA/planAhead_run_1" -part xc6slx45fgg484-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Xilinx/projects/taxi_test/SVA/taxiTop_cs.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Xilinx/projects/taxi_test/SVA} {ipcore_dir} }
add_files [list {ipcore_dir/ADC_FIFO.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/Dual_Port_RAM.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/FIFO.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/ISERDES_Dual_Port_RAM.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/ISERDES_FIFO.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/testRam.ncf}] -fileset [get_property constrset [current_run]]
set_param project.pinAheadLayout  yes
set_property target_constrs_file "taxi.ucf" [current_fileset -constrset]
add_files [list {taxi.ucf}] -fileset [get_property constrset [current_run]]
link_design
