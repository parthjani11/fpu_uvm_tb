class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_tlm_analysis_fifo#(sequence_item) in_fifo1;
    uvm_tlm_analysis_fifo#(sequence_item) out_fifo1;

    logic [31:0] operands;
    logic [15:0] result;
    logic [15:0] result_out;
    logic        opcode;

    // Protocol & synchronizer tracking state
    int         wr_ptr_idx       = 0;
    int         byte_count       = 0;
    int         busy_cycles      = 0;
    bit         wr_chk_pending   = 0;
    bit         busy_chk_pending = 0;
    bit         ign_start_chk    = 0;
    bit         pre_start_done   = 0;
    bit         exp_ready        = 0;
    bit         in_compute       = 0;
    bit         expect_err       = 0;
    bit         expect_special   = 0;
    bit         prev2_write_en   = 0;
    bit         prev2_start_en   = 0;
    logic [7:0] prev_uio_oe      = 8'h00;

    int pass = 0, fail = 0;
    real operand_a, operand_b, result_real;

    function new(string name="scoreboard", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      in_fifo1  = new("in_fifo1", this);
      out_fifo1 = new("out_fifo1", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
      sequence_item in_trans, out_trans, prev_trans;
      prev_trans = sequence_item::type_id::create("prev_trans");
      prev_trans.ui_in  = 8'h00;
      prev_trans.uo_out = 8'h00;

      forever begin
        in_fifo1.get(in_trans);
        out_fifo1.get(out_trans);

        // ---------------------------------------------------------
        // 0. RESET & PRE-RESET CHECK (TC 1, TC 26)
        // ---------------------------------------------------------
        if (in_trans.rst_n !== 1'b1) begin
          wr_ptr_idx        = 0;
          byte_count        = 0;
          busy_cycles       = 0;
          wr_chk_pending    = 0;
          busy_chk_pending  = 0;
          ign_start_chk     = 0;
          exp_ready         = 0;
          in_compute        = 0;
          prev2_write_en    = 0;
          prev2_start_en    = 0;
          prev_uio_oe       = 8'h00;
          prev_trans.ui_in  = 8'h00;
          prev_trans.uo_out = 8'h00;

          if (in_trans.rst_n === 1'b0) begin
            if (out_trans.uo_out !== 8'h00 || out_trans.uio_out !== 8'h00 || out_trans.uio_oe !== 8'h00) begin
              fail++;
              `uvm_error("SCB_RST", $sformatf("Reset outputs non-zero! uo_out=%h uio_out=%h uio_oe=%h",
                         out_trans.uo_out, out_trans.uio_out, out_trans.uio_oe))
            end
          end
        end
        else begin

          // ---------------------------------------------------------
          // 1. BIDIRECTIONAL OE CHECK (Clarification 3 & 7, TC 9)
          // ---------------------------------------------------------
          if (prev_trans.ui_in[1] == 1'b1 && out_trans.uo_out[0] == 1'b0) begin
            if (out_trans.uio_oe !== 8'hFF) begin
              fail++;
              `uvm_error("SCB_OE", $sformatf("Expected uio_oe=FF during read, got %h", out_trans.uio_oe))
            end
          end else begin
            if (out_trans.uio_oe !== 8'h00) begin
              fail++;
              `uvm_error("SCB_OE", $sformatf("Expected uio_oe=00 outside read, got %h", out_trans.uio_oe))
            end
          end

          // ---------------------------------------------------------
          // 2. LOADING PHASE: Check wr_ptr & ready (Clarifications 1, 2, 4)
          // ---------------------------------------------------------
          if (wr_chk_pending) begin
            wr_chk_pending = 0;
            if (out_trans.uo_out[7:4] !== wr_ptr_idx[3:0]) begin
              fail++;
              `uvm_error("SCB_WR", $sformatf("wr_ptr mismatch! Actual=%0d Expected=%0d",
                         out_trans.uo_out[7:4], wr_ptr_idx))
            end
            if (out_trans.uo_out[3] !== exp_ready) begin
              fail++;
              `uvm_error("SCB_RDY", $sformatf("ready mismatch! Actual=%b Expected=%b (wr_ptr=%0d)",
                         out_trans.uo_out[3], exp_ready, wr_ptr_idx))
            end
          end

          // Synchronized write event: 1 cycle after external wr_en rising edge (Clarification 1)
          if (prev_trans.ui_in[0] == 1'b1 && !prev2_write_en && out_trans.uo_out[0] == 1'b0) begin
            case (wr_ptr_idx)
              0: operands[7:0]   = in_trans.uio_in;
              1: operands[15:8]  = in_trans.uio_in;
              2: operands[23:16] = in_trans.uio_in;
              3: operands[31:24] = in_trans.uio_in;
            endcase
            wr_ptr_idx     = (wr_ptr_idx + 1) % 4;
            exp_ready      = (wr_ptr_idx == 0); // Matches Table 6.2.2 & Sec 10.1 waveform
            wr_chk_pending = 1;
          end

          // ---------------------------------------------------------
          // 3A. IGNORED START CHECK (TC 19 & TC 25 when ready == 0)
          // ---------------------------------------------------------
          if (ign_start_chk) begin
            ign_start_chk = 0;
            if (out_trans.uo_out[0] !== 1'b0 || out_trans.uo_out[1] !== pre_start_done) begin
              fail++;
              `uvm_error("SCB_IGN_ST", $sformatf("Start while ready=0 was NOT ignored! busy=%b done=%b (prev_done=%b)",
                         out_trans.uo_out[0], out_trans.uo_out[1], pre_start_done))
            end else begin
              pass++;
              `uvm_info("SCB", "Start while ready=0 cleanly ignored (busy=0, done unchanged)", UVM_LOW)
            end
          end

          // ---------------------------------------------------------
          // 3B. COMPUTATION PHASE: busy, done, error & latency (Clarification 5)
          // ---------------------------------------------------------
          if (busy_chk_pending) begin
            busy_chk_pending = 0;
            if (out_trans.uo_out[0] !== 1'b1) begin
              fail++;
              `uvm_error("SCB_BUSY", "busy (uo_out[0]) did not assert after synchronized start!")
            end
            if (out_trans.uo_out[1] !== 1'b0) begin
              fail++;
              `uvm_error("SCB_DONE_CLR", "done (uo_out[1]) did not clear on new start pulse!")
            end
            in_compute  = 1;
            busy_cycles = 1;
          end
          else if (in_compute) begin
            if (out_trans.uo_out[0] == 1'b1) begin
              busy_cycles++;
            end else begin
              in_compute = 0;
              if (out_trans.uo_out[1] !== 1'b1) begin
                fail++;
                `uvm_error("SCB_DONE", "busy dropped without done (uo_out[1]) asserting!")
              end
              if (out_trans.uo_out[2] !== expect_err) begin
                fail++;
                `uvm_error("SCB_ERR", $sformatf("error flag mismatch! Actual=%b Expected=%b (A=%h B=%h)",
                           out_trans.uo_out[2], expect_err, operands[15:0], operands[31:16]))
              end
              if (expect_special && busy_cycles != 2) begin
                fail++;
                `uvm_error("SCB_LAT", $sformatf("Special-case busy=%0d cycles (expected 2 / 3 from sync start)", busy_cycles))
              end else if (!expect_special && busy_cycles != 3) begin
                fail++;
                `uvm_error("SCB_LAT", $sformatf("Normal-case busy=%0d cycles (expected 3 / 4 from sync start)", busy_cycles))
              end
            end
          end

          // Synchronized start event: 1 cycle after external start rising edge (Clarifications 5 & 6)
          if (prev_trans.ui_in[2] == 1'b1 && !prev2_start_en && out_trans.uo_out[0] == 1'b0) begin
            if (out_trans.uo_out[3] == 1'b0) begin
              pre_start_done = out_trans.uo_out[1];
              ign_start_chk  = 1;
            end else begin
              logic [4:0] exp_a, exp_b;
              logic [9:0] frac_a, frac_b;
              bit a_is_zero, b_is_zero, a_is_den, b_is_den, a_is_inf_nan, b_is_inf_nan;

              exp_a  = operands[14:10];
              exp_b  = operands[30:26];
              frac_a = operands[9:0];
              frac_b = operands[25:16];
              a_is_zero    = (exp_a == 5'h00 && frac_a == 10'h0);
              b_is_zero    = (exp_b == 5'h00 && frac_b == 10'h0);
              a_is_den     = (exp_a == 5'h00 && frac_a != 10'h0);
              b_is_den     = (exp_b == 5'h00 && frac_b != 10'h0);
              a_is_inf_nan = (exp_a == 5'h1F);
              b_is_inf_nan = (exp_b == 5'h1F);

              opcode           = in_trans.ui_in[3]; // Sampled on synchronized start edge (Clarification 6)
              busy_chk_pending = 1;
              byte_count       = 0;

              // Reference Model
              if (a_is_inf_nan || b_is_inf_nan || a_is_den || b_is_den) begin
                expect_err     = 1;
                expect_special = 1;
                result         = 16'h0000;
              end
              else if (a_is_zero && b_is_zero) begin
                expect_err     = 0;
                expect_special = 1;
                result         = operands[15:0];
              end
              else if (a_is_zero) begin
                expect_err     = 0;
                expect_special = 1;
                result         = {operands[31] ^ opcode, operands[30:16]};
              end
              else if (b_is_zero) begin
                expect_err     = 0;
                expect_special = 1;
                result         = operands[15:0];
              end
              else begin
                int exp_big, exp_out;
                logic [10:0] man_a, man_b;
                logic [31:0] bits32;

                expect_err     = 0;
                expect_special = 0;

                exp_big = (exp_a >= exp_b) ? exp_a : exp_b;
                man_a   = {1'b1, frac_a};
                man_b   = {1'b1, frac_b};

                if (exp_a >= exp_b) man_b = man_b >> (exp_a - exp_b);
                else                man_a = man_a >> (exp_b - exp_a);

                operand_a   = (operands[15] ? -1.0 : 1.0) * (real'(man_a) / 1024.0) * (2.0 ** (exp_big - 15));
                operand_b   = (operands[31] ? -1.0 : 1.0) * (real'(man_b) / 1024.0) * (2.0 ** (exp_big - 15));
                result_real = (opcode == 1'b0) ? (operand_a + operand_b) : (operand_a - operand_b);

                bits32  = $shortrealtobits(shortreal'(result_real));
                exp_out = bits32[30:23] - 127 + 15;

                if (result_real == 0.0) begin
                  result = 16'h0000;
                end else if (exp_out >= 31) begin
                  result = {bits32[31], 5'h1f, 10'h0};
                end else if (exp_out <= 0) begin
                  result = {bits32[31], 15'h0000};
                end else begin
                  result[15]    = bits32[31];
                  result[14:10] = exp_out[4:0];
                  result[9:0]   = bits32[22:13];
                end
              end
            end
          end

          // ---------------------------------------------------------
          // 4. READING PHASE: Gate readout strictly on uio_oe == 8'hFF (Clarification 7)
          // ---------------------------------------------------------
          if (out_trans.uio_oe === 8'hFF && prev_uio_oe !== 8'hFF) begin
            result_out = {out_trans.uio_out, result_out[15:8]};
            byte_count++;

            if (byte_count == 2) begin
              byte_count = 0;
              if (result_out === result) begin
                pass++;
                `uvm_info("SCB", $sformatf("MATCH! OP:%s | A:%h B:%h | Err:%b | Result:%h",
                          (opcode ? "SUB" : "ADD"), operands[15:0], operands[31:16], out_trans.uo_out[2], result_out), UVM_LOW)
              end else begin
                fail++;
                `uvm_error("SCB", $sformatf("MISMATCH! OP:%s | A:%h B:%h | Err:%b || Actual:%h Expected:%h",
                           (opcode ? "SUB" : "ADD"), operands[15:0], operands[31:16], out_trans.uo_out[2], result_out, result))
              end
            end
          end

          // Update cycle history
          prev2_write_en    = prev_trans.ui_in[0];
          prev2_start_en    = prev_trans.ui_in[2];
          prev_uio_oe       = out_trans.uio_oe;
          prev_trans.ui_in  = in_trans.ui_in;
          prev_trans.uo_out = out_trans.uo_out;
        end
      end
    endtask

    virtual function void report_phase(uvm_phase phase);
      `uvm_info("SCB_REPORT", $sformatf("Test Finished. Verified: %0d | Passes: %0d | Fails: %0d",
                pass + fail, pass, fail), UVM_NONE)
    endfunction
  endclass
