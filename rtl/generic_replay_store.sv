// Research-only generic outstanding-data store; NOT UCIe replay protocol.
// Captures words, retires oldest, and plays outstanding words in arrival order.
// External controller is responsible for ACK legality, replay request and
// matching retransmissions to transmission decisions.
module generic_replay_store #(parameter integer DATA_WIDTH=64,DEPTH=4)(
 input wire clk,rst_n,
 input wire [DATA_WIDTH-1:0] capture_data,
 input wire capture_valid,output wire capture_ready,
 input wire retire_oldest,request_replay,
 output wire replay_busy,replay_valid,
 input wire replay_ready,
 output wire [DATA_WIDTH-1:0] replay_data,
 output wire [$clog2(DEPTH+1)-1:0] occupancy
);
 localparam integer PTR_W=(DEPTH<2)?1:$clog2(DEPTH);
 localparam integer CNT_W=(DEPTH<2)?1:$clog2(DEPTH+1);
 reg [DATA_WIDTH-1:0] storage[0:DEPTH-1];
 reg [PTR_W-1:0] rd_ptr,wr_ptr,replay_ptr;
 reg [CNT_W-1:0] used,replay_left;
 reg replay_active;
 function [PTR_W-1:0] step_ptr(input [PTR_W-1:0] p);
  begin
   if(p==DEPTH-1) step_ptr=0;
   else step_ptr=p+1'b1;
  end
 endfunction
 wire retire=retire_oldest && used!=0 &&
             !replay_active && !request_replay;
 assign capture_ready=!replay_active && !request_replay &&
              ((used<DEPTH) || retire);
 wire capture=capture_valid && capture_ready;
 assign occupancy=used;
 assign replay_busy=replay_active;
 assign replay_valid=replay_active;
 assign replay_data=replay_active?storage[replay_ptr]:{DATA_WIDTH{1'b0}};
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
   rd_ptr<=0;wr_ptr<=0;replay_ptr<=0;used<=0;replay_left<=0;
   replay_active<=0;
  end else if(replay_active) begin
   if(replay_ready) begin
    if(replay_left==1) begin
     replay_active<=0;replay_left<=0;
    end else begin
     replay_ptr<=step_ptr(replay_ptr);
     replay_left<=replay_left-1'b1;
    end
   end
  end else if(request_replay) begin
   if(used!=0) begin
    replay_active<=1;
    replay_ptr<=rd_ptr;
    replay_left<=used;
   end
  end else begin
   if(capture) begin
    storage[wr_ptr]<=capture_data;
    wr_ptr<=step_ptr(wr_ptr);
   end
   if(retire) rd_ptr<=step_ptr(rd_ptr);
   case({capture,retire})
    2'b10: used<=used+1'b1;
    2'b01: used<=used-1'b1;
    default: used<=used;
   endcase
  end
 end
endmodule
