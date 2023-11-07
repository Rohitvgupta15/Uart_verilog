module Top_Module(
    input [7:0] data,
    input clk,
    input transmit,
    input reset,
    //input clk_fpga,
    input reset_r,
    input RxD,
    output [7:0]RxData,
    output TxD,
    output TxD_debug,
    output transmit_debug,
    output btn_debug,
    output clk_debug
    );
    
    wire transmit_out;
    
     assign Tx_debug = TxD;
       assign transmit_debug = transmit_out;
       assign btn_debug = reset;
       assign clk_debug = clk;
       
    
    Transmitter T1(clk, reset, transmit, data, TxD);
    Debounce_Signals DB(clk, reset, transmit_out);
    
     Receiver_RxD uut(.clk_fpga(clk) , .reset(reset_r) , .RxD(RxD) , .RxData(RxData));  
endmodule
