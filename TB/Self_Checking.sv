`include "../Design/Moore_NonSeq.sv"
`include "../Design/Moore_OverSeq.sv"
`include "../Design/Mealy_OverSeq.sv"
`include "../Design/Mealy_NonSeq.sv"



module tb_seq_detectors;

  localparam logic [11:0] P = 12'b0000_0100_1000;
  localparam int N_RANDOM   = 200000;

  logic clk = 0, rst = 1, A = 0;
  logic mo_no, mo_ov, me_no, me_ov;

  // ---------------- DUTs (all four share the same stimulus) ----------------
  Moore_Nonover_seq u_mo_no (.A(A), .clk(clk), .rst(rst), .Out(mo_no));
  Moore_Over_seq    u_mo_ov (.A(A), .clk(clk), .rst(rst), .Out(mo_ov));
  Mealy_Nonover_seq u_me_no (.A(A), .clk(clk), .rst(rst), .Out(me_no));
  Mealy_Over_seq    u_me_ov (.A(A), .clk(clk), .rst(rst), .Out(me_ov));

  always #5 clk = ~clk;

  // ---------------- Reference model ----------------
  // Mealy output = match completes with the bit currently on A (same cycle).
  // Moore output = same match, registered one cycle later.
  logic [10:0] h_ov, h_no;   // previous 11 input bits
  int          c_ov, c_no;   // number of valid bits in history
  logic        q_ov, q_no;   // registered hit, expected Moore outputs
  logic        hit_ov, hit_no;
  logic [11:0] w_ov, w_no;

  int errs [4];              // 0 Moore-nonover, 1 Moore-over, 2 Mealy-nonover, 3 Mealy-over
  int hits_ov, hits_no, cycles;

  function automatic string nm(int k);
    case (k)
      0: return "Moore non-overlap";
      1: return "Moore overlap    ";
      2: return "Mealy non-overlap";
      default: return "Mealy overlap    ";
    endcase
  endfunction

  task automatic check(int k, logic got, logic exp);
    if (got !== exp) begin
      errs[k]++;
      if (errs[k] <= 3)
        $display("[%0t] MISMATCH %s: got=%b expected=%b (cycle %0d, A=%b)",
                 $time, nm(k), got, exp, cycles, A);
    end
  endtask

  // Outputs are sampled at the posedge in the active region, i.e. the
  // pre-edge value; stimulus changes on negedge, so there is no race.
  always @(posedge clk) begin
    if (rst) begin
      h_ov = 0; h_no = 0; c_ov = 0; c_no = 0; q_ov = 0; q_no = 0;
    end else begin
      cycles++;
      w_ov = {h_ov, A};  hit_ov = (c_ov >= 11) && (w_ov == P);
      w_no = {h_no, A};  hit_no = (c_no >= 11) && (w_no == P);
      if (hit_ov) hits_ov++;
      if (hit_no) hits_no++;

      check(0, mo_no, q_no);
      check(1, mo_ov, q_ov);
      check(2, me_no, hit_no);
      check(3, me_ov, hit_ov);

      h_ov = w_ov[10:0];  if (c_ov < 11) c_ov++;
      if (hit_no) begin h_no = 0; c_no = 0; end          // non-overlap: restart
      else begin h_no = w_no[10:0]; if (c_no < 11) c_no++; end
      q_ov = hit_ov;
      q_no = hit_no;
    end
  end

  // ---------------- Stimulus helpers ----------------
  task automatic send(input logic b);
    @(negedge clk);
    A = b;
  endtask

  task automatic send_pat();
    for (int i = 11; i >= 0; i--) send(P[i]);
  endtask

  // ---------------- Test sequence ----------------
  int p0;
  initial begin
    for (int k = 0; k < 4; k++) errs[k] = 0;
    hits_ov = 0; hits_no = 0; cycles = 0;

    repeat (3) @(negedge clk);
    rst = 0;

    // 1) one pattern, then a few 1s
    send_pat();  send(1); send(1);

    // 2) back-to-back patterns, no shared bits (catches Moore non-overlap bug)
    send_pat();  send_pat();  send(1); send(1);

    // 3) second pattern shares the trailing 000 (overlap case)
    send_pat();
    send(0); send(0); send(1); send(0); send(0); send(1); send(0); send(0); send(0);
    send(1); send(1);

    // 4) reset in the middle of a pattern: bits 11..4, then the next pattern bit
    //    (P[3]) is presented DURING reset, then bits 2..0. A DUT that ignores
    //    reset would see the full pattern and match; the reference expects none.
    for (int i = 11; i >= 4; i--) send(P[i]);
    @(negedge clk); rst = 1; A = P[3];      // this bit must be ignored (reset cycle)
    @(negedge clk); rst = 0; A = P[2];
    send(P[1]); send(P[0]);
    send(1); send(1);

    // 5) constrained-random stream, 0-bias re-picked every 1000 cycles
    p0 = 70;
    for (int n = 0; n < N_RANDOM; n++) begin
      if (n % 1000 == 0) p0 = $urandom_range(50, 90);
      send(($urandom_range(0, 99) < p0) ? 1'b0 : 1'b1);
    end
    @(negedge clk);

    // ---------------- Report ----------------
    $display("------------------------------------------------------------");
    $display("cycles=%0d  expected matches: overlap=%0d  non-overlap=%0d",
             cycles, hits_ov, hits_no);
    for (int k = 0; k < 4; k++)
      $display("%s : %s (%0d mismatches)", nm(k), errs[k] == 0 ? "PASS" : "FAIL", errs[k]);
    if (hits_ov == 0 || hits_no == 0)
      $display("WARNING: no matches seen, the test is vacuous");
    if (errs[0] + errs[1] + errs[2] + errs[3] == 0 && hits_ov > 0 && hits_no > 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end

endmodule
