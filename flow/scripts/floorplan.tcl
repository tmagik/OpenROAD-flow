if {![info exists standalone] || $standalone} {
  # Read lef
  read_lef $::env(TECH_LEF)
  read_lef $::env(SC_LEF)
  if {[info exist ::env(ADDITIONAL_LEFS)]} {
    read_lef $::env(ADDITIONAL_LEFS)
  }

  # Read liberty files
  foreach libFile $::env(LIB_FILES) {
    read_liberty $libFile
  }

  # Read verilog
  read_verilog $::env(RESULTS_DIR)/1_synth.v

  link_design $::env(DESIGN_NAME)
  read_sdc $::env(RESULTS_DIR)/1_synth.sdc
}

# Initialize floorplan using ICeWall FOOTPRINT
# ----------------------------------------------------------------------------
if {[info exists ::env(FOOTPRINT)]} {

  ICeWall load_footprint $env(FOOTPRINT)

  initialize_floorplan \
    -die_area  [ICeWall get_die_area] \
    -core_area [ICeWall get_core_area] \
    -tracks    $::env(TRACKS_INFO_FILE) \
    -site      $::env(PLACE_SITE)

  ICeWall init_footprint $env(SIG_MAP_FILE)


puts "\n Setting nets within the padring as special"
puts "--------------------------------------------------------------------------"

set db [::ord::get_db]
set block [[$db getChip] getBlock]

foreach inst [$block getInsts] {
  set inst_master [$inst getMaster]

  if { [string match [$inst_master getName] "IN12LP_GPIO18_13M9S30P_IO_H"] ||
       [string match [$inst_master getName] "IN12LP_GPIO18_13M9S30P_IO_V"]} {

      foreach termName "IOPWROK PWROK RETC" {
        set term [$inst findITerm $termName]
        if {[set net [$term getNet]] != "NULL"} {
          $net setSpecial
          $term setSpecial
        }
      }
  }
}

# Initialize floorplan using CORE_UTILIZATION
# ----------------------------------------------------------------------------
} elseif {[info exists ::env(CORE_UTILIZATION)] && $::env(CORE_UTILIZATION) != "" } {
  initialize_floorplan -utilization $::env(CORE_UTILIZATION) \
                       -aspect_ratio $::env(CORE_ASPECT_RATIO) \
                       -core_space $::env(CORE_MARGIN) \
                       -tracks $::env(TRACKS_INFO_FILE) \
                       -site $::env(PLACE_SITE)

# Initialize floorplan using DIE_AREA/CORE_AREA
# ----------------------------------------------------------------------------
} else {
  initialize_floorplan -die_area $::env(DIE_AREA) \
                       -core_area $::env(CORE_AREA) \
                       -tracks $::env(TRACKS_INFO_FILE) \
                       -site $::env(PLACE_SITE)
}


# pre report
log_begin $::env(REPORTS_DIR)/2_init.rpt

puts "\n=========================================================================="
puts "report_checks"
puts "--------------------------------------------------------------------------"
report_checks

puts "\n=========================================================================="
puts "report_tns"
puts "--------------------------------------------------------------------------"
report_tns

puts "\n=========================================================================="
puts "report_wns"
puts "--------------------------------------------------------------------------"
report_wns

puts "\n=========================================================================="
puts "report_design_area"
puts "--------------------------------------------------------------------------"
report_design_area

log_end


if {![info exists standalone] || $standalone} {
  # write output
  write_def $::env(RESULTS_DIR)/2_1_floorplan.def
  write_verilog $::env(RESULTS_DIR)/2_floorplan.v
  write_sdc $::env(RESULTS_DIR)/2_floorplan.sdc
  exit
}