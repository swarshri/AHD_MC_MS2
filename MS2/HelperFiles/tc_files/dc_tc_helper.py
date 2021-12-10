# -*- coding: utf-8 -*-
"""
Created on Fri Dec  3 11:20:54 2021

@author: cswar
"""
import os

if __name__ == "__main__":
    filePath = os.path.abspath("C:/Swarnashri/Masters/TandonCourses/GY6463_AdvancedHardwareDesign/FinalProject/RV32I/tc_files/ip.txt")
    
    with open(filePath, "r") as tc_file:
        lines = tc_file.readlines()
      
    test_cases = []
    
    for line in lines:
        line = line.strip()
        print ("line:", line)
        instruction_int = int('0x' + line.split(" ")[1], 16)
        instruction_hex = hex(instruction_int)
        instruction_bin = bin(instruction_int)
        ins_bin_str = str(instruction_bin)[2:]
        print ("ins hex:", instruction_hex)
        print ("ins bin:", instruction_bin)
        print ("ins bin str:", ins_bin_str, len(ins_bin_str))
        
        final_ins_bin_str = "0" * (32-len(ins_bin_str)) + ins_bin_str
        print ("final ins bin str:", final_ins_bin_str, len(final_ins_bin_str))
        
        opcode = final_ins_bin_str[25:]
        if (opcode == "0001111"):
            ins_type = "F"
        elif (opcode == "1100011"):
            ins_type = "B"
        elif (opcode == "1100111"):
            ins_type = "JI"
        elif (opcode == "0000011"):
            ins_type = "LI"
        elif (opcode == "0010011"):
            ins_type = "I"
        elif (opcode == "1101111"):
            ins_type = "J"
        elif (opcode == "1110011"):
            ins_type = "N"
        elif (opcode == "0110011"):
            ins_type = "R"
        elif (opcode == "0010011"):
            ins_type = "SI"
        elif (opcode == "0100011"):
            ins_type = "S"
        elif opcode == "0110111":
            ins_type = "LU"
        elif opcode == "0010111":
            ins_type = "AU"
        else:
            ins_type = "invalid"
            
        funct7 = final_ins_bin_str[0:7]
        rs2 = shamt = final_ins_bin_str[7:12]
        rs1 = final_ins_bin_str[12:17]
        funct3 = final_ins_bin_str[17:20]
        rd = final_ins_bin_str[20:25]
        
        if ins_type == "I" and funct3[1:0] == "01":
            ins_type = "SI"
            
        if ins_type == "S":
            imm_short = final_ins_bin_str[0:8] + final_ins_bin_str[20:25]
        elif ins_type == "B":
            imm_short = final_ins_bin_str[0] + final_ins_bin_str[24] + final_ins_bin_str[1:7] + final_ins_bin_str[20:24]
        else:
            imm_short = final_ins_bin_str[0:12]
            
        if ins_type == "J":
            imm_long = final_ins_bin_str[0] + final_ins_bin_str[11:20] + final_ins_bin_str[10] + final_ins_bin_str[1:10]
        else:
            imm_long = final_ins_bin_str[0:20]
        
        store_control = funct3[1:]
        branch_control = funct3
        de_control = funct3
        ie_control = str(int(ins_type[0] == "U")) + str(int(ins_type == "SI")) + str(int(ins_type == "J"))
        
        #alu_op
        
        br_en = str(int(ins_type == "B"))
        load_en = str(int(ins_type in ["LU", "LI"]))
        store_en = str(int(ins_type == "S"))
        wr_en = str(int(ins_type not in ["B", "S", "N"]))
        
        op1_mux_cntl = str(int(ins_type in ["AU", "B", "J", "JI"]))
        op2_mux1_cntl = str(int(ins_type == "R"))
        op2_mux2_cntl = str(int(ins_type == "SI"))
        pc_mux_cntl = str(int(ins_type in ["B", "J", "JI"]))
        wb_mux1_cntl = str(int(ins_type in ["LU", "LI"]))
        wb_mux2_cntl = str(int(ins_type in ["J", "JI"]))
        wb_mux3_cntl = str(int(ins_type in ["AU", "LU", "LI"]))
        
        if ins_type in ["B", "N", "F"]:
            alu_op = "1111"
        elif ins_type in ["JI", "AU", "LU", "LI", "J", "S"]:
            alu_op = "0000"
        elif ins_type in ["R", "I", "SI"]:
            if funct3 == "000":
                if funct7[1] == "0":
                    alu_op = "0000"
                else:
                    alu_op = "0001"
            elif funct3 == "111":
                alu_op = "0101"
            elif funct3 == "110":
                alu_op = "0110"
            elif funct3 == "100":
                alu_op = "0111"
            elif funct3 == "010":
                alu_op = "1001"
            elif funct3 == "011":
                alu_op = "1000"
            elif funct3 == "001":
                alu_op = "0010"
            elif funct3 == "101":
                if funct7[1] == "0":
                    alu_op = "0011"
                else:
                    alu_op = "0100"
        else:
            alu_op = "IV"
            
        pre_elements = [store_control: store_control, ie_control: ie_control, branch_control: branch_control, de_control: de_control,
                        alu_op: alu_op, rs1: rs1, rs2: rs2, rd: rd, imm_short: imm_short, imm_long: imm_long, op2_mux1_cntl: op2_mux1_cntl,
                        op2_mux2_cntl: op2_mux2_cntl, op1_mux_cntl: op1_mux_cntl, br_en: br_en, load_en: load_en, store_en: store_en,
                        wr_en: wr_en, wb_mux1_cntl: wb_mux1_cntl, wb_mux2_cntl: wb_mux2_cntl, wb_mux3_cntl: wb_mux3_cntl, 
                        pc_mux_cntl: pc_mux_cntl]
        
        for elem in pre_elements:
            print ("pre", elem)
        print ("opcode pre:", opcode)
        #Rewrite field bits to hex
        
        opcode = str(hex(int(("0b" + opcode), 2)))[2:]
        opcode = "0" * (2 - len(opcode)) + opcode
        print ("opcode post:", opcode)         
        
        print ("funct7 pre:", funct7)
        #Rewrite field bits to hex
        
        funct7 = str(hex(int(("0b" + funct7), 2)))[2:]
        funct7 = "0" * (2 - len(funct7)) + funct7
        print ("funct7 post:", funct7)       
        
        print ("rs2 pre:", rs2)
        #Rewrite field bits to hex
        
        rs2 = str(hex(int(("0b" + rs2), 2)))[2:]
        rs2 = "0" * (2 - len(rs2)) + rs2
        print ("rs2 post:", rs2)
        
        print ("shamt pre:", shamt)
        #Rewrite field bits to hex
        
        shamt = str(hex(int(("0b" + shamt), 2)))[2:]
        shamt = "0" * (2 - len(shamt)) + shamt
        print ("rs2 post:", shamt)
        
        print ("rs1 pre:", rs1)
        #Rewrite field bits to hex
        
        rs1 = str(hex(int(("0b" + rs1), 2)))[2:]
        rs1 = "0" * (2 - len(rs1)) + rs1
        print ("rs1 post:", rs1)        
        
        print ("funct3 pre:", funct3)
        #Rewrite field bits to hex
        
        funct3 = str(hex(int(("0b" + funct3), 2)))[2:]
        print ("funct3 post:", funct3)
        
        print ("rd pre:", rd)
        #Rewrite field bits to hex
        
        rd = str(hex(int(("0b" + rd), 2)))[2:]
        rd = "0" * (2 - len(rd)) + rd
        print ("rd post:", rd)     
        
        print ("imm_short pre:", imm_short)
        #Rewrite field bits to hex
        
        imm_short = str(hex(int(("0b" + imm_short), 2)))[2:]
        imm_short = "0" * (3 - len(imm_short)) + imm_short
        print ("imm_short post:", imm_short)  
        
        print ("imm_long pre:", imm_long)
        #Rewrite field bits to hex
        
        imm_long = str(hex(int(("0b" + imm_long), 2)))[2:]
        imm_long = "0" * (5 - len(imm_long)) + imm_long
        print ("imm_long post:", imm_long)    
        
        print ("alu_op pre:", alu_op)
        #Rewrite field bits to hex
        
        alu_op = str(hex(int(("0b" + alu_op), 2)))[2:]
        print ("alu_op post:", alu_op)   
        
        tc_elements = [line.replace("\n", ""), store_control, ie_control, branch_control, de_control, alu_op, rs1, rs2, rd,
                       imm_short, imm_long, op2_mux1_cntl, op2_mux2_cntl, op1_mux_cntl, br_en, load_en, 
                       store_en, wr_en, wb_mux1_cntl, wb_mux2_cntl, wb_mux3_cntl, pc_mux_cntl]
        
        test_cases.append(' '.join(tc_elements) + "\n")
        print ("tc:", tc_elements)
        print ("tc_joined:", ' '.join(tc_elements))
        
    wr_filePath = os.path.abspath("C:/Swarnashri/Masters/TandonCourses/GY6463_AdvancedHardwareDesign/FinalProject/RV32I/tc_files/dc_tc.txt")
    with open(wr_filePath, "w") as wfp:
        wfp.writelines(test_cases)