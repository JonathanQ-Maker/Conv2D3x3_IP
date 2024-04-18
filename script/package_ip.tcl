#######################################################################
# Description: Srcipt to be ran in vivado project to package ip
#######################################################################


ipx::package_project -root_dir ../ip_repo -vendor xilinx.com -library user -taxonomy /UserIP -import_files

set_property vendor JonathanQiao [ipx::current_core]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "IMG_HEIGHT" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters IMG_HEIGHT -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 3 [ipx::get_user_parameters IMG_HEIGHT -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 1024 [ipx::get_user_parameters IMG_HEIGHT -of_objects [ipx::current_core]]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "IMG_WIDTH" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters IMG_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 3 [ipx::get_user_parameters IMG_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 1024 [ipx::get_user_parameters IMG_WIDTH -of_objects [ipx::current_core]]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "TRANSFERS_PER_PIXEL" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters TRANSFERS_PER_PIXEL -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 1 [ipx::get_user_parameters TRANSFERS_PER_PIXEL -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 512 [ipx::get_user_parameters TRANSFERS_PER_PIXEL -of_objects [ipx::current_core]]
set_property widget {comboBox} [ipgui::get_guiparamspec -name "WORDS_PER_TRANSFER" -component [ipx::current_core] ]
set_property value_validation_type list [ipx::get_user_parameters WORDS_PER_TRANSFER -of_objects [ipx::current_core]]
set_property value_validation_list {1 2 4 8} [ipx::get_user_parameters WORDS_PER_TRANSFER -of_objects [ipx::current_core]]
set_property widget {comboBox} [ipgui::get_guiparamspec -name "FILTERS" -component [ipx::current_core] ]
set_property value_validation_type list [ipx::get_user_parameters FILTERS -of_objects [ipx::current_core]]
set_property value_validation_list {8 16 24 32 40 48 56 64} [ipx::get_user_parameters FILTERS -of_objects [ipx::current_core]]
set_property enablement_value false [ipx::get_user_parameters KERNEL_BUF_WIDTH -of_objects [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "KERNEL_BUF_WIDTH" -component [ipx::current_core]]
set_property enablement_value false [ipx::get_user_parameters WORD_WIDTH -of_objects [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "WORD_WIDTH" -component [ipx::current_core]]
set_property name axis_img [ipx::get_bus_interfaces i_img -of_objects [ipx::current_core]]
ipx::add_port_map TREADY [ipx::get_bus_interfaces axis_img -of_objects [ipx::current_core]]
set_property physical_name o_img_tready [ipx::get_port_maps TREADY -of_objects [ipx::get_bus_interfaces axis_img -of_objects [ipx::current_core]]]
set_property name axis_kernel [ipx::get_bus_interfaces i_kernel -of_objects [ipx::current_core]]
ipx::add_port_map TREADY [ipx::get_bus_interfaces axis_kernel -of_objects [ipx::current_core]]
set_property physical_name o_kernel_tready [ipx::get_port_maps TREADY -of_objects [ipx::get_bus_interfaces axis_kernel -of_objects [ipx::current_core]]]
set_property name axis_out [ipx::get_bus_interfaces o_out -of_objects [ipx::current_core]]
ipx::add_port_map TREADY [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]
set_property physical_name i_out_tready [ipx::get_port_maps TREADY -of_objects [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]]
set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]


ipx::save_core [ipx::current_core]
set_property ip_repo_paths ../ip_repo [current_project]
update_ip_catalog