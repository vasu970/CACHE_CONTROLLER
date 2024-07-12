`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.07.2024 12:17:48
// Design Name: 
// Module Name: Cache_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Cache_controller(

//module Controller(
input clk,reset,
input mode,//mode is used to decide if its whether its read or write for read value is 1 and for write it is 0
input [31:0]address,
input [31:0]Data,
output reg [31:0] out_Data=0

);
//L1_Cache L1();
//Main_Memory main();
integer i;
reg read_count=0;
reg read_count2=0;
reg hit=0;//it will indicate whether the required word is present in the L1 cache memory or not
//reg miss;//this will indicate the word is not there
reg[31:0] adress;

 reg [31:0] data_value_from_memory;
 
 /*****************************************************/
 //Declaration of required parameters
 //main memory parameters
 parameter no_of_blocks_main=1024;
parameter words_per_each_block_main_mem=1;
parameter word_size=32;



//L1 Cache parameters 2 Way Set Associative
parameter no_of_blocks=8;//Basically this uses 2bits for index
parameter Index_bits=2;
parameter words_per_each_block=2;
parameter way_associative=2;
parameter Bits_per_block=2*32;
//parameter word_size=32;
parameter Block_offset=1;//for selecting the words in cache memory
parameter no_of_tag_bits=27;//32-2-1-2(word_size-Block_offset-Index_bits-2)
parameter each_tag_size=27*2;//(no_of_tag_bits*words_per_each_block)
 
 //declaration of  main memory registers and corresponding functions
 reg [word_size-1:0] Main_memory[0:no_of_blocks_main-1];
//integer i;
initial
begin

for(i=0;i<no_of_blocks_main;i=i+1)
begin
Main_memory[i]=i;
end
end

//endmodule
 /************************************************/
 // Declaration L1 cache registers and the functions
 
 reg [Bits_per_block-1:0] L1_cache[0:no_of_blocks-1];
reg [each_tag_size-1:0] Tag_bits[0:no_of_blocks-1];
reg valid_bit[0:no_of_blocks-1];
reg Dirty_bit[0:no_of_blocks-1];
reg[1:0] Index_bits_1;
reg Block_offset_1;
reg [2:0]Least_recently_used_bits;
//integer i;
reg [2:0]valid_bit_formation_for_writing_1;
reg [2:0]valid_bit_formation_for_writing_2;
reg valid_0=0,valid_1=0;
reg Tag_0=0,Tag_1=0;
reg count=0;
reg clk_stall;
reg for_stalling=0;
reg[2:0] count1=0;
reg miss=1;//invert condition

/***********************************************************************/
//here we are defining valid bit as concatenation of adress and the 0 and 1 this is used for writing
//always@(posedge clk)
//begin
//valid_bit_formation_for_writing_1={adress[4:3],{1{1'b0}}};
//valid_bit_formation_for_writing_2={adress[4:3],{1{1'b1}}};
//end
initial
begin
for(i=0;i<no_of_blocks;i=i+1)
begin
valid_bit[i]=0;
Dirty_bit[i]=0;
L1_cache[i]=i;
Tag_bits[i]=0;
Index_bits_1[i]=i;
Block_offset_1=0;//1st word select by default
Least_recently_used_bits[i]=1;//reverse logic write when LRU is "1" and don't write when it's "0"
end
end
//
reg [2:0] state=0,nextstate=0;
reg read_hit_done=0;
reg  read_not_hit_done;
reg write_hit_done;
reg write_not_hit_done;
parameter idle_state=0,write_hit=1,write_not_hit=2,read_hit=3,read_not_hit=4;
always@(posedge clk)
 adress=address;//urke

always@(posedge clk,posedge reset) begin
    if(reset) 
        begin
            state = 0;
            
        end
    else 
        state = nextstate;  
end

always@(posedge clk_stall)
    begin
        case(state)
            idle_state:begin
//                            for_stalling=1;
                            if((valid_bit[{adress[4:3],{1{1'b0}}}]==1))
                                valid_0=1;//checking if the first block is valid or not in set1
                            if((valid_bit[{adress[4:3],{1{1'b1}}}]==1))
                                valid_1=1;//checking if second block is valid or not in set1
                            if(Tag_bits[{adress[4:3],{1{1'b0}}}][each_tag_size-1:+no_of_tag_bits]==address[31:5])
                            begin
                                Least_recently_used_bits[{adress[4:3],{1{1'b0}}}]=0;//here we are updating LRU value when its a hit
                                Tag_0=1;//checking tag bit of 1st block
                            end
                            if(Tag_bits[{adress[4:3],{1{1'b1}}}][each_tag_size-1:+no_of_tag_bits]==address[31:5])//here we are checking if the  corresponding tag is present in the word
                                begin
                                    Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]=0;
                                    Tag_1=1;//checking tag bit of second block
                                end
                            if((Tag_1&&valid_1)||(Tag_0&&valid_0))
                                begin
                                    hit=1;
                                    miss=1;
                                        if(hit==1&&mode==1)
                                            begin
                                                if(read_hit_done==0)
                                                    nextstate=read_hit;
                                                else
                                                    nextstate=idle_state;
                                            end
                                        else
                                        begin
                                                  if(write_hit_done==0)
                                                      nextstate=write_hit;
                                                  else
                                                      nextstate=idle_state;
                                              end                                            
                                end
                            else
                                    begin
                                          hit=0;
                                          miss=0;
                                              if(hit==0&&mode==1)
                                              begin
                                                  if(read_not_hit_done==0)
                                                       nextstate=read_not_hit;
                                                  else
                                                       nextstate=idle_state;
                                              end
                                                  
                                              else
                                              begin
                                                  if(write_not_hit_done==0)
                                                      nextstate=write_not_hit;
                                                  else
                                                      nextstate=idle_state;
                                              end
                                    end
                          end
            
            
     read_hit:
                     begin
                        if(hit==1&&valid_0&&Tag_0)
                            out_Data=(address[2])? L1_cache[{adress[4:3],{1{1'b0}}}][63:32]:L1_cache[{adress[4:3],{1{1'b0}}}][31:0];
                        else
                            out_Data=(address[2])? L1_cache[{adress[4:3],{1{1'b1}}}][63:32]:L1_cache[{adress[4:3],{1{1'b1}}}][31:0];
                            nextstate=idle_state;
                            read_hit_done=1;
                       end        
            
            
   read_not_hit:
                         begin
                            if((hit!=1)&&mode)
                            begin
                            if(Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]==0)
                                begin
                                    Tag_bits[{adress[4:3],{1{1'b0}}}][each_tag_size-1:+no_of_tag_bits]=address[31:5];//updating the tag register field with the writing values of the new adress
                                    // when one word in block gets updated both of them get updated
                                     L1_cache[{adress[4:3],{1{1'b0}}}][63:32]=Main_memory[adress+1];// we saving the values from the main memory into the cahe 
                                     L1_cache[{adress[4:3],{1{1'b0}}}][31:0]=Main_memory[adress];
                                     valid_bit[{adress[4:3],{1{1'b0}}}]=1;//after saving from memory making valid bit equals to 1
                                     Least_recently_used_bits[{adress[4:3],{1{1'b0}}}]=0;//recently used/write done 
                                      Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]=1;
                                end
                            else
                                begin
                                     Tag_bits[{adress[4:3],{1{1'b1}}}][each_tag_size-1:+no_of_tag_bits]=address[31:5];//updating the tag register field with the writing values of the new adress
                                    // when one word in block gets updated both of them get updated
                                     L1_cache[{adress[4:3],{1{1'b1}}}][63:32]=Main_memory[adress+1];// we saving the values from the main memory into the cahe 
                                     L1_cache[{adress[4:3],{1{1'b1}}}][31:0]=Main_memory[adress];
                                     valid_bit[{adress[4:3],{1{1'b1}}}]=1;//after saving from memory making valid bit equals to 1
                                      Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]=0;
                                       Least_recently_used_bits[{adress[4:3],{1{1'b0}}}]=1;
                                 end
                                 nextstate=idle_state;
                                 read_not_hit_done=1;
                            end
//                            hit=1;
                            end
                                     
            
 write_hit:     if(mode==0)//write operation

                        begin
                        
                            if((hit==1)&&(Tag_1&&valid_1))//checking if the same value already being used in the cache set1 location 1
                                begin
                                if(adress[2]==1)
                                begin
                                      L1_cache[{adress[4:3],{1{1'b1}}}][63:32]=Data;
                                      L1_cache[{adress[4:3],{1{1'b1}}}][31:0]=Main_memory[adress-1];
                                      Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]=0;
                                       Least_recently_used_bits[{adress[4:3],{1{1'b0}}}]=1;
                                end
                                else
                                begin
                                       L1_cache[{adress[4:3],{1{1'b1}}}][31:0]=Data;
                                       L1_cache[{adress[4:3],{1{1'b1}}}][63:32]=Main_memory[adress+1];
                                       Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]=0;
                                       Least_recently_used_bits[{adress[4:3],{1{1'b0}}}]=1;
                                end
                                end
                            
                                else if((hit==1)&&(Tag_0&&valid_0))//checking if the same value already being used in the cache set 1 location 0
                                    begin
                                    if(adress[2]==1)
                                        begin
                                              L1_cache[{adress[4:3],{1{1'b0}}}][63:32]=Data;
                                              L1_cache[{adress[4:3],{1{1'b0}}}][31:0]=Main_memory[adress-1];
                                              Least_recently_used_bits[{adress[4:3],{1{1'b0}}}]=0;
                                               Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]=1;
                                          end
                                    else
                                        begin
                                        
                                               L1_cache[{adress[4:3],{1{1'b0}}}][31:0]=Data;
                                               L1_cache[{adress[4:3],{1{1'b0}}}][63:32]=Main_memory[adress+1];
                                               Least_recently_used_bits[{adress[4:3],{1{1'b0}}}]=0;
                                               Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]=1;
                                        end
                                    end
                                     Main_memory[adress]=Data;
                                     nextstate=read_hit;
                                     write_hit_done=1;
//                                     hit=1
                            end            
            
   write_not_hit:
   
                      begin
                            if(valid_bit[{adress[4:3],{1{1'b0}}}]==0)
                                    begin
                                         L1_cache[{adress[4:3],{1{1'b0}}}][31:0]=Data;
                                         Tag_bits[{adress[4:3],{1{1'b0}}}][each_tag_size-1:+no_of_tag_bits]=address[31:5];
                                         valid_bit[{adress[4:3],{1{1'b0}}}]=1;
                                          L1_cache[{adress[4:3],{1{1'b0}}}][63:32]=Main_memory[adress+1];
                                           Least_recently_used_bits[{adress[4:3],{1{1'b0}}}]=0;
                                           Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]=1;
                                     end
                            else if(valid_bit[{adress[4:3],{1{1'b1}}}]==0)
                                begin
                                      L1_cache[{adress[4:3],{1{1'b1}}}][31:0]=Data;
                                      Tag_bits[{adress[4:3],{1{1'b1}}}][each_tag_size-1:+no_of_tag_bits]=address[31:5];
                                      valid_bit[{adress[4:3],{1{1'b1}}}]=1;
                                       L1_cache[{adress[4:3],{1{1'b1}}}][63:32]=Main_memory[adress+1];
                                       Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]=0;
                                       Least_recently_used_bits[{adress[4:3],{1{1'b0}}}]=1;
                                  end
                            else if(Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]==0)//
                                begin
                                     L1_cache[{adress[4:3],{1{1'b0}}}][31:0]=Data;
                                    Tag_bits[{adress[4:3],{1{1'b0}}}][each_tag_size-1:+no_of_tag_bits]=address[31:5];
                                    valid_bit[{adress[4:3],{1{1'b0}}}]=1;
                                     L1_cache[{adress[4:3],{1{1'b0}}}][63:32]=Main_memory[adress+1];
                                     Least_recently_used_bits[{adress[4:3],{1{1'b0}}}]=0;
                                     Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]=1;
                                end
                            //updating the tag register field with the writing values of the new adress
                            // when one word in block gets updated both of them get updated
                            else
                                begin
                                     L1_cache[{adress[4:3],{1{1'b1}}}][31:0]=Data;
                                    Tag_bits[{adress[4:3],{1{1'b1}}}][each_tag_size-1:+no_of_tag_bits]=address[31:5];
                                    valid_bit[{adress[4:3],{1{1'b1}}}]=1;
                                     L1_cache[{adress[4:3],{1{1'b1}}}][63:32]=Main_memory[adress+1];
                                     Least_recently_used_bits[{adress[4:3],{1{1'b1}}}]=0;
                                     Least_recently_used_bits[{adress[4:3],{1{1'b0}}}]=1;
                                 end
                                 nextstate=idle_state;
                                 write_not_hit_done=1;
//                                 hit=1;
                       end      
            endcase
    end
//always@(*)
// if(nextstate==1||nextstate==2||nextstate==4)
// hit=1;
//always@(posedge clk,negedge clk)
//    if(miss==0)
//        begin
//            if(count1!=2)
//                begin
//                    clk_stall=0;
//                    count1=count+1;
//                end
//            else
//                begin
//                    clk_stall=clk;
//                    count1=0;
//                end
//        end
      reg stall=0;  
        
always@( posedge clk,negedge clk)
    begin
    if((hit!=1||nextstate==write_hit)&&stall!=1)
        begin
            if(((nextstate==1||nextstate==2||nextstate==4))&&(count1!=2))
                begin
                    clk_stall=0;
                    count1=count1+1;
                end
            else if(count1==2)
                begin
                    clk_stall=clk;
                    count1=0;
                    stall=1;
                end
            else
            begin
                clk_stall=clk;

                end
            end
   else
      
      begin
      clk_stall=clk;
//      stall=0;
      end
    end
    
//always@(posedge clk,negedge clk)
//if(stall==0)
//clk_stall=clk;


        
        
always@(adress,mode)
    begin
        state=0;
        nextstate=0;
    end
    
    always@(address,mode)
        begin
            hit=0;
            stall=0;
            Tag_0=0;
            Tag_1=0;
            valid_0=0;
            valid_1=0;
            count=0;
            miss=1;
            clk_stall=clk;
            read_hit_done=0;
            read_not_hit_done=0;
            write_hit_done=0;
            write_not_hit_done=0;
        end
endmodule
