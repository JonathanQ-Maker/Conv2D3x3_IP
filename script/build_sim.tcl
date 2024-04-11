
#######################################################################
# define variables
#######################################################################

set part xc7z020clg400-2
set origin_dir .
set output_dir $origin_dir/output
set sim_dir $origin_dir/sim
set src_dir $origin_dir/src



#######################################################################
# main
#######################################################################

# create the project
set vivado_sim_dir $output_dir/simulation
create_project -force -part $part simulation $vivado_sim_dir
set_property simulator_language Verilog [current_project]

# add all RTL source files in the src directory 
add_files -fileset sources_1 $src_dir

# create simulation sets
foreach tb_filename [glob $sim_dir/*.sv] {

    # get root filename without extention
    set sim_fileset [file tail [file rootname $tb_filename]]

    create_fileset -simset $sim_fileset

    # add simulation file to unique simulation set
    add_files -fileset $sim_fileset -norecurse $tb_filename

    # set top module for simulation
    set_property top $sim_fileset [get_fileset $sim_fileset]
    update_compile_order -fileset $sim_fileset
}

puts "Created project at path: $vivado_sim_dir"

quit