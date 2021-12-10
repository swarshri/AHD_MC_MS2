//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2021 05:53:06 PM
// Design Name: 
// Module Name: Components
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

module ControlUnit
    (input clk, rst,
     input singlecycle_mode,
     output reg rst_sys, load_imem, pc_en, dec_en, iex_en, rf_en, bres_en, alu_en, dex_en, wb_en);
     
     parameter reset = 0, load_ins = 1, insFetch = 2, insDecode = 3, execute = 4, memory = 5, writeback = 6, run = 7;
     reg [2:0] state = 0, next_state;
     
     always@(negedge clk) begin
        state <= next_state;
     end
     
     always@(state, rst) begin
        case(state)
            reset: 
                if (rst) next_state <= reset;
                else next_state <= load_ins;
            load_ins:
                if (rst) next_state <= reset;
                else if (singlecycle_mode)
                    next_state <= run;
                else next_state <= insFetch;
            run:
                if(rst) next_state <= reset;
                else next_state <= run;
            insFetch:
                next_state <= insDecode;
            insDecode:
                next_state <= execute;
            execute:
                next_state <= memory;
            memory:
                next_state <= writeback;
            writeback:
                if(rst) next_state <= reset;
                else next_state <= insFetch;
        endcase
     end
     
     always @(state) begin
        rst_sys <= 0;
        load_imem <= 0;
        pc_en <= 0;
        dec_en <= 0;
        iex_en <= 0;
        rf_en <= 0;
        bres_en <= 0;
        alu_en <= 0;
        dex_en <= 0;
        wb_en <= 0;
        case(state)
            reset: rst_sys <= 1;
            load_ins: begin
                load_imem <= 1;
            end
            run: begin
                pc_en <= 1;
                dec_en <= 1;
                iex_en <= 1;
                rf_en <= 1;
                bres_en <= 1;
                alu_en <= 1;
                dex_en <= 1;
            end
            insFetch:
                pc_en <= 1;
            insDecode: begin
                dec_en <= 1;
                iex_en <= 1;
                rf_en <= 1;
                bres_en <= 1;
            end
            execute: alu_en <= 1;
            memory:
                dex_en <= 1;
            writeback: wb_en <= 1;
        endcase
     end
endmodule

module InstructionMemory
    #(parameter data_width = 32, 
                address_width = 32,
                addressible_data_width = 8,
                start_address = 32'h01000000,
                memory_size = 16'h7FFF)
    (input [address_width-1:0] instruction_address,
     input rst, load_imem,
     output reg [data_width-1:0] instruction);
     
    // Instruction RAM
    reg [7:0] insMem [start_address: start_address + memory_size];
    integer ram_start_address = 32'h0100000C;
    integer i, j, file_ptr;
    reg [address_width-1:0] address; 
    
    initial begin
        insMem[start_address + 0] = 8'h10;
        insMem[start_address + 1] = 8'h97;
        insMem[start_address + 2] = 8'h01;
        insMem[start_address + 3] = 8'h49;
        insMem[start_address + 4] = 8'h12;
        insMem[start_address + 5] = 8'h31;
        insMem[start_address + 6] = 8'h79;
        insMem[start_address + 7] = 8'h41;
        insMem[start_address + 8] = 8'h10;
        insMem[start_address + 9] = 8'h39;
        insMem[start_address + 10] = 8'h92;
        insMem[start_address + 11] = 8'h15;
    end
    
    always @(posedge load_imem) begin
        // Read from the memory file and fill the Instruction RAM.
        // Read file and fill instruction RAM.
        $readmemh("imem.mem", insMem, ram_start_address, start_address + memory_size);
    end
    
    always @(instruction_address, load_imem) begin
        if(!load_imem) begin
            if (instruction_address > start_address + memory_size)
                address = start_address + memory_size;
            else if (instruction_address < start_address)
                address = start_address;
            else
                address = instruction_address;
            
            address = address & 32'hFFFFFFFC;
            
            instruction <= {insMem[address],
                            insMem[address + 1],
                            insMem[address + 2],
                            insMem[address + 3]};
        end
    end
endmodule

