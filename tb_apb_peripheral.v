
`timescale 1ns / 1ps

module tb_apb_peripheral;

    reg PCLK;
    reg PRESETn;

    reg [7:0] PADDR;
    reg PSEL;
    reg PENABLE;
    reg PWRITE;
    reg [31:0] PWDATA;

    wire [31:0] PRDATA;
    wire PREADY;
    wire PSLVERR;

    reg [31:0] read_data;

    apb_peripheral dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );

    // 100 MHz simulation clock
    initial PCLK = 0;
    always #5 PCLK = ~PCLK;

    // APB write task
    task apb_write;
        input [7:0] addr;
        input [31:0] data;
        begin
            @(negedge PCLK);
            PSEL = 1;
            PENABLE = 0;
            PWRITE = 1;
            PADDR = addr;
            PWDATA = data;

            @(negedge PCLK);
            PENABLE = 1;

            @(posedge PCLK);
            while (!PREADY)
                @(posedge PCLK);

            @(negedge PCLK);
            PSEL = 0;
            PENABLE = 0;
            PWRITE = 0;
            PADDR = 0;
            PWDATA = 0;
        end
    endtask

    // APB read task
    task apb_read;
        input [7:0] addr;
        output [31:0] data;
        begin
            @(negedge PCLK);
            PSEL = 1;
            PENABLE = 0;
            PWRITE = 0;
            PADDR = addr;
            PWDATA = 0;

            @(negedge PCLK);
            PENABLE = 1;

            @(posedge PCLK);
            while (!PREADY)
                @(posedge PCLK);

            data = PRDATA;

            @(negedge PCLK);
            PSEL = 0;
            PENABLE = 0;
            PADDR = 0;
        end
    endtask

    // Check expected read data
    task check_register;
        input [7:0] addr;
        input [31:0] expected;
        begin
            apb_read(addr, read_data);

            if (read_data !== expected) begin
                $display(
                    "FAIL: address=%h expected=%h actual=%h",
                    addr, expected, read_data
                );
                $fatal(1, "Register check failed");
            end
            else begin
                $display(
                    "PASS: address=%h data=%h",
                    addr, read_data
                );
            end
        end
    endtask

    initial begin
        PRESETn = 0;
        PADDR = 0;
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;
        PWDATA = 0;
        read_data = 0;

        repeat (3) @(negedge PCLK);
        PRESETn = 1;

        // Write to all four registers
        apb_write(8'h00, 32'h12345678);
        apb_write(8'h04, 32'hAABBCCDD);
        apb_write(8'h08, 32'hDEADBEEF);
        apb_write(8'h0C, 32'h00000025);

        // Read and verify all four registers
        check_register(8'h00, 32'h12345678);
        check_register(8'h04, 32'hAABBCCDD);
        check_register(8'h08, 32'hDEADBEEF);
        check_register(8'h0C, 32'h00000025);

        // Verify reset clears the registers
        @(negedge PCLK);
        PRESETn = 0;

        repeat (2) @(negedge PCLK);
        PRESETn = 1;

        check_register(8'h00, 32'h00000000);
        check_register(8'h04, 32'h00000000);
        check_register(8'h08, 32'h00000000);
        check_register(8'h0C, 32'h00000000);

        $display("--------------------------------");
        $display("ALL APB TESTS PASSED!");
        $display("--------------------------------");

        $finish;
    end

endmodule
