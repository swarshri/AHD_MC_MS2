`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2021 11:47:00 AM
// Design Name: 
// Module Name: TestBenches
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
module ALU_tb();
    parameter data_width = 32;
    reg enable = 1;
    reg [data_width-1:0] op1, op2, exp_res;
    reg [3:0] alu_control;
    wire [data_width-1:0] alu_result;
    
    integer tc_file_ptr, tc_id, tc_count = 0, pass_count = 0, fail_count = 0;
    reg [8*6:1] tc_result; //string
    reg [8*2:1] line_str;
    
    ALU ALU_UnderTest(enable, op1, op2, alu_control, alu_result);
    
    initial begin
        tc_file_ptr = $fopen("alu_tc.txt", "r");
        
        if (tc_file_ptr == 0) begin
            $display("Unable to open the test case file.");
            $finish;
        end
        
        while(!$feof(tc_file_ptr)) begin
            $fscanf(tc_file_ptr, "%d %h %h %h %h\n", tc_id, op1, op2, alu_control, exp_res);
            tc_count = tc_count + 1;
            #5;
            if(exp_res == alu_result) begin
                pass_count = pass_count + 1;
                tc_result = "Passed";
            end else begin
                fail_count = fail_count + 1;
                tc_result = "Failed";
            end
            $display("TC %d: %s; Expected: %h, Actual: %h", tc_id, tc_result, exp_res, alu_result);
        end
        
        $display("\nResult:");
        if(pass_count == tc_count)
            $display("All tests passed.");
        else begin
            $display("%d tests passed.", pass_count);
            $display("%d tests failed.", fail_count);
        end
        $finish;
    end
endmodule

module BR_tb();
    parameter data_width = 32;
    reg enable = 1;
    reg mod_en, exp_res;
    reg [data_width-1:0] op1, op2;
    reg [2:0] br_control;
    wire br_result;
    
    integer tc_file_ptr, tc_id, tc_count = 0, pass_count = 0, fail_count = 0;
    reg [8*6:1] tc_result; //string
    
    BranchResolver BR_UnderTest(enable, mod_en, br_control, op1, op2, br_result);
    
    initial begin
        tc_file_ptr = $fopen("br_tc.txt", "r");
        
        if (tc_file_ptr == 0) begin
            $display("Unable to open the test case file.");
            $finish;
        end
        
        while(!$feof(tc_file_ptr)) begin
            $fscanf(tc_file_ptr, "%d %h %h %h %h %h\n", tc_id, mod_en, op1, op2, br_control, exp_res);
            tc_count = tc_count + 1;
            #5;
            if(exp_res == br_result) begin
                pass_count = pass_count + 1;
                tc_result = "Passed";
            end else begin
                fail_count = fail_count + 1;
                tc_result = "Failed";
            end
            $display("TC %d: %s; Expected: %h, Actual: %h", tc_id, tc_result, exp_res, br_result);
        end
        
        $display("\nResult:");
        if(pass_count == tc_count)
            $display("All tests passed.");
        else begin
            $display("%d tests passed.", pass_count);
            $display("%d tests failed.", fail_count);
        end
        $finish;
    end
endmodule

module ControlUnit_tb();
    reg clk = 0, rst, exp_rst_system, exp_load_imem, exp_pc_en, exp_dec_en, exp_iex_en, exp_rf_en, exp_bres_en, exp_alu_en, exp_dex_en, exp_wb_en;
    wire rst_system, load_imem, pc_en, dec_en, iex_en, rf_en, bres_en, alu_en, dex_en, wb_en;
     
    parameter reset = 0, load_ins = 1, insFetch = 2, insDecode = 3, execute = 4, memory = 5, writeback = 6;
    
    integer tc_file_ptr, tc_id, tc_count = 0, pass_count = 0, fail_count = 0;
    reg [8*6:1] tc_result; //string
    
    ControlUnit CU_UnderTest(clk, rst, 0, rst_system, load_imem, pc_en, dec_en, iex_en, rf_en, bres_en, alu_en, dex_en, wb_en);
    always #5 clk = ~clk;
    
    initial begin
        tc_file_ptr = $fopen("cu_tc.txt", "r");
        
        if (tc_file_ptr == 0) begin
            $display("Unable to open the test case file.");
            $finish;
        end
        
        while(!$feof(tc_file_ptr)) begin
            wait(clk == 0);
            $fscanf(tc_file_ptr, "%d %h %h %h %h %h %h %h %h %h %h %h\n", tc_id, rst, exp_rst_system, exp_load_imem, exp_pc_en, exp_dec_en, exp_iex_en, exp_rf_en, exp_bres_en, exp_alu_en, exp_dex_en, exp_wb_en);
            tc_count = tc_count + 1;
            
            wait(clk == 1) #2;
            if(rst_system == exp_rst_system  && load_imem == exp_load_imem && pc_en == exp_pc_en &&
               dec_en == exp_dec_en && iex_en == exp_iex_en && rf_en == exp_rf_en && bres_en == exp_bres_en &&
               alu_en == exp_alu_en && dex_en == exp_dex_en && wb_en == exp_wb_en) begin
                pass_count = pass_count + 1;
                tc_result = "Passed";
            end else begin
                fail_count = fail_count + 1;
                tc_result = "Failed";
            end
            
            $display("TC %d: %s", tc_id, tc_result); 
            $display("Expected: %h, %h, %h, %h, %h, %h, %h, %h, %h", exp_rst_system, exp_load_imem, exp_pc_en, exp_dec_en, exp_iex_en, exp_rf_en, exp_bres_en, exp_alu_en, exp_dex_en, exp_wb_en);
            $display("Actual: %h, %h, %h, %h, %h, %h, %h, %h, %h", rst_system, load_imem, pc_en, dec_en, iex_en, rf_en, bres_en, alu_en, dex_en, wb_en);
        end
        
        $display("\nResult:");
        if(pass_count == tc_count)
            $display("All tests passed.");
        else begin
            $display("%d tests passed.", pass_count);
            $display("%d tests failed.", fail_count);
        end
        $finish;
    end
endmodule

module Decoder_tb();
    parameter data_width = 32;
    reg [data_width-1:0] instruction;
    reg [1:0] exp_store_control;
    reg [2:0] exp_branch_control, exp_de_control;
    reg [3:0] exp_ie_control, exp_AluOP;
    reg [4:0] exp_rs1, exp_rs2, exp_rd;
    reg [11:0] exp_immediate_short;
    reg [19:0] exp_immediate_long;
    reg exp_op2_mux1_cntl, exp_op2_mux2_cntl, exp_op1_mux_cntl, exp_br_en, exp_load_en, exp_store_en, exp_wr_en;
    reg exp_wb_mux1_cntl, exp_wb_mux2_cntl, exp_wb_mux3_cntl, exp_pc_mux_cntl;
    wire [1:0] store_control;
    wire [2:0] branch_control, de_control;
    wire [3:0] ie_control, AluOP;
    wire [4:0] rs1, rs2, rd;
    wire [11:0] immediate_short;
    wire [19:0] immediate_long;
    wire op2_mux1_cntl, op2_mux2_cntl, op1_mux_cntl, br_en, load_en, store_en, wr_en, wb_mux1_cntl, wb_mux2_cntl, wb_mux3_cntl, pc_mux_cntl;
        
    integer tc_file_ptr, tc_id, tc_count = 0, pass_count = 0, fail_count = 0;
    reg [8*6:1] tc_result; //string
    
    Decoder DC_UnderTest(instruction, store_control, ie_control, branch_control, de_control, AluOP, rs1, rs2, rd, immediate_short,
                         immediate_long, op2_mux1_cntl, op2_mux2_cntl, op1_mux_cntl, br_en, load_en, store_en, wr_en, wb_mux1_cntl,
                         wb_mux2_cntl, wb_mux3_cntl, pc_mux_cntl);

    initial begin
        tc_file_ptr = $fopen("dc_tc.txt", "r");
        $display("opened file");
        
        if (tc_file_ptr == 0) begin
            $display("Unable to open the test case file.");
            $finish;
        end
        
        while(!$feof(tc_file_ptr)) begin
            $fscanf(tc_file_ptr, "%d %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h\n",
                                 tc_id, instruction, exp_store_control, exp_ie_control, exp_branch_control, exp_de_control,
                                 exp_AluOP, exp_rs1, exp_rs2, exp_rd, exp_immediate_short, exp_immediate_long, exp_op2_mux1_cntl, 
                                 exp_op2_mux2_cntl, exp_op1_mux_cntl, exp_br_en, exp_load_en, exp_store_en, exp_wr_en, exp_wb_mux1_cntl,
                                 exp_wb_mux2_cntl, exp_wb_mux3_cntl, exp_pc_mux_cntl);
            tc_count = tc_count + 1;
            
            #5;
            if(store_control == exp_store_control && ie_control == exp_ie_control && branch_control == exp_branch_control && 
               de_control == exp_de_control && AluOP == exp_AluOP && rs1 == exp_rs1 && rs2 == exp_rs2 && rd == exp_rd && 
               immediate_short == exp_immediate_short && immediate_long == exp_immediate_long && op2_mux1_cntl == exp_op2_mux1_cntl && 
               op2_mux2_cntl == exp_op2_mux2_cntl && op1_mux_cntl == exp_op1_mux_cntl && br_en == br_en && load_en == exp_load_en &&
               store_en == exp_store_en && wr_en == exp_wr_en && wb_mux1_cntl == exp_wb_mux1_cntl && wb_mux2_cntl == exp_wb_mux2_cntl && 
               wb_mux3_cntl == exp_wb_mux3_cntl && pc_mux_cntl == exp_pc_mux_cntl) begin
                pass_count = pass_count + 1;
                tc_result = "Passed";
            end else begin
                fail_count = fail_count + 1;
                tc_result = "Failed";
            end
            $display("TC %d: %s", tc_id, tc_result); 
            $display("Expected: %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h",
                                exp_store_control, exp_ie_control, exp_branch_control, exp_de_control,
                                exp_AluOP, exp_rs1, exp_rs2, exp_rd, exp_immediate_short, exp_immediate_long, exp_op2_mux1_cntl, exp_op2_mux2_cntl,
                                exp_op1_mux_cntl, exp_br_en, exp_load_en, exp_store_en, exp_wr_en, exp_wb_mux1_cntl, exp_wb_mux2_cntl,
                                exp_wb_mux3_cntl, exp_pc_mux_cntl);
            $display("Actual: %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h",
                              store_control, ie_control, branch_control, de_control, AluOP, rs1, rs2, rd, immediate_short,
                              immediate_long, op2_mux1_cntl, op2_mux2_cntl, op1_mux_cntl, br_en, load_en, store_en, wr_en, wb_mux1_cntl,
                              wb_mux2_cntl, wb_mux3_cntl, pc_mux_cntl);
        end
        
        $display("\nResult:");
        if(pass_count == tc_count)
            $display("All tests passed.");
        else begin
            $display("%d tests passed.", pass_count);
            $display("%d tests failed.", fail_count);
        end
        $finish;
    end
endmodule

module DataExtender_tb();
    parameter data_width = 32;
    reg enable = 1;
    reg [data_width-1:0] data, exp_out_data;
    reg [2:0] control;
    wire [data_width-1:0] out_data;
    
    integer tc_file_ptr, tc_id, tc_count = 0, pass_count = 0, fail_count = 0;
    reg [8*6:1] tc_result; //string
    
    DataExtender DE_UnderTest(enable, data, control, out_data);
    
    initial begin
        tc_file_ptr = $fopen("de_tc.txt", "r");
        
        if (tc_file_ptr == 0) begin
            $display("Unable to open the test case file.");
            $finish;
        end
        
        while(!$feof(tc_file_ptr)) begin
            $fscanf(tc_file_ptr, "%d %h %h %h\n", tc_id, data, control, exp_out_data);
            tc_count = tc_count + 1;
            #5;
            if(exp_out_data == out_data) begin
                pass_count = pass_count + 1;
                tc_result = "Passed";
            end else begin
                fail_count = fail_count + 1;
                tc_result = "Failed";
            end
            $display("TC %d: %s; Expected: %h, Actual: %h", tc_id, tc_result, exp_out_data, out_data);
        end
        
        $display("\nResult:");
        if(pass_count == tc_count)
            $display("All tests passed.");
        else begin
            $display("%d tests passed.", pass_count);
            $display("%d tests failed.", fail_count);
        end
        $finish;
    end
endmodule

module ImmExtender_tb();
    parameter data_width = 32;
    reg enable = 1;
    reg [11:0] imm_short;
    reg [19:0] imm_long;
    reg [3:0] control; // {is_UType, is_SIType, is_JType}
    reg [data_width-1:0] exp_immediate_out;
    wire [data_width-1:0] immediate_out;
    
    integer tc_file_ptr, tc_id, tc_count = 0, pass_count = 0, fail_count = 0;
    reg [8*6:1] tc_result; //string
    
    ImmExtender IE_UnderTest(enable, imm_short, imm_long, control, immediate_out);
    
    initial begin
        tc_file_ptr = $fopen("ie_tc.txt", "r");
        
        if (tc_file_ptr == 0) begin
            $display("Unable to open the test case file.");
            $finish;
        end
        
        while(!$feof(tc_file_ptr)) begin
            $fscanf(tc_file_ptr, "%d %h %h %h %h\n", tc_id, imm_short, imm_long, control, exp_immediate_out);
            tc_count = tc_count + 1;
            #5;
            if(exp_immediate_out == immediate_out) begin
                pass_count = pass_count + 1;
                tc_result = "Passed";
            end else begin
                fail_count = fail_count + 1;
                tc_result = "Failed";
            end
            $display("TC %d: %s; Expected: %h, Actual: %h", tc_id, tc_result, exp_immediate_out, immediate_out);
        end
        
        $display("\nResult:");
        if(pass_count == tc_count)
            $display("All tests passed.");
        else begin
            $display("%d tests passed.", pass_count);
            $display("%d tests failed.", fail_count);
        end
        $finish;
    end
endmodule

module RegisterFile_tb();
    parameter data_width = 32, address_width = 5, reg_count = 32;
    reg [address_width-1:0] read_address1, read_address2, write_address;
    reg [data_width-1:0] write_data, exp_read_data1, exp_read_data2;
    reg clk = 0, rst, wr_enable, enable = 1;
    wire [data_width-1:0] read_data1, read_data2;
    
    integer tc_file_ptr, tc_id, tc_count = 0, pass_count = 0, fail_count = 0;
    reg [8*6:1] tc_result; //string
    
    RegisterFile RF_UnderTest(clk, rst, wr_enable, enable, read_address1, read_address2, write_address, write_data, read_data1, read_data2);
    
    always #5 clk = ~clk;
    initial begin
        tc_file_ptr = $fopen("rf_tc.txt", "r");
        
        if (tc_file_ptr == 0) begin
            $display("Unable to open the test case file.");
            $finish;
        end
        
        while(!$feof(tc_file_ptr)) begin
            $fscanf(tc_file_ptr, "%d %h %h %h %h %h %h %h %h\n", tc_id, read_address1, read_address2, write_address, write_data, rst, wr_enable, exp_read_data1, exp_read_data2);
            tc_count = tc_count + 1;
            #5;
            if(read_data1 == exp_read_data1 && read_data2 == exp_read_data2) begin
                pass_count = pass_count + 1;
                tc_result = "Passed";
            end else begin
                fail_count = fail_count + 1;
                tc_result = "Failed";
            end
            $display("TC %d: %s; Expected: %h %h, Actual: %h %h", tc_id, tc_result, exp_read_data1, exp_read_data2, read_data1, read_data2);
        end
        
        $display("\nResult:");
        if(pass_count == tc_count)
            $display("All tests passed.");
        else begin
            $display("%d tests passed.", pass_count);
            $display("%d tests failed.", fail_count);
        end
        $finish;
    end
endmodule

module DataMemory_tb();
    parameter data_width = 32,
              addressible_width = 7,
              address_width = 33,
              start_address = 33'h80000000,
              memory_size = 16'h3FFF;
              
    reg [address_width-1:0] read_address, write_address;
    reg [data_width-1:0] write_data, exp_read_data;
    reg wr_dmem, rd_dmem, rst, clk;
    reg [1:0] st_control;
    wire [data_width-1:0] read_data;
    
    integer tc_file_ptr, tc_id, tc_count = 0, pass_count = 0, fail_count = 0;
    reg [8*6:1] tc_result; //string
    
    DataMemory DM_UnderTest(clk, wr_dmem, rd_dmem, rst, read_address, write_address, write_data, st_control, read_data);
    
    always #5 clk = ~clk;
    initial begin
        tc_file_ptr = $fopen("dm_tc.txt", "r");
        
        if (tc_file_ptr == 0) begin
            $display("Unable to open the test case file.");
            $finish;
        end
        
        while(!$feof(tc_file_ptr)) begin
            $fscanf(tc_file_ptr, "%d %h %h %h %h %h %h %h %h\n", tc_id, read_address, write_address,
                    write_data, wr_dmem, rd_dmem, rst, st_control, exp_read_data);
            tc_count = tc_count + 1;
            #5;
            if(read_data == exp_read_data) begin
                pass_count = pass_count + 1;
                tc_result = "Passed";
            end else begin
                fail_count = fail_count + 1;
                tc_result = "Failed";
            end
            $display("TC %d: %s; Expected: %h, Actual: %h", tc_id, tc_result, exp_read_data, read_data);
        end
        
        $display("\nResult:");
        if(pass_count == tc_count)
            $display("All tests passed.");
        else begin
            $display("%d tests passed.", pass_count);
            $display("%d tests failed.", fail_count);
        end
        $finish;
    end
endmodule

module InstructionMemory_tb();
    parameter data_width = 32, 
                address_width = 32,
                addressible_data_width = 8,
                start_address = 32'h01000000,
                memory_size = 16'h7FFF;
    reg clk, rst, load_imem;
    reg [address_width-1:0] instruction_address;
    reg [data_width-1:0] exp_instruction;
    wire [data_width-1:0] instruction;
    
    integer tc_file_ptr, tc_id, tc_count = 0, pass_count = 0, fail_count = 0;
    reg [8*6:1] tc_result; //string
    
    InstructionMemory IM_UnderTest(instruction_address, rst, load_imem, instruction);
    
    always #5 clk = ~clk;
    
    initial begin
        tc_file_ptr = $fopen("im_tc.txt", "r");
        
        if (tc_file_ptr == 0) begin
            $display("Unable to open the test case file.");
            $finish;
        end
        
        while(!$feof(tc_file_ptr)) begin
            wait(clk == 0);
            $fscanf(tc_file_ptr, "%d %h %h %h %h\n", tc_id, instruction_address, rst, load_imem, exp_instruction);
            tc_count = tc_count + 1;
            
            wait(clk == 1) #2;
            if(instruction == exp_instruction) begin
                pass_count = pass_count + 1;
                tc_result = "Passed";
            end else begin
                fail_count = fail_count + 1;
                tc_result = "Failed";
            end
            $display("TC %d: %s; Expected: %h, Actual: %h", tc_id, tc_result, exp_instruction, instruction);
        end
        
        $display("\nResult:");
        if(pass_count == tc_count)
            $display("All tests passed.");
        else begin
            $display("%d tests passed.", pass_count);
            $display("%d tests failed.", fail_count);
        end
        $finish;
    end
endmodule