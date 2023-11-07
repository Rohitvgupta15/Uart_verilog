module Debounce_Signals #(parameter threshold =2000000)
(
    input clk,
    input btn, //take button value as input
    output reg transmit 
    );
    
    reg button_ff1=0; // btn value is fed to ff1
    reg button_ff2=0; //ff1 is fed to ff2 with 1 cycle delay
    reg [30:0] count=0; //20 bit count i.e 1000000 (threshold) for increment and decerement when button is pressed or released.
    

    
    always @(posedge clk)
    begin
        button_ff1<=btn;
        button_ff2<=button_ff1;
    end
    

   
   always @(posedge clk)
   begin
       if (button_ff2 == 1) 
          begin
              if (~&count == 1)  // every count is AND and then NOT eg 101 --> 1&0&1 = 0 --> ~0 == 1 if 111 --> 1&1&1 = 1 --> ~1 == 0 it voilate the condition ,also indicate that max limit(1111..) is not reached
                  count<=count+1; //when btn is pressed, count up
          end
       else 
          begin
             if (|count == 1) // every count is OR eg 101 --> 1 | 0 | 1 = 1 the condition is satisfy and also indicate that count is not at 0000...  
                 count<=count-1; //when btn is released, count down 
          end
             if (count>threshold) //if the count is larger than the threshhold
                 transmit<=1; //debounced signal is 1
             else
                 transmit<=0; //debounced signal is 0
  end
  
 endmodule
