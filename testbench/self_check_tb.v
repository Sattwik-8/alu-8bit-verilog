
// self_check_tb.v
// Self-checking testbench for alu_8bit
// Directed test vectors + randomized stimulus.
// =====================================================

`timescale 1ns/1ps

module self_check_tb;

    reg  [7:0] a, b;
    reg  [2:0] opcode;
    wire [7:0] result;
    wire       zero, carry, overflow;

    integer pass_count = 0;
    integer fail_count = 0;
    integer i;

    alu_8bit dut (
        .a(a), .b(b), .opcode(opcode),
        .result(result), .zero(zero), .carry(carry), .overflow(overflow)
    );

    // -------------------------------------------------
    // Reference model: computes the EXPECTED result
    // independently of the DUT's internal implementation.
    // -------------------------------------------------
    task check_result;
        reg [7:0] exp_result;
        reg       exp_zero, exp_carry, exp_overflow;
        reg [8:0] ext_add, ext_sub;
        begin
            ext_add = {1'b0, a} + {1'b0, b};
            ext_sub = {1'b0, a} - {1'b0, b};
            exp_overflow = 1'b0;
            exp_carry    = 1'b0;

            case (opcode)
                3'b000: begin exp_result = ext_add[7:0]; exp_carry = ext_add[8];
                              exp_overflow = (a[7]==b[7]) && (exp_result[7]!=a[7]); end
                3'b001: begin exp_result = ext_sub[7:0]; exp_carry = ext_sub[8];
                              exp_overflow = (a[7]!=b[7]) && (exp_result[7]!=a[7]); end
                3'b010: exp_result = a & b;
                3'b011: exp_result = a | b;
                3'b100: exp_result = a ^ b;
                3'b101: exp_result = ~a;
                3'b110: exp_result = a << 1;
                3'b111: exp_result = a >> 1;
                default: exp_result = 8'b0;
            endcase

            exp_zero = (exp_result == 8'b0);

            #1; // let DUT settle before comparing
            if (result === exp_result && zero === exp_zero &&
                carry === exp_carry && overflow === exp_overflow) begin
                pass_count = pass_count + 1;
                $display("PASS  opcode=%0d a=%3d b=%3d | result=%3d zero=%b carry=%b ovf=%b",
                          opcode, a, b, result, zero, carry, overflow);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL  opcode=%0d a=%3d b=%3d | got result=%3d zero=%b carry=%b ovf=%b | expected result=%3d zero=%b carry=%b ovf=%b",
                          opcode, a, b, result, zero, carry, overflow,
                          exp_result, exp_zero, exp_carry, exp_overflow);
            end
        end
    endtask

    initial begin
    $dumpfile("alu_waveform.vcd");
    $dumpvars(0, self_check_tb);
        // ---------- DIRECTED TESTS (known edge cases) ----------
        a=8'd15;  b=8'd10;  opcode=3'b000; #5; check_result; // ADD normal
        a=8'd200; b=8'd100; opcode=3'b000; #5; check_result; // ADD overflow/carry
        a=8'd10;  b=8'd15;  opcode=3'b001; #5; check_result; // SUB borrow
        a=8'd5;   b=8'd5;   opcode=3'b001; #5; check_result; // SUB zero result
        a=8'hF0;  b=8'h0F;  opcode=3'b010; #5; check_result; // AND
        a=8'hF0;  b=8'h0F;  opcode=3'b011; #5; check_result; // OR
        a=8'hAA;  b=8'hFF;  opcode=3'b100; #5; check_result; // XOR
        a=8'h0F;  b=8'h00;  opcode=3'b101; #5; check_result; // NOT
        a=8'b00000011; b=8'b0; opcode=3'b110; #5; check_result; // SHL
        a=8'b00000100; b=8'b0; opcode=3'b111; #5; check_result; // SHR
        a=8'd127; b=8'd1;   opcode=3'b000; #5; check_result; // ADD signed overflow
        a=8'd0;   b=8'd0;   opcode=3'b001; #5; check_result; // SUB 0-0

        $display("-----------------------------------------");
        $display("Directed tests complete: %0d PASS, %0d FAIL so far", pass_count, fail_count);
        $display("-----------------------------------------");

        // ---------- RANDOMIZED TESTS ----------
        for (i = 0; i < 200; i = i + 1) begin
            a      = $random;
            b      = $random;
            opcode = $random;
            #5; check_result;
        end

        $display("-----------------------------------------");
        $display("Total: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: SOME TESTS FAILED");
        $finish;
    end

endmodule
