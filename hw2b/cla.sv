`timescale 1ns / 1ps

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits internally would generate a carry-out (independent of cin)
 * @param pout whether these 4 bits internally would propagate an incoming carry from cin
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
   // TODO: your code here
   // C2 = G(1-0) | P(1-0) & Cin

   assign cout[0] = gin[0] | (pin[0] & cin);
   assign cout[1] = gin[1] | (pin[1] & gin[0]) | (pin[1] & pin[0] & cin);
   assign cout[2] = gin[2] | (pin[2] & gin[1]) | (pin[2] & pin[1] & gin[0]) | (pin[2] & pin[1] & pin[0] & cin);

   assign gout = gin[3] | (pin[3] & gin[2]) | (pin[3] & pin[2] & gin[1]) | (pin[3] & pin[2] & pin[1] & gin[0]);
   assign pout = pin[3] & pin[2] & pin[1] & pin[0];

endmodule

/** Same as gp4 but for an 8-bit window instead */
module gp8(input wire [7:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [6:0] cout);

   // TODO: your code here
   logic [6:0] cout_temp;

   always_comb begin;
    assign cout_temp[0] = gin[0] | (pin[0] & cin);
    assign cout_temp[1] = gin[1] | (pin[1] & cout_temp[0]);
    assign cout_temp[2] = gin[2] | (pin[2] & cout_temp[1]);
    assign cout_temp[3] = gin[3] | (pin[3] & cout_temp[2]);
    assign cout_temp[4] = gin[4] | (pin[4] & cout_temp[3]);
    assign cout_temp[5] = gin[5] | (pin[5] & cout_temp[4]);
    assign cout_temp[6] = gin[6] | (pin[6] & cout_temp[5]);
   end;

   assign gout = gin[7] | (pin[7] & cout_temp[6]);
   assign pout = (& pin);
   
   assign cout = cout_temp;

endmodule

module cla
  (input wire [31:0]  a, b,
   input wire         cin,
   output wire [31:0] sum);

   // TODO: your code here
   wire [31:0] g ;
   wire [31:0] p;
   wire [30:0] cout;
   wire [4:0] gout;
   wire [4:0] pout;
   reg [31:0] sum_temp;
   genvar i;
   genvar k; 

  // Generates the initial 32 gps
   generate
      for(i = 0; i < 32; i = i +1) begin : gp_initial
         gp1 h1(.a(a[i]),
               .b(b[i]), 
               .g(g[i]),
               .p(p[i]));
      end : gp_initial
   endgenerate 

   // generates the 1st gp8 which take cin input
   gp8 gp8_initial (.gin(g[7:0]),
            .pin(p[7:0]),
            .cin(cin),
            .gout(gout[0]),
            .pout(pout[0]),
            .cout(cout[6:0]));

    // generates the rest of the 3 pg. 
    for(k = 1; k < 4; k = k + 1) begin : gp8_transfer
        gp8 gp8_step (.gin(g[(k+1)*7:k*7]),
        .pin(p[(k+1)*7:k*7]),
        .cin(cout[(k*7)- 1]),
        .gout(gout[k]),
        .pout(pout[k]),
        .cout(cout[((k+1)*7)-1:k*7])
    );
    end : gp8_transfer

   gp4 gp8_end (.gin(g[31:28]),
            .pin(p[31:28]),
            .cin(cout[27]),
            .gout(gout[4]),
            .pout(pout[4]),
            .cout(cout[30:28]));
 
   always_comb begin
   integer j;
      for(j = 0; j < 32; j = j + 1) begin : calculate_sum
         if(j == 0) begin : initial_cin
            sum_temp[j] = a[j] ^ b[j] ^ cin;
         end : initial_cin
         else begin : extract_cout
            sum_temp[j] = a[j] ^ b[j] ^ cout[j-1];
         end : extract_cout
      end : calculate_sum 
   end   

   assign sum = sum_temp;
endmodule
