module StallforControlHazard(
    input newPCSrcE,
    input PCSrcM,
    input PCSrcW,
    input BranchTakenE,
    output reg FlushD,
    output reg FlushE
);
  always @(*) begin
    if (BranchTakenE == 1'b1) begin
       FlushD = 1'b1;
       FlushE = 1'b1;
    end
    else if (newPCSrcE == 1'b1 || PCSrcM == 1'b1 || PCSrcW == 1'b1) begin
       FlushD = 1'b1;
       FlushE = 1'b1;
    end
    else begin
       FlushD = 1'b0;
       FlushE = 1'b0;
    end
  end
endmodule

module StallforDataHazard(
    input [3:0] ReadRegister1,
    input [3:0] ReadRegister2,
    input [3:0] WriteRegisterE,
    input [3:0] WriteRegisterW,
    input [1:0] OpcodeE,
    input RegWriteE,
    input RegWriteW,
    input BranchTakenE,
    input IsReadAddr1_ValidE,
    output reg StallF,
    output reg StallD,
    output reg FlushCtrlD
);

    always @(*) begin

        if (RegWriteE == 1'b1 && OpcodeE == 2'b01 && (WriteRegisterE == ReadRegister1 || WriteRegisterE == ReadRegister2
    )) begin // if inst in EXE is "load"
    
                StallF = 1; // pipe registers are disabled when the signal is 0
                StallD = 1;
                FlushCtrlD = 1;
                // when flushCtrlID is 1, input ctrl sig of pipe register ID/EXE will be 0
          end
        else if (BranchTakenE == 1'b0 && RegWriteW == 1'b1 && (WriteRegisterW == ReadRegister1 || WriteRegisterW == ReadRegister2))
           begin StallF = 1; StallD = 1; FlushCtrlD = 1;
           end
        else begin
            StallF = 0;
            StallD = 0;
            FlushCtrlD = 0;
        end
    end

endmodule

module ForwardforDataHazard(
    input [3:0] ReadAddr1E,
    input [3:0] ReadAddr2E,
    input InvalidRegE, // is ReadAddr2 Invalid?
    input [3:0] WriteAddrM,
    input regWriteM,
    input [3:0] WriteAddrW,
    input regWriteW,
    input IsReadAddr1_ValidE, 
    input IsReadAddr2_ValidE, 

    output reg [1:0] ForwardAE,
    output reg [1:0] ForwardBE
);

    wire match1EM;
    wire match1EW;
    wire match2EM;
    wire match2EW;

    // match(x)E(a) means:
    // if ReadRegister(x) in the state E is same to WriteRegister in the stage (a) 
    // then match(x)E(a) is 1; otherwise it is 0
    assign match1EM = (ReadAddr1E == WriteAddrM) ? 1'b1 : 1'b0;
    assign match1EW = (ReadAddr1E == WriteAddrW) ? 1'b1 : 1'b0;
    assign match2EM = (ReadAddr2E == WriteAddrM) ? 1'b1 : 1'b0;
    assign match2EW = (ReadAddr2E == WriteAddrW) ? 1'b1 : 1'b0;

    // 10: forward from MEM stage to EXE stage
    // 01: forward from WB stage to EXE stage
    // 00: normal operation
    always @(*) begin
        // decide ForwardAE
        begin
            if (match1EM && regWriteM)
                ForwardAE = 2'b10;
            else if (match1EW && regWriteW)
                ForwardAE = 2'b01;
            else
                ForwardAE = 2'b00;
        end

        // decide ForwardBE
 
        begin
  
            if (match2EM && regWriteM)
                ForwardBE = 2'b10;
            else if (match2EW && regWriteW)
                ForwardBE = 2'b01;
            else
                ForwardBE = 2'b00;
        end
    end

endmodule