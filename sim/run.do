# =================================================
# Clean & create work library
# =================================================
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# =================================================
# Compile (ORDER MATTERS)
# =================================================
vlog rtl/common/defines.sv
vlog rtl/common/types.sv

# Frontend
vlog rtl/frontend/if_stage.sv
vlog rtl/frontend/id_stage.sv

# Execute
vlog rtl/execute/alu.sv
vlog rtl/execute/branch_unit.sv

# Rename / Issue
vlog rtl/regfile/phys_regfile.sv
vlog rtl/rename_issue/freelist.sv
vlog rtl/rename_issue/rat.sv
vlog rtl/rename_issue/reservation_station.sv
vlog rtl/rename_issue/issue_logic.sv

# Commit
vlog rtl/commit/rob.sv

# Memory system
vlog rtl/memory/lsu.sv
vlog rtl/memory/d_cache.sv
vlog rtl/memory/mshr.sv
vlog rtl/memory/memory_system.sv

# Instruction memory
vlog rtl/memory/imem.sv

# Top & TB
vlog rtl/top/core_top.sv
vlog tb/tb_core.sv

# =================================================
# Simulate
# =================================================
vsim -voptargs="+acc" work.tb_core
view wave
radix hex

# =================================================
# CLOCK / RESET
# =================================================
add wave -group TB sim:/tb_core/clk
add wave -group TB sim:/tb_core/rst

# =================================================
# FRONTEND
# =================================================
add wave -group IF sim:/tb_core/dut/pc
add wave -group IF sim:/tb_core/dut/inst

# =================================================
# DECODE
# =================================================
add wave -group ID sim:/tb_core/dut/opcode
add wave -group ID sim:/tb_core/dut/rs1
add wave -group ID sim:/tb_core/dut/rs2
add wave -group ID sim:/tb_core/dut/rd
add wave -group ID sim:/tb_core/dut/id_is_branch
add wave -group ID sim:/tb_core/dut/id_br_type

# =================================================
# RENAME
# =================================================
add wave -group RENAME sim:/tb_core/dut/alloc_valid
add wave -group RENAME sim:/tb_core/dut/rs1_phys
add wave -group RENAME sim:/tb_core/dut/rs2_phys
add wave -group RENAME sim:/tb_core/dut/rd_phys
add wave -group RENAME sim:/tb_core/dut/old_phys
add wave -group RENAME sim:/tb_core/dut/ren_is_branch

# =================================================
# RESERVATION STATION
# =================================================
add wave -group RS sim:/tb_core/dut/rs_dispatch_en
add wave -group RS sim:/tb_core/dut/src1_ready
add wave -group RS sim:/tb_core/dut/src2_ready
add wave -group RS sim:/tb_core/dut/rs_issue_valid
add wave -group RS sim:/tb_core/dut/issue_idx
add wave -group RS sim:/tb_core/dut/issue_is_branch
add wave -group RS sim:/tb_core/dut/issue_br_type
add wave -group RS sim:/tb_core/dut/u_rs/rs

# =================================================
# ISSUE / EXECUTE
# =================================================
add wave -group ISSUE sim:/tb_core/dut/alu_grant

add wave -group EX sim:/tb_core/dut/ex_valid
add wave -group EX sim:/tb_core/dut/ex_a
add wave -group EX sim:/tb_core/dut/ex_b
add wave -group EX sim:/tb_core/dut/ex_is_branch
add wave -group EX sim:/tb_core/dut/ex_br_type
add wave -group EX sim:/tb_core/dut/alu_out

# =================================================
# BRANCH UNIT (CRITICAL)
# =================================================
add wave -group BRANCH sim:/tb_core/dut/br_mispredict
add wave -group BRANCH sim:/tb_core/dut/br_redirect_pc

# =================================================
# WRITEBACK
# =================================================
add wave -group WB sim:/tb_core/dut/wb_valid_r
add wave -group WB sim:/tb_core/dut/wb_phys_r
add wave -group WB sim:/tb_core/dut/wb_data_r
add wave -group WB sim:/tb_core/dut/mem_wb_valid
add wave -group WB sim:/tb_core/dut/mem_wb_phys
add wave -group WB sim:/tb_core/dut/mem_wb_data

# =================================================
# PHYSICAL REGISTER FILE
# =================================================
add wave -group PRF sim:/tb_core/dut/prf_we
add wave -group PRF sim:/tb_core/dut/prf_waddr
add wave -group PRF sim:/tb_core/dut/prf_wdata
add wave -group PRF sim:/tb_core/dut/prf_rdata1
add wave -group PRF sim:/tb_core/dut/prf_rdata2

# =================================================
# ROB
# =================================================
add wave -group ROB sim:/tb_core/dut/alloc_rob_idx
add wave -group ROB sim:/tb_core/dut/rob_idx_ex
add wave -group ROB sim:/tb_core/dut/commit_valid
add wave -group ROB sim:/tb_core/dut/commit_rd_arch
add wave -group ROB sim:/tb_core/dut/free_phys
add wave -group ROB sim:/tb_core/dut/u_rob/head
add wave -group ROB sim:/tb_core/dut/u_rob/tail

# =================================================
# MEMORY (FOR FUTURE LOAD/STORE TESTS)
# =================================================
add wave -group MEM sim:/tb_core/dut/mem_is_load
add wave -group MEM sim:/tb_core/dut/mem_is_store
add wave -group MEM sim:/tb_core/dut/main_mem_req
add wave -group MEM sim:/tb_core/dut/main_mem_ready

# =================================================
# CONTROL (BRANCH RECOVERY)
# =================================================
add wave -group CTRL sim:/tb_core/dut/flush
add wave -group CTRL sim:/tb_core/dut/redirect_pc

# =================================================
# LSU / LSQ
# =================================================
add wave -group LSU sim:/tb_core/dut/u_mem_system/u_lsu/head
add wave -group LSU sim:/tb_core/dut/u_mem_system/u_lsu/tail
add wave -group LSU sim:/tb_core/dut/u_mem_system/u_lsu/lsu_full
add wave -group LSU sim:/tb_core/dut/u_mem_system/u_lsu/lsu_wb_valid
add wave -group LSU sim:/tb_core/dut/u_mem_system/u_lsu/lsu_wb_phys
add wave -group LSU sim:/tb_core/dut/u_mem_system/u_lsu/lsu_wb_data

# =================================================
# D-CACHE
# =================================================
add wave -group DCACHE sim:/tb_core/dut/u_mem_system/u_dcache/read_en
add wave -group DCACHE sim:/tb_core/dut/u_mem_system/u_dcache/write_en
add wave -group DCACHE sim:/tb_core/dut/u_mem_system/u_dcache/addr
add wave -group DCACHE sim:/tb_core/dut/u_mem_system/u_dcache/rdata
add wave -group DCACHE sim:/tb_core/dut/u_mem_system/u_dcache/hit

# =================================================
# RUN
# =================================================
run 500ns
