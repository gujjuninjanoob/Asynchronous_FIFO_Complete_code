module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input wire clk_wr,          // Write clock
    input wire clk_rd,          // Read clock
    input wire rst_n,           // Active-low reset signal
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

    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // Internal memory for FIFO
    reg [DATA_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0];

    // Write and read pointers
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;            // Binary pointers
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;  // Gray-coded pointers

    // Synchronized pointers
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync_rd;  // Synchronized write pointer in read domain
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync_wr;  // Synchronized read pointer in write domain

    // Synchronize write pointer to the read clock domain
    always @(posedge clk_rd or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync_rd <= 0;
        end else begin
            wr_ptr_gray_sync_rd <= wr_ptr_gray;
        end
    end

    // Synchronize read pointer to the write clock domain
    always @(posedge clk_wr or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync_wr <= 0;
        end else begin
            rd_ptr_gray_sync_wr <= rd_ptr_gray;
        end
    end

    // Write logic
    always @(posedge clk_wr or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            wr_count <= 0;
            full <= 0;
            almost_full <= 0;
            write_error <= 0;
        end else if (clear) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            wr_count <= 0;
            full <= 0;
            almost_full <= 0;
            write_error <= 0;
        end else if (wr_en && !full) begin
            fifo_mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);  // Convert to Gray code
            wr_count <= wr_count + 1;
        end else if (wr_en && full) begin
            write_error <= 1;  // Write error if FIFO is full
        end else begin
            write_error <= 0;  // Clear error
        end

        // Full flag logic
        full <= (wr_ptr_gray == {~rd_ptr_gray_sync_wr[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync_wr[ADDR_WIDTH-2:0]});
        almost_full <= (wr_count == FIFO_DEPTH - 1);
    end

    // Read logic
    always @(posedge clk_rd or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            rd_count <= 0;
            empty <= 1;
            almost_empty <= 0;
            read_error <= 0;
        end else if (clear) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            rd_count <= 0;
            empty <= 1;
            almost_empty <= 0;
            read_error <= 0;
        end else if (rd_en && !empty) begin
            rd_data <= fifo_mem[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);  // Convert to Gray code
            rd_count <= rd_count + 1;
        end else if (rd_en && empty) begin
            read_error <= 1;  // Read error if FIFO is empty
        end else begin
            read_error <= 0;  // Clear error
        end

        // Empty flag logic
        empty <= (rd_ptr_gray == wr_ptr_gray_sync_rd);
        almost_empty <= (rd_count == 1);
    end

endmodule
