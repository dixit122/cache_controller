`timescale 1ns / 100ps

/*
 * 	File:  				ee457_mem.v
 *	Description:  		64*8 Memory
 *	Author: 			Mark Redekopp (Adapted for MSI Cache Lab)
 * 	Revisions:
 *  2009-Mar-18		Initial Release
 */
 
 module Memory 
 (
	input			[4:0]		addr,
	input	 		[15:0]  	wdata,
	input       	   			memread,
	input       	   			memwrite,
	input                       clk,
	input                       rst,
	output reg		[15:0] 		rdata,
	output   					mem_done
	);

	localparam RDWAITSTATES = 9;
	localparam WRWAITSTATES = 2;
	localparam CYCLETIME = 2;	
	parameter INIT_FILE = "datamem.txt";
	integer j;
	reg [7:0] 	mem [0:63];
	reg			WCLK;
	reg [3:0]   cnt;
	reg         running;
	reg         memread_d1;
	reg         memwrite_d1;
	initial
	begin
		for(j=0; j < 64; j=j+1)
		begin
			mem[j] = j;
		end
		$readmemh(INIT_FILE, mem);
	end

	assign mem_done = running && (cnt == 4'b0000) || memwrite;

	always @(posedge clk)
	begin
		memread_d1 <= memread;
		memwrite_d1 <= memwrite;

		if(rst)
		begin
			running <= 0;
			cnt <= 4'b0000;
		end
		if(memread && !running)
		begin
			cnt <= RDWAITSTATES;
			running <= 1;
		end
		else if(cnt > 0)
			cnt <= cnt - 1;
		else if(cnt == 0)
			running <= 0;
		
	end

	always @(posedge clk)
	begin
		if(memwrite)
		begin
			{mem[{addr, 1'b1}], mem[{addr, 1'b0}]} <= wdata;
		end
	end

	
	always @*
	begin
		if(memread && mem_done)
		begin
			rdata <= {mem[{addr, 1'b1}], mem[{addr, 1'b0}]};
		end
	end
	
endmodule
