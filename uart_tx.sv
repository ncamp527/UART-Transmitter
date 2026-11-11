module uart_tx #(
    parameter int CLK_FREQ  = 50_000_000,   // ext. clock frequency (Hz)
    parameter int BAUD_RATE = 115_200       // baud rate (bits/s)
)(
    input  logic       clk, rst,            // clock, synchronous active-high reset
    input  logic       tx_start,            // cue to start
    input  logic [7:0] tx_data,             // data to transmit
    output logic       tx,                  // output bit
    output logic       tx_busy, tx_done
);
    localparam int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam IDLE = 3'b000, STRT = 3'b001, DATA = 3'b010, STOP = 3'b100, DONE = 3'b111;

    logic [2:0] state, next_state;                  // fsm variables
    logic [$clog2(CLKS_PER_BIT):0] clk_cnt;         // clock counter
    logic [2:0] bit_idx, bit_idx_nxt;               // index of tx_data to be sent, LSB first
    logic [7:0] tx_buf;                             // local copy of tx_data, should it change
    logic ready, xmt, xmt_fin, nextbit, tx_next;    // state behavior

    // state transition logic
    always_comb begin
        case(state)
            IDLE   : next_state =   ready ? STRT : IDLE;
            STRT   : next_state = nextbit ? DATA : STRT;
            DATA   : next_state = xmt_fin ? STOP : DATA;
            STOP   : next_state = nextbit ? DONE : STOP;
            DONE   : next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // state flip-flops with synchronous reset
    always_ff @(posedge clk) begin
        if (rst) begin
            state   <= IDLE;

            clk_cnt <= '0;
            bit_idx <= '0;
            tx_buf  <= '0;

            tx      <= 1'b1;
        end
        else begin
            state   <= next_state;
            tx      <= tx_next;
            bit_idx <= bit_idx_nxt;

            if (ready)   tx_buf  <= tx_data;
            if (tx_busy) clk_cnt <= nextbit ? '0 : clk_cnt + 1;
            else         clk_cnt <= '0;
        end
    end

    // behavior logic
    assign ready   =  tx_start && !tx_busy;
    assign xmt     =    (state == DATA);
    assign xmt_fin = ((bit_idx == 3'b111) && nextbit);
    assign nextbit =  (clk_cnt == CLKS_PER_BIT-1);

    assign bit_idx_nxt = !xmt ? '0 : (nextbit ? bit_idx + 3'd1 : bit_idx);
    assign tx_next     = (next_state == STRT) ? 1'b0 : ((next_state == DATA) ? tx_buf[bit_idx_nxt] : 1'b1);

    // output logic
    assign tx_busy = !(state == IDLE);
    assign tx_done =  (state == DONE);
endmodule
