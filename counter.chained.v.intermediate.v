

module BoundaryScanRegister_input
(
  din,
  dout,
  sin,
  sout,
  clock,
  reset,
  testing,
  shift
);

  input din;
  output dout;
  input sin;
  output sout;
  input clock;input reset;input testing;input shift;
  reg store;

  always @(posedge clock or negedge reset) begin
    if(~reset) begin
      store <= 1'b0;
    end else begin
      store <= (shift)? sin : dout;
    end
  end

  assign sout = store;
  assign dout = (testing)? store : din;

endmodule



module BoundaryScanRegister_output
(
  din,
  dout,
  sin,
  sout,
  clock,
  reset,
  testing,
  shift
);

  input din;
  output dout;
  input sin;
  output sout;
  input clock;input reset;input testing;input shift;
  reg store;

  always @(posedge clock or negedge reset) begin
    if(~reset) begin
      store <= 1'b0;
    end else begin
      store <= (shift)? sin : dout;
    end
  end

  assign sout = store;
  assign dout = din;

endmodule



module \counter.original 
(
  clk,
  rst_n,
  en,
  count,
  sin,
  shift,
  sout,
  tck,
  test
);

  input sin;
  output sout;
  input shift;
  input tck;
  input test;
  wire __clk_source__;
  wire __chain_0__;
  assign __chain_0__ = sin;
  wire _00_;
  wire _01_;
  wire _02_;
  wire _03_;
  wire _04_;
  wire _05_;
  wire _06_;
  wire _07_;
  wire _08_;
  wire _09_;
  wire _10_;
  wire _11_;
  wire _12_;
  wire _13_;
  wire _14_;
  wire _15_;
  wire _16_;
  wire _17_;
  wire _18_;
  wire _19_;
  wire _20_;
  wire _21_;
  wire _22_;
  wire _23_;
  wire _24_;
  wire _25_;
  wire _26_;
  wire _27_;
  input clk;
  output [7:0] count;
  input en;
  input rst_n;

  INVX1
  _28_
  (
    .A(count[6]),
    .Y(_08_)
  );


  INVX1
  _29_
  (
    .A(count[3]),
    .Y(_09_)
  );


  INVX1
  _30_
  (
    .A(count[2]),
    .Y(_10_)
  );


  AND2X1
  _31_
  (
    .A(en),
    .B(count[0]),
    .Y(_11_)
  );


  OAI21X1
  _32_
  (
    .A(en),
    .B(count[0]),
    .C(rst_n),
    .Y(_12_)
  );


  NOR2X1
  _33_
  (
    .A(_11_),
    .B(_12_),
    .Y(_00_)
  );


  AND2X1
  _34_
  (
    .A(count[1]),
    .B(_11_),
    .Y(_13_)
  );


  NAND3X1
  _35_
  (
    .A(en),
    .B(count[1]),
    .C(count[0]),
    .Y(_14_)
  );


  OAI21X1
  _36_
  (
    .A(count[1]),
    .B(_11_),
    .C(rst_n),
    .Y(_15_)
  );


  NOR2X1
  _37_
  (
    .A(_13_),
    .B(_15_),
    .Y(_01_)
  );


  NOR2X1
  _38_
  (
    .A(_10_),
    .B(_14_),
    .Y(_16_)
  );


  OAI21X1
  _39_
  (
    .A(count[2]),
    .B(_13_),
    .C(rst_n),
    .Y(_17_)
  );


  NOR2X1
  _40_
  (
    .A(_16_),
    .B(_17_),
    .Y(_02_)
  );


  NOR3X1
  _41_
  (
    .A(_09_),
    .B(_10_),
    .C(_14_),
    .Y(_18_)
  );


  OAI21X1
  _42_
  (
    .A(count[3]),
    .B(_16_),
    .C(rst_n),
    .Y(_19_)
  );


  NOR2X1
  _43_
  (
    .A(_18_),
    .B(_19_),
    .Y(_03_)
  );


  AND2X1
  _44_
  (
    .A(count[4]),
    .B(_18_),
    .Y(_20_)
  );


  OAI21X1
  _45_
  (
    .A(count[4]),
    .B(_18_),
    .C(rst_n),
    .Y(_21_)
  );


  NOR2X1
  _46_
  (
    .A(_20_),
    .B(_21_),
    .Y(_04_)
  );


  AND2X1
  _47_
  (
    .A(count[5]),
    .B(_20_),
    .Y(_22_)
  );


  NAND3X1
  _48_
  (
    .A(count[5]),
    .B(count[4]),
    .C(_18_),
    .Y(_23_)
  );


  OAI21X1
  _49_
  (
    .A(count[5]),
    .B(_20_),
    .C(rst_n),
    .Y(_24_)
  );


  NOR2X1
  _50_
  (
    .A(_22_),
    .B(_24_),
    .Y(_05_)
  );


  NOR2X1
  _51_
  (
    .A(_08_),
    .B(_23_),
    .Y(_25_)
  );


  OAI21X1
  _52_
  (
    .A(count[6]),
    .B(_22_),
    .C(rst_n),
    .Y(_26_)
  );


  NOR2X1
  _53_
  (
    .A(_25_),
    .B(_26_),
    .Y(_06_)
  );


  OAI21X1
  _54_
  (
    .A(count[7]),
    .B(_25_),
    .C(rst_n),
    .Y(_27_)
  );


  AOI21X1
  _55_
  (
    .A(count[7]),
    .B(_25_),
    .C(_27_),
    .Y(_07_)
  );


  DFFPOSX1
  _56_
  (
    .CLK(__clk_source__),
    .D((shift)? __chain_0__ : _00_),
    .Q(count[0])
  );


  DFFPOSX1
  _57_
  (
    .CLK(__clk_source__),
    .D((shift)? count[0] : _01_),
    .Q(count[1])
  );


  DFFPOSX1
  _58_
  (
    .CLK(__clk_source__),
    .D((shift)? count[1] : _02_),
    .Q(count[2])
  );


  DFFPOSX1
  _59_
  (
    .CLK(__clk_source__),
    .D((shift)? count[2] : _03_),
    .Q(count[3])
  );


  DFFPOSX1
  _60_
  (
    .CLK(__clk_source__),
    .D((shift)? count[3] : _04_),
    .Q(count[4])
  );


  DFFPOSX1
  _61_
  (
    .CLK(__clk_source__),
    .D((shift)? count[4] : _05_),
    .Q(count[5])
  );


  DFFPOSX1
  _62_
  (
    .CLK(__clk_source__),
    .D((shift)? count[5] : _06_),
    .Q(count[6])
  );


  DFFPOSX1
  _63_
  (
    .CLK(__clk_source__),
    .D((shift)? count[6] : _07_),
    .Q(count[7])
  );

  assign sout = count[7];
  assign __clk_source__ = (test)? tck : clk;

