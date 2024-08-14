module Receiver_RxD(

input clk_fpga, 
input reset, 
input RxD, 
output [7:0] RxData // 8-bit received data
);

reg shift; // Controls when to shift data
reg state, nextstate; 
reg [3:0] bit_counter; // Counts bits (10 total: 1 start, 8 data, 1 stop)
reg [1:0] sample_counter; // For oversampling (4x baud rate)
reg [13:0] baudrate_counter; // Counts clock cycles for baud rate
reg [9:0] rxshift_reg; // Holds received bits (start, data, stop)
reg clear_bitcounter, inc_bitcounter, inc_samplecounter, clear_samplecounter; // Control signals for counters

parameter clk_freq = 100_000_000; 
parameter baud_rate = 9_600; 
parameter div_sample = 4;  // Divide bit into 4 parts
parameter div_counter = clk_freq / (baud_rate * div_sample);  // Count value for baud rate
parameter mid_sample = div_sample / 2;  // Middle of a bit
parameter div_bit = 10; // Total bits: 1 start, 1 stop, 8 data

parameter idle = 0;
parameter start = 1;
assign RxData = rxshift_reg[8:1]; // Assign 8-bit data, removing start and stop bits

always @(posedge clk_fpga)
begin 
    if (reset)
    begin 
        state <= 0; // Idle state
        bit_counter <= 0;
        baudrate_counter <= 0; 
        sample_counter <= 0; 
    end
    else 
    begin 
        baudrate_counter <= baudrate_counter + 1; 
        if (baudrate_counter >= div_counter - 1)  // Count up to baud rate value
        begin 
            baudrate_counter <= 0; // Reset counter
            state <= nextstate; 
            if (shift)  
                rxshift_reg <= {RxD, rxshift_reg[9:1]}; // Shift in new bit
            if (clear_samplecounter)
                sample_counter <= 0; // Reset sample counter
            if (inc_samplecounter)
                sample_counter <= sample_counter + 1; // Increment sample counter
            if (clear_bitcounter)
                bit_counter <= 0; // Reset bit counter
            if (inc_bitcounter)
                bit_counter <= bit_counter + 1; // Increment bit counter
        end
    end
end

always @(posedge clk_fpga)
begin 
    shift <= 0; // Default to no shift
    clear_samplecounter <= 0; 
    inc_samplecounter <= 0; 
    clear_bitcounter <= 0; 
    inc_bitcounter <= 0; 
    nextstate <= idle; 
    case (state)
        idle: begin 
            if (RxD) 
                nextstate <= idle; // Stay idle if no start bit
            else 
            begin 
                nextstate <= start; // Start receiving
                clear_bitcounter <= 1; 
                clear_samplecounter <= 1; 
            end
        end
        start: begin 
            nextstate <= start; 
            if (sample_counter == mid_sample - 1) 
                shift <= 1; // Shift data at midpoint
            if (sample_counter == div_sample - 1) 
            begin 
                if (bit_counter == div_bit - 1) 
                    nextstate <= idle; // Go idle after last bit
                inc_bitcounter <= 1; 
                clear_samplecounter <= 1; 
            end
            else
                inc_samplecounter <= 1; // Keep sampling
        end
        default: nextstate <= idle; // Default to idle
    endcase
end         
endmodule
