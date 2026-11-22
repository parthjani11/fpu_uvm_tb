// Code your design here
`default_nettype none

module tt_um_project_fpu #(
    parameter EXP_W = 5,            // exponent width  (default: FP16)
    parameter MAN_W = 10            // mantissa width   (default: FP16)
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] ui_in,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    output wire [7:0] uo_out
);

// Derived constants
localparam WIDTH        = 1 + EXP_W + MAN_W;               // total FP width
localparam BYTES_PER_OP = WIDTH / 8;                        // bytes per operand
localparam TOTAL_BYTES  = 2 * BYTES_PER_OP;                 // a + b
localparam WR_PTR_W     = $clog2(TOTAL_BYTES)  > 0
                        ? $clog2(TOTAL_BYTES)  : 1;         // write-pointer width
localparam RD_PTR_W     = $clog2(BYTES_PER_OP) > 0
                        ? $clog2(BYTES_PER_OP) : 1;         // read-pointer width

// Edge detection - single-stage pipeline (TT mux, same clock domain)
reg [1:0] wr_s, rd_s, st_s;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_s <= 2'b0;  rd_s <= 2'b0;  st_s <= 2'b0;
    end else begin
        wr_s  <= {wr_s[0],  ui_in[0]};
        rd_s  <= {rd_s[0],  ui_in[1]};
        st_s  <= {st_s[0],  ui_in[2]};
    end
end

wire wr_pulse    =  wr_s[0] & ~wr_s[1];
wire start_pulse =  st_s[0] & ~st_s[1];
wire rd_fall     = ~rd_s[0] &  rd_s[1];
wire rd_level    =  rd_s[0];

// Operand registers - NO reset (saves mux cells)
reg [WIDTH-1:0]       a_reg, b_reg, result_reg;
reg [WR_PTR_W-1:0]   wr_ptr;
reg [RD_PTR_W-1:0]   rd_ptr;
reg                   op_reg;
reg                   busy, done_l, err_l, ready, core_start;

// FPU Core instantiation (parameterized, combinational approach)
wire [WIDTH-1:0] core_result;
wire             core_done, core_err;

fpu_core #(
    .EXP_W (EXP_W),
    .MAN_W (MAN_W)
) u_fpu (
    .clk       (clk),
    .rst_n     (rst_n),
    .op_a      (a_reg),
    .op_b      (b_reg),
    .op        (op_reg),
    .start     (core_start),
    .result    (core_result),
    .done      (core_done),
    .err       (core_err)
);

// Byte-write logic - uses synthesisable variable part-select
// Each iteration of the loop is unrolled at elaboration (constant index).
localparam [WR_PTR_W-1:0] BYTES_OFFSET = BYTES_PER_OP[WR_PTR_W-1:0];
localparam [WR_PTR_W-1:0] WR_PTR_LAST  = TOTAL_BYTES[WR_PTR_W-1:0] - 1'b1;

integer wi;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (wi = 0; wi < BYTES_PER_OP; wi = wi + 1) begin
                a_reg[wi*8 +: 8] <= 'd0;
                b_reg[wi*8 +: 8] <= 'd0;
            end
        end
        else if (!busy && wr_pulse && !(start_pulse && ready)) begin
            for (wi = 0; wi < BYTES_PER_OP; wi = wi + 1) begin
                if (wr_ptr == wi[WR_PTR_W-1:0])
                    a_reg[wi*8 +: 8] <= uio_in;
                if (wr_ptr == (BYTES_OFFSET + wi[WR_PTR_W-1:0]))
                    b_reg[wi*8 +: 8] <= uio_in;
            end
        end
end

// Control FSM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr     <= {WR_PTR_W{1'b0}};
        rd_ptr     <= {RD_PTR_W{1'b0}};
        op_reg     <= 1'b0;
        busy       <= 1'b0;
        done_l     <= 1'b0;
        err_l      <= 1'b0;
        ready      <= 1'b0;
        core_start <= 1'b0;
        result_reg <= {WIDTH{1'b0}};
    end else begin
        core_start <= 1'b0;                          // default: 1-cycle pulse

        if (busy) begin
            // LOCKED - ignore user inputs while core computes
            if (!core_start && (core_done || core_err)) begin
                busy       <= 1'b0;
                done_l     <= core_done;
                err_l      <= core_err;
                result_reg <= core_result;
            end
        end else begin
            if (start_pulse && ready) begin
                op_reg     <= ui_in[3];
                core_start <= 1'b1;
                busy       <= 1'b1;
                done_l     <= 1'b0;
                err_l      <= 1'b0;
                rd_ptr     <= {RD_PTR_W{1'b0}};
            end
            else if (wr_pulse) begin
                wr_ptr <= wr_ptr + {{(WR_PTR_W-1){1'b0}}, 1'b1};
                ready  <= (wr_ptr == WR_PTR_LAST);  // ready after last byte
            end
            else if (rd_fall) begin
                rd_ptr <= rd_ptr + {{(RD_PTR_W-1){1'b0}}, 1'b1};
            end
        end
    end
end

// Byte-read mux (safe for all widths, including FP8 where only 1 byte)
reg [7:0] rd_byte;
integer ri;
always @(*) begin
    rd_byte = result_reg[7:0];                       // default: lowest byte
    for (ri = 1; ri < BYTES_PER_OP; ri = ri + 1) begin
        if (rd_ptr == ri[RD_PTR_W-1:0])
            rd_byte = result_reg[ri*8 +: 8];
    end
end

// Output assignments
assign uio_oe  = (rd_level && !busy) ? 8'hFF : 8'h00;
assign uio_out = rd_byte;

assign uo_out[0] = busy;
assign uo_out[1] = done_l;
assign uo_out[2] = err_l;
assign uo_out[3] = ready;

// Show write-pointer on uo_out[7:4] (up to 4 bits)
generate
    if (WR_PTR_W >= 4) begin : gen_wrptr_wide
        assign uo_out[7:4] = wr_ptr[3:0];
    end else begin : gen_wrptr_narrow
        assign uo_out[7:4] = {{(4-WR_PTR_W){1'b0}}, wr_ptr};
    end
endgenerate

// Tie off unused inputs
wire _unused = &{ena, ui_in[7:4], 1'b0};

endmodule
`default_nettype none

