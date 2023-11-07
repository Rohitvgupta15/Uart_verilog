module Receiver_RxD(

input clk_fpga, 
input reset, 
input RxD, 
output [7:0]RxData // 8 bit data after removeing start and stop bit
    );
    

reg shift; // indicate when to shift data ot not
reg state, nextstate; 
reg [3:0] bit_counter; //total length of the bits is 10 where 8 bit data and 1 bit for start and 1 bit for stop
reg [1:0] sample_counter; //frequency = 4 times the BR, 4 time oversampled 
reg [13:0] baudrate_counter; //for count the value which we find in div_counter 
reg [9:0] rxshift_reg; //data byte (10 bits) [0] for start bit ,[8:1] for  data byte, [9] for stop bit
reg clear_bitcounter,inc_bitcounter,inc_samplecounter,clear_samplecounter; //to clear and increment the bit counter and sample counter


parameter clk_freq = 100_000_000; 
parameter baud_rate = 9_600; 
parameter div_sample = 4;  // dividing a bit into 4 part
parameter div_counter = clk_freq/(baud_rate*div_sample);  // formula to final value i.e here it is 2604
parameter mid_sample = (div_sample/2);  //this is the middle point of a bit to know exactly value of bit
parameter div_bit = 10; // 1 start, 1 stop, 8 bit of data

parameter idle =0;
parameter start = 1;
assign RxData = rxshift_reg [8:1]; //assigning the RxData from the shift register only 8 bit data removing start and stop bit


always @ (posedge clk_fpga)
    begin 
        if (reset)
          begin //if reset button is pressed, all counters are rset
            state <=0; //idle
            bit_counter <=0;
            baudrate_counter <=0; 
            sample_counter <=0; 
          end
        else 
           begin 
            baudrate_counter <= baudrate_counter +1; 
            if (baudrate_counter >= div_counter-1)  // count upto 2603 i.e oversampled value
               begin //if the counter reach the BR with sampling
                baudrate_counter <=0; //reset counter when baudrate_counter is greater then 2603
                state <= nextstate; 
                if (shift)  // if shift is 1
                   rxshift_reg <= {RxD,rxshift_reg[9:1]}; //then load the receiving data
                if (clear_samplecounter) // if clear_samplecouter is 1
                   sample_counter <=0; // then reset the sample counter
                if (inc_samplecounter) // if inc_samplecounter is 1
                    sample_counter <= sample_counter +1; // increment by 1
                if (clear_bitcounter) // if clear_bitcounter is 1
                    bit_counter <=0; // ithen rset itself
                if (inc_bitcounter)
                    bit_counter <= bit_counter +1; //bitcounter goes up by 1.
               end
           end
    end
   

always @ (posedge clk_fpga) //trigger by clock
begin 
    shift <= 0; //idle shift is set to 0 to avoid the shift of data when not set shift to 1
    clear_samplecounter <=0; 
    inc_samplecounter <=0; 
    clear_bitcounter <=0; 
    inc_bitcounter <=0; 
    nextstate <=idle; 
    case (state)
        idle: begin 
            if (RxD) //in RxD start bit is low ,it will wait for low signal and when it recevie ,start receiveing the data
              begin
              nextstate <=idle; //stay in the idle state, RxD needs to be low to start the transmission
              end
            else begin 
                nextstate <=start; //receiving start
                clear_bitcounter <=1; //set to 1
                clear_samplecounter <=1; //set to 1
            end
        end
        start: begin // Receiving start
            nextstate <= start; 
            if (sample_counter== mid_sample - 1) // when sample_counter is equal to 1
                shift <= 1; //if  sample counter is 1, set the shift 
            if (sample_counter== div_sample - 1) //when sample_counter is equal to 3
                 begin 
                    if (bit_counter == div_bit - 1) // if bit_counter is eqaul to 9, then next_state is idle 
                      begin 
                         nextstate <= idle; 
                      end 
                     inc_bitcounter <=1; //increment bit counter if bit count is not 9,
                    clear_samplecounter <=1; //sample counter is reset
                 end
              else
                  inc_samplecounter <=1; //if the sample counter is not 3 then 
            end
       default: nextstate <=idle; // default state is idle
     endcase
end         
endmodule
