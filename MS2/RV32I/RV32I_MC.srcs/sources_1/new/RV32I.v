//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2021 05:53:06 PM
// Design Name: 
// Module Name: RV32I_MC
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

module RV32I_MC
    #(parameter data_width = 32)
    (input clk,
    input reset,
    output [data_width-1:0] ddata, alu_res, pc);
    
    wire ext_pc, branch_flag;
    wire rst, load_imem, pc_en, dec_en, iex_en, rf_en, bres_en, alu_en, dex_en, wb_en;
    
    wire [data_width-1:0] instruction, regdata1, regdata2;
    wire [data_width-1:0] immediate_32bits, alu_data2, alu_op1, alu_op2, alu_result, dmem_data;
    wire [data_width-1:0] dmemdata_32bits, wb_mux1_out, wb_mux2_out, wb_data;
        
    reg [31:0] ProgramCounter;
    always@(posedge clk, posedge rst) begin
        if (rst)
            ProgramCounter <= 32'h01000008;
        else if (pc_en)
            if(ext_pc)
                ProgramCounter <= alu_result;
            else
                ProgramCounter <= ProgramCounter + 4;
    end
    
    ControlUnit CU(clk, reset, 1'b0, rst, load_imem, pc_en, dec_en,
                   iex_en, rf_en, bres_en, alu_en, dex_en, wb_en);
                   
    InstructionMemory IMEM(ProgramCounter, rst, load_imem, instruction);
    
    //Wires to get data from decoder
    wire [1:0] store_control_w;
    wire [3:0] ie_control_w;
    wire [2:0] branch_control_w, de_control_w;
    wire [3:0] AluOP_w;
    wire [4:0] rs1_w, rs2_w, rd_w;
    wire [11:0] immediate_short_w;
    wire [19:0] immediate_long_w;
    wire op2_mux1_cntl_w, op2_mux2_cntl_w, op1_mux_cntl_w, br_en_w, load_en_w, store_en_w;
    wire wr_en_w, wb_mux1_cntl_w, wb_mux2_cntl_w, wb_mux3_cntl_w, pc_mux_cntl_w;
    
    Decoder DC(instruction, store_control_w, ie_control_w, branch_control_w, de_control_w,
               AluOP_w, rs1_w, rs2_w, rd_w, immediate_short_w, immediate_long_w, op2_mux1_cntl_w,
               op2_mux2_cntl_w, op1_mux_cntl_w, br_en_w, load_en_w, store_en_w, wr_en_w, wb_mux1_cntl_w,
               wb_mux2_cntl_w, wb_mux3_cntl_w, pc_mux_cntl_w);
    
    //Buffer registers for decoded data
    reg [1:0] store_control;
    reg [3:0] ie_control;
    reg [2:0] branch_control, de_control;
    reg [3:0] AluOP;
    reg [4:0] rs1, rs2, rd;
    reg [11:0] immediate_short;
    reg [19:0] immediate_long;
    reg op2_mux1_cntl, op2_mux2_cntl, op1_mux_cntl, br_en, load_en;
    reg store_en, wr_en, wb_mux1_cntl, wb_mux2_cntl, wb_mux3_cntl, pc_mux_cntl;
    
    assign ext_pc = pc_mux_cntl | branch_flag;
    
    always@(posedge clk) begin
        if(dec_en) begin
            store_control <= store_control_w;
            ie_control <= ie_control_w;
            branch_control <= branch_control_w;
            de_control <= de_control_w;
            AluOP <= AluOP_w;
            rs1 <= rs1_w;
            rs2 <= rs2_w;
            rd <= rd_w;
            immediate_short <= immediate_short_w;
            immediate_long <= immediate_long_w;
            op2_mux1_cntl <= op2_mux1_cntl_w;
            op2_mux2_cntl <= op2_mux2_cntl_w;
            op1_mux_cntl <= op1_mux_cntl_w;
            br_en <= br_en_w;
            load_en <= load_en_w;
            store_en <= store_en_w;
            wr_en <= wr_en_w;
            wb_mux1_cntl <= wb_mux1_cntl_w;
            wb_mux2_cntl <= wb_mux2_cntl_w;
            wb_mux3_cntl <= wb_mux3_cntl_w;
            pc_mux_cntl <= pc_mux_cntl_w;
        end
    end
    
    RegisterFile RF(clk, reset, (wr_en & wb_en), rf_en, rs1, rs2, rd, wb_data, regdata1, regdata2);
    
    ImmExtender IE(iex_en, immediate_short, immediate_long, ie_control, immediate_32bits);
    
    BranchResolver BR(bres_en, br_en, branch_control, regdata1, regdata2, branch_flag);
    
    assign alu_data2 = op2_mux1_cntl? regdata2: immediate_32bits;
    
    assign alu_op2 = op2_mux2_cntl? {{27{1'b0}}, rs2}: alu_data2;
    
    assign alu_op1 = (op1_mux_cntl || branch_flag)? ProgramCounter: regdata1;
        
    ALU ALUnit(alu_en, alu_op1, alu_op2, AluOP, alu_result);
    
    DataMemory DMEM(clk, store_en, load_en, reset, alu_result, alu_result, regdata2, store_control, dmem_data);
    
    DataExtender DE(dex_en, dmem_data, de_control, dmemdata_32bits);
    
    assign wb_mux1_out = wb_mux1_cntl? dmemdata_32bits: alu_result;
    
    assign wb_mux2_out = wb_mux2_cntl? ProgramCounter + 4: wb_mux1_out;
    
    assign wb_data = wb_mux3_cntl? immediate_32bits: wb_mux2_out;
    
    assign ddata = dmemdata_32bits;
    assign pc = ProgramCounter;
    assign alu_res = alu_result; 
endmodule