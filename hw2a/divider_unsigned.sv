/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ns

// quotient = dividend / divisor

module divider_unsigned (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);

    // Need total of 33 pair of wires, as
    // one additional for at end of the output
    wire [31:0] wires_dividend[32:0];
    wire [31:0] wires_remainder[32:0];
    wire [31:0] wires_quotient[32:0];  

    // Initial conditions for the iterative process
    assign wires_dividend[0] = i_dividend[31:0];
    assign wires_remainder[0] = 32'b0;
    assign wires_quotient[0] = 32'b0;

    // Generate block to conceptually iterate the division steps
    generate
        for (genvar i = 0; i < 32; i = i + 1) begin : div_loop
            divu_1iter div_iter_step(
                .i_dividend(wires_dividend[i]),
                .i_divisor(i_divisor),
                .i_remainder(wires_remainder[i]),
                .i_quotient(wires_quotient[i]),
                .o_dividend(wires_dividend[i+1]),
                .o_remainder(wires_remainder[i+1]),
                .o_quotient(wires_quotient[i+1])
            );
        end
    endgenerate

    // Final step results are the output of the division process
    assign o_remainder = wires_remainder[32];
    assign o_quotient = wires_quotient[32];

endmodule

module divu_1iter (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    input  wire [31:0] i_remainder,
    input  wire [31:0] i_quotient,
    output wire [31:0] o_dividend,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);
  /*
    for (int i = 0; i < 32; i++) {
        remainder = (remainder << 1) | ((dividend >> 31) & 0x1);
        if (remainder < divisor) {
            quotient = (quotient <<< 1);
        } else {
            quotient = (quotient <<< 1) | 0x1;
            remainder = remainder - divisor;
        }
        dividend = dividend << 1;
    }
    */
    
    // Internal signals for new values
    logic [31:0] new_remainder;
    logic [31:0] new_quotient;
    logic [31:0] next_dividend;

    // Procedural block for computing new values
    always_comb begin
        new_remainder = (i_remainder <<< 1) | ((i_dividend >>> 31) & 32'b1);
        new_quotient = (i_quotient <<< 1);
        if (new_remainder >= i_divisor) begin
            new_quotient = new_quotient | 32'b1;
            new_remainder = new_remainder - i_divisor;
        end

        next_dividend = i_dividend <<< 1;
    end

    // Continuous assignments to output wires
    assign o_dividend = next_dividend;
    assign o_remainder = new_remainder;
    assign o_quotient = new_quotient;

endmodule
