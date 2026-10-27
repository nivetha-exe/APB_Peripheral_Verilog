
module apb_peripheral (
    input wire PCLK,
    input wire PRESETn,

    input wire [7:0] PADDR,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PWDATA,

    output reg [31:0] PRDATA,
    output wire PREADY,
    output wire PSLVERR
);

    reg [31:0] REG0;
    reg [31:0] REG1;
    reg [31:0] REG2;
    reg [31:0] REG3;

    assign PREADY = 1'b1;
    assign PSLVERR = 1'b0;

    // Write operation
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            REG0 <= 32'b0;
            REG1 <= 32'b0;
            REG2 <= 32'b0;
            REG3 <= 32'b0;
        end
        else if (PSEL && PENABLE && PWRITE) begin
            case (PADDR)
                8'h00: REG0 <= PWDATA;
                8'h04: REG1 <= PWDATA;
                8'h08: REG2 <= PWDATA;
                8'h0C: REG3 <= PWDATA;
                default: ;
            endcase
        end
    end

    // Read operation
    always @(*) begin
        PRDATA = 32'b0;

        if (PSEL && !PWRITE) begin
            case (PADDR)
                8'h00: PRDATA = REG0;
                8'h04: PRDATA = REG1;
                8'h08: PRDATA = REG2;
                8'h0C: PRDATA = REG3;
                default: PRDATA = 32'b0;
            endcase
        end
    end

endmodule
