module Debounce_Signals #(parameter threshold = 2000000)
(
    input clk,         // Clock signal
    input btn,         // Button input
    output reg transmit // Debounced output
);

    reg button_ff1 = 0; // First flip-flop
    reg button_ff2 = 0; // Second flip-flop
    reg [30:0] count = 0; // Counter

    // Capture button state in flip-flops
    always @(posedge clk)
    begin
        button_ff1 <= btn;
        button_ff2 <= button_ff1;
    end

    // Debouncing logic
    always @(posedge clk)
    begin
        if (button_ff2 == 1) 
        begin
            if (~&count == 1)  // Count up if button is pressed
                count <= count + 1;
        end
        else 
        begin
            if (|count == 1) // Count down if button is released
                count <= count - 1;
        end

        // Set output based on count
        if (count > threshold) 
            transmit <= 1;
        else
            transmit <= 0;
    end
  
endmodule