endmodule



module counter
(
  clk,
  rst_n,
  en,
  count,
  sin,
  shift,
  sout,
  tck,
  test
);

  input sin;
  output sout;
  input rst_n;
  input shift;
  input tck;
  input test;
  input clk;
  wire __chain_0__;
  assign __chain_0__ = sin;
  input en;
  wire en__dout;
  wire __chain_1__;

  BoundaryScanRegister_input
  __BoundaryScanRegister_input__0__
  (
    .din(en),
    .dout(en__dout),
    .sin(__chain_0__),
    .sout(__chain_1__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  wire __chain_2__;
  output [7:0] count;
  wire [7:0] count_din;
  wire __chain_3__;

  BoundaryScanRegister_output
  __BoundaryScanRegister_output__1__
  (
    .din(count_din[0]),
    .dout(count[0]),
    .sin(__chain_2__),
    .sout(__chain_3__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  wire __chain_4__;

  BoundaryScanRegister_output
  __BoundaryScanRegister_output__2__
  (
    .din(count_din[1]),
    .dout(count[1]),
    .sin(__chain_3__),
    .sout(__chain_4__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  wire __chain_5__;

  BoundaryScanRegister_output
  __BoundaryScanRegister_output__3__
  (
    .din(count_din[2]),
    .dout(count[2]),
    .sin(__chain_4__),
    .sout(__chain_5__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  wire __chain_6__;

  BoundaryScanRegister_output
  __BoundaryScanRegister_output__4__
  (
    .din(count_din[3]),
    .dout(count[3]),
    .sin(__chain_5__),
    .sout(__chain_6__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  wire __chain_7__;

  BoundaryScanRegister_output
  __BoundaryScanRegister_output__5__
  (
    .din(count_din[4]),
    .dout(count[4]),
    .sin(__chain_6__),
    .sout(__chain_7__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  wire __chain_8__;

  BoundaryScanRegister_output
  __BoundaryScanRegister_output__6__
  (
    .din(count_din[5]),
    .dout(count[5]),
    .sin(__chain_7__),
    .sout(__chain_8__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  wire __chain_9__;

  BoundaryScanRegister_output
  __BoundaryScanRegister_output__7__
  (
    .din(count_din[6]),
    .dout(count[6]),
    .sin(__chain_8__),
    .sout(__chain_9__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  wire __chain_10__;

  BoundaryScanRegister_output
  __BoundaryScanRegister_output__8__
  (
    .din(count_din[7]),
    .dout(count[7]),
    .sin(__chain_9__),
    .sout(__chain_10__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );


  \counter.original 
  __uuf__
  (
    .clk(clk),
    .rst_n(rst_n),
    .en(en__dout),
    .shift(shift),
    .tck(tck),
    .test(test),
    .sin(__chain_1__),
    .sout(__chain_2__),
    .count(count_din)
  );

  assign sout = __chain_10__;

endmodule


