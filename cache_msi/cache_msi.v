`timescale 1ns / 100ps

module CacheMSI (
    input             clk,
    input             reset,
    input      [ 7:0] pr_din,
    output     [ 7:0] pr_dout,
    input      [ 5:0] pr_addr,
    input             pr_rd,
    input             pr_wr,
    output            pr_done,
    input      [15:0] bus_din,
    output reg [15:0] bus_dout,
    input             bus_done_in,
    output reg        bus_done_out,
    input             bus_grant,
    output reg        bus_request,
    input      [ 4:0] bus_addr_in,
    output reg [ 4:0] bus_addr_out,
    input      [ 2:0] bus_op_in,
    output reg [ 2:0] bus_op_out
);

  localparam 	QInitial	= 		7'b0000001,
			   	QMonitor	=		7'b0000010,
				QFlush =   			7'b0000100,  
				QWB = 				7'b0001000,
			   	QBusRd	=			7'b0010000,
			   	QBusRdX	=			7'b0100000,
			   	QBusUpgr	=		7'b1000000;

  localparam BusNone = 3'b000, BusRd = 3'b001, BusUpgr = 3'b010, BusFlush = 3'b011, BusRdX = 3'b100;

  localparam I = 2'b00, S = 2'b01, M = 2'b11;


  reg     [2:0] tag                                                            [0:3];
  reg     [7:0] data                                                           [0:7];
  reg     [1:0] msi_state                                                      [0:3];
  integer       i;

  reg     [1:0] curr_msi_state;  // Dirty, Valid output of selected cache block

  reg     [8:0] state;
  wire          pr_hit;
  wire          pr_req;
  wire          bus_req;
  wire          bus_hit;

  wire    [1:0] pr_cblk;
  wire    [1:0] bus_cblk;
  wire          pr_word;
  wire    [2:0] pr_tag;
  wire    [2:0] bus_tag;
  wire    [4:0] pr_bus_addr;

  // Address breakdown
  assign pr_cblk = pr_addr[2:1];
  assign pr_word = pr_addr[0];
  assign pr_tag = pr_addr[5:3];
  assign pr_bus_addr = pr_addr[5:1];

  assign bus_cblk = bus_addr_in[1:0];
  assign bus_tag = bus_addr_in[4:2];

  assign pr_dout = data[{pr_cblk, pr_word}];

  assign pr_req = (pr_rd || pr_wr);
  assign pr_hit = (tag[pr_cblk] == pr_tag) & msi_state[pr_cblk] != I;
  assign bus_req = bus_op_in != BusNone;
  assign bus_hit = (bus_req) && (msi_state[bus_cblk] != I) && (tag[bus_cblk] == bus_tag);


  // You complete or add more signals
  assign pr_done = pr_req && pr_hit;  // Change this

  wire needToReqBus;
  assign needToReqBus = (~pr_hit) && (pr_req); // Change this: condition for when this processor needs to request use of the bus

  wire needToServiceBusRdX;
  assign needToServiceBusRdX = (bus_hit && bus_op_in == 3'b100); // Change this: condition for when this cache needs to service another's BusRdX

  wire needToServiceBusUpgr;
  assign needToServiceBusUpgr = (bus_hit && bus_op_in == 3'b010); // Change this: condition for when this cache needs to service another's BusUpgr

  // condition A on PDF diagram
  wire needToServiceBusReq;
  assign needToServiceBusReq = (bus_hit && bus_op_in == 3'b001); // Change this: condition for when we need to flush data (condition A)

  // condition B on PDF diagram
  wire startWB;
  assign startWB = ((~pr_hit) && curr_msi_state == M);  // Change this: (condition B)

  // condition C on PDF diagram   
  wire startBusRd;
  assign startBusRd = (~pr_hit) && (pr_rd);  // Change this: (condition C)

  // condition D on PDF diagram
  wire startBusRdX;
  assign startBusRdX = (~pr_hit) && (pr_wr);  // Change this: (condition D)

  // condition E on PDF diagram
  wire startBusUpgr;
  assign startBusUpgr = (pr_hit) && (pr_wr);  // Change this: (condition E)


  // pick MSI state (dirty and valid bit) from currently selected block 
  always @* begin
    if (bus_hit && bus_op_in != BusNone) curr_msi_state = {msi_state[bus_cblk]};
    else curr_msi_state = {msi_state[pr_cblk]};
  end

  // For each state consider any changes necessary to the internal and 
  // output signals:
  //   state, msi_state, tags and data
  // You can access a desired element of the tag, valid, or dirty array 
  //   by using array indexes (e.g. tag[pr_cblk]). 
  // Remember you can concatenate signals like: { data[15:8], pr_data[7:0] }
  always @(posedge clk) begin
    if (reset) begin
      state <= QInitial;
      // reqFlag <= 0;
    end else
      case (state)
        QInitial: begin
          for (i = 0; i < 4; i = i + 1) begin
            tag[i] <= 0;
            msi_state[i] <= I;
          end
          state <= QMonitor;
        end

        QMonitor: begin
          // If no bus requests then service processor requests that can
          // begin handled locally

          if (pr_hit && pr_wr) begin
            data[{pr_cblk, pr_word}] <= pr_din;
            msi_state[pr_cblk] <= M;
          end

          // Code to to invalidate a locally cached block
          if (needToServiceBusUpgr || needToServiceBusRdX) begin
            // Complete this line:  Invalidate the block
            msi_state[bus_cblk] <= I;
          end  // Code for state changes				
          else if (needToServiceBusReq) begin
            state <= QFlush;
          end else if (startWB) begin
            state <= QWB;
          end else if (!startWB && startBusRd) begin
            state <= QBusRd;
          end else if (!startWB && startBusRdX) begin
            state <= QBusRdX;
          end else if (startBusUpgr) begin
            state <= QBusUpgr;
          end

        end
        QFlush: begin
          // Update MSI state of block being flushed, appropriately

          msi_state[bus_cblk] <= S;

          // Code for state changes
          if (startWB) begin
            state <= QWB;
          end else if (!startWB && startBusRd) begin
            state <= QBusRd;
          end else if (!startWB && startBusRdX) begin
            state <= QBusRdX;
          end else if (startBusUpgr) begin
            state <= QBusUpgr;
          end else state <= QMonitor;

        end
        QWB: begin

          if (!bus_done_in) begin
            state <= QWB;
          end else if (startBusRd) begin
            state <= QBusRd;
          end else if (startBusRdX) begin
            state <= QBusRdX;
          end

        end
        QBusRd: begin

          if (!bus_done_in) begin
            state <= QBusRd;
          end else begin
            tag[pr_cblk] <= pr_tag;
            data[{pr_cblk, 1'b1}] <= bus_din[15:8];
            data[{pr_cblk, 1'b0}] <= bus_din[7:0];
            msi_state[pr_cblk] <= S;
            state <= QMonitor;
          end

        end
        QBusRdX: begin

          if (!bus_done_in) begin
            state <= QBusRdX;
          end else begin

            if (pr_word == 1'b1) begin
              data[{pr_cblk, 1'b1}] <= pr_din;
              data[{pr_cblk, 1'b0}] <= bus_din[7:0];
            end else begin
              data[{pr_cblk, 1'b1}] <= bus_din[15:8];
              data[{pr_cblk, 1'b0}] <= pr_din;
            end

            tag[pr_cblk] <= pr_tag;
            msi_state[pr_cblk] <= M;
            state <= QMonitor;
          end

        end
        QBusUpgr: begin
          state <= QMonitor;
        end
      endcase
  end


  // Output function logic
  //   Produce bus outputs:
  //     bus_request, bus_op_out, bus_dout, bus_done_out, and bus_addr_out
  always @* begin
    // Default values

    if (reset) begin
      bus_op_out <= BusNone;
      bus_addr_out <= 5'b00000;
      bus_dout <= 16'h0000;
      bus_request <= 0;
      bus_done_out <= 0;
    end else begin
      case (state)
        QMonitor: begin
          if (needToReqBus) begin
            bus_request <= 1;
          end
        end

        QFlush: begin
          if (needToReqBus) begin
            bus_request <= 1;
          end

          bus_dout <= data[bus_cblk];
          bus_addr_out <= bus_addr_in;
          bus_op_out <= 3'b011;
          bus_done_out <= 1'b1;
          // Add more code to output appropriate signals on the bus

        end

        QWB: begin

          if (bus_grant) begin
            bus_dout <= data[bus_cblk];
            bus_addr_out <= {tag[pr_cblk], pr_cblk};
            bus_op_out <= 3'b011;
            bus_done_out <= 1'b1;
          end

        end

        QBusRd: begin

          if (bus_grant) begin
            bus_addr_out <= pr_bus_addr;
            bus_op_out   <= 3'b001;
          end

        end

        QBusRdX: begin

          if (bus_grant) begin
            bus_addr_out <= pr_bus_addr;
            bus_op_out   <= 3'b100;
          end

        end

        QBusUpgr: begin

          if (bus_grant) begin
            bus_op_out   <= 3'b010;
            bus_addr_out <= pr_bus_addr;
          end

        end

      endcase
    end

  end
endmodule
