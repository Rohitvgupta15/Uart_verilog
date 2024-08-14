module Transmitter(
    input clk, 
    input reset, 
    input transmit,
    input [7:0] data,

    output reg TxD // 1-bit output for transmission
);
    
    reg [3:0] bit_counter;          // Counts up to 10 bits (1 start, 8 data, 1 stop)
    reg [13:0] baudrate_counter;    // Counts clock cycles for baud rate (10415 count for 9600 baud)
    reg [9:0] shiftright_register;  // Holds the 10 bits to be sent (start, data, stop)
    reg state, next_state;          // Current and next state (idle or start)
    reg shift;                      // Controls when to shift bits
    reg load;                       // Loads data into the shift register
    reg clear;                      // Clears the bit counter
    
    parameter idle  = 0;            // Idle state
    parameter start = 1;            // Start state
    
    always @(posedge clk)
    begin
        if (reset)
        begin
            state <= idle; 
            bit_counter <= 0;       // Reset bit counter
            baudrate_counter <= 0;  // Reset baud rate counter
        end
        else
        begin
            baudrate_counter <= baudrate_counter + 1; // Increment baud rate counter
            if (baudrate_counter == 10415) // If counter matches baud rate value
            begin
                state <= next_state;  // Move to the next state
                baudrate_counter <= 0; // Reset baud rate counter
                if (load) // If load is 1
                    shiftright_register <= {1'b1, data, 1'b0}; // Load data with start and stop bits
                if (clear) // If clear is 1
                    bit_counter <= 0; // Reset bit counter
                if (shift) // If shift is 1
                begin
                    shiftright_register <= shiftright_register >> 1; // Shift bits to the right
                    bit_counter <= bit_counter + 1; // Increment bit counter
                end
            end
        end
    end
    
    always @(posedge clk)
    begin
        load <= 0; 
        shift <= 0;
        clear <= 0; 
        TxD <= 1; // Set TxD to 1 (no transmission)
    
        case(state) 
            idle: begin
                if (transmit) // If transmit signal is active
                begin 
                    next_state <= start; // Move to start state
                    load <= 1; // Load the data
                end
                else
                begin
                    next_state <= idle; 
                    TxD <= 1; // Keep TxD at 1 (no transmission)
                end
            end
    
            start: begin // Start transmitting
                if (bit_counter == 10) // If all bits are sent
                begin
                    next_state <= idle; // Move back to idle
                    clear <= 1; // Clear the bit counter
                end
                else
                begin
                    next_state <= start; // Stay in start state
                    TxD <= shiftright_register[0]; // Send the next bit
                    shift <= 1; // Continue shifting bits
                end
            end
            default: next_state <= idle; // Default to idle
        endcase
    end
endmodule
