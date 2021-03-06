import tiny8_types::*;

module datapath
(
    input clk,
    
    /* register loads */
    input load_pc,
    input load_ir,
    input load_acc,
    input load_rs,
    input load_rd,
    input load_mar,
    input load_mdr,

    input tiny8_aluop aluop,
    output logic branch_enable,
    output tiny8_opcode opcode,

    /* mux selects */
    input pcmux_sel,
    input alumux1_sel,
    input alumux2_sel,
    input regfilemux_sel,
    input [1:0] marmux_sel,
    input mdrmux_sel,

    /* memory connections */
    output tiny8_word mem_address,
    output tiny8_word mem_wdata,
    input tiny8_word mem_rdata
);

tiny8_word pc_out;
tiny8_word ir_out;
tiny8_word acc_out;
tiny8_word rs_out;
tiny8_word rd_out;
tiny8_word alu_out;
tiny8_word pcmux_out;
tiny8_word addrmux_out;
tiny8_word alumux1_out;
tiny8_word alumux2_out;
tiny8_word regfilemux_out;
tiny8_reg rs;
tiny8_reg rd;
logic [1:0] delta2;
logic [3:0] imm4;
tiny8_word marmux_out;
tiny8_word mdrmux_out;
tiny8_word imm4_sext;
tiny8_word delta2_sext;

assign branch_enable = (rs_out>0);

register pc
(
    .clk,
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

register ir
(
    .clk,
    .load(load_ir),
    .in(mem_rdata),
    .out(ir_out)
);

register acc
(
    .clk,
    .load(load_acc),
    .in(acc_out + alu_out),
    .out(acc_out)
);

regfile regfile
(
    .clk,
    .load1(load_rs),
    .load2(load_rd),
    .in1(regfilemux_out),
    .in2(alu_out),
    .r1(rs),
    .r2(rd),
    .out1(rs_out),
    .out2(rd_out)
);

alu alu
(
    .aluop,
    .a(alumux1_out),
    .b(alumux2_out),
    .f(alu_out)
);

mux2 pcmux
(
    .sel(pcmux_sel),
    .a(pc_out + 1'b1),
    .b(pc_out + imm4),
    .f(pcmux_out)
);

mux2 alumux1
(
    .sel(alumux1_sel),
    .a(rs_out),
    .b(rd_out),
    .f(alumux1_out)
);

sext #(2) delta2_sext_
(
    .in (delta2),
    .out(delta2_sext)
);

sext #(4) imm4_sext_
(
    .in (imm4),
    .out(imm4_sext)
);

mux2 alumux2
(
    .sel(alumux2_sel),
    .a(delta2_sext),
    .b(imm4_sext),
    .f(alumux2_out)
);

mux2 regfilemux
(
    .sel(regfilemux_sel),
    .a(alu_out),
    .b(mem_wdata),
    .f(regfilemux_out)
);

ir ir_
(
    .clk,
    .load(load_ir),
    .in(mem_rdata),
    .opcode,
    .rs,
    .rd,
    .delta2,
    .imm4
);

register mar 
(
    .clk, 
    .load(load_mar), 
    .in(marmux_out), 
    .out(mem_address)
);

mux4 marmux 
(
    .sel(marmux_sel), 
    .a(rd_out), 
    .b(rs_out), 
    .c(pc_out),
    .d(),
    .f(marmux_out)
);

register mdr 
(
    .clk, 
    .load(load_mdr), 
    .in(mdrmux_out), 
    .out(mem_wdata)
);

mux2 mdrmux 
(
    .sel(mdrmux_sel), 
    .a(acc_out), 
    .b(mem_rdata), 
    .f(mdrmux_out)
);

endmodule
