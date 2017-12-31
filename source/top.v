`include "head.v"
`timescale 1ns/1ps
module top(
    input clk,
    input nRST
);
    //TODO:: not finished 
    reg pcWrite = 1;
    reg [1:0]sel = 0;
    //TODO END
    wire labelEN;
    wire [31:0] pc;
    wire [31:0] newpc;
    wire [31:0] ins;
    wire [5:0] op;
    wire [5:0] func;
    wire [4:0] sftamt;
    wire [4:0] rs;
    wire [4:0] rt;
    wire [4:0] rd;
    wire [15:0] immd16,
    wire [25:0] immd26;
    wire [31:0] rsData;
    wire [31:0] rtData;
    wire [3:0] rsLabel;
    wire [3:0] rtLabel;
    wire BCEN;
    wire [31:0] BCdata;
    wire [3:0] BClabel;
    PC pc(
        .clk,
        .nRST,
        .newpc,
        .pcWrite,
        .pc
    );
    PCHelper pc_helper(
        .pc,
        .immd16,
        .immd26,
        .sel,
        .rs(0), // rs here is data
        .newpc
    );
    Rom rom(
        .nrd(0),
        .dataOut(ins),
        .addr(pc)
    );
    Decoder decoder(
        .ins,
        .op,
        .func,
        .sftamt,
        .rs,
        .rt,
        .rd,
        .immd16,
        .immd26
    );

    wire [3:0] cur_label;

    RegFile regfile(
        .clk,
        .nRST,
        .ReadAddr1(rs), // TODO:
        .ReadAddr2(rt),
        .RegWr(labelEN),
        .WriteAddr(rd),
        .WriteLabel(cur_label), //TODO
        .DataOut1(rsData),
        .DataOut2(rtData),
        .LabelOut1(rsLabel),
        .LabelOut2(rtLabel),
        .BCEN,
        .BClabel,
        .BCdata
    );


    // 假设已经搞定，译码完成，以下就是我想要的
    wire [3:0] ResStationEN;// 3,2,1,0 : lw,div,mul,alu
    wire [1:0] opcode;// updated by control_unit
    wire [1:0] ResStationDst // updated by control_unit
    wire [3:0] Qj;
    wire [3:0] Qk;
    wire [31:0] Vj;
    wire [31:0] Vk;
    // wire [31:0] Qi;
    // wire [31:0] A;
    //--------------------------
    assign Qj = rslabel;
    assign Qk = rtLabel;
    assign Vj = rsData;
    assign Vk = rtLabel;
    // assign Qi = 

    mux4to1_4 my_mux4to1_4(
        .sel(ResStationDst),
        .dataIn0(alu_label),
        .dataIn1(mul_label),
        .dataIn2(div_label),
        .dataIn3(0),
        .dataOut(cur_label)
    );

    //-------------------------------

    wire alu_EXEable;
    wire alu_op;
    wire [31:0] alu_A;
    wire [31:0] alu_B;
    wire alu_isReady;
    wire [3:0] alu_label;
    wire alu_isfull;
    wire [31:0] alu_result;
    wire [3:0] alu_labelOut;

    ReservationStation alu_reservationstation(
        .clk(clk),
        .nRST(nRST),
        .EXEable(alu_EXEable),
        .WEN(ResStationEN[0]),
        .ResStationDst(ResStationDst),
        .opCode(opcode),
        .dataIn1(Vj),
        .label1(Qj),
        .dataIn2(Vk),
        .label2(Qk),
        .BCEN,
        .BClabel,
        .BCdata,
        .opOut(alu_op),
        .dataOut1(alu_A),
        .DataOut2(alu_B),
        .isFull(alu_isfull),
        .OutEn(alu_isReady),
        .labelOut(alu_label), 
    );

    wire [1:0]pmfStateOut;
    wire pmfALUAvailable;
    wire pmfALUEN;
    wire pmfRequire;
    pmfState pmf_state(
        .clk,
        .nRST,
        .stateOut(pmfStateOut),
        .WEN(alu_isReady),
        .requireAC(requireAC_s[0]),
        .available(alu_EXEable),
        .pmfALUEN,
        .op(alu_op),
        .require(require_s[0])
    );

    pmfALU pmf_alu(
        .clk,
        .nRST,
        .EN(pmfALUEN),
        .dataIn1(alu_A),
        .dataIn2(alu_B),
        .labelIn(alu_label),
        .state(pmfStateOut),
        .result(alu_result),
        .labelOut(alu_labelOut)
    );




    wire mul_EXEable;
    wire mul_op;
    wire [31:0] mul_A;
    wire [31:0] mul_B;
    wire mul_isReady;
    wire [3:0] mul_label;
    wire mul_isfull;
    wire [31:0] mul_result;
    wire [3:0] mul_labelOut;

    ReservationStation mul_reservationstation(
        .clk(clk),
        .nRST(nRST),
        .EXEable(mul_EXEable),
        .WEN(ResStationEN[0]),
        .ResStationDst(ResStationDst),
        .opCode(opcode),
        .dataIn1(Vj),
        .label1(Qj),
        .dataIn2(Vk),
        .label2(Qk),
        .BCEN,
        .BClabel,
        .BCdata,
        .opOut(mul_op),
        .dataOut1(mul_A),
        .DataOut2(mul_B),
        .isFull(mul_isfull),
        .OutEn(mul_isReady),
        .labelOut(mul_label), 
    );

    wire [1:0]mfStateOut;
    wire mfALUAvailable;
    wire mfALUEN;
    wire mfRequire;
    mfState mf_state(
        .clk,
        .nRST,
        .stateOut(mfStateOut),
        .WEN(mul_isReady),
        .requireAC(requireAC_s[1]),
        .available(mul_EXEable),
        .mfALUEN,
        .op(mul_op),
        .require(require_s[1])
    );

    mfALU mf_alu(
        .clk,
        .nRST,
        .EN(mfALUEN),
        .dataIn1(mul_A),
        .dataIn2(mul_B),
        .labelIn(mul_label),
        .state(mfStateOut),
        .result(mul_result),
        .labelOut(mul_labelOut)
    );



    // wire div_EXEable;
    // wire div_op;
    // wire [31:0] div_A;
    // wire [31:0] div_B;
    // wire div_isReady;
    // wire [3:0] div_label;
    // wire div_isfull;
    // wire [31:0] div_result;

    // ReservationStation div_reservationstation(
    //     .clk(clk),
    //     .nRST(nRST),
    //     .EXEable(div_EXEable),// TODO:
    //     .WEN(ResStationEN[2]),
    //     .ResStationDst(ResStationDst),
    //     .opCode(op),
    //     .dataIn1(Vj),
    //     .label1(Qj),
    //     .dataIn2(Vk),
    //     .label2(Qk),
    //     .BCEN,
    //     .BClabel,
    //     .BCdata,
    //     .opOut(div_op),
    //     .dataOut1(div_A),
    //     .DataOut2(div_B),
    //     .isFull(div_isfull),
    //     .OutEn(div_isReady),
    //     .labelOut(div_label), 
    // );

    // wire [1:0]dfStateOut;
    // wire dfALUAvailable;
    // wire dfALUEN;
    // wire dfRequire;
    // dfState df_state(
    //     .clk,
    //     .nRST,
    //     .stateOut(dfStateOut),
    //     .WEN(div_isReady),
    //     .requireAC(),// TODO:
    //     .available(div_EXEable),
    //     .dfALUEN,
    //     .op(div_op),
    //     .require()// TODO:
    // );

    // dfALU df_alu(
    //     .clk,
    //     .nRST,
    //     .EN(dfALUEN),
    //     .dataIn1(div_A),
    //     .dataIn2(div_B),
    //     .state(dfStateOut),
    //     .result(div_result)
    // );

    // TODO: memory part
    // wire memory_available;
    // wire 
    
    // Queue opprendA_queue(
    //     .clk,
    //     .nRST,
    //     .requireAC(memory_available),
    //     .WEN(),
    //     .isFull(),
    //     .require(),
    //     .dataIn(),
    //     .labelIn(),
    //     .opIN(),
    //     .BCEN,
    //     .BClabel,
    //     .BCdata,
    //     .opOut(),
    //     .dataOut(),
    //     .labelOut()
    // );


    // Memory yf_memory(
    //     .clk,
    //     .outEn,
    //     .dataIn1,
    //     .dataIn2,
    //     .op,
    //     .wrireData,
    //     .loadData,
    //     .available,
    //     .requireCDB,
    //     .requireAC
    // );


    // 3,2,1,0 ls, div ,mul ,alu
    wire [3:0] require_s;
    wire [3:0] requireAC_s;

    // test memory
    require_s[2] = 0;
    require_s[3] = 0;


    CDBHelper(
        .requires(require_s),
        .accepts(requireAC_s)
    );

    CDB(
        .data0(alu_result),
        .label0(alu_labelOut),
        .data1(mul_result),
        .label1(mul_labelOut),
        // TODO: no link dfalu, memory
        .data2(0),
        .label2(0),
        .data3(0),
        .label3(0),

        .sel(requireAC_s),
        .dataOut(BCData),
        .labelOut(BClabel),
        .EN(BCEN)
    );


    CU contril_unit(
        .op,
        .func,
        .ALUop(opcode),
        .ALUSel(ResStatioinDst),
        .isFull({0, mul_isfull, alu_isfull}),
        .isFullOut(labelEN)
        // .RegDst() TODO:
    );


endmodule