// Code your design here
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input wire clk_wr,          // Write clock
    input wire clk_rd,          // Read clock
    input wire rst,             // Reset signal
    input wire wr_en,           // Write enable
    input wire rd_en,           // Read enable
    input wire clear,           // Clear signal
    
    input wire [DATA_WIDTH-1:0] wr_data,  // Data input for write
    output reg [DATA_WIDTH-1:0] rd_data,  // Data output for read
    
    output reg full,            // FIFO FULL flag
    output reg almost_full,     // FIFO Almost FULL flag
    output reg empty,           // FIFO EMPTY flag
    output reg almost_empty,    // FIFO Almost EMPTY flag
    
    output reg write_error,     // Write error flag
    output reg read_error,      // Read error flag
    
    output reg [3:0] wr_count,  // Write pointer count
    output reg [3:0] rd_count   // Read pointer count
);

    // Internal memory for FIFO
    reg [DATA_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0];
    reg [3:0] wr_ptr, rd_ptr;  // Write and Read pointers

    always @(posedge clk_wr or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            wr_count <= 0;
            full <= 0;
            almost_full <= 0;
            write_error <= 0;
        end else if (clear) begin
            wr_ptr <= 0;
            wr_count <= 0;
            full <= 0;
            almost_full <= 0;
            write_error <= 0;
        end else if (wr_en) begin
            if (!full) begin
                fifo_mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1;
                wr_count <= wr_count + 1;
                if (wr_count == FIFO_DEPTH - 1) full <= 1;
                if (wr_count == FIFO_DEPTH - 2) almost_full <= 1;
            end else begin
                write_error <= 1;  // Set write error if FIFO is full
            end
        end else begin
            write_error <= 0;  // Clear error if wr_en is not asserted
        end
    end

    always @(posedge clk_rd or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
            rd_count <= 0;
            empty <= 1;
            almost_empty <= 0;
            read_error <= 0;
        end else if (clear) begin
            rd_ptr <= 0;
            rd_count <= 0;
            empty <= 1;
            almost_empty <= 0;
            read_error <= 0;
        end else if (rd_en) begin
            if (!empty) begin
                rd_data <= fifo_mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                rd_count <= rd_count + 1;
                if (rd_count == 1) empty <= 1;
                if (rd_count == 2) almost_empty <= 1;
            end else begin
                read_error <= 1;  // Set read error if FIFO is empty
            end
        end else begin
            read_error <= 0;  // Clear error if rd_en is not asserted
        end
    end

    // Update EMPTY and FULL flags based on write and read counts
    always @(*) begin
        empty = (wr_count == rd_count);
        full = (wr_count - rd_count == FIFO_DEPTH);
        almost_empty = (wr_count - rd_count == 1);
        almost_full = (wr_count - rd_count == FIFO_DEPTH - 1);
    end

endmodule
