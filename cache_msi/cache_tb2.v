`timescale 1ns / 100ps

module cache_tb2;



  // Cache Inputs
  reg  [ 7:0] pr_din;
  reg  [ 5:0] pr_addr;
  reg         pr_rd;
  reg         pr_wr;

  // Bus Inputs
  reg  [ 5:0] bus_addr_in;
  reg  [ 2:0] bus_op_in;
  reg         bus_grant;
  wire [15:0] bus_din;
  wire        bus_done_in;

  // Cache Outputs 
  wire [ 7:0] pr_dout;
  wire        pr_done;

  // Bus outputs
  wire [15:0] bus_dout;
  wire        bus_done_out;
  wire        bus_request;
  wire [ 4:0] bus_addr_out;
  wire [ 2:0] bus_op_out;

  reg         clk;
  reg         rst;

  wire        stall;

  localparam 	QInitial	= 		7'b0000001,
			   	QMonitor	=		7'b0000010,
				QFlush =   			7'b0000100,  
				QWB = 				7'b0001000,
			   	QBusRd	=			7'b0010000,
			   	QBusRdX	=			7'b0100000,
			   	QBusUpgr	=		7'b1000000;
  localparam BusNone = 3'b000, BusRd = 3'b001, BusUpgr = 3'b010, BusFlush = 3'b011, BusRdX = 3'b100;

  localparam I = 2'b00, S = 2'b01, M = 2'b11;

  reg [16*8:0] state_string;
  reg [16*8:0] bus_op_out_string;
  reg [16*8:0] bus_op_in_string;

  reg [1:0] rand_cnt;
  wire mem_rd, mem_wr;
  assign mem_rd = (bus_op_out == BusRd || bus_op_out == BusRdX);
  assign mem_wr = (bus_op_out == BusFlush);

  integer i;

  // Instantiate the Unit Under Test (UUT)
  CacheMSI cache (
      .clk(clk),
      .reset(rst),
      .pr_din(pr_din),
      .pr_dout(pr_dout),
      .pr_addr(pr_addr),
      .pr_rd(pr_rd),
      .pr_wr(pr_wr),
      .pr_done(pr_done),
      .bus_din(bus_din),
      .bus_dout(bus_dout),
      .bus_done_in(bus_done_in),
      .bus_done_out(bus_done_out),
      .bus_grant(bus_grant),
      .bus_request(bus_request),
      .bus_addr_in(bus_addr_in[5:1]),
      .bus_addr_out(bus_addr_out),
      .bus_op_in(bus_op_in),
      .bus_op_out(bus_op_out)
  );


  Memory #(
      .INIT_FILE("datamem.txt")
  ) dmem (
      .addr(bus_addr_out),
      .memread(mem_rd),
      .memwrite(mem_wr),
      .wdata(bus_dout),
      .clk(clk),
      .rst(rst),
      .rdata(bus_din),
      .mem_done(bus_done_in)
  );

  always @ (cache.state) // report the state in text format in the waveform
	begin : report_state
    case (cache.state)
      QInitial: state_string = "QInitial ";
      QMonitor: state_string = "QMonitor ";
      QFlush:   state_string = "QFlush ";
      QWB:      state_string = "QWB";
      QBusRd:   state_string = "QBusRd";
      QBusRdX:  state_string = "QBusRdX";
      QBusUpgr: state_string = "QBusUpgr";
      default:  state_string = "Unknown ";

    endcase
  end

  always @ (bus_op_out) // report bus_op_out in text format in the waveform
	begin : report_bus_op_out
    case (bus_op_out)
      BusRd:    bus_op_out_string = "   BusRd   ";
      BusRdX:   bus_op_out_string = "   BusRdX  ";
      BusUpgr:  bus_op_out_string = "   BusUpgr ";
      BusFlush: bus_op_out_string = "   Flush   ";
      default:  bus_op_out_string = "   NONE    ";

    endcase
  end

  always @ (bus_op_in) // report bus_op_in in text format in the waveform
	begin : report_bus_op_in
    case (bus_op_in)
      BusRd:    bus_op_in_string = "   BusRd   ";
      BusRdX:   bus_op_in_string = "   BusRdX  ";
      BusUpgr:  bus_op_in_string = "   BusUpgr ";
      BusFlush: bus_op_in_string = "   Flush   ";
      default:  bus_op_in_string = "   NONE    ";
    endcase
  end

  always #1 clk <= ~clk;

  reg granted;

  always @(posedge clk) begin
    if (rst || rand_cnt == 2'b10) rand_cnt <= 0;
    else rand_cnt <= rand_cnt + 1;

    granted <= 0;
    if (!granted && bus_grant) granted <= 1;
    else if (granted && bus_done_out) granted <= 0;
  end
  always @* begin
    bus_grant <= 0;
    if (granted || (bus_request && rand_cnt == 0 && bus_op_in == BusNone)) bus_grant <= 1;
  end
  initial begin
    $dumpfile("cache_msi.vcd");
    $dumpvars(0, cache_tb2);
    // Initialize Inputs
    clk <= 0;
    rst <= 1;
    i   <= 0;
    #2;
    rst <= 0;
    bus_grant <= 1;
    bus_op_in <= BusNone;
    pr_rd <= 0;
    pr_wr <= 0;
    #2;

    // LW @1; 1   -> Read miss, I to S, busRd
    i <= i + 1;
    pr_addr <= 1;
    pr_rd <= 1;
    #2;
    wait (pr_done && !clk);
    wait (pr_done && clk);

    // SW 12@9;  write miss, clean, S to M, busRdX
    i <= i + 1;
    pr_addr <= 9;
    pr_rd <= 0;
    pr_wr <= 1;
    pr_din <= 12;
    wait (pr_done && !clk);
    wait (pr_done && clk);
    pr_wr <= 0;

    // Remote core bus read on Block 0 -> Not in the cache -> No action  
    i <= i + 1;
    bus_addr_in <= 0;
    bus_op_in <= BusRd;
    wait (!clk);
    wait (clk);
    wait (!clk && cache.state == QMonitor);
    wait (clk);

    bus_op_in <= BusNone;
    wait (!clk);
    wait (clk);


    // Remote core bus read on Block 8 -> mem adrress 8 & 9, M to S, FLUSH to main memory 
    i <= i + 1;  // 4
    bus_addr_in <= 8;
    bus_op_in <= BusRd;
    wait ((cache.msi_state[0] == S));
    wait (!clk);
    wait (clk);

    bus_op_in <= BusNone;
    wait (!clk);
    wait (clk);

    // SW 13@9;  write hit, S to M, busUpgr
    i <= i + 1;  // 5
    pr_addr <= 9;
    pr_rd <= 0;
    pr_wr <= 1;
    pr_din <= 13;

    wait (pr_done && !clk && (cache.msi_state[0] == M));
    wait (pr_done && clk);
    pr_wr <= 0;

    // SW 14@1; dirty write miss -> Flush, 13 -> mem[9], 1-> cache, BusRdX, M
    i <= i + 1;  // 6
    pr_addr <= 1;
    pr_rd <= 0;
    pr_wr <= 1;
    pr_din <= 14;

    wait (pr_done && !clk && (cache.msi_state[0] == M));
    wait (pr_done && clk);
    pr_wr <= 0;

    // Remote Core BusRdX on Block 8 -> Not in the cache -> No action 
    i <= i + 1;  // 7
    bus_addr_in <= 8;
    bus_op_in <= BusRdX;
    wait (!clk);
    wait (clk);
    wait (!clk && cache.state == QMonitor);
    wait (clk);
    bus_op_in <= BusNone;

    // Remote Core BusRdX on Block 0 -> mem address 0 & 1 , M to I, FLUSH
    i <= i + 1;  // 8
    bus_addr_in <= 0;
    bus_op_in <= BusRdX;
    wait ((cache.msi_state[0] == I));
    bus_op_in <= BusNone;
    wait (!clk);
    wait (clk);

    // LW @9; Clean Read miss I->S, busRd, 3 -> Cache.data
    i <= i + 1;  // 9
    pr_addr <= 9;
    pr_rd <= 1;
    pr_wr <= 0;
    wait (pr_done && !clk && (cache.msi_state[0] == S));
    wait (pr_done && clk);

    // LW @9; Hit! NONE
    i <= i + 1;  // 10
    pr_addr <= 9;
    pr_rd <= 1;
    pr_wr <= 0;
    wait (pr_done && !clk && (cache.msi_state[0] == S));
    wait (pr_done && clk);

    pr_addr <= 0;
    pr_rd <= 0;

    // Remote Core BusRdX on Block 8 -> mem address 8 & 9 , S to I
    i <= i + 1;  // 11
    bus_addr_in <= 8;
    bus_op_in <= BusRdX;
    wait ((cache.msi_state[0] == I));

    bus_op_in <= BusNone;
    wait (!clk);
    wait (clk);

    // LW @3 ; Read miss clean I->S, busRd
    i <= i + 1;  // 12
    pr_addr <= 3;
    pr_rd <= 1;
    pr_wr <= 0;
    wait (pr_done && !clk && (cache.msi_state[1] == S));
    wait (pr_done && clk);

    // LW @2 ; Hit!
    i <= i + 1;  // 13
    pr_addr <= 2;
    pr_rd <= 1;
    pr_wr <= 0;
    wait (pr_done && !clk && (cache.msi_state[1] == S));
    wait (pr_done && clk);
    pr_rd <= 0;

    // BusRd @2 ; Shared
    i <= i + 1;  // 14
    bus_addr_in <= 2;
    bus_op_in <= BusRd;
    wait (!clk);
    wait (clk);
    wait (!clk && (cache.msi_state[1] == S));
    wait (clk);
    bus_op_in <= BusNone;
    wait (!clk);
    wait (clk);

    // Remote Core busUpgr on Block 1 -> mem address 2 & 3 , S to I
    i <= i + 1;  // 15
    bus_addr_in <= 2;
    bus_op_in <= BusUpgr;
    wait (!clk && (cache.msi_state[1] == I));
    wait (clk);
    bus_op_in <= BusNone;
    wait (!clk);
    wait (clk);


    // Add your memory accesses here!


    #10 $stop();
  end

endmodule



