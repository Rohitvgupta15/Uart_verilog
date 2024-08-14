module Top_Module(
    input [7:0] data,        // Input data (8 bits)
    input clk,               // Clock signal
    input transmit,          // Transmit signal
    input reset,             // Reset signal
    input reset_r,           // Reset signal for receiver
    input RxD,               // Received data
    output [7:0] RxData,     // Output received data (8 bits)
    output TxD,              // Output transmitted data
    output TxD_debug,        // Debug transmitted data
    output transmit_debug,   // Debug transmit signal
    output btn_debug,        // Debug reset signal
    output clk_debug         // Debug clock signal
);

    wire transmit_out;       // Wire for debounced transmit signal

    // Assign debug signals
    assign Tx_debug = TxD;
    assign transmit_debug = transmit_out;
    assign btn_debug = reset;
    assign clk_debug = clk;

    // Transmitter module
    Transmitter T1(clk, reset, transmit, data, TxD);

    // Debounce module
    Debounce_Signals DB(clk, reset, transmit_out);

    // Receiver module
    Receiver_RxD uut(.clk_fpga(clk), .reset(reset_r), .RxD(RxD), .RxData(RxData));  

endmodule
