module Transmitter(
    input clk, 
    input reset, 
    input transmit,
    input [7:0] data,

    output reg TxD // 1bit output 
    );
    
    
    reg [3:0] bit_counter;//bit_counter count upto 10 bits i.e 2 bit for start/stop and 8 bit for data
    reg [13:0] baudrate_counter; //10,415, counter = clock/BR --> counter=100 Mhz / 9600
    reg [9:0] shiftright_register; //10 bits that will be serially transmitted through UART 
    reg state, next_state;// idle and start state
    reg shift; //shift signal to start shifting the bits 
    reg load;// load signal to start loading the data into the shiftright register, and add start and stop bits
    reg clear;//reset the bit_counter 
    
    parameter idle  = 0;
    parameter start = 1;
    
    always @(posedge clk)
    begin
        if (reset)
           begin
               state<=idle; 
               bit_counter<=0; //counter for bit transmission is reset to 0 every time when we recevie new data
               baudrate_counter<=0;// reset to zero every time when new data is recevie
           end
        else
            begin
                baudrate_counter<=baudrate_counter+1;// else increment baudrate counter
               if (baudrate_counter==10415)
                  begin
                      state<=next_state; //state changes from idle to start for transmitting
                      baudrate_counter<=0;//resetting counter
                      if (load) //if load is 1
                          shiftright_register<={1'b1, data,1'b0};//the data is loaded into the register, 10-bits where start and stop bit is added
                          if (clear)//if clear is 1
                              bit_counter<=0; // bit_counter is reset to 0 for new data transmmission
                               if (shift)//if shift signal is 1
                                  begin
                                      shiftright_register<=shiftright_register>>1;//start right shifting the data and transmitting bit by bit through TxD
                                      bit_counter<=bit_counter+1;// bit_counter is increment by 1
                                  end
                 end
           end
    end
    
    always @(posedge clk)
    begin
        load<=0; 
        shift<=0;
        clear<=0; 
        TxD<=1; //when set to 1, there is no transmission in progress , as indicate stop bit 
    
    case(state) 
       idle: begin
                 if (transmit) //transmit button is pressed 
                    begin 
                        next_state<=start; // transmission start
                        load<=1; //start loading the bits
                        shift<=0; //no shift at this point;
                        clear<=0; // to avoid any clearing of any counter
                    end

                 else
                    begin //if transmit button is not pressed
                        next_state<=idle; 
                        TxD<=1; //no transmission the set to 1
                    end
              end
    
       start: begin //transmitting start
                  if (bit_counter==10)// indicate transmission is done 
                      begin
                          next_state<=idle; 
                          clear<=1; //clear all the counters that reset the bit_counter
                      end
                  else
                      begin
                          next_state<=start; //stay in the transmit state
                           TxD<=shiftright_register[0]; // zero'th bit is transmitted to TxD every time after shift operation
                           shift<=1;//continue shifting the data
                      end
               end
       default: next_state<=idle;
   endcase
          
    end
endmodule
