
#######################################################################
# define variables
#######################################################################

set part xc7z020clg400-2
set origin_dir .
set output_dir $origin_dir/output
set sim_dir $origin_dir/sim
set src_dir $origin_dir/src

#######################################################################
# define helper procedure(s)
#######################################################################
proc has_word {filename search_word} {
    # open and read file conetents
    set file_contents [read [open $filename r]]
    return [string match *$search_word* $file_contents]
}




#######################################################################
# main
#######################################################################

# create the project
set vivado_sim_dir $output_dir/simulation
create_project -force -part $part simulation $vivado_sim_dir
set_property simulator_language Verilog [current_project]

# add all RTL source files in the src directory 
add_files -fileset sources_1 $src_dir

# run simulation on each Systemverilog file found in sim_dir
foreach tb_filename [glob $sim_dir/*.sv] {

    # get root filename without extention
    set sim_fileset [file tail [file rootname $tb_filename]]

    create_fileset -simset $sim_fileset

    # add simulation file to unique simulation set
    add_files -fileset $sim_fileset -norecurse $tb_filename

    # set top module for simulation
    set_property top $sim_fileset [get_fileset $sim_fileset]
    update_compile_order -fileset $sim_fileset

    # run simulation
    launch_simulation -simset $sim_fileset -mode behavioral

    # record waveform into wdb file
    log_wave -r [get_objects /$sim_fileset/*]

    # close simulation to save simulate.log file
    close_sim -quiet
    
    # read simulate.log to check if string "Error:" exists. 
    # If exists, report error to console
    set simulate_log $vivado_sim_dir/simulation.sim/$sim_fileset/behav/xsim/simulate.log
    if {[has_word $simulate_log Error:]} {
        puts "\n\nERROR FOUND IN SIMULATION LOG $simulate_log"
        puts "ERROR FOUND IN SIMULATION LOG $simulate_log"
        puts "ERROR FOUND IN SIMULATION LOG $simulate_log"
        puts "ERROR FOUND IN SIMULATION LOG $simulate_log"
        puts "ERROR FOUND IN SIMULATION LOG $simulate_log\n"
        
        # simulate.log reported an error, print out simulate.log
        set file_contents [read [open $simulate_log r]]
        puts $file_contents
        puts "\n\n"; # improve readability 
    } else {
        puts "No errors found in $sim_fileset"
    }
}

quit
