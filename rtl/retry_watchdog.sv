// Generic bounded timeout counter for a single outstanding transaction.
// Experimental infrastructure; NOT UCIe normative retry timing.
module retry_watchdog #(
 parameter integer COUNTER_WIDTH=16,
 parameter integer TIMEOUT_CYCLES=32
)(
 input wire clk,rst_n,
 input wire outstanding,
 input wire progress,
 output reg timeout_pulse
);
 reg [COUNTER_WIDTH-1:0] age;
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin age<=0; timeout_pulse<=0; end
  else begin
   timeout_pulse<=0;
   if(!outstanding || progress) age<=0;
   else if(age>=TIMEOUT_CYCLES-1) begin
    age<=0;
    timeout_pulse<=1;
   end else age<=age+1'b1;
  end
 end
endmodule
