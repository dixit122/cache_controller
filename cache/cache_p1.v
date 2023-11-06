
`timescale 1ns / 1ns
module Cache (
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
    input             bus_done,
    output reg        bus_rd,
    output reg        bus_wr,
    output reg [ 4:0] bus_addr,
    output     [ 2:0] temp,
    output            pr_tag_eq,
    output reg        in_side
);

  reg     [2:0] tag         [0:3];
  reg     [7:0] data        [0:7];
  reg     [3:0] valid;
  reg     [3:0] dirty;
  integer       i;

  reg     [3:0] state;
  wire          hit;
  wire    [1:0] pr_cblk;
  wire          pr_word;
  wire    [2:0] pr_tag;
  wire    [4:0] pr_bus_addr;


  // Address breakdown
  assign pr_cblk = pr_addr[2:1];
  assign pr_word = pr_addr[0];
  assign pr_tag = pr_addr[5:3];
  assign pr_bus_addr = pr_addr[5:1];

  localparam QInitial = 4'b0001, QMonitor = 4'b0010, QWB = 4'b0100, QFetch = 4'b1000;
	
  // Completed...You may change if needed but we recommend keeping this
  assign req = (pr_rd || pr_wr);
  assign pr_done = req & hit;
  assign temp = tag[pr_cblk];

  assign pr_tag_eq = tag[pr_cblk] == pr_tag;


  // You complete (change the assignments below to the appropriate logic)
  assign hit = (pr_tag == tag[pr_cblk]) && (valid[pr_cblk] == 1'b1);
  assign pr_dout = data[{pr_cblk, pr_word}];

  // For each state consider any changes necessary to the registered signals:
  //   state, valid and dirty bits, tags and data
  // You can access a desired element of the tag, valid, or dirty array by  
  //   using array indexes (e.g. tag[pr_cblk]). 
  // Remember you can concatenate signals like:  { data[15:8], pr_data[7:0] } 
  always @(posedge clk) begin
    if (reset) state <= QInitial;
    else
      case (state)
        QInitial: begin
          valid <= 4'b0000;
          dirty <= 4'b0000;
          for (i = 0; i < 4; i = i + 1) tag[i] <= 0;

          state <= QMonitor;
        end
        QMonitor: begin

          if ((pr_tag == tag[pr_cblk]) && (valid[pr_cblk] == 1'b1) && pr_wr) begin

            in_side <= 1'b1;
            data[{pr_cblk, pr_word}] <= pr_din;
            dirty[pr_cblk] <= 1'b1;

          end else if (!hit) begin

            in_side <= 1'b0;
            if (dirty[pr_cblk] == 1'b1) begin
              state <= QWB;
            end else begin
              state <= QFetch;
            end

          end else begin
            state   <= QMonitor;
            in_side <= 1'b0;
          end


        end
        // Hint: you only need to update signals when the WB is complete 
        QWB: begin

          in_side <= 1'b0;

          if (bus_done == 1'b1) begin
            state <= QFetch;
          end else begin
            state <= QWB;
          end

        end

        // Hint: you only need to update signals when the fetch is complete 
        QFetch: begin

          in_side <= 1'b0;

          if (bus_done == 1'b1) begin

            state <= QMonitor;
            tag[pr_cblk] <= pr_tag;
            valid[pr_cblk] <= 1'b1;

            if (pr_wr) begin
              dirty[pr_cblk] <= 1'b1;

              if (pr_word == 1'b0) begin
                data[{pr_cblk, 1'b0}] <= pr_din;
                data[{pr_cblk, 1'b1}] <= bus_din[15:8];
              end else begin
                data[{pr_cblk, 1'b0}] <= bus_din[7:0];
                data[{pr_cblk, 1'b1}] <= pr_din;
              end

            end else if (pr_rd) begin

              dirty[pr_cblk] <= 1'b0;
              data[{pr_cblk, 1'b0}] <= bus_din[7:0];
              data[{pr_cblk, 1'b1}] <= bus_din[15:8];

            end

          end else begin
            state <= QFetch;
          end

        end

      endcase
  end

  // Output Function Logic
  // Produce the bus/memory signals:
  //    bus_rd, bus_wr, bus_dout, and bus_addr
  always @* begin
    case (state)
      QInitial: begin
        bus_rd   <= 0;
        bus_wr   <= 0;
        bus_addr <= 5'b0;
        bus_dout <= 16'b0;
      end

      QMonitor: begin

        bus_rd <= 1'b0;
        bus_wr <= 1'b0;

      end

      QWB: begin

        bus_rd   <= 1'b0;
        bus_wr   <= 1'b1;
        bus_addr <= {tag[pr_cblk], pr_cblk};
        bus_dout <= {data[{pr_cblk, 1'b1}], data[{pr_cblk, 1'b0}]};

      end
      QFetch: begin

        bus_rd   <= 1'b1;
        bus_wr   <= 1'b0;
        bus_addr <= pr_bus_addr;

      end
    endcase
  end
endmodule