module Decoder
    #(parameter data_width = 32)
    (input [data_width-1:0] instruction,
     output [1:0] store_control,
     output [3:0] ie_control, branch_control, de_control,
     output reg [3:0] AluOP,
     output [4:0] rs1, rs2, rd,
     output reg [11:0] immediate_short,
     output reg [19:0] immediate_long,
     output op2_mux1_cntl, op2_mux2_cntl, op1_mux_cntl, br_en, load_en, store_en, wr_en, wb_mux1_cntl, wb_mux2_cntl, wb_mux3_cntl, pc_mux_cntl);
     
     localparam[4:0] RType_opcode = 5'h0C, BType_opcode = 5'h18, SType_opcode = 5'h08, JType_opcode = 5'h1B,
                     JIType_opcode = 5'h19, FType_opcode = 5'h03, NType_opcode = 5'h1C, LUType_opcode = 5'h0D,
                     LIType_opcode = 5'h00, AUType_opcode = 5'h05, IType_opcode = 5'h04, UType_opcode = 5'h65;
                     
     wire [4:0] opcode; 
     wire [6:0] funct7;
     wire [2:0] funct3;
     wire is_RType, is_BType, is_SType, is_SIType, is_JType, is_UType, is_NType, is_Load, is_Jump;
     
     assign opcode = instruction[6:2];
     assign rs2 = instruction[24:20];
     assign rs1 = instruction[19:15];
     assign rd = instruction[11:7];
     assign funct7 = instruction[31:25];
     assign funct3 = instruction[14:12];
     
     assign is_RType = opcode == RType_opcode;
     assign is_BType = opcode == BType_opcode;
     assign is_SType = opcode == SType_opcode;
     assign is_JType = opcode == JType_opcode;
     assign is_SIType = opcode == IType_opcode & funct3[1:0] == 2'b01;
     assign is_UType = opcode == LUType_opcode | opcode == AUType_opcode;
     assign is_NType = opcode == NType_opcode | opcode == FType_opcode;
     assign is_Jump = opcode == JType_opcode | opcode == JIType_opcode;
     assign is_Load = opcode == LIType_opcode | opcode == LUType_opcode;
     
     assign branch_control = funct3;
     assign store_control = funct3[1:0];
     assign de_control = funct3;
     assign ie_control = {is_BType, is_UType, is_SIType, is_JType};
     
     assign load_en = is_Load;
     assign store_en = is_SType;
     assign wr_en = ~(is_BType | is_SType | is_NType);
     assign br_en = is_BType;
     assign op2_mux1_cntl = is_RType;
     assign op2_mux2_cntl = is_SIType;
     assign op1_mux_cntl = opcode == AUType_opcode | opcode == JType_opcode;
     assign pc_mux_cntl = is_Jump;
     assign wb_mux1_cntl = is_Load; 
     assign wb_mux2_cntl = is_Jump;
     assign wb_mux3_cntl = is_Load & is_UType;
     
     always@(instruction) begin
        immediate_short <= instruction[31:20];
        immediate_long <= instruction[31:12];
        case(opcode)
            BType_opcode:
                immediate_short <= {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};
            SType_opcode:
                immediate_short <= {instruction[31:25], instruction[11:7]};
            JType_opcode:
                immediate_long <= {instruction[31], instruction[20:12], instruction[21], instruction[30:22]};
            AUType_opcode,
            LUType_opcode: begin
                immediate_long <= instruction[31:12];
            end
        endcase
     end
     
     always@(instruction) begin
        case(opcode)
            NType_opcode,
            FType_opcode:
                AluOP <= 4'b1111; //NOP
            BType_opcode:
                AluOP <= 4'b0000; //ADD
            RType_opcode,
            IType_opcode:
                case(funct3)
                    3'b000:
                        if(funct7[6:5] == 2'b00) AluOP <= 4'b0000; //Add
                        else if(funct7[6:5] == 2'b01) AluOP <= 4'b0001; //Sub
                    3'b111: AluOP <= 4'b0101; //And
                    3'b110: AluOP <= 4'b0110; //Or
                    3'b100: AluOP <= 4'b0111; //Xor
                    3'b010: AluOP <= 4'b1001; //LT
                    3'b011: AluOP <= 4'b1000; //LTU
                    3'b001: AluOP <= 4'b0010; //Shift Left
                    3'b101: //Shift Right
                        if(funct7[6:5] == 2'b00) AluOP <= 4'b0011; //Logical
                        else if(funct7[6:5] == 2'b01) AluOP <= 4'b0100; //Arithmetic
                endcase
            JIType_opcode,
            AUType_opcode,
            LUType_opcode,
            LIType_opcode,
            JType_opcode,
            SType_opcode:
                AluOP <= 4'b0000; //Add
        endcase
     end
endmodule

module RegisterFile
    #(parameter data_width = 32, address_width = 5, reg_count = 32)
    (input clk, rst, wr_enable, rd_enable,
     input [address_width-1:0] read_reg1, read_reg2, write_address,
     input [data_width-1:0] write_data,
     output reg [data_width-1:0] read_data1, read_data2);
     
     reg [data_width-1:0] register [0:reg_count-1];
     integer i;
     
     initial begin
         register[0] = 32'h00000000;
         register[1] = 32'h00000000;
         register[2] = 32'h00000000;
         register[3] = 32'h00000000;
         register[4] = 32'h00000000;
         register[5] = 32'h00000000;
         register[6] = 32'h00000000;
         register[7] = 32'h00000000;
         register[8] = 32'h00000000;
         register[9] = 32'h00000000;
         register[10] = 32'h00000000;
         register[11] = 32'h00000000;
         register[12] = 32'h00000000;
         register[13] = 32'h00000000;
         register[14] = 32'h00000000;
         register[15] = 32'h00000000;
         register[16] = 32'h00000000;
         register[17] = 32'h00000000;
         register[18] = 32'h00000000;
         register[19] = 32'h00000000;
         register[20] = 32'h00000000;
         register[21] = 32'h00000000;
         register[22] = 32'h00000000;
         register[23] = 32'h00000000;
         register[24] = 32'h00000000;
         register[25] = 32'h00000000;
         register[26] = 32'h00000000;
         register[27] = 32'h00000000;
         register[28] = 32'h00000000;
         register[29] = 32'h00000000;
         register[30] = 32'h00000000;
         register[31] = 32'h00000000;     
     end
     
     always @(negedge clk) begin
        if (!rst && wr_enable)
            if (write_address != 32'd0) register[write_address] = write_data;
     end
     
     always @(read_reg1, read_reg2, rd_enable) begin
        if(rd_enable) begin
            read_data1 <= register[read_reg1];
            read_data2 <= register[read_reg2];
        end
     end
endmodule

module ImmExtender
    #(parameter data_width = 32)
    (input enable,
     input [11:0] imm_short,
     input [19:0] imm_long,
     input [3:0] control, // {is_BType, is_UType, is_SIType, is_JType}
     output [data_width-1:0] immediate_out);
     
     wire [data_width-1:0] long_dout, short_dout;
     
     assign long_dout = control[2] ? {imm_long, 12'h000}: {{10{imm_long[19]}}, imm_long, 2'b00};
     assign short_dout = control[3] ? {{19{imm_short[11]}}, imm_short, 1'b0}: (control[1] ? {{20{1'b0}}, imm_short}: {{20{imm_short[11]}}, imm_short});
     assign immediate_out = (control[2] || control[0]) ? long_dout : short_dout;
endmodule

module BranchResolver
    #(parameter data_width = 32)
    (input enable, btype_ins,
     input [2:0] branch_funct,
     input [data_width-1:0] op1, op2,
     output reg branch_control);
     always@(*)begin
        if(enable)
            if(btype_ins) begin
                case(branch_funct)
                    3'b000: branch_control <= op1 == op2;
                    3'b001: branch_control <= op1 != op2;
                    3'b100: branch_control <= $signed(op1) < $signed(op2);
                    3'b101: branch_control <= $signed(op1) >= $signed(op2);
                    3'b110: branch_control <= op1 < op2;
                    3'b111: branch_control <= op1 >= op2;
                endcase
            end else
                branch_control <= 0;
     end
endmodule

module ALU(
    input enable,
    input [31:0] op1,  //src1
    input [31:0] op2,  //src2
    input [3:0] alu_control, //function sel
    output reg [31:0] result);  //result
    
    always @(*) begin
        if (enable) begin 
            case(alu_control)
                4'b0000: result = op1 + op2; // add
                4'b0001: result = op1 - op2; // sub
                4'b0010: result = op1 << op2[4:0]; // Left Shift
                4'b0011: result = op1 >> op2[4:0]; // Right Shift
                4'b0100: result = $signed(op1) >>> op2[4:0]; // Arithmetic Right shift
                4'b0101: result = op1 & op2; // and
                4'b0110: result = op1 | op2; // or
                4'b0111: result = op1 ^ op2; // xor
                4'b1000: result = $unsigned(op1) < $unsigned(op2); // set less than unsigned
                4'b1001: result = $signed(op1) < $signed(op2); // set less than signed
            endcase
        end
    end
endmodule

module DataMemory
    #(parameter data_width = 32,
                addressible_width = 8,
                address_width = 32,
                start_address = 32'h80000000,
                memory_size = 16'h3F)
    (input clk, wr_dmem, rd_dmem, rst,
     input [address_width-1:0] read_address, write_address,
     input [data_width-1:0] write_data,
     input [1:0] st_control,
     output reg [data_width-1:0] read_data);
     
     reg [address_width-1:0] i;
     reg [address_width-1:0] wr_address;
     reg [address_width-1:0] rd_address;
     reg [addressible_width-1:0] dmem [start_address: start_address + memory_size];
     
     always@(write_address) begin
        if (write_address < start_address) wr_address = start_address;
        else if (write_address > start_address + memory_size) wr_address = start_address + memory_size;
        else wr_address = write_address;
        
        wr_address = wr_address & 32'hFFFFFFFC;
     end
     
     always@(negedge clk) begin        
        if(rst) begin
            for (i=start_address; i <= start_address + memory_size; i=i+1)
                dmem[i] = 8'h00;
        end else if(wr_dmem) begin
            case(st_control)
                2'b00: dmem[wr_address+3] = write_data[7:0]; //store byte - SB
                2'b01: begin
                     dmem[wr_address+2] = write_data[15:8];
                     dmem[wr_address+3] = write_data[7:0];
                end //store half word - SH
                2'b10: begin
                     dmem[wr_address] = write_data[31:24];
                     dmem[wr_address+1] = write_data[23:16];
                     dmem[wr_address+2] = write_data[15:8];
                     dmem[wr_address+3] = write_data[7:0]; //store word - S
                end
                default: begin
                     dmem[wr_address] = write_data[31:24];
                     dmem[wr_address+1] = write_data[23:16];
                     dmem[wr_address+2] = write_data[15:8];
                     dmem[wr_address+3] = write_data[7:0]; //store word - S
                end
            endcase
        end
     end
     
     always@(read_address, rd_dmem) begin
        if (read_address < start_address) rd_address = start_address;
        else if (read_address > start_address + memory_size) rd_address = start_address + memory_size;
        else rd_address = read_address;
        
        rd_address = rd_address & 32'hFFFFFFFC;
        
        if(rd_dmem) begin
            read_data <= {dmem[rd_address], dmem[rd_address+1], dmem[rd_address+2], dmem[rd_address+3]};   
        end
     end
endmodule

module DataExtender
    #(parameter data_width = 32)
    (input enable,
     input [data_width-1:0] data,
     input [2:0] control,
     output reg [data_width-1:0] out_data);
    
    localparam byte_width = 8, halfword_width = 16;
    wire msb;
    
    assign msb = control[2] ? 0 : control[0] ? data[halfword_width-1] : data[byte_width-1];
    
    always@(*) begin
        if(control[1]) out_data <= data;
        else begin
           if(control[0]) out_data <= {{data_width-halfword_width{msb}}, data[halfword_width-1:0]};
           else out_data <= {{data_width-byte_width{msb}}, data[byte_width-1:0]};
        end
    end
endmodule