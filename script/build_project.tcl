
#######################################################################
# define variables
#######################################################################

set part xc7z020clg400-2
set origin_dir .
set output_dir $origin_dir/output
set sim_dir $origin_dir/sim
set src_dir $origin_dir/src
set const_file $origin_dir/const/Conv2D3x3.xdc
set repo_dir $origin_dir/ip_repo
set top_module $src_dir/Conv2D3x3.v



#######################################################################
# create the project
#######################################################################
set vivado_sim_dir $output_dir/vivado_conv2d3x3
create_project -force -part $part vivado_conv2d3x3 $vivado_sim_dir
set_property simulator_language Verilog [current_project]



#######################################################################
# add all RTL source files in the src directory 
#######################################################################
add_files -fileset sources_1 $src_dir



#######################################################################
# add constraint file
#######################################################################
add_files -fileset constrs_1 $const_file
# Specify as out of out-of-context constraint file
set_property USED_IN {synthesis implementation out_of_context} [get_files $const_file]
# set processing order to late to allow top module override
set_property PROCESSING_ORDER LATE [get_files $const_file]



#######################################################################
# create simulation sets
#######################################################################
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


#######################################################################
# finalize
#######################################################################
puts "Created project at path: $vivado_sim_dir"

quit