module fpu_core #(
    parameter EXP_W = 5,            // exponent width
    parameter MAN_W = 10,           // mantissa width (excluding hidden bit)
    localparam WIDTH = 1 + EXP_W + MAN_W // total bit-width
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire               start,      // Assert when valid operands + opcode are ready
    input  wire               op,         // 0 = ADD, 1 = SUB
    input  wire [WIDTH-1:0]   op_a,
    input  wire [WIDTH-1:0]   op_b,
    output reg  [WIDTH-1:0]   result,
    output reg                done,       // Done flag
    output reg                err         // Error flag
);

    // Derived parameters
    localparam MAN_FULL  = MAN_W + 1;                   // mantissa + hidden bit
    localparam SUM_W     = MAN_W + 2;                   // carry + hidden + mantissa
    localparam LZ_W      = $clog2(MAN_FULL + 1) > 0    // leading-zero counter width
                         ? $clog2(MAN_FULL + 1) : 1;
    localparam [EXP_W-1:0] EXP_INF = {EXP_W{1'b1}};   // all-ones exponent (inf/nan)
    localparam [EXP_W-1:0] EXP_MAX = EXP_INF - 1'b1;   // max normal exponent

    // FSM states
    localparam S_IDLE      = 2'd0;
    localparam S_SPECIAL   = 2'd1;
    localparam S_OPERATION = 2'd2;

    // Swap / sign handling
    wire sign_eff = op_b[WIDTH-1] ^ op;                 // SUB = ADD with B's sign flipped
    wire a_bigger = (op_a[WIDTH-2:0] >= op_b[WIDTH-2:0]);

    wire sign_big   = a_bigger ? op_a[WIDTH-1] : sign_eff;
    wire sign_small = a_bigger ? sign_eff      : op_a[WIDTH-1];

    wire [EXP_W-1:0] exp_big   = a_bigger ? op_a[WIDTH-2:MAN_W] : op_b[WIDTH-2:MAN_W];
    wire [EXP_W-1:0] exp_small = a_bigger ? op_b[WIDTH-2:MAN_W] : op_a[WIDTH-2:MAN_W];
    wire [MAN_W-1:0] mant_big   = a_bigger ? op_a[MAN_W-1:0] : op_b[MAN_W-1:0];
    wire [MAN_W-1:0] mant_small = a_bigger ? op_b[MAN_W-1:0] : op_a[MAN_W-1:0];

    wire sub_operation = sign_big ^ sign_small;         // 1 = subtract magnitudes

    // Mantissa with hidden bit
    wire [MAN_FULL-1:0] m_big   = {1'b1, mant_big};
    wire [MAN_FULL-1:0] m_small = {1'b1, mant_small};

    // Alignment: barrel-shift smaller mantissa right by exponent diff
    // (if diff >= MAN_FULL the shifted mantissa becomes zero - correct)
    wire [EXP_W-1:0]    exp_diff        = exp_big - exp_small;
    wire [MAN_FULL-1:0] m_small_aligned = m_small >> exp_diff;

    // Add / Subtract
    wire [SUM_W-1:0] mant_sum = sub_operation
        ? {1'b0, m_big} - {1'b0, m_small_aligned}
        : {1'b0, m_big} + {1'b0, m_small_aligned};

    // Leading-zero count (priority encoder, combinational)
    // Scans from LSB to MSB; last match wins → gives leading-zero count.
    function [LZ_W-1:0] leading_zeroes;
        input [MAN_FULL-1:0] x;
        integer i;
        begin
            leading_zeroes = MAN_W[LZ_W-1:0];          // default: all zeros
            for (i = 0; i < MAN_FULL; i = i + 1)
                if (x[i]) leading_zeroes = MAN_W[LZ_W-1:0] - i[LZ_W-1:0];
        end
    endfunction

    wire [LZ_W-1:0]    lz = leading_zeroes(mant_sum[MAN_FULL-1:0]);

    /* verilator lint_off UNUSEDSIGNAL */
    wire [MAN_FULL-1:0] mant_norm = mant_sum[MAN_FULL-1:0] << lz;
    /* verilator lint_on UNUSEDSIGNAL */

    // Extend lz to exponent width for safe comparison and subtraction
    wire [EXP_W-1:0] lz_ext = {{(EXP_W-LZ_W){1'b0}}, lz};

    // FSM
    reg [1:0] ps, ns;

    // Present-state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ps <= S_IDLE;
        else        ps <= ns;
    end

    // Next-state + output logic (combinational)
    always @(*) begin
        ns     = ps;
        result = {WIDTH{1'b0}};
        done   = 1'b0;
        err    = 1'b0;

        case (ps)
            S_IDLE: begin
                if (start) ns = S_SPECIAL;
            end

            S_SPECIAL: begin
                // --- Infinity / NaN (exponent = all ones) ---
                if ((exp_big == EXP_INF) || (exp_small == EXP_INF)) begin
                    err  = 1'b1;
                    done = 1'b1;
                    ns   = S_IDLE;
                end
                // --- Denormalized numbers → error ---
                else if (((exp_big   == {EXP_W{1'b0}}) && (mant_big   != {MAN_W{1'b0}})) ||
                         ((exp_small == {EXP_W{1'b0}}) && (mant_small != {MAN_W{1'b0}}))) begin
                    err  = 1'b1;
                    done = 1'b1;
                    ns   = S_IDLE;
                end
                // --- Smaller operand is zero ---
                else if ((exp_small == {EXP_W{1'b0}}) && (mant_small == {MAN_W{1'b0}})) begin
                    result = {sign_big, exp_big, mant_big};
                    done   = 1'b1;
                    ns     = S_IDLE;
                end
                else begin
                    ns = S_OPERATION;
                end
            end

            S_OPERATION: begin
                done = 1'b1;
                ns   = S_IDLE;

                // Carry-out from addition → shift right 1, exponent + 1
                if (mant_sum[SUM_W-1]) begin
                    if (exp_big == EXP_MAX)
                        result = {sign_big, EXP_INF, {MAN_W{1'b0}}};       // overflow
                    else
                        result = {sign_big, exp_big + 1'b1, mant_sum[MAN_FULL-1:1]};
                end
                // Exact cancellation → +0
                else if (mant_sum[MAN_FULL-1:0] == {MAN_FULL{1'b0}})
                    result = {WIDTH{1'b0}};
                // Underflow - lz exceeds available exponent room
                else if (lz_ext >= exp_big)
                    result = {sign_big, {(WIDTH-1){1'b0}}};
                // Left-normalise
                else
                    result = {sign_big, exp_big - lz_ext, mant_norm[MAN_W-1:0]};
            end

            default: ns = S_IDLE;
        endcase
    end

endmodule
