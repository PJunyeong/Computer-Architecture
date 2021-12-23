module ExtendMUX(
	 input[23:0] in,
	 input[1:0] ImmSrc,
	 output reg[31:0] ExtImm
	 );
 
	integer i;
	always @ (*)
	begin
		case(ImmSrc)
		2'b00: //signed
		begin
			ExtImm[7:0] = in[7:0];
			for(i=8;i<32;i=i+1)
				ExtImm[i] = in[7];
		end
		2'b01: 
		begin
			ExtImm[11:0] = in[11:0];
			for(i=12;i<32;i=i+1)
				ExtImm[i] = 'b0;
		end
		2'b10: //left shift 2
		begin
			ExtImm[1:0] = 2'b00;
			ExtImm[25:2] = in[23:0];
			for(i=26;i<32;i=i+1)
				ExtImm[i] = in[23];
		end
		default:
			ExtImm = 'h00000000;
		endcase
	end
endmodule

module RegisterFile(
	input clk,
	input reset,
	input we,
	input RegSrcW,
	input[1:0] RegSrc,
	input[3:0] addr1,
	input[3:0] addr2,
	input[3:0] addr3,
	input[3:0] waddr,
	input[31:0] wdata,
	input[31:0] pcin,
	output reg[31:0] data1,
	output reg[31:0] data2,
	output reg[31:0] data3,
	output[31:0] pcout
	);
	
	reg[31:0] registers[15:0];
	integer idx;
	
	assign pcout = registers[15] + 32'd4;
		
	// write to register file
	always @ (negedge clk)
	begin
		if (reset)
		begin
			for(idx=0; idx<=15; idx=idx+1) begin
				registers[idx] = 'h00000000;
			end
		end
		else
		  begin
			if(we)
					registers[waddr] = wdata;
					
					
		
		    if (RegSrcW == 1'b1) registers[15] = pcin;

			else if (waddr != 4'b1111)
			    registers[15] = pcin;	
		end
	end
	
	// read from register file
	always @ (posedge clk)
	begin
		if (reset)
		begin
			data1 <= 'h00000000;
			data2 <= 'h00000000;
		end
		else
	    begin
			if (addr1 == 15) begin
				data1 = registers[15] +32'd8;
			end
			else begin
				if(RegSrc[0] != 1'b1)
					data1 = registers[addr1];
				else
					data1 = registers[15] + 32'd8;
			end
			
			if (addr2 == 15) begin
				data2 = registers[15] + 32'd8;
			end
			else
			begin
				// RegSrc MUX
				//  if (RegSrc[1] == 1'b0)
					data2 = registers[addr2];
				//  else
				//	data2 = registers[waddr];
			end
			if (addr3 == 15) begin
				data3 = registers[15] + 32'd8;
			end
			else begin
				data3 = registers[addr3];
			end
		end
	end

endmodule

module armreduced(
	input clk,
	input reset,
	output[31:0] pc,
	input[31:0] inst,
	input nIRQ,
	output[3:0] be,
	output[31:0] memaddr,
	output memwrite,
	output memread,
	output[31:0] writedata,
	input[31:0] readdata
	);
	
	// Control signals
	wire PCSrcD, PCSrcE, PCSrcM, PCSrcW;
	wire RegWriteD, RegWriteE, RegWriteM, RegWriteW;
	wire MemtoRegD, MemtoRegE, MemtoRegM, MemtoRegW;
	wire MemWriteD, MemWriteE, MemWriteM;
	wire [3:0] ALUControlD, ALUControlE;
	wire BranchD, BranchE, BranchTakenE;
	wire ALUSrcD, ALUSrcE;
	wire FlagWriteD, FlagWriteE;
	wire [1:0] ImmSrcD;
	wire [1:0] RegSrcD;
	wire [3:0] condE;
	wire condEx;
	wire [3:0] NZCV, FlagsE;
	wire newPCSrcE, newRegWriteE, newMemWriteE;
	wire [3:0] ALUFlags;
	wire InvalidRegD, InvalidRegE;

	// signals for hazard
	wire StallF, StallD;
	wire FlushD, FlushE;
	wire FlushCtrlD;
	wire [1:0] ForwardAE, ForwardBE;

	wire[31:0] PCPlus4F, PCBranch;
	wire[31:0] NextPC;
	wire [31:0] PCF;
	
	wire [31:0] ResultW;

	assign be = 4'b1111;

	assign PCBranch = ALUResultE;
	assign NextPC = (BranchTakenE == 1'b1) ? PCBranch : (PCSrcW == 1'b1) ? ResultW : PCPlus4F;
	// PCSrcW => 0s

	RegisterWBIF _RegisterWBIF(.clk(clk), .en(~StallF), .PC(NextPC), .PCF(PCF), .reset(reset));

	wire [31:0] instF;
	wire [31:0] instD;

	assign pc = PCF;
	assign PCPlus4F = PCF + 32'd4;

	RegisterIFID _RegisterIFID(.instF(inst), .clk(clk), .clr(FlushD), .en(~StallD), .instD(instD), .reset(reset));

	wire [1:0] OpcodeD;
	wire [3:0] ReadAddr1, ReadAddr2, WriteAddr, WA3D;
	wire [31:0] ReadData1, ReadData2, ReadData3;
	

	assign OpcodeD = instD[27:26];
	assign ReadAddr1 = instD[19:16];
	assign ReadAddr2 = (RegSrcD[1] == 1'b0) ? instD[3:0] : instD[15:12];
	assign WA3D = instD[15:12];
	
	ctrlSig _ctrlSig(.op(OpcodeD), .funct(instD[25:20]), .ALUOp(ALUControlD), .ImmSrc(ImmSrcD), .RegSrc(RegSrcD),  
		.PCSrc(PCSrcD), .RegWrite(RegWriteD), .MemWrite(MemWriteD), .MemtoReg(MemtoRegD), 
		.ALUSrc(ALUSrcD), .Svalue(FlagWriteD), .Branch(BranchD), .InvalidReg(InvalidRegD));
	wire newPCSrcD;
	assign newPCSrcD = (instD[15:12] == 4'b1111 && instD[24:21] == 4'b1101) ? 1'b1 : 1'b0;
		
	wire[31:0] pcoutD, pcoutE, pcoutM, pcoutW;	
		
	RegisterFile _RegisterFile(.clk(clk), .reset(reset), .we(RegWriteW), .RegSrcW(RegSrcW), .RegSrc(RegSrcD), 
		.addr1(ReadAddr1), .addr2(ReadAddr2), .addr3(WA3D), .waddr(WA3W), .wdata(ResultW), .pcin(PCF), 
		.data1(ReadData1), .data2(ReadData2), .data3(ReadData3), .pcout(pcoutD));
		// pcout??
		// pcin <= PCF (from PCPlus4F)
    wire IsReadAddr1_ValidD;//really it reads this number in case of branch or mov useless.
    wire IsReadAddr2_ValidD; //really it reads this number
    
    assign IsReadAddr1_ValidD = ((instD[25:21] == 4'b1101 && OpcodeD == 2'b00) || BranchD)?  1'b0 : 1'b1;
    assign IsReadAddr2_ValidD = ( RegSrcD[1] == 1'b0 || (OpcodeD == 2'b01 && instD[20] == 1'b1 ) || (instD[25:21] ==4'b1101 &&
    OpcodeD == 2'b00)) ? 1'b1 : 1'b0;


	wire [31:0] ExtImmD;
	ExtendMUX _ExtendMUX(.in(instD[23:0]), .ImmSrc(ImmSrcD), .ExtImm(ExtImmD));

    wire RegSrcE;
	wire [1:0] OpcodeE;
    wire [3:0] ReadAddr1E, ReadAddr2E;
    wire [31:0] ReadData1E, ReadData2E;
    wire [3:0] WA3E, newWA3E;
    wire [31:0] ExtImmE;
	
	RegisterIDEXE _RegisterIDEXE(.ReadAddr1D(ReadAddr1), .ReadAddr2D(ReadAddr2), .OpcodeD(OpcodeD),
		.PCSrcD(newPCSrcD), .RegWriteD(RegWriteD), .MemtoRegD(MemtoRegD), .MemWriteD(MemWriteD),
        .ALUControlD(ALUControlD),.BranchD(BranchD),.ALUSrcD(ALUSrcD),.FlagWriteD(FlagWriteD),
		.CondD(instD[31:28]),.FlagsD(NZCV), .RegSrcD(RegSrcD[0]),
		.ReadData1D(ReadData1), .ReadData2D(ReadData2), .WriteAddress3D(WA3D),
		.ExtImmD(ExtImmD), .IsReadAddr1_ValidD(IsReadAddr1_ValidD), .IsReadAddr2_ValidD(IsReadAddr2_ValidD),
		.pcoutD(pcoutD), .clk(clk), .clr(FlushE), .reset(reset), .flushCtrlSig(FlushCtrlD),

        .ReadAddr1E(ReadAddr1E), .ReadAddr2E(ReadAddr2E), .OpcodeE(OpcodeE),
		.PCSrcE(PCSrcE),.RegWriteE(RegWriteE), .MemtoRegE(MemtoRegE),.MemWriteE(MemWriteE),
		.ALUControlE(ALUControlE),.BranchE(BranchE),.ALUSrcE(ALUSrcE), .FlagWriteE(FlagWriteE),
		.condE(condE),.FlagsE(FlagsE), .RegSrcE(RegSrcE),
		.ReadData1E(ReadData1E),.ReadData2E(ReadData2E),.WriteAddress3E(WA3E),
		.ExtImmE(ExtImmE), .IsReadAddr1_ValidE(IsReadAddr1_ValidE), .IsReadAddr2_ValidE(IsReadAddr2_ValidE), .pcoutE(pcoutE)
    );
	// Except nzcv, flush ctrl sig to zero (flushctrl)

	wire [31:0] WriteDataE, ALUResultE;
    wire [31:0] SrcAE,SrcBE; 
    wire IsReadAddr1_ValidE, IsReadAddr2_ValidE;
    assign  newWA3E = (BranchTakenE) ? 4'd14 : WA3E;
    

    assign SrcAE = (ForwardAE == 2'b00) ? ReadData1E : (ForwardAE == 2'b01) ? ResultW : ALUOutM;
    assign WriteDataE = (ForwardBE == 2'b00) ? ReadData2E :(ForwardBE == 2'b01) ? ResultW : ALUOutM;
    assign SrcBE = (ALUSrcE == 1'b0) ? WriteDataE : ExtImmE;
    
    ALU32bit _ALU32bit (.SrcA(SrcAE), .SrcB(SrcBE), .ALUOp(ALUControlE), .ALUResult(ALUResultE), .ALUFlags(ALUFlags));
	conditionUnit _conditionUnit(.FlagWriteE(FlagWriteE), .condE(condE), .FlagsE(FlagsE), .ALUFlags(ALUFlags), 
		.NZCV(NZCV), .condEx(condEx));

	assign BranchTakenE = BranchE & condEx;
    assign newPCSrcE = PCSrcE & condEx;
    assign newRegWriteE = RegWriteE & condEx;
    assign newMemWriteE = MemWriteE & condEx;
    

	wire [3:0] WA3M;
    wire [31:0] WriteDataM;
    wire [31:0] ALUOutM;
    wire RegSrcM;
    wire BranchTakenM, BranchTakenW;


    RegisterEXEMEM _RegisterEXEMEM(
		.PCSrcE(newPCSrcE),.RegWriteE(newRegWriteE),.MemtoRegE(MemtoRegE),.MemWriteE(newMemWriteE),
        .clk(clk), .reset(reset),
		.ALUResultE(ALUResultE),.WriteDataE(WriteDataE),.WA3E(newWA3E), .RegSrcE(RegSrcE), .pcoutE(pcoutE), .BranchTakenE(BranchTakenE), 

        .PCSrcM(PCSrcM), .RegWriteM(RegWriteM), .MemtoRegM(MemtoRegM), .MemWriteM(MemWriteM), 
        .WriteDataM(WriteDataM),.ALUOutM(ALUOutM), .WA3M(WA3M), .RegSrcM(RegSrcM), .pcoutM(pcoutM), .BranchTakenM(BranchTakenM));
	
	assign memaddr = ALUOutM;
    assign memread = 1'b1; // same to single cycle
    assign memwrite = MemWriteM;
    assign writedata = WriteDataM;

	wire [31:0] ReadDataW, ALUOutW;
	wire [3:0] WA3W;
	wire RegSrcW;

	RegisterMEMWB _RegisterMEMWB(
		.clk(clk),
		.reset(reset),
		.PCSrcM(PCSrcM),
		.RegWriteM(RegWriteM),
		.MemtoRegM(MemtoRegM),
		.ALUOutM(ALUOutM),
		.ReadDataM(readdata),
		.WA3M(WA3M),
		.RegSrcM(RegSrcM),
		.pcoutM(pcoutM),
		.BranchTakenM(BranchTakenM),
		
		.PCSrcW(PCSrcW),
		.RegWriteW(RegWriteW),
		.MemtoRegW(MemtoRegW),
		.ReadDataW(ReadDataW),
		.ALUOutW(ALUOutW),
		.WA3W(WA3W),
		.RegSrcW(RegSrcW),
		.pcoutW(pcoutW),
		.BranchTakenW(BranchTakenW));

	assign ResultW = (BranchTakenW) ? pcoutW : (MemtoRegW == 1'b1) ? ReadDataW : ALUOutW;
    
    
	StallforControlHazard _StallforControlHazard(.newPCSrcE(newPCSrcE), .PCSrcM(PCSrcM), .PCSrcW(PCSrcW), 
	 .BranchTakenE(BranchTakenE), .FlushD(FlushD), .FlushE(FlushE));

    StallforDataHazard _StallforDataHazard(
		.ReadRegister1(ReadAddr1), .ReadRegister2(ReadAddr2),.WriteRegisterE(WA3E),
		.OpcodeE(OpcodeE), .RegWriteE(RegWriteE), .BranchTakenE(BranchTakenE),
		.StallF(StallF),.StallD(StallD),.FlushCtrlD(FlushCtrlD), .IsReadAddr1_ValidE(IsReadAddr1_ValidE),
		.WriteRegisterW(WA3W), .RegWriteW(RegWriteW));

	ForwardforDataHazard _ForwardforDataHazard(
    	.ReadAddr1E(ReadAddr1E), .ReadAddr2E(ReadAddr2E),
		.WriteAddrM(WA3M),.regWriteM(RegWriteM),
    	.WriteAddrW(WA3W), .regWriteW(RegWriteW), 
		.ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
		.IsReadAddr1_ValidE(IsReadAddr1_ValidE), 
        .IsReadAddr2_ValidE(IsReadAddr2_ValidE) 
		);
endmodule

