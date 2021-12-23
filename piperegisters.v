module RegisterIFID(
    input [31:0] instF,
    input clk,
    input clr,
    input en,
    input reset,
    output reg [31:0] instD
);

    // clear if clr == 1
    // refresh the value in NEG edge of the clk
    always @(negedge clk) begin
        if (clr)
            instD <= 32'd0;
        else if (reset)
            instD <= 32'd0;
        else if (en)
            instD <= instF;
        else 
            instD <= instD;
    end

endmodule

module RegisterIDEXE(
    input [3:0]ReadAddr1D,
    input [3:0]ReadAddr2D,
    input [1:0]OpcodeD,
    input PCSrcD,
    input RegWriteD,
    input MemtoRegD,
    input MemWriteD,
    input [3:0] ALUControlD,
    input BranchD,
    input ALUSrcD,
    input FlagWriteD,
    input [3:0] CondD,
    input [3:0] FlagsD,
    input RegSrcD,
    input [31:0] ReadData1D,
    input [31:0] ReadData2D,
    input [3:0] WriteAddress3D,
    input [31:0] ExtImmD,
    input flushCtrlSig,
    input InvalidRegD,
    input IsReadAddr1_ValidD,
    input IsReadAddr2_ValidD,
    input [31:0]pcoutD,

    input clk,
    input clr,
    input reset,
    output reg [3:0] ReadAddr1E,
    output reg [3:0] ReadAddr2E,
    output reg [1:0] OpcodeE,
    output reg PCSrcE,
    output reg RegWriteE,
    output reg MemtoRegE,
    output reg MemWriteE,
    output reg [3:0] ALUControlE,
    output reg BranchE,
    output reg ALUSrcE,
    output reg FlagWriteE,
    output reg [3:0] condE,
    output reg [3:0] FlagsE,
    output reg RegSrcE,
    output reg [31:0] ReadData1E,
    output reg [31:0] ReadData2E,
    output reg [3:0] WriteAddress3E,
    output reg [31:0] ExtImmE,
    output reg InvalidRegE,
    output reg IsReadAddr1_ValidE,
    output reg IsReadAddr2_ValidE,
    output reg [31:0] pcoutE
);

    always @(negedge clk) begin
        if (clr) begin
            ReadAddr1E <= 4'b0;
            ReadAddr2E <= 4'b0;
            OpcodeE <= 2'b0;
            PCSrcE <= 1'b0;
            RegWriteE <= 1'b0;
            MemtoRegE <= 1'b0;
            MemWriteE <= 1'b0;
            ALUControlE <= 4'b0000;
            BranchE <= 1'b0;
            ALUSrcE <= 1'b0;
            FlagWriteE <= 1'b0;
            condE <= 4'b0;
            RegSrcE <= 1'b0;
            ReadData1E <= 32'b0;
            ReadData2E <= 32'b0;
            WriteAddress3E <= 4'b0;
            ExtImmE <= 32'b0;
            InvalidRegE <= 1'b0;
            IsReadAddr1_ValidE <= 1'b0; 
            IsReadAddr2_ValidE <= 1'b0;
            pcoutE <= 32'b0;
            FlagsE <= 4'b0000;

        end
        else if (reset) begin
            ReadAddr1E <= 4'b0;
            ReadAddr2E <= 4'b0;
            OpcodeE <= 2'b0;
            PCSrcE <= 1'b0;
            RegWriteE <= 1'b0;
            MemtoRegE <= 1'b0;
            MemWriteE <= 1'b0;
            ALUControlE <= 4'b0000;
            BranchE <= 1'b0;
            ALUSrcE <= 1'b0;
            FlagWriteE <= 1'b0;
            condE <= 4'b0;
            RegSrcE <= 1'b0;
            FlagsE <= 4'b0;
            ReadData1E <= 32'b0;
            ReadData2E <= 32'b0;
            WriteAddress3E <= 4'b0;
            ExtImmE <= 32'b0;
            InvalidRegE <= 1'b0;
            IsReadAddr1_ValidE <= 1'b0; 
            IsReadAddr2_ValidE <= 1'b0;
            pcoutE <= 32'b0;
            FlagsE <= 4'b0000;

		end
        else begin
            if (flushCtrlSig == 1'b1) begin
                PCSrcE <= 1'b0;
                RegWriteE <= 1'b0;
                MemtoRegE <= 1'b0;
                MemWriteE <= 1'b0;
                ALUControlE <= 4'b0000;
                BranchE <= 1'b0;
                ALUSrcE <= 1'b0;
                FlagWriteE <= 1'b0;
                condE <= 4'b0;     
                RegSrcE <= 1'b0;
                InvalidRegE <= 1'b0;   
                IsReadAddr1_ValidE <= 1'b0; 
                IsReadAddr2_ValidE <= 1'b0;
               // FlagsE <= 4'b0;
 
            end
            else begin
                PCSrcE <= PCSrcD;
                RegWriteE <= RegWriteD;
                MemtoRegE <= MemtoRegD;
                MemWriteE <= MemWriteD;
                ALUControlE <= ALUControlD;
                BranchE <= BranchD;
                ALUSrcE <= ALUSrcD;
                FlagWriteE <= FlagWriteD;
                condE <= CondD;
                RegSrcE <= RegSrcD;
                InvalidRegE <= InvalidRegD;
                IsReadAddr1_ValidE <= IsReadAddr1_ValidD; 
                IsReadAddr2_ValidE <= IsReadAddr2_ValidD; 
            end
            ReadAddr1E <= ReadAddr1D;
            ReadAddr2E <= ReadAddr2D;
            OpcodeE <= OpcodeD;
            ReadData1E <= ReadData1D;
            ReadData2E <= ReadData2D;
            WriteAddress3E <= WriteAddress3D;
            ExtImmE <= ExtImmD;
            pcoutE <= pcoutD;
            FlagsE <= FlagsD;
        end
    end

endmodule

module RegisterEXEMEM(
   input PCSrcE,
   input RegWriteE,
   input MemtoRegE,
   input MemWriteE,
   input clk,
   input reset,
   input [31:0] ALUResultE,
   input [31:0] WriteDataE,
   input [3:0] WA3E,
   input RegSrcE,
   input [31:0]pcoutE,
   input BranchTakenE,
   
   output reg PCSrcM,
   output reg RegWriteM,
   output reg MemtoRegM,
   output reg MemWriteM,
   output reg [3:0] WA3M,
   output reg [31:0] WriteDataM,
   output reg [31:0] ALUOutM,
   output reg RegSrcM,
   output reg [31:0]pcoutM,
   output reg BranchTakenM
   );

   always @ (negedge clk) begin
      if (reset) begin
            PCSrcM <= 1'b0;
            RegWriteM <= 1'b0;
            MemtoRegM <= 1'b0;
            MemWriteM <= 1'b0;
            WA3M <= 4'b0;
            ALUOutM <= 32'b0;
            WriteDataM <= 32'b0;
            RegSrcM <= 1'b0;
            pcoutM <= 32'b0;
            BranchTakenM <= 1'b0;
      end
      else
            PCSrcM <= PCSrcE;
            RegWriteM <= RegWriteE;
            MemtoRegM <= MemtoRegE;
            MemWriteM <= MemWriteE;
            WA3M <= WA3E;
            ALUOutM <= ALUResultE;
            WriteDataM <= WriteDataE;
            RegSrcM <= RegSrcE;
            pcoutM <= pcoutE;
            BranchTakenM <= BranchTakenE;

      end
endmodule

module RegisterMEMWB(
   input clk,
   input reset,
   input PCSrcM,
   input RegWriteM,
   input MemtoRegM,
   input [31:0] ALUOutM,
   input [31:0] ReadDataM,
   input [3:0] WA3M,
   input RegSrcM,
   input [31:0]pcoutM,
   input BranchTakenM,
   
   output reg PCSrcW,
   output reg RegWriteW,
   output reg MemtoRegW,
   output reg [31:0]ReadDataW,
   output reg [31:0] ALUOutW,
   output reg [3:0] WA3W,
   output reg RegSrcW,
   output reg [31:0]pcoutW,
   output reg BranchTakenW
);

 always @ (negedge clk) begin
      if (reset) begin
            PCSrcW <= 1'b0;
            RegWriteW <= 1'b0;
            MemtoRegW <= 1'b0;
            ReadDataW <= 32'b0;
            ALUOutW <= 32'b0;
            WA3W <= 4'b0;
            RegSrcW <= 1'b0;
            pcoutW <= 32'b0;
            BranchTakenW <= 1'b0;
      end
      else
           PCSrcW <= PCSrcM;
           RegWriteW <= RegWriteM;
           MemtoRegW <= MemtoRegM;
           ReadDataW <= ReadDataM;
           ALUOutW <= ALUOutM;
           WA3W <= WA3M;
           RegSrcW <= RegSrcM;
           pcoutW <= pcoutM;
           BranchTakenW <= BranchTakenM;
      end
endmodule

module RegisterWBIF(
    input clk,
    input en,
    input [31:0] PC,
    input reset,
    output reg [31:0] PCF
);
    always @(negedge clk) begin
		if (reset)
			PCF <= 'h00000000;
        else if (en)
            PCF <= PC;
        else
            PCF <= PCF;
    end
endmodule
