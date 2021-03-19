// Copyright (c) 2020 OpenHW Group
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://solderpad.org/licenses/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

// CV32E40P RVFI interface
// Contributor: Davide Schiavone <davide@openhwgroup.org>

module cv32e40p_rvfi import cv32e40p_pkg::*;
(
  input  logic        clk_i,
  input  logic        rst_ni,

  input  logic [31:0] hart_id_i,

  input  logic        irq_ack_i,
  input  logic        illegal_insn_id_i,
  input  logic        mret_insn_id_i,
  input  logic        ebrk_insn_id_i,
  input  logic        ecall_insn_id_i,

  input  logic        instr_is_compressed_id_i,
  input  logic [15:0] instr_rdata_c_id_i,
  input  logic [31:0] instr_rdata_id_i,


  input  logic        instr_id_valid_i,
  input  logic        instr_id_is_decoding_i,

  input  logic [31:0] rdata_a_id_i,
  input  logic [4:0]  raddr_a_id_i,
  input  logic [31:0] rdata_b_id_i,
  input  logic [4:0]  raddr_b_id_i,
  input  logic [31:0] rdata_c_id_i,
  input  logic [4:0]  raddr_c_id_i,

  input  logic        rd1_we_id_i,
  input  logic [4:0]  rd1_addr_id_i,
  input  logic        rd2_we_id_i,
  input  logic [4:0]  rd2_addr_id_i,

  input  logic [31:0] pc_id_i,
  input  logic [31:0] pc_if_i,
  input  logic [31:0] jump_target_id_i,

  input  logic        pc_set_i,
  input  logic        is_jump_id_i,

  input  logic [1:0]  lsu_type_id_i,
  input  logic        lsu_we_id_i,
  input  logic        lsu_req_id_i,

  input  logic        instr_ex_ready_i,
  input  logic        instr_ex_valid_i,

  input  logic [31:0] rd1_wdata_ex_i,

  input  logic [31:0] branch_target_ex_i,
  input  logic        is_branch_ex_i,

  input  logic [31:0] lsu_addr_ex_i,
  input  logic [31:0] lsu_wdata_ex_i,
  input  logic        lsu_req_ex_i,
  input  logic        lsu_misagligned_ex_i,
  input  logic        lsu_is_misagligned_ex_i,

  input  logic        lsu_rvalid_wb_i,
  input  logic [31:0] rd2_wdata_wb_i,

  input  logic [31:0] exception_target_wb_i,
  input  logic        is_exception_wb_i,


  input  logic [31:0] mepc_target_wb_i,
  input  logic        is_mret_wb_i,

  input  logic        is_debug_mode,

  //CSRs
  input Status_t      csr_mstatus_n_i,
  input Status_t      csr_mstatus_q_i,

  // RISC-V Formal Interface
  // Does not comply with the coding standards of _i/_o suffixes, but follows
  // the convention of RISC-V Formal Interface Specification.
  output logic [RVFI_NRET-1:0]     rvfi_valid,
  output logic [RVFI_NRET*64-1:0]  rvfi_order,
  output logic [RVFI_NRET*32 -1:0] rvfi_insn,
  output logic [RVFI_NRET-1:0]     rvfi_trap,
  output logic [RVFI_NRET-1:0]     rvfi_halt,
  output logic [RVFI_NRET-1:0]     rvfi_intr,
  output logic [RVFI_NRET*2-1:0]   rvfi_mode,
  output logic [RVFI_NRET*2-1:0]   rvfi_ixl,

  output logic [RVFI_NRET*5-1:0]   rvfi_rs1_addr,
  output logic [RVFI_NRET*5-1:0]   rvfi_rs2_addr,
  output logic [RVFI_NRET*5-1:0]   rvfi_rs3_addr,
  output logic [RVFI_NRET*32-1:0]  rvfi_rs1_rdata,
  output logic [RVFI_NRET*32-1:0]  rvfi_rs2_rdata,
  output logic [RVFI_NRET*32-1:0]  rvfi_rs3_rdata,
  output logic [RVFI_NRET*5-1:0]   rvfi_rd1_addr,
  output logic [RVFI_NRET*32-1:0]  rvfi_rd1_wdata,
  output logic [RVFI_NRET*5-1:0]   rvfi_rd2_addr,
  output logic [RVFI_NRET*32-1:0]  rvfi_rd2_wdata,
  output logic [RVFI_NRET*32-1:0]  rvfi_pc_rdata,
  output logic [RVFI_NRET*32-1:0]  rvfi_pc_wdata,
  output logic [RVFI_NRET*32-1:0]  rvfi_mem_addr,
  output logic [RVFI_NRET*32/8-1:0]rvfi_mem_rmask,
  output logic [RVFI_NRET*32/8-1:0]rvfi_mem_wmask,
  output logic [RVFI_NRET*32-1:0]  rvfi_mem_rdata,
  output logic [RVFI_NRET*32-1:0]  rvfi_mem_wdata,

  output logic [RVFI_NRET*32-1:0]  rvfi_csr_mstatus_rmask,
  output logic [RVFI_NRET*32-1:0]  rvfi_csr_mstatus_wmask,
  output logic [RVFI_NRET*32-1:0]  rvfi_csr_mstatus_rdata,
  output logic [RVFI_NRET*32-1:0]  rvfi_csr_mstatus_wdata
);

  logic [31:0] rvfi_insn_id;
  logic [4:0]  rvfi_rs1_addr_d;
  logic [4:0]  rvfi_rs2_addr_d;
  logic [4:0]  rvfi_rs3_addr_d;
  logic [31:0] rvfi_rs1_data_d;
  logic [31:0] rvfi_rs2_data_d;
  logic [31:0] rvfi_rs3_data_d;

  logic [4:0]  rvfi_rd1_addr_d;
  logic [4:0]  rvfi_rd2_addr_d;

  logic [31:0] rvfi_rd1_wdata_d;
  logic [31:0] rvfi_rd2_wdata_d;


  logic [3:0]  rvfi_mem_mask_int;
  logic [31:0] rvfi_mem_rdata_d;
  logic [31:0] rvfi_mem_wdata_d;
  logic [31:0] rvfi_mem_addr_d;

  // When writeback stage is present RVFI information is emitted when instruction is finished in
  // third stage but some information must be captured whilst the instruction is in the second
  // stage. Without writeback stage RVFI information is all emitted when instruction retires in
  // second stage. RVFI outputs are all straight from flops. So 2 stage pipeline requires a single
  // set of flops (instr_info => RVFI_out), 3 stage pipeline requires two sets (instr_info => wb
  // => RVFI_out)
  localparam int RVFI_STAGES = 3;


  logic  [RVFI_STAGES-1:0] data_req_q;
  logic  [RVFI_STAGES-1:0] mret_q;
  logic  [RVFI_STAGES-1:0] syscall_q;

  logic         data_misagligned_q;
  logic         intr1_d;
  logic         intr0_d;
  logic         is_next_instr;
  logic         instr_id_done;

  logic         ex_stage_ready_q;
  logic         ex_stage_valid_q;

  `include "cv32e40p_rvfi_trace.svh"

  rvfi_instr_t rvfi_stage [RVFI_STAGES][RVFI_NRET];
  rvfi_intr_t  prev_instr;
  rvfi_intr_t  instr_1_q;
  rvfi_intr_t  instr_0_q;

  //instructions retiring in the EX stage
  assign rvfi_valid     [0]         = rvfi_stage[RVFI_STAGES-2][0].rvfi_valid     ;
  assign rvfi_order     [63:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_order     ;
  assign rvfi_insn      [31:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_insn      ;
  assign rvfi_trap      [0]         = rvfi_stage[RVFI_STAGES-2][0].rvfi_trap      ;
  assign rvfi_halt      [0]         = rvfi_stage[RVFI_STAGES-2][0].rvfi_halt      ;
  assign rvfi_intr      [0]         = intr0_d;
  assign rvfi_mode      [1:0]       = 2'b11;
  assign rvfi_ixl       [1:0]       = 2'b01;
  assign rvfi_rs1_addr  [4:0]       = rvfi_stage[RVFI_STAGES-2][0].rvfi_rs1_addr  ;
  assign rvfi_rs2_addr  [4:0]       = rvfi_stage[RVFI_STAGES-2][0].rvfi_rs2_addr  ;
  assign rvfi_rs3_addr  [4:0]       = rvfi_stage[RVFI_STAGES-2][0].rvfi_rs3_addr  ;
  assign rvfi_rs1_rdata [31:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_rs1_rdata ;
  assign rvfi_rs2_rdata [31:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_rs2_rdata ;
  assign rvfi_rs3_rdata [31:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_rs3_rdata ;
  assign rvfi_rd1_addr  [4:0]       = rvfi_stage[RVFI_STAGES-2][0].rvfi_rd1_addr  ;
  assign rvfi_rd2_addr  [4:0]       = rvfi_stage[RVFI_STAGES-2][0].rvfi_rd2_addr  ;
  assign rvfi_rd1_wdata [31:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_rd1_wdata ;
  assign rvfi_rd2_wdata [31:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_rd2_wdata ;
  assign rvfi_pc_rdata  [31:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_pc_rdata  ;
  assign rvfi_pc_wdata  [31:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_pc_wdata  ;
  assign rvfi_mem_addr  [31:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_mem_addr  ;
  assign rvfi_mem_rmask [3:0]       = rvfi_stage[RVFI_STAGES-2][0].rvfi_mem_rmask ;
  assign rvfi_mem_wmask [3:0]       = rvfi_stage[RVFI_STAGES-2][0].rvfi_mem_wmask ;
  assign rvfi_mem_rdata [31:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_mem_rdata ;
  assign rvfi_mem_wdata [31:0]      = rvfi_stage[RVFI_STAGES-2][0].rvfi_mem_wdata ;
  assign rvfi_csr_mstatus_rmask[31:0] = rvfi_stage[RVFI_STAGES-2][0].rvfi_csr_mstatus_rmask;
  assign rvfi_csr_mstatus_wmask[31:0] = rvfi_stage[RVFI_STAGES-2][0].rvfi_csr_mstatus_wmask;
  assign rvfi_csr_mstatus_rdata[31:0] = rvfi_stage[RVFI_STAGES-2][0].rvfi_csr_mstatus_rdata;
  assign rvfi_csr_mstatus_wdata[31:0] = rvfi_stage[RVFI_STAGES-2][0].rvfi_csr_mstatus_wdata;

  //instructions retiring in the WB stage
  assign rvfi_valid     [1]         = rvfi_stage[RVFI_STAGES-1][1].rvfi_valid     ;
  assign rvfi_order     [2*64-1:64] = rvfi_stage[RVFI_STAGES-1][1].rvfi_order     ;
  assign rvfi_insn      [2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_insn      ;
  assign rvfi_trap      [1]         = rvfi_stage[RVFI_STAGES-1][1].rvfi_trap      ;
  assign rvfi_halt      [1]         = rvfi_stage[RVFI_STAGES-1][1].rvfi_halt      ;
  assign rvfi_intr      [1]         = intr1_d;;
  assign rvfi_mode      [3:2]       = 2'b11;
  assign rvfi_ixl       [3:2]       = 2'b01;
  assign rvfi_rs1_addr  [9:5]       = rvfi_stage[RVFI_STAGES-1][1].rvfi_rs1_addr  ;
  assign rvfi_rs2_addr  [9:5]       = rvfi_stage[RVFI_STAGES-1][1].rvfi_rs2_addr  ;
  assign rvfi_rs3_addr  [9:5]       = rvfi_stage[RVFI_STAGES-1][1].rvfi_rs3_addr  ;
  assign rvfi_rs1_rdata [2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_rs1_rdata ;
  assign rvfi_rs2_rdata [2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_rs2_rdata ;
  assign rvfi_rs3_rdata [2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_rs3_rdata ;
  assign rvfi_rd1_addr  [9:5]       = rvfi_stage[RVFI_STAGES-1][1].rvfi_rd1_addr  ;
  assign rvfi_rd2_addr  [9:5]       = rvfi_stage[RVFI_STAGES-1][1].rvfi_rd2_addr  ;
  assign rvfi_rd1_wdata [2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_rd1_wdata ;
  assign rvfi_rd2_wdata [2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_rd2_wdata ;
  assign rvfi_pc_rdata  [2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_pc_rdata  ;
  assign rvfi_pc_wdata  [2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_pc_wdata  ;
  assign rvfi_mem_addr  [2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_mem_addr  ;
  assign rvfi_mem_rmask [7:4]       = rvfi_stage[RVFI_STAGES-1][1].rvfi_mem_rmask ;
  assign rvfi_mem_wmask [7:4]       = rvfi_stage[RVFI_STAGES-1][1].rvfi_mem_wmask ;
  assign rvfi_mem_rdata [2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_mem_rdata ;
  assign rvfi_mem_wdata [2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_mem_wdata ;
  assign rvfi_csr_mstatus_rmask[2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_csr_mstatus_rmask;
  assign rvfi_csr_mstatus_wmask[2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_csr_mstatus_wmask;
  assign rvfi_csr_mstatus_rdata[2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_csr_mstatus_rdata;
  assign rvfi_csr_mstatus_wdata[2*32-1:32] = rvfi_stage[RVFI_STAGES-1][1].rvfi_csr_mstatus_wdata;

  // An instruction in the ID stage is valid (instr_id_valid_i)
  // when it's not stalled by the EX stage
  // due to stalls in the EX stage, data hazards, or if it is not halted by the controller
  // as due interrupts, debug requests, illegal instructions, ebreaks and ecalls
  assign instr_id_done  = instr_id_valid_i & instr_id_is_decoding_i;

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        ex_stage_ready_q   <= '0;
        ex_stage_valid_q   <= '0;
        data_misagligned_q <= '0;
        instr_1_q          <= '0;
        instr_0_q          <= '0;
      end else begin
        /*
          Keep instr in EX valid if next instruction is not valid
        */
        ex_stage_ready_q       <= instr_id_done ? 1'b1 : ( instr_ex_ready_i == 1'b0 ? ex_stage_ready_q : 1'b0);

        ex_stage_valid_q       <= instr_id_done ? 1'b1 : ( instr_ex_valid_i == 1'b0 ? ex_stage_valid_q : 1'b0);

        //Handle misaligned state
        if (instr_ex_ready_i & data_req_q[0] & !lsu_misagligned_ex_i) begin
          data_misagligned_q <= lsu_is_misagligned_ex_i;
        end else begin
           if (lsu_rvalid_wb_i)
              if(data_misagligned_q)
                data_misagligned_q <= 1'b0;
        end
        //store last valid instructios
        if(rvfi_valid[1])
          {instr_1_q.valid, instr_1_q.order, instr_1_q.pc_wdata} <= {rvfi_valid[1], rvfi_order[2*64-1:64], rvfi_pc_wdata[2*32-1:32]};
        if(rvfi_valid[0])
          {instr_0_q.valid, instr_0_q.order, instr_0_q.pc_wdata} <= {rvfi_valid[0], rvfi_order[63:0], rvfi_pc_wdata[31:0]};

      end
    end


    always_comb begin
      intr1_d              = 1'b0;
      intr0_d              = 1'b0;
      is_next_instr        = 1'b0;

      prev_instr  = find_last_instr(instr_1_q, instr_0_q);

      //find the newest
      if(rvfi_valid[1] ^ rvfi_valid[0]) begin

        if(rvfi_valid[1])
            is_next_instr  = rvfi_order[2*64-1:64] - prev_instr.order == 1;
        else
            is_next_instr  = rvfi_order[63:0]      - prev_instr.order == 1;

        if(!instr_1_q.valid & !instr_1_q.valid) begin
          intr1_d  = 1'b0;
          intr0_d  = 1'b0;
        end else begin
          intr1_d  = rvfi_valid[1] & (rvfi_pc_rdata[2*32-1:32] != prev_instr.pc_wdata) & is_next_instr;
          intr0_d  = rvfi_valid[0] & (rvfi_pc_rdata[31:0]      != prev_instr.pc_wdata) & is_next_instr;
        end

      end else if(rvfi_valid[1] & rvfi_valid[0]) begin //both true

        //instr1 is the oldest
        if(rvfi_order[2*64-1:64] < rvfi_order[63:0]) begin

          is_next_instr  = rvfi_order[2*64-1:64] - prev_instr.order == 1;

          if(!instr_1_q.valid & !instr_1_q.valid) begin
            intr1_d  = 1'b0;
            intr0_d  = 1'b0;
          end else begin
            intr1_d = rvfi_valid[1] & (rvfi_pc_rdata[2*32-1:32] != prev_instr.pc_wdata ) & is_next_instr;
            //instr0 prev is instr1
            intr0_d = rvfi_valid[0] & (rvfi_pc_rdata[31:0] != rvfi_pc_wdata[2*32-1:32]) & (rvfi_order[63:0] - rvfi_order[2*64-1:64] == 1);
          end
        end else begin
          //instr0 is the oldest
          $display("[ERROR] Instr1 is newer than Instr0 at time %t",$time);
          $stop;
        end

      end
    end


  for (genvar i = 0;i < RVFI_STAGES; i = i + 1) begin : g_rvfi_stages
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin

        rvfi_stage[i][0]            <= rvfi_instr_t'(0);
        rvfi_stage[i][1]            <= rvfi_instr_t'(0);

        rvfi_stage[i][0].rvfi_csr_mstatus_rmask <= 32'hFFFF_FFFF;
        rvfi_stage[i][0].rvfi_csr_mstatus_wmask <= 32'hFFFF_FFFF;

        data_req_q[i]               <= '0;
        mret_q[i]                   <= '0;
        syscall_q[i]                <= '0;

      end else begin

        // Signals valid in ID stage
        // all the instructions treated the same
        if (i == 0) begin

          rvfi_stage[i][0].rvfi_valid    <= instr_id_done;

          if(instr_id_done) begin

            rvfi_stage[i][0].rvfi_halt      <= '0;
            rvfi_stage[i][0].rvfi_trap      <= illegal_insn_id_i;
            rvfi_stage[i][0].rvfi_intr      <= 1'b0;
            rvfi_stage[i][0].rvfi_order     <= rvfi_stage[i][0].rvfi_order + 64'b1;
            rvfi_stage[i][0].rvfi_insn      <= rvfi_insn_id;

            rvfi_stage[i][0].rvfi_rs1_addr  <= rvfi_rs1_addr_d;
            rvfi_stage[i][0].rvfi_rs2_addr  <= rvfi_rs2_addr_d;
            rvfi_stage[i][0].rvfi_rs3_addr  <= rvfi_rs3_addr_d;
            rvfi_stage[i][0].rvfi_rs1_rdata <= rvfi_rs1_data_d;
            rvfi_stage[i][0].rvfi_rs2_rdata <= rvfi_rs2_data_d;
            rvfi_stage[i][0].rvfi_rs3_rdata <= rvfi_rs3_data_d;
            rvfi_stage[i][0].rvfi_rd1_addr  <= rvfi_rd1_addr_d;
            rvfi_stage[i][0].rvfi_rd2_addr  <= rvfi_rd2_addr_d;

            rvfi_stage[i][0].rvfi_pc_rdata  <= pc_id_i;
            rvfi_stage[i][0].rvfi_pc_wdata  <= pc_set_i & is_jump_id_i ? jump_target_id_i : pc_if_i;

            rvfi_stage[i][0].rvfi_mem_rmask <= lsu_req_id_i & !lsu_we_id_i ? rvfi_mem_mask_int : 4'b0000;
            rvfi_stage[i][0].rvfi_mem_wmask <= lsu_req_id_i &  lsu_we_id_i ? rvfi_mem_mask_int : 4'b0000;

            data_req_q[i]                   <= lsu_req_id_i;
            mret_q[i]                       <= mret_insn_id_i;
            syscall_q[i]                    <= ebrk_insn_id_i | ecall_insn_id_i;

          end
        end else if (i == 1) begin
        // Signals valid in EX stage

          //instructions retiring in the EX stage
          if(instr_ex_ready_i & !data_req_q[i-1] & !(rvfi_stage[i-1][0].rvfi_trap | mret_q[i-1] | syscall_q[i-1])) begin

            rvfi_stage[i][0]                <= rvfi_stage[i-1][0];

            rvfi_stage[i][0].rvfi_valid     <= ex_stage_ready_q;

            // If writing to x0 zero write data as required by RVFI specification
            rvfi_stage[i][0].rvfi_rd1_wdata <= rvfi_stage[i-1][0].rvfi_rd1_addr == '0 ? '0 : rvfi_rd1_wdata_d;
            rvfi_stage[i][0].rvfi_pc_wdata  <= pc_set_i & is_branch_ex_i ? branch_target_ex_i : rvfi_stage[i-1][0].rvfi_pc_wdata;

            //csr operations as READ, WRITE, SET, CLEAR (does not work yet with interrupts)
            rvfi_stage[i][0].rvfi_csr_mstatus_wdata <= {14'b0,csr_mstatus_n_i.mprv,4'b0,csr_mstatus_n_i.mpp,3'b0,csr_mstatus_n_i.mpie,2'h0,csr_mstatus_n_i.upie,csr_mstatus_n_i.mie,2'h0,csr_mstatus_n_i.uie};
            rvfi_stage[i][0].rvfi_csr_mstatus_rdata <= {14'b0,csr_mstatus_q_i.mprv,4'b0,csr_mstatus_q_i.mpp,3'b0,csr_mstatus_q_i.mpie,2'h0,csr_mstatus_q_i.upie,csr_mstatus_q_i.mie,2'h0,csr_mstatus_q_i.uie};

            //clean up data_req_q[1] when the previous ld/st retired
            if(data_req_q[i]) begin
              if(lsu_rvalid_wb_i & rvfi_stage[i][1].rvfi_valid & !data_misagligned_q)
                data_req_q[i] <= 1'b0;
            end
            mret_q[i]                  <= mret_q[i-1];
            syscall_q[i]               <= syscall_q[i-1];

          end else rvfi_stage[i][0].rvfi_valid <= 1'b0;

          //instructions retiring in the WB stage

          //memory operations
          if(instr_ex_ready_i & data_req_q[i-1]) begin
            //true during first data req if GNT
            if(!lsu_misagligned_ex_i) begin

              rvfi_stage[i][1]                <= rvfi_stage[i-1][0];
              rvfi_stage[i][1].rvfi_valid     <= ex_stage_ready_q;

              // If writing to x0 zero write data as required by RVFI specification
              rvfi_stage[i][1].rvfi_rd1_wdata <= rvfi_stage[i-1][0].rvfi_rd1_addr == '0 ? '0 : rvfi_rd1_wdata_d;

              rvfi_stage[i][1].rvfi_mem_addr  <= rvfi_mem_addr_d;
              rvfi_stage[i][1].rvfi_mem_wdata <= rvfi_mem_wdata_d;
              data_req_q[i]                   <= data_req_q[i-1];
              mret_q[i]                       <= mret_q[i-1];
              syscall_q[i]                    <= syscall_q[i-1];
            end
          end

          //exceptions
          if(instr_ex_valid_i & (rvfi_stage[i-1][0].rvfi_trap | mret_q[i-1] | syscall_q[i-1])) begin

              rvfi_stage[i][1]                <= rvfi_stage[i-1][0];
              rvfi_stage[i][1].rvfi_valid     <= ex_stage_valid_q;

              // If writing to x0 zero write data as required by RVFI specification
              rvfi_stage[i][1].rvfi_rd1_wdata <= rvfi_stage[i-1][0].rvfi_rd1_addr == '0 ? '0 : rvfi_rd1_wdata_d;

              rvfi_stage[i][1].rvfi_mem_addr  <= rvfi_mem_addr_d;
              rvfi_stage[i][1].rvfi_mem_wdata <= rvfi_mem_wdata_d;

              //exceptions as illegal, and syscalls
              rvfi_stage[i][1].rvfi_csr_mstatus_wdata <= {14'b0,csr_mstatus_n_i.mprv,4'b0,csr_mstatus_n_i.mpp,3'b0,csr_mstatus_n_i.mpie,2'h0,csr_mstatus_n_i.upie,csr_mstatus_n_i.mie,2'h0,csr_mstatus_n_i.uie};
              rvfi_stage[i][1].rvfi_csr_mstatus_rdata <= {14'b0,csr_mstatus_q_i.mprv,4'b0,csr_mstatus_q_i.mpp,3'b0,csr_mstatus_q_i.mpie,2'h0,csr_mstatus_q_i.upie,csr_mstatus_q_i.mie,2'h0,csr_mstatus_q_i.uie};

              data_req_q[i]                   <= 1'b0;
              mret_q[i]                       <= mret_q[i-1];
              syscall_q[i]                    <= syscall_q[i-1];
          end

        end else if (i == 2) begin
        // Signals valid in WB stage

          case(1'b1)

            //memory operations
            lsu_rvalid_wb_i & data_req_q[i-1]: begin
              rvfi_stage[i][1]                <= rvfi_stage[i-1][1];
              //misaligneds take 2 cycles at least
              rvfi_stage[i][1].rvfi_valid     <= rvfi_stage[i-1][1].rvfi_valid & !data_misagligned_q;
              rvfi_stage[i][1].rvfi_mem_rdata <= rvfi_rd2_wdata_d;
            end
            //traps
            rvfi_stage[i-1][1].rvfi_trap: begin
              rvfi_stage[i][1]                <= rvfi_stage[i-1][1];
            end
            //ebreaks, ecall, fence.i
            syscall_q[i-1]: begin
              rvfi_stage[i][1]                <= rvfi_stage[i-1][1];
              rvfi_stage[i][1].rvfi_pc_wdata  <= exception_target_wb_i;
            end
            //mret
            (mret_q[i-1] & rvfi_stage[i-1][1].rvfi_valid )|| mret_q[i]: begin
              //the MRET retires in one extra cycle, thus
              rvfi_stage[i][1]                <= rvfi_stage[i-1][1];
              rvfi_stage[i][1].rvfi_valid     <= mret_q[i];
              rvfi_stage[i][1].rvfi_pc_wdata  <= is_mret_wb_i ? mepc_target_wb_i : exception_target_wb_i;
              if(!mret_q[i]) begin
                //first cyle of MRET (FLUSH_WB)
                rvfi_stage[i][1].rvfi_csr_mstatus_wdata <= {14'b0,csr_mstatus_n_i.mprv,4'b0,csr_mstatus_n_i.mpp,3'b0,csr_mstatus_n_i.mpie,2'h0,csr_mstatus_n_i.upie,csr_mstatus_n_i.mie,2'h0,csr_mstatus_n_i.uie};
                rvfi_stage[i][1].rvfi_csr_mstatus_rdata <= {14'b0,csr_mstatus_q_i.mprv,4'b0,csr_mstatus_q_i.mpp,3'b0,csr_mstatus_q_i.mpie,2'h0,csr_mstatus_q_i.upie,csr_mstatus_q_i.mie,2'h0,csr_mstatus_q_i.uie};
              end

              mret_q[i]                       <= !mret_q[i];
            end
            default:
              rvfi_stage[i][1].rvfi_valid     <= 1'b0;
            endcase
        end
      end
    end
  end

  // Byte enable based on data type
  always_comb begin
    unique case (lsu_type_id_i)
      2'b00:   rvfi_mem_mask_int = 4'b1111;
      2'b01:   rvfi_mem_mask_int = 4'b0011;
      2'b10:   rvfi_mem_mask_int = 4'b0001;
      default: rvfi_mem_mask_int = 4'b0000;
    endcase
  end

  // Memory adddress
  assign rvfi_mem_addr_d = lsu_addr_ex_i;

  // Memory write data
  assign rvfi_mem_wdata_d = lsu_wdata_ex_i;


  always_comb begin
    if (instr_is_compressed_id_i) begin
      rvfi_insn_id = {16'b0, instr_rdata_c_id_i};
    end else begin
      rvfi_insn_id = instr_rdata_id_i;
    end
  end

  // Source registers
  always_comb begin
    rvfi_rs1_data_d = rdata_a_id_i;
    rvfi_rs1_addr_d = raddr_a_id_i;
    rvfi_rs2_data_d = rdata_b_id_i;
    rvfi_rs2_addr_d = raddr_b_id_i;
    rvfi_rs3_data_d = rdata_c_id_i;
    rvfi_rs3_addr_d = raddr_c_id_i;
  end

  // Destination registers
  always_comb begin
    if(rd1_we_id_i) begin
      // Capture address/data of write to register file
      rvfi_rd1_addr_d  = rd1_addr_id_i;
    end else begin
      // If no RF write then zero RF write address as required by RVFI specification
      rvfi_rd1_addr_d  = '0;
    end
  end
  //result from EX stage
  assign rvfi_rd1_wdata_d = rd1_wdata_ex_i;

  always_comb begin
    if(rd2_we_id_i) begin
      // Capture address/data of write to register file
      rvfi_rd2_addr_d  = rd2_addr_id_i;
    end else begin
      // If no RF write then zero RF write address/data as required by RVFI specification
      rvfi_rd2_addr_d  = '0;
    end
  end

  //result from WB stage/read value from Dmem
  assign rvfi_rd2_wdata_d = rd2_wdata_wb_i === 'x ? '0 : rd2_wdata_wb_i;


endmodule