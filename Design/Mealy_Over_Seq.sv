module Mealy_Over_seq(
  input logic A, clk, rst,
  output logic Out
); // Mealy and Overlapping
  
  
  typedef enum bit [3:0] {
    S0 = 0, S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11
  } State;
  State CS, NS;
  
  always_ff @(posedge clk) begin
    if(rst) CS <= S0; 
    else CS <= NS;  
  end
  
  always_comb begin
    case (CS)
      S0: NS = A ? S0 : S1; 
      S1: NS = A ? S0 : S2; 
      S2: NS = A ? S0 : S3; 
      S3: NS = A ? S0 : S4; 
      S4: NS = A ? S0 : S5; 
      S5: NS = A ? S6 : S5; 
      S6: NS = A ? S0 : S7; 
      S7: NS = A ? S0 : S8; 
      S8: NS = A ? S9 : S3; 
      S9: NS = A ? S0 : S10; 
      S10: NS = A ? S0 : S11;
      S11: NS = A ? S0 : S3;
      default: NS = S0;
    endcase
  end
  assign Out = ((CS == S11) && (A == 0))? 1:0;
endmodule
