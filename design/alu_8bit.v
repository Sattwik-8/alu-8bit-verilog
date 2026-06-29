// =====================================================
// alu_8bit.v
// 8-bit Arithmetic Logic Unit (ALU)
// Combinational design - 8 operations selected by opcode
// =====================================================

module alu_8bit (
    input  [7:0] a,         // operand A
    input  [7:0] b,         // operand B
    input  [2:0] opcode,    // operation select
    output [7:0] result,    // ALU result
    output       zero,      // result == 0 flag
    output       carry,     // carry-out (ADD) / borrow (SUB)
    output       overflow   // signed overflow flag (ADD/SUB only)
);

    // Opcode encoding
    localparam OP_ADD  = 3'b000;
    localparam OP_SUB  = 3'b001;
    localparam OP_AND  = 3'b010;
    localparam OP_OR   = 3'b011;
    localparam OP_XOR  = 3'b100;
    localparam OP_NOT  = 3'b101;
    localparam OP_SHL  = 3'b110;   // shift a left by 1
    localparam OP_SHR  = 3'b111;   // shift a right by 1

    reg [7:0] result_reg;
    reg       carry_reg;
    reg       overflow_reg;

    reg [8:0] add_ext;
    reg [8:0] sub_ext;

    always @(*) begin
        result_reg   = 8'b0;
        carry_reg    = 1'b0;
        overflow_reg = 1'b0;
        add_ext      = {1'b0, a} + {1'b0, b};
        sub_ext      = {1'b0, a} - {1'b0, b};

        case (opcode)
            OP_ADD: begin
                result_reg = add_ext[7:0];
                carry_reg  = add_ext[8];
                overflow_reg = (a[7] == b[7]) && (result_reg[7] != a[7]);
            end

            OP_SUB: begin
                result_reg = sub_ext[7:0];
                carry_reg  = sub_ext[8];
                overflow_reg = (a[7] != b[7]) && (result_reg[7] != a[7]);
            end

            OP_AND: result_reg = a & b;
            OP_OR:  result_reg = a | b;
            OP_XOR: result_reg = a ^ b;
            OP_NOT: result_reg = ~a;
            OP_SHL: result_reg = a << 1;
            OP_SHR: result_reg = a >> 1;

            default: result_reg = 8'b0;
        endcase
    end

    assign result   = result_reg;
    assign zero     = (result_reg == 8'b0);
    assign carry    = carry_reg;
    assign overflow = overflow_reg;

endmodule
