
module screen_driver (
    input   logic                                   clk_i,
    input   logic                                   rst_i,

    input   calc_pkg::num_t                         num_i,
    input   logic                                   override_shift_amount_i,
    input   logic [2:0]                             new_shift_amount_i,
    output  logic [calc_pkg::NumDigits-1:0][7:0]    display_segments_o,

    output  logic [7:0]                             segments_cathode_o,
    output  logic [calc_pkg::NumDigits-1:0]         segments_anode_o
);


logic [2:0] num_decimal_places;
logic [2:0] shift_amount;

logic signed [31:0] i1;
always_comb begin
    i1 = 'x;
    num_decimal_places = 'x;
    shift_amount = 'x;

    if (override_shift_amount_i) begin
        // TODO: set num_decimal_places
        shift_amount = new_shift_amount_i;
    end else begin
        num_decimal_places = '0;
        for (i1 = calc_pkg::NumDigits-1; i1 >= 0; i1--) begin
            if ((num_i.significand[i1] != 0) && (i1 < calc_pkg::NumDigits-1-num_i.exponent))
                num_decimal_places = calc_pkg::NumDigits-1-num_i.exponent-i1;
        end
        shift_amount = (calc_pkg::NumDigits-1 - num_i.exponent - num_decimal_places);
    end
end

logic signed [31:0] i2;
always_comb begin
    display_segments_o = '0;
    for (i2 = 0; i2 < calc_pkg::NumDigits; i2++) begin
        if (calc_pkg::NumDigits-1 - i2 >= shift_amount)
            display_segments_o[i2] = calc_pkg::bcd2segments(num_i.significand[i2+shift_amount]);
    end
    display_segments_o[num_decimal_places][7] = 1;
end

logic [$clog2(calc_pkg::NumDigits)-1:0] segments_counter_d, segments_counter_q;
logic [calc_pkg::NumDigits-1:0]         segments_anode_d, segments_anode_q;

assign segments_cathode_o = ~display_segments_o[segments_counter_q];
assign segments_anode_o = segments_anode_q;

always_comb begin
    segments_anode_d = {segments_anode_q, segments_anode_q[calc_pkg::NumDigits-1]};
end
always_comb begin
    segments_counter_d = (segments_counter_q + 1);
    if (segments_counter_d == calc_pkg::NumDigits)
        segments_counter_d = 0;
end

always_ff @(posedge clk_i) begin
    if (rst_i) begin
        segments_counter_q <= 0;
        segments_anode_q <= ~(1<<(calc_pkg::NumDigits-1));
    end else begin
        segments_counter_q <= segments_counter_d;
        segments_anode_q <= segments_anode_d;
    end
end

endmodule
