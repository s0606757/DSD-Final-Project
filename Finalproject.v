`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// Create Date:    11:36:21 06/03/2015 
// Design Name: 
// Module Name:    Finalproject 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
// Dependencies: 
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//////////////////////////////////////////////////////////////////////////////////
module Finalproject(CLK,Reset,Location,S,column,level,LED,Sevenseg,Enable,row,,LGM_En,LGM_RW,LGM_DI,LGM_RST,LGM_CS1,LGM_CS2,LGM_DATA);
input CLK;
input Reset;
input Location;
input [7:0]S;
input [3:0] column;
input level;

output reg[3:0]row;
output reg[7:0]LED;
output reg[3:0] Enable;
output reg[14:0] Sevenseg;

reg [27:0]counter;
reg press;
reg [3:0] debounce_count;
reg [7:0]key_code;

reg [3:0]Fullfeeling;
reg [3:0]cleanness;
reg [3:0]mood;
reg [3:0]friendship;

reg [3:0] scan_code;
reg keyboard_press;
reg [3:0]keyboard_debounce_count;
reg [4:0]keyboard_key_code;
reg [4:0]keyboard_key_in;

reg [3:0]X;
reg [3:0]Y;
reg  move_valid;

reg [1:0]SevenSeg_count;
reg [3:0]Decode_BCD;
reg [3:0]five_count;

reg [3:0]check_counter;

wire LGM_CLK;
wire DEBOUNCE_CLK;
wire OUT_CLK1;
wire OUT_CLK2;
wire OUT_CLK3;
wire OUT_CLK4;
wire press_valid;
wire keyboard_press_valid;
wire Scan_CLK;

/**************************產生各種clk***********************************/
always@(posedge CLK or negedge Reset) 
begin 
   if (!Reset) 
	   counter<=28'd0;
	else 
	   counter<=counter+1'b1; 
end

assign LGM_CLK=counter[7];
assign DEBOUNCE_CLK=counter[14];

assign OUT_CLK1=counter[23]; //2   Hz的clk
assign OUT_CLK2=counter[24]; //1   Hz的clk
assign OUT_CLK3=counter[25]; //0.5 Hz的clk
assign OUT_CLK4=counter[27]; //0.2 Hz的clk
assign Scan_CLK=counter[14];


/*********************************************************************************************************************/
/***************************************************各種度控制**********************************************************/
/*********************************************************************************************************************/	

	
/****************************飽足感控制(每5秒飽足感下降1)******************************/    
always @(posedge OUT_CLK1 or negedge Reset)       
begin
   if(!Reset)
		  Fullfeeling<=4'd5; //飽足感最高為9，初始為5
	else if((key_code==8'b01111111)&&(Fullfeeling<=4'd7)&&(Fullfeeling)&&(level==1'b0))
	     Fullfeeling<=Fullfeeling+4'd2;
   else if((key_code==8'b01111111)&&(Fullfeeling<=4'd8)&&(Fullfeeling)&&(level==1'b0))
	     Fullfeeling<=Fullfeeling+4'd1;
	else if((key_code==8'b01111111)&&(Fullfeeling<=4'd9)&&(Fullfeeling)&&(level==1'b0))
	     Fullfeeling<=Fullfeeling;
	else if((!(Fullfeeling))&&(level==1'b0))
	     Fullfeeling<=4'd0;
		  
	else if((key_code==8'b01111111)&&(Fullfeeling<=4'd7)&&(Fullfeeling&&cleanness&&mood)&&(level==1'b1))
	     Fullfeeling<=Fullfeeling+4'd2;
	else if((key_code==8'b01111111)&&(Fullfeeling==4'd8)&&(Fullfeeling&&cleanness&&mood)&&(level==1'b1))
	     Fullfeeling<=Fullfeeling+4'd1;
   else if((key_code==8'b01111111)&&(Fullfeeling==4'd9)&&(Fullfeeling&&cleanness&&mood)&&(level==1'b1))
	     Fullfeeling<=Fullfeeling;  
	else if(Fullfeeling==4'd0)
	     Fullfeeling<=4'd0;
		  
   else if(five_count==4'd9&&(Fullfeeling)&&(level==1'b0))
        Fullfeeling<=Fullfeeling-4'd1;
	else if(five_count==4'd9&&((Fullfeeling&&cleanness&&mood))&&(level==1'b1))
        Fullfeeling<=Fullfeeling-4'd1;
   else 
	     Fullfeeling<=Fullfeeling;
end

/***************************清潔度控制(每按壓一次餵食下降3)******************************/    
always @(posedge OUT_CLK1 or negedge Reset)       
begin
   if(!Reset)
		  cleanness<=4'd6; //清潔度最高為9，初始為6
	else if((key_code==8'b01111111)&&(Fullfeeling<=4'd8)&&(cleanness>=4'd3)&&(Fullfeeling&&cleanness&&mood))
	     cleanness<=cleanness-4'd3;
   else if((key_code==8'b01111111)&&(Fullfeeling<=4'd8)&&(cleanness==4'd2)&&(Fullfeeling&&cleanness&&mood))
	     cleanness<=cleanness-4'd2;
	else if((key_code==8'b01111111)&&(Fullfeeling<=4'd8)&&(cleanness==4'd1)&&(Fullfeeling&&cleanness&&mood))
	     cleanness<=cleanness-4'd1;
   else if(cleanness==4'd0)
	     cleanness<=4'd0;
  		  
   else if((key_code==8'b10111111)&&(Location==1'b1)&&(cleanness<=4'd7)&&(Fullfeeling&&cleanness&&mood)) //1是bathroom
	     cleanness<=cleanness+4'd2;
   else if((key_code==8'b10111111)&&(Location==1'b1)&&(cleanness==4'd8)&&(Fullfeeling&&cleanness&&mood)) //1是bathroom
	     cleanness<=cleanness+4'd1;
	else if((key_code==8'b10111111)&&(Location==1'b1)&&(cleanness==4'd9)&&(Fullfeeling&&cleanness&&mood)) //1是bathroom
	     cleanness<=cleanness;
	else 
	     cleanness<=cleanness;
end

/***************************心情控制(每按壓一次清洗下降2)******************************/     
always @(posedge OUT_CLK1 or negedge Reset)       
begin
   if(!Reset)
		  mood<=4'd5; //心情最高為9，初始為5
   else if((key_code==8'b10111111)&&(Location==1'b1)&&(cleanness<=4'd8)&&(mood>=4'd2)&&(Fullfeeling&&cleanness&&mood)) //1是bathroom
	     mood<=mood-4'd2;
   else if((key_code==8'b10111111)&&(Location==1'b1)&&(cleanness<=4'd8)&&(mood==4'd1)&&(Fullfeeling&&cleanness&&mood)) //1是bathroom
	     mood<=mood-4'd1;
	else if(mood==4'd0)
        mood<=4'd0;
		  
	else if((move_valid==1'b1)&&(Location==1'b0)&&(mood<=4'd8)&&(Fullfeeling&&cleanness&&mood)) //0是livingroom
	     mood<=mood+4'd1;
	else if((move_valid==1'b1)&&(Location==1'b0)&&(mood==4'd9)&&(Fullfeeling&&cleanness&&mood)) //0是livingroom
	     mood<=mood;
   else 
	     mood<=mood;
end

/**************************親密度控制(每2秒一次偵測)*********************************/    
always @(posedge OUT_CLK3 or negedge Reset)       
begin
   if(!Reset)
		  friendship<=4'd4; //親密度最高為8，初始為4
   else if((Fullfeeling>=4'd3)&&(cleanness>=4'd3)&&(mood>=4'd3)&&(friendship<=4'd7)) 
	     friendship<=friendship+4'd1;
	else if((Fullfeeling>=4'd3)&&(cleanness>=4'd3)&&(mood>=4'd3)&&(friendship==4'd8))
        friendship<=friendship;
	else if(friendship==4'd0)
	     friendship<=friendship;
	else
	     friendship<=friendship-4'd1;
end


/****************************數0~9的counter**************************/
always @(posedge OUT_CLK1 or negedge Reset)
begin
   if(!Reset)
      five_count<=4'd0;
   else if (five_count==4'd9)
	   five_count<=4'd0;
	else
	   five_count<=five_count+1'b1;
end


reg Previous_Location;
wire Location_Change;
/****************************偵測Location是否變化**************************/
always@(posedge LGM_CLK or negedge Reset) 
begin 
   if (!Reset) 
	   Previous_Location<=1'b0;
   else if (EnableCount==2'd3)
	   Previous_Location<=Location;
	else 
	   Previous_Location<=Previous_Location;
end

assign Location_Change=Location^Previous_Location;




/*********************************************************************************************************************/
/****************************************************X、Y控制block*****************************************************/
/*********************************************************************************************************************/
always @(posedge OUT_CLK1 or negedge Reset)
begin
   if(!Reset)
   begin
		  X<=4'd5;
		  Y<=4'd0;
		  move_valid<=1'b0;
   end
   else 
   begin
	   case({X,Y})
		   8'b0000_0000:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0001_0000:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
		   8'b0010_0000:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0011_0000:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
         8'b0100_0000:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
         8'b0101_0000:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
         8'b0110_0000:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end 
         8'b0111_0000:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b1000_0000:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end		 
         8'b1001_0000:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b1010_0000:begin   case(keyboard_key_in)
							           
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end


  

         8'b0000_0001:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0001_0001:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end 
			8'b0010_0001:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end				
         8'b0011_0001:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end 
         8'b0100_0001:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0101_0001:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0110_0001:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0111_0001:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b1000_0001:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b1001_0001:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b1010_0001:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
							 
							 
							 
			8'b0000_0010:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0001_0010:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end 
			8'b0010_0010:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end				
         8'b0011_0010:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end 
         8'b0100_0010:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0101_0010:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0110_0010:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0111_0010:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b1000_0010:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b1001_0010:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
							           5'd6:begin X<=X; Y<=Y+1'b1; move_valid<=1'b1;end
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b1010_0010:begin   case(keyboard_key_in)
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end		




         8'b0000_0011:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0001_0011:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end							          
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end 
			8'b0010_0011:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end							           
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end				
         8'b0011_0011:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end							           
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end 
         8'b0100_0011:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end							           
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0101_0011:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end							           
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0110_0011:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end							           
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b0111_0011:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end							          
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b1000_0011:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end							          
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b1001_0011:begin   case(keyboard_key_in)          
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end
			8'b1010_0011:begin   case(keyboard_key_in)
							           5'd8:begin X<=X+1'b1; Y<=Y; move_valid<=1'b1;end						
										  5'd2:begin X<=X-1'b1; Y<=Y; move_valid<=1'b1;end
										  5'd4:begin X<=X; Y<=Y-1'b1; move_valid<=1'b1;end
							           default:begin X<=X; Y<=Y; move_valid<=1'b0;end
						    endcase  end

          default:    begin   case(keyboard_key_in)
							         default:begin X<=X; Y<=Y;  move_valid<=1'b0;end
						    endcase                                         end
		endcase	
    end
end


/*********************************************************************************************************************/
/********************************************LGM Combinational部分*****************************************************/
/*********************************************************************************************************************/
output reg LGM_DI;
output reg LGM_RW;
output reg[7:0] LGM_DATA;
output reg LGM_RST;

output LGM_En; 
output LGM_CS1, LGM_CS2;

reg [1:0] EnableCount; 
reg STOP;
reg [4:0]level0_state;
reg [4:0]level0_state_NextState;
reg [1:0] LGM_SEL;
reg [2:0] X_Page;
reg [7:0] Y_index;
reg [2:0] X_Page1;
reg [7:0] Y_index1;

reg [7:0] LOWER_PATTERN0,LOWER_PATTERN1,LOWER_PATTERN2,LOWER_PATTERN3,LOWER_PATTERN4,LOWER_PATTERN5,LOWER_PATTERN6,LOWER_PATTERN7;
reg [7:0] UPPER_PATTERN0,UPPER_PATTERN1,UPPER_PATTERN2,UPPER_PATTERN3,UPPER_PATTERN4;
reg [7:0] Figure_PATTERN0,Figure_PATTERN1,Figure_PATTERN2,Figure_PATTERN3;

reg [4:0]level1_state;
reg [4:0]level1_state_NextState;

wire LGM_CS1, LGM_CS2; 
wire LGM_En;

assign LGM_CS1=LGM_SEL[0]; 
assign LGM_CS2=LGM_SEL[1];


/**************************** LGM_En(不用改)******************************/
always@(posedge LGM_CLK or negedge Reset)
begin
   if(!Reset)
      EnableCount<=2'b0;
   else
      EnableCount<=EnableCount+1'b1;
end

assign LGM_En=(STOP)?    1'b0:(EnableCount[0]&(~EnableCount[1]));

/******************** Next State Control(不用改)*************************/
always@(posedge LGM_CLK or negedge Reset)
begin
   if (!Reset)
      level0_state<=5'd0; //from state0
   else 
	begin
   if (EnableCount==2'd3) 
	   level0_state<=level0_state_NextState;
   else 
	   level0_state<=level0_state;
   end
end



/******************** Next State Control(不用改)*************************/
always@(posedge LGM_CLK or negedge Reset)
begin
   if (!Reset)
      level1_state<=5'd0; //from state0
   else 
	begin
   if (EnableCount==2'd3) 
	   level1_state<=level1_state_NextState;
   else 
	   level1_state<=level1_state;
   end
end

/************************Combinational Logic****************************/
always@(*)
begin
   case(level)
	1'b0:begin 
           case (level0_state)
              5'd0: begin 
                    STOP=0;
                    LGM_RST=0; // assert LGM_RST
                    LGM_SEL=2'b11;
                    LGM_DI=1'b0;
                    LGM_RW=1'b0;
                    LGM_DATA=8'd0;
                    level0_state_NextState=5'd1; end
   
	           5'd1: begin 
	                 STOP=0;
                    LGM_RST=1; // back to normal mode
                    LGM_SEL=2'b11;
                    LGM_DI=1'b0; 
                    LGM_RW=1'b0;
                    LGM_DATA=8'h3F; //display on the screen
                    level0_state_NextState=5'd2; end

              5'd2: begin 
                    STOP=0; 
	                 LGM_RST=1; 
					     LGM_SEL=2'b11; 
					     LGM_DI=1'b0; 
					     LGM_RW=1'b0; 
					     LGM_DATA=8'b11_000000; //start line is 0 
					     level0_state_NextState=5'd3; end 
/************************************************************************/	
	           5'd3: begin 
	                 STOP=0; 
	                 LGM_RST=1; 
					     LGM_SEL=2'b11; 
					     LGM_DI=1'b0; 
					     LGM_RW=1'b0; 
					     LGM_DATA=8'h40; //Y address register = 0
					     level0_state_NextState=5'd4; end 
	
	           5'd4: begin 
	                 STOP=0; 
	                 LGM_RST=1; 
					     LGM_SEL=2'b11; 
					     LGM_DI=1'b0; 
					     LGM_RW=1'b0; 
					     LGM_DATA= {5'b10111,X_Page}; //set X_page
					     level0_state_NextState=5'd5; end
  
              5'd5: begin 
                    STOP=0; // clear screen
                    LGM_RST=1;
                    LGM_SEL=2'b11;
                    LGM_DI=1'b1; 
					     LGM_RW=1'b0; // write data
                    LGM_DATA=8'd00; //write " "
                    if ((X_Page<3'd7)&&(Y_index==8'd127))
                       level0_state_NextState=5'd4;
                    else if ((X_Page==3'd7)&&(Y_index==8'd127))
                       level0_state_NextState=5'd6;
                    else
                       level0_state_NextState=5'd5;end
/************************************************************************/	              
              5'd6: begin 
                    STOP=0;
                    LGM_RST=1;
                    LGM_SEL=2'b11;
                    LGM_DI=1'b0; 
					     LGM_RW=1'b0;
                    LGM_DATA= {5'b10111,X_Page}; //set X_page
                    level0_state_NextState=5'd7; end

              5'd7: begin 
                    STOP=0; 
	                 LGM_RST=1; 
					     if (Y_index<64) 
					         LGM_SEL=2'b01; 
					     else 
					         LGM_SEL=2'b10; 
					     LGM_DI=1'b1;
					     LGM_RW=1'b0; // write data 
					
  			           LGM_DATA=LOWER_PATTERN0;
                   
                   
						
					     if ((X_Page==3'd5)&&(Y_index==8'd127)) 
					         level0_state_NextState=5'd8; 
					     else 
					         level0_state_NextState=5'd7; end
					
/************************************************************************/
              5'd8: begin 
                    STOP=0;
                    LGM_RST=1;
                    LGM_SEL=2'b11;
					     LGM_DI=1'b0; 
					     LGM_RW=1'b0;
					     LGM_DATA=8'd0;
					          
					     if(!(Fullfeeling))
					             level0_state_NextState=5'd9;
					     else
					             level0_state_NextState=5'd8; end
					
/************************************************************************/	 					
              5'd9: begin  
                    STOP=0; 
	                 LGM_RST=1; 
					     LGM_SEL=2'b11; 
					     LGM_DI=1'b0; 
					     LGM_RW=1'b0; 
					     LGM_DATA=8'h40; //Y address register = 0
					     level0_state_NextState=5'd10; end

             5'd10: begin 
                    STOP=0;
                    LGM_RST=1;
                    LGM_SEL=2'b11;
                    LGM_DI=1'b0; 
					     LGM_RW=1'b0;
                    LGM_DATA= {5'b10111,X_Page}; //set X_page
                    level0_state_NextState=4'd11; end		
					
             5'd11: begin 
                    STOP=0; 
	                 LGM_RST=1; 
					     if (Y_index<64) 
					          LGM_SEL=2'b01; 
					     else 
					          LGM_SEL=2'b10; 
					     LGM_DI=1'b1;
					     LGM_RW=1'b0; // write data 
					
                    LGM_DATA=LOWER_PATTERN1;
                     
                    if ((X_Page==3'd5)&&(Y_index==8'd127)) 
					             level0_state_NextState=5'd8; 
					     else 
					             level0_state_NextState=5'd11; end
					             
           default: begin
                    STOP=1; // stop LGM_En 
	                 LGM_RST=1; 
						  LGM_SEL=2'b11; 
						  LGM_DI=1'b0; 
						  LGM_RW=1'b0; 
						  LGM_DATA=8'd0; 
						  level0_state_NextState=4'd15; end 
           endcase    	 
           end
			  
     1'b1: begin 
           case (level1_state)
              5'd0: begin 
                    STOP=0;
                    LGM_RST=0; // assert LGM_RST
                    LGM_SEL=2'b11;
                    LGM_DI=1'b0;
                    LGM_RW=1'b0;
                    LGM_DATA=8'd0;
                    level1_state_NextState=5'd1; end
   
	           5'd1: begin 
	                 STOP=0;
                    LGM_RST=1; // back to normal mode
                    LGM_SEL=2'b11;
                    LGM_DI=1'b0; 
                    LGM_RW=1'b0;
                    LGM_DATA=8'h3F; //display on the screen
                    level1_state_NextState=5'd2; end

              5'd2: begin 
                    STOP=0; 
	                 LGM_RST=1; 
					     LGM_SEL=2'b11; 
					     LGM_DI=1'b0; 
					     LGM_RW=1'b0; 
					     LGM_DATA=8'b11_000000; //start line is 0 
					     level1_state_NextState=5'd3; end 
/************************************************************************/	
	           5'd3: begin 
	                 STOP=0; 
	                 LGM_RST=1; 
					     LGM_SEL=2'b11; 
					     LGM_DI=1'b0; 
					     LGM_RW=1'b0; 
					     LGM_DATA=8'h40; //Y address register = 0
					     level1_state_NextState=5'd4; end 
	
	           5'd4: begin 
	                 STOP=0; 
	                 LGM_RST=1; 
					     LGM_SEL=2'b11; 
					     LGM_DI=1'b0; 
					     LGM_RW=1'b0; 
					     LGM_DATA= {5'b10111,X_Page1}; //set X_page
					     level1_state_NextState=5'd5; end
  
              5'd5: begin 
                    STOP=0; // clear screen
                    LGM_RST=1;
                    LGM_SEL=2'b11;
                    LGM_DI=1'b1; 
					     LGM_RW=1'b0; // write data
                    LGM_DATA=8'd00; //write " "
                    if ((X_Page1<3'd7)&&(Y_index1==8'd127))
                       level1_state_NextState=5'd4;
                    else if ((X_Page1==3'd7)&&(Y_index1==8'd127))
                       level1_state_NextState=5'd6;
                    else
                       level1_state_NextState=5'd5;end
/************************************************************************/	              
              5'd6: begin 
                    STOP=0;
                    LGM_RST=1;
                    LGM_SEL=2'b11;
                    LGM_DI=1'b0; 
					     LGM_RW=1'b0;
                    LGM_DATA= {5'b10111,X_Page1}; //set X_page
                    level1_state_NextState=5'd7; end

              5'd7: begin 
                    STOP=0; 
	                 LGM_RST=1; 
					     if (Y_index1<64) 
					          LGM_SEL=2'b01; 
					     else 
					          LGM_SEL=2'b10; 
					     LGM_DI=1'b1;
					     LGM_RW=1'b0; // write data 
					
  			           if (X_Page1==3'd2)
                    begin
                       case(Location)
                          1'b0:LGM_DATA=UPPER_PATTERN0;
                          1'b1:LGM_DATA=UPPER_PATTERN1;							  
					        endcase
						  end
						  
                    else if(X_Page1==3'd4)
						  begin
						     case(Location)
                          1'b0:LGM_DATA=UPPER_PATTERN2;
                          1'b1:LGM_DATA=UPPER_PATTERN3;							  
					        endcase
						  end
						  
                    else if(X_Page1==3'd6)
                       LGM_DATA=UPPER_PATTERN4;		
						
				        else if(X_Page1==3'd3)
						  begin
						     case(Location)
							  1'b0:LGM_DATA=LOWER_PATTERN2;
							  1'b1:LGM_DATA=LOWER_PATTERN3;
					        endcase
						  end
						  
				        else
						  begin
						     case(Location)
							  1'b0:LGM_DATA=LOWER_PATTERN4;
							  1'b1:LGM_DATA=LOWER_PATTERN5;
					        endcase
						  end 
						
				        if ((X_Page1==3'd6)&&(Y_index1==8'd127)) 
					        level1_state_NextState=4'd8; 
				        else if (((X_Page1==3'd2)||(X_Page1==3'd3)||(X_Page1==3'd4)||(X_Page1==3'd5))&&(Y_index1==8'd127)) 
					        level1_state_NextState=5'd6; 
				        else    
                       level1_state_NextState=5'd7; end

					
/************************************************************************/
              5'd8: begin 
                    STOP=0;
                    LGM_RST=1;
                    LGM_SEL=2'b11;
					     LGM_DI=1'b0; 
					     LGM_RW=1'b0;
					     LGM_DATA=8'd0;
					          
												  
					     if((!(Fullfeeling&&cleanness&&mood))||((move_valid==1'b1)&&(Figure_counter==6'b000000)&&(check_counter<=4'b0011))||Location_Change)
					          level1_state_NextState=5'd9;      
					     else
					          level1_state_NextState=5'd8; end					
/************************************************************************/	 					
              5'd9: begin  
                    STOP=0; 
	                 LGM_RST=1; 
					     LGM_SEL=2'b11; 
					     LGM_DI=1'b0; 
					     LGM_RW=1'b0; 
					     LGM_DATA=8'h40; //Y address register = 0
					     level1_state_NextState=5'd10; end

             5'd10: begin 
                    STOP=0;
                    LGM_RST=1;
                    LGM_SEL=2'b11;
                    LGM_DI=1'b0; 
					     LGM_RW=1'b0;
                    LGM_DATA= {5'b10111,X_Page1}; //set X_page
                    level1_state_NextState=5'd11; end		
					
             5'd11: begin 
                    STOP=0; 
	                 LGM_RST=1; 
					     if (Y_index1<64) 
					         LGM_SEL=2'b01; 
					     else 
					         LGM_SEL=2'b10; 
					     LGM_DI=1'b1;
					     LGM_RW=1'b0; // write data 
					
                    if (X_Page1==3'd2)
                    begin
                       case(Location)
                          1'b0:LGM_DATA=UPPER_PATTERN0;
                          1'b1:LGM_DATA=UPPER_PATTERN1;							  
					        endcase
						  end
						  
                    else if(X_Page1==3'd4)
						  begin
						     case(Location)
                          1'b0:LGM_DATA=UPPER_PATTERN2;
                          1'b1:LGM_DATA=UPPER_PATTERN3;							  
					        endcase
						  end
						  
                    else if(X_Page1==3'd6)
                       LGM_DATA=UPPER_PATTERN4;		
						
				        else if(X_Page1==3'd3)
						  begin
						     case(Location)
							  1'b0:LGM_DATA=LOWER_PATTERN2;
							  1'b1:LGM_DATA=LOWER_PATTERN3;
					        endcase
						  end
						  
				        else
						  begin
						     case(Location)
							  1'b0:LGM_DATA=LOWER_PATTERN6;
							  1'b1:LGM_DATA=LOWER_PATTERN7;
					        endcase
						  end 
						
				        if ((X_Page1==3'd6)&&(Y_index1==8'd127)) 
					        level1_state_NextState=4'd12; 
				        else if (((X_Page1==3'd2)||(X_Page1==3'd3)||(X_Page1==3'd4)||(X_Page1==3'd5))&&(Y_index1==8'd127)) 
					        level1_state_NextState=5'd10; 
				        else    
                       level1_state_NextState=5'd11; end
							  
							  
/************************************************************************/	 					
              5'd12: begin  
                    STOP=0; 
	                 LGM_RST=1; 
					     LGM_SEL=2'b11; 
					     LGM_DI=1'b0; 
					     LGM_RW=1'b0; 
					     LGM_DATA={2'b01,Y_index1[5:0]}; //Y address register  已經是變數了
					     level1_state_NextState=5'd13; end

             5'd13: begin 
                    STOP=0;
                    LGM_RST=1;
                    LGM_SEL=2'b11;
                    LGM_DI=1'b0; 
					     LGM_RW=1'b0;
                    LGM_DATA= {5'b10111,X_Page1}; //set X_page
                    level1_state_NextState=5'd14; end		
					
             5'd14: begin 
                    STOP=0; 
	                 LGM_RST=1; 
					     if (Y_index1<64) 
					         LGM_SEL=2'b01; 
					     else 
					         LGM_SEL=2'b10; 
					     LGM_DI=1'b1;
					     LGM_RW=1'b0; // write data 
					
                    if((({X,Y}==8'b00000000)||({X,Y}==8'b00010000)||({X,Y}==8'b00100000)||({X,Y}==8'b00110000)||({X,Y}==8'b01000000)||({X,Y}==8'b01010000)||({X,Y}==8'b01100000)||({X,Y}==8'b01110000)||({X,Y}==8'b10000000)||({X,Y}==8'b10010000)||({X,Y}==8'b10100000)||
						      ({X,Y}==8'b00000001)||({X,Y}==8'b00010001)||({X,Y}==8'b00100001)||({X,Y}==8'b00110001)||({X,Y}==8'b01000001)||({X,Y}==8'b01010001)||({X,Y}==8'b01100001)||({X,Y}==8'b01110001)||({X,Y}==8'b10000001)||({X,Y}==8'b10010001)||({X,Y}==8'b10100001)||
								({X,Y}==8'b00000010)||({X,Y}==8'b00010010)||({X,Y}==8'b00100010)||({X,Y}==8'b00110010)||({X,Y}==8'b01000010)||({X,Y}==8'b01010010)||({X,Y}==8'b01100010)||({X,Y}==8'b01110010)||({X,Y}==8'b10000010)||({X,Y}==8'b10010010)||({X,Y}==8'b10100010)||
								({X,Y}==8'b00000011))&&(Fullfeeling&&cleanness&&mood))
					           LGM_DATA=Figure_PATTERN0;
						  else if((({X,Y}==8'b00010011)||({X,Y}==8'b00100011)||({X,Y}==8'b00110011)||({X,Y}==8'b01000011)||({X,Y}==8'b01010011)||({X,Y}==8'b01100011)||({X,Y}==8'b01110011)||({X,Y}==8'b10000011)||({X,Y}==8'b10010011)||
						           ({X,Y}==8'b10100011))&&(Fullfeeling&&cleanness&&mood))
								  LGM_DATA=Figure_PATTERN2;
						  else if((({X,Y}==8'b00010011)||({X,Y}==8'b00100011)||({X,Y}==8'b00110011)||({X,Y}==8'b01000011)||({X,Y}==8'b01010011)||({X,Y}==8'b01100011)||({X,Y}==8'b01110011)||({X,Y}==8'b10000011)||({X,Y}==8'b10010011)||
						           ({X,Y}==8'b10100011))&&!(Fullfeeling&&cleanness&&mood))
								  LGM_DATA=Figure_PATTERN3;  
                    else 
					           LGM_DATA=Figure_PATTERN1;	
                   
						 
						 
						 
						  
			           if (Figure_counter1==6'd7) 
						  begin
						     if(!(Fullfeeling&&cleanness&&mood))
				           level1_state_NextState=5'd15;
                       else
                       level1_state_NextState=5'd8; 
                    end  							  
			           else
                       level1_state_NextState=5'd14; end


					             
           default: begin
                    STOP=1; // stop LGM_En 
	                 LGM_RST=1; 
						  LGM_SEL=2'b11; 
						  LGM_DI=1'b0; 
						  LGM_RW=1'b0; 
						  LGM_DATA=8'd0; 
						  level1_state_NextState=5'd15; end 
           endcase    	 
           end
    endcase
end



/*********************************************************************************************************************/
/*********************************************LGM Sequential部分0*******************************************************/
/*********************************************************************************************************************/
reg [7:0]P_index;
reg [5:0]Figure_counter;
reg [5:0]Figure_counter1;


/************************Page & index Control****************************/ 
always@(posedge LGM_CLK or negedge Reset) 
begin 
   if (!Reset) 
   begin 
	   X_Page<=3'd0;  
	   Y_index<=8'd0;
     
	   Figure_counter<=6'd0;
	end
 
	else 
	begin
/****************************state=4'd5***********************************/		
	if ((EnableCount==2'd3) && (level0_state==4'd5)) 
	begin 
	   if (Y_index==8'd127)
		begin 
		   if (X_Page==3'd7)		
			   X_Page<=3'd5;
		   else			
			   X_Page <= X_Page+1'b1;
				
		   Y_index<=8'd0;	    
		end 
		
		else 
		begin 
		   X_Page<=X_Page; 
		   Y_index<=Y_index+1'b1; 
		   
		   Figure_counter<=6'd0;
		end 
	end
/****************************state=4'd7***********************************/   
	else if ((EnableCount==2'd3) && (level0_state==4'd7)) 
	begin 
	   if (Y_index==8'd127)
		begin 
		   if (X_Page==3'd5)
         begin			
			   X_Page<=3'd5;
			   Y_index<=8'd0;
		   end
		   else
         begin			
			   X_Page <= X_Page+1'b1;
			   Y_index<=8'd0;
			end
		end  
		
	   else 
		begin 
		   X_Page<=X_Page; 
		   Y_index<=Y_index+1'b1;
        
		   Figure_counter<=6'd0;			
		end 
	end 

/****************************state=4'd8***********************************/
   else if ((EnableCount==2'd3) && (level0_state==4'd8)) 
	begin 
		X_Page<=3'd5;
		Y_index<=8'd0;
	end
/****************************state=4'd11***********************************/	
	else if((EnableCount==2'd3) && (level0_state==4'd11))
	begin 
	   if (Y_index==8'd127)
		begin 
		   if (X_Page==3'd5)
         begin			
			   X_Page<=3'd5;
		      Y_index<=8'd0;   
 		   end


			else
         begin			
			   X_Page <= X_Page+1'b1;
				Y_index<=8'd0;
			 end   
		end  
		
		else 
		begin 
		   X_Page<=X_Page; 
			Y_index<=Y_index+1'b1;
         
			Figure_counter<=6'd0;			
		end 
	end

/****************************其餘state***********************************/	
	else 
	begin
	   X_Page<=X_Page;
		Y_index<=Y_index;
		Figure_counter<=Figure_counter;
		
	end
	end
end








/*********************************************************************************************************************/
/*********************************************LGM Sequential部分1*******************************************************/
/*********************************************************************************************************************/

/************************Page & index Control****************************/ 
always@(posedge LGM_CLK or negedge Reset) 
begin 
   if (!Reset) 
   begin 
	   X_Page1<=3'd0;  
	   Y_index1<=8'd0;
      P_index<=8'd0;
	   Figure_counter1<=6'd0;
	end
 
	else 
	begin
/****************************state=4'd5***********************************/		
	if ((EnableCount==2'd3) && (level1_state==4'd5)) 
	begin 
	   if (Y_index1==8'd127)
		begin 
		   if (X_Page1==3'd7)		
			   X_Page1<=3'd2;
		   else			
			   X_Page1 <= X_Page1+1'b1;
				
		   Y_index1<=8'd0;	    
		end 
		
		else 
		begin 
		   X_Page1<=X_Page1; 
		   Y_index1<=Y_index1+1'b1; 
		   P_index<=8'd0;
		   Figure_counter1<=6'd0;
		end 
	end
/****************************state=4'd7***********************************/   
	else if ((EnableCount==2'd3) && (level1_state==4'd7)) 
	begin 
	   if (Y_index1==8'd127)
		begin 
		   if (X_Page1==3'd6)
         begin			
			   X_Page1<=3'd2;
			   Y_index1<=8'd0;
		   end
		   else
         begin			
			   X_Page1 <= X_Page1+1'b1;
			   Y_index1<=8'd0;
			end
		end  
		
	   else 
		begin 
		   X_Page1<=X_Page1; 
		   Y_index1<=Y_index1+1'b1;
         P_index<=8'd0;
		   Figure_counter1<=6'd0;			
		end 
	end 

/****************************state=4'd8***********************************/
   else if ((EnableCount==2'd3) && (level1_state==4'd8)) 
	begin 
		X_Page1<=3'd2;
		Y_index1<=8'd0;
		
		if(keyboard_press)
		   Figure_counter1<=Figure_counter1;
		else
		   Figure_counter1<=6'b000000;

	end
/****************************state=4'd11***********************************/	
	else if((EnableCount==2'd3) && (level1_state==4'd11))
	begin 
	   if (Y_index1==8'd127)
		begin 
		   if (X_Page1==3'd6)
         begin			
			   case({X,Y})   //設定要畫的X_Page、設定要畫的Y_index
				   8'b0000_0000:begin X_Page1<=3'd5; Y_index1<=8'd16;end
				   8'b0001_0000:begin X_Page1<=3'd5; Y_index1<=8'd24;end
					8'b0010_0000:begin X_Page1<=3'd5; Y_index1<=8'd32;end
					8'b0011_0000:begin X_Page1<=3'd5; Y_index1<=8'd40;end
					8'b0100_0000:begin X_Page1<=3'd5; Y_index1<=8'd48;end
					8'b0101_0000:begin X_Page1<=3'd5; Y_index1<=8'd56;end
					8'b0110_0000:begin X_Page1<=3'd5; Y_index1<=8'd64;end
					8'b0111_0000:begin X_Page1<=3'd5; Y_index1<=8'd72;end
					8'b1000_0000:begin X_Page1<=3'd5; Y_index1<=8'd80;end
					8'b1001_0000:begin X_Page1<=3'd5; Y_index1<=8'd88;end
					8'b1010_0000:begin X_Page1<=3'd5; Y_index1<=8'd96;end
					
					8'b0000_0001:begin X_Page1<=3'd4; Y_index1<=8'd16;end
				   8'b0001_0001:begin X_Page1<=3'd4; Y_index1<=8'd24;end
					8'b0010_0001:begin X_Page1<=3'd4; Y_index1<=8'd32;end
					8'b0011_0001:begin X_Page1<=3'd4; Y_index1<=8'd40;end
					8'b0100_0001:begin X_Page1<=3'd4; Y_index1<=8'd48;end
					8'b0101_0001:begin X_Page1<=3'd4; Y_index1<=8'd56;end
					8'b0110_0001:begin X_Page1<=3'd4; Y_index1<=8'd64;end
					8'b0111_0001:begin X_Page1<=3'd4; Y_index1<=8'd72;end
					8'b1000_0001:begin X_Page1<=3'd4; Y_index1<=8'd80;end
					8'b1001_0001:begin X_Page1<=3'd4; Y_index1<=8'd88;end
					8'b1010_0001:begin X_Page1<=3'd4; Y_index1<=8'd96;end
					
					8'b0000_0010:begin X_Page1<=3'd3; Y_index1<=8'd16;end
				   8'b0001_0010:begin X_Page1<=3'd3; Y_index1<=8'd24;end
					8'b0010_0010:begin X_Page1<=3'd3; Y_index1<=8'd32;end
					8'b0011_0010:begin X_Page1<=3'd3; Y_index1<=8'd40;end
					8'b0100_0010:begin X_Page1<=3'd3; Y_index1<=8'd48;end
					8'b0101_0010:begin X_Page1<=3'd3; Y_index1<=8'd56;end
					8'b0110_0010:begin X_Page1<=3'd3; Y_index1<=8'd64;end
					8'b0111_0010:begin X_Page1<=3'd3; Y_index1<=8'd72;end
					8'b1000_0010:begin X_Page1<=3'd3; Y_index1<=8'd80;end
					8'b1001_0010:begin X_Page1<=3'd3; Y_index1<=8'd88;end
					8'b1010_0010:begin X_Page1<=3'd3; Y_index1<=8'd96;end
					
					8'b0000_0011:begin X_Page1<=3'd2; Y_index1<=8'd16;end
				   8'b0001_0011:begin X_Page1<=3'd2; Y_index1<=8'd24;end
					8'b0010_0011:begin X_Page1<=3'd2; Y_index1<=8'd32;end
					8'b0011_0011:begin X_Page1<=3'd2; Y_index1<=8'd40;end
					8'b0100_0011:begin X_Page1<=3'd2; Y_index1<=8'd48;end
					8'b0101_0011:begin X_Page1<=3'd2; Y_index1<=8'd56;end
					8'b0110_0011:begin X_Page1<=3'd2; Y_index1<=8'd64;end
					8'b0111_0011:begin X_Page1<=3'd2; Y_index1<=8'd72;end
					8'b1000_0011:begin X_Page1<=3'd2; Y_index1<=8'd80;end
					8'b1001_0011:begin X_Page1<=3'd2; Y_index1<=8'd88;end
					8'b1010_0011:begin X_Page1<=3'd2; Y_index1<=8'd96;end
					
					default:begin X_Page1<=3'd2; Y_index1<=8'd16;end         
				endcase
   
 		   end


			else
         begin			
			   X_Page1 <= X_Page1+1'b1;
				Y_index1<=8'd0;
			 end   
		end  
		
		else 
		begin 
		   X_Page1<=X_Page1; 
			Y_index1<=Y_index1+1'b1;
         P_index<=8'd0;
			Figure_counter1<=6'd0;			
		end 
	end


/****************************state=4'd14***********************************/
	else if ((EnableCount==2'd3) && (level1_state==4'd14)) 
	begin 
	   if (Figure_counter1==6'd7)
	   begin	
    	  X_Page1<=5'd0;
		  Y_index1<=8'd40;
		  P_index<=8'd0;
		  Figure_counter1<=6'b100000; //做一個記號表示已畫完，不然會一直從state8~state14
	   end
      else
	   begin
		   P_index<=P_index+1'b1;
         Figure_counter1<=Figure_counter1+1'b1;		
	   end
	end 	

/****************************其餘state***********************************/	
	else 
	begin
	   X_Page1<=X_Page1;
		Y_index1<=Y_index1;
		Figure_counter1<=Figure_counter1;
		P_index<=P_index;
	end
	end

end

/*************************check_counter*********************************/
always@(posedge LGM_CLK or negedge Reset) 
begin 
   if (!Reset) 
		check_counter<=4'b0;
   else if(move_valid&&(check_counter<4'b1000))
	   check_counter<=check_counter+1'b1;
	else if (move_valid&&(check_counter==4'b1000))
	   check_counter<=check_counter;
	else
	   check_counter<=4'b0;
end



/*********************************************************************************************************************/
/******************************************************push button****************************************************/
/*********************************************************************************************************************/

/************************偵測press******************************/
always @ (S)
begin
   case(S)		
	   8'b01111111:press=1'b0;//S1對到S[7]
      8'b10111111:press=1'b0;//S2對到S[6]
		8'b11011111:press=1'b0;//S3對到S[5]
		8'b11101111:press=1'b0;//S4對到S[4]
		8'b11110111:press=1'b0;//S5對到S[3]
		8'b11111011:press=1'b0;//S6對到S[2]
	   8'b11111101:press=1'b0;//S7對到S[1]
		8'b11111110:press=1'b0;//S8對到S[0]
		default:press=1'b1;
	endcase
end
	
/***********************Debounce Circuit************************/
always @(posedge DEBOUNCE_CLK or negedge Reset)
begin
   if(!Reset)
	   debounce_count<=4'b0;
	else if(press)
	   debounce_count<=4'b0;
	else if(debounce_count<=4'b1110)
	   debounce_count<=debounce_count+4'b0001;
end

assign press_valid = (debounce_count == 4'b1101)?  1'b1:1'b0;

/**********************Fetch Key Code**************************/
always @ (negedge DEBOUNCE_CLK or negedge Reset)
begin
   if(!Reset)
	   key_code <=8'b11111111;
	else if(press_valid)
	   key_code <=S;
	else if(press)
	   key_code<=8'b11111111;
	else
	   key_code <=key_code;
end




/*********************************************************************************************************************/
/****************************************************鍵盤設定**********************************************************/
/*********************************************************************************************************************/


/***********************Scanning Code Generator***************************/
always @(posedge CLK or negedge Reset)
begin
   if(!Reset)
      scan_code<=4'b0;
	else if (keyboard_press)  /*沒有按 keyboard_press=1，有按 keyboard_press=0*/
	   scan_code <=scan_code+4'b0001;
	else
	   scan_code <=scan_code;
end

/****************************Scanning Keyboard*****************************/
always@(scan_code or column)
begin
   case(scan_code[3:2])
	   2'b00:row=4'b1110;
		2'b01:row=4'b1101;
		2'b10:row=4'b1011;
		2'b11:row=4'b0111;
	endcase
	case(scan_code[1:0])
	   2'b00:keyboard_press=column[0];
		2'b01:keyboard_press=column[1];
		2'b10:keyboard_press=column[2];
		2'b11:keyboard_press=column[3];
	endcase
end

/****************************Debounce Circuit*********************************/
always @(posedge DEBOUNCE_CLK or negedge Reset)
begin
   if(!Reset)
	   keyboard_debounce_count<=4'b0;
	else if(keyboard_press)
	   keyboard_debounce_count<=4'b0;
	else if(keyboard_debounce_count<=4'b1110)
	   keyboard_debounce_count<=keyboard_debounce_count+4'b0001;
end

assign keyboard_press_valid = (keyboard_debounce_count == 4'b1101)?  1'b1:1'b0;

/****************************Fetch Key Code********************************/
always @ (negedge DEBOUNCE_CLK or negedge Reset)
begin
   if(!Reset)
	   keyboard_key_code <=5'b11111;                
	else if(keyboard_press_valid)
	   keyboard_key_code <={1'b0,scan_code};
	else  if(!keyboard_press)
	   keyboard_key_code<=keyboard_key_code;
	else
	   keyboard_key_code <=5'b11111;
end

/**************************Convert Key Code******************************/
always @(keyboard_key_code)
begin
   case(keyboard_key_code)
	   5'd0: keyboard_key_in=5'd12;
		5'd1: keyboard_key_in=5'd13;
		5'd2: keyboard_key_in=5'd14;
		5'd3: keyboard_key_in=5'd15;
		5'd4: keyboard_key_in=5'd9;
		5'd5: keyboard_key_in=5'd6;
		5'd6: keyboard_key_in=5'd3;
		5'd7: keyboard_key_in=5'd11;
		5'd8: keyboard_key_in=5'd8;
		5'd9: keyboard_key_in=5'd5;
		5'd10:keyboard_key_in=5'd2;
		5'd11:keyboard_key_in=5'd10;
		5'd12:keyboard_key_in=5'd7;
		5'd13:keyboard_key_in=5'd4;
		5'd14:keyboard_key_in=5'd1;
		5'd15:keyboard_key_in=5'd0;
		default:keyboard_key_in=5'b11111; /*31*/
	endcase
end



/*********************************************************************************************************************/
/*****************************************************LED、Seg控制*****************************************************/
/*********************************************************************************************************************/
always @ (friendship or level)
begin
   case({friendship,level})
	   5'b0000_1:LED={8'b0};
		5'b0001_1:LED={1'b1,7'b0};
		5'b0010_1:LED={2'b11,6'b0};
		5'b0011_1:LED={3'b111,5'b0};
		5'b0100_1:LED={4'b1111,4'b0};
		5'b0101_1:LED={5'b11111,3'b0};
		5'b0110_1:LED={6'b111111,2'b0};
		5'b0111_1:LED={7'b1111111,1'b0};
		5'b1000_1:LED={8'b11111111};
		default:LED=8'b00000000;
	endcase
end

/*************************SevenSeg_count************************/
always @(posedge Scan_CLK or negedge Reset)
begin
   if(!Reset)
      SevenSeg_count<=2'd0;
   else if (SevenSeg_count==2'd2)
	   SevenSeg_count<=2'd0;
	else
	   SevenSeg_count<=SevenSeg_count+1'b1;
end

/********************Enable Display Location*******************/
always @(SevenSeg_count or level)
begin
   case({SevenSeg_count,level})
	   3'b00_1: Enable<=4'b1110;
		3'b01_1: Enable<=4'b1101;
		3'b10_1: Enable<=4'b1011;
		default:Enable<=4'b1011;
   endcase
end

/********************Data Display Multiplexer******************/
always @(Enable or mood or cleanness or Fullfeeling)
begin
   case(Enable)
	  4'b1110:Decode_BCD=mood;//顯示心情
	  4'b1101:Decode_BCD=cleanness;//顯示清潔度
	  4'b1011:Decode_BCD=Fullfeeling;//顯示飽足感
	  default:Decode_BCD=4'b0;
   endcase
end

/*********************7seg Decoder**********************/
always @(Decode_BCD)
begin
   
   case(Decode_BCD)   
      4'b0000: Sevenseg ={7'b1111111,8'b11000000};/*0*/
	   4'b0001: Sevenseg ={7'b1111111,8'b11111001};/*1*/
	   4'b0010: Sevenseg ={7'b1111111,8'b00100100};/*2*/
	   4'b0011: Sevenseg ={7'b1111111,8'b00110000};/*3*/
      4'b0100: Sevenseg ={7'b1111111,8'b00011001};/*4*/
	   4'b0101: Sevenseg ={7'b1111111,8'b00010010};/*5*/
	   4'b0110: Sevenseg ={7'b1111111,8'b00000010};/*6*/
	   4'b0111: Sevenseg ={7'b1111111,8'b11111000};/*7*/
	   4'b1000: Sevenseg ={7'b1111111,8'b00000000};/*8*/
	   4'b1001: Sevenseg ={7'b1111111,8'b00010000};/*9*/
	   default: Sevenseg =15'b0;
   endcase
end



/*********************************************************************************************************************/
/****************************************************各個pattern*******************************************************/
/*********************************************************************************************************************/

/**************************LOWER_PATTERN0*********************************/
always@(Y_index) 
begin 
case(Y_index)  

8'h38:LOWER_PATTERN0=8'h08;
8'h39:LOWER_PATTERN0=8'h7E; 
8'h3A:LOWER_PATTERN0=8'hCA; 
8'h3B:LOWER_PATTERN0=8'h63; 
8'h3C:LOWER_PATTERN0=8'h63; 
8'h3D:LOWER_PATTERN0=8'hCA; 
8'h3E:LOWER_PATTERN0=8'h7E; 
8'h3F:LOWER_PATTERN0=8'h08;

default:LOWER_PATTERN0=8'h00;
endcase
end

/**************************LOWER_PATTERN1*********************************/
always@(Y_index) 
begin 
case(Y_index) 

8'h38:LOWER_PATTERN1=8'h08; 
8'h39:LOWER_PATTERN1=8'h7E; 
8'h3A:LOWER_PATTERN1=8'hCA; 
8'h3B:LOWER_PATTERN1=8'h6B; 
8'h3C:LOWER_PATTERN1=8'h6B; 
8'h3D:LOWER_PATTERN1=8'hCA; 
8'h3E:LOWER_PATTERN1=8'h7E; 
8'h3F:LOWER_PATTERN1=8'h08;

default:LOWER_PATTERN1=8'h00; 
endcase 
end


/**************************LOWER_PATTERN2*********************************/
always@(Y_index1)
begin
case(Y_index1)

8'h0F:LOWER_PATTERN2=8'hFF;
8'h68:LOWER_PATTERN2=8'hFF; 

default:LOWER_PATTERN2=8'h00;
endcase
end

/**************************LOWER_PATTERN3*********************************/
always@(Y_index1)
begin
case(Y_index1)

8'h0F:LOWER_PATTERN3=8'hFF;
8'h68:LOWER_PATTERN3=8'hFF; 

default:LOWER_PATTERN3=8'h00;
endcase
end


/**************************LOWER_PATTERN4*********************************/
always@(Y_index1)
begin
case(Y_index1)

8'h0F:LOWER_PATTERN4=8'hFF;
 
8'h38:LOWER_PATTERN4=8'h08;
8'h39:LOWER_PATTERN4=8'h7E;
8'h3A:LOWER_PATTERN4=8'hCA;
8'h3B:LOWER_PATTERN4=8'h63;
8'h3C:LOWER_PATTERN4=8'h63;
8'h3D:LOWER_PATTERN4=8'hCA;
8'h3E:LOWER_PATTERN4=8'h7E;
8'h3F:LOWER_PATTERN4=8'h08;
 
8'h68:LOWER_PATTERN4=8'hFF; 

default:LOWER_PATTERN4=8'h00;
endcase
end



/**************************LOWER_PATTERN5*********************************/
always@(Y_index1)
begin
case(Y_index1)

8'h0F:LOWER_PATTERN5=8'hFF;
 
8'h38:LOWER_PATTERN5=8'h08;
8'h39:LOWER_PATTERN5=8'h7E;
8'h3A:LOWER_PATTERN5=8'hCA;
8'h3B:LOWER_PATTERN5=8'h63;
8'h3C:LOWER_PATTERN5=8'h63;
8'h3D:LOWER_PATTERN5=8'hCA;
8'h3E:LOWER_PATTERN5=8'h7E;
8'h3F:LOWER_PATTERN5=8'h08;
 
8'h68:LOWER_PATTERN5=8'hFF; 

default:LOWER_PATTERN5=8'h00;
endcase
end




/**************************LOWER_PATTERN6*********************************/
always@(Y_index1)
begin
case(Y_index1)

8'h0F:LOWER_PATTERN6=8'hFF;
8'h68:LOWER_PATTERN6=8'hFF; 

default:LOWER_PATTERN6=8'h00;
endcase
end




/**************************LOWER_PATTERN7*********************************/
always@(Y_index1)
begin
case(Y_index1)

8'h0F:LOWER_PATTERN7=8'hFF;
8'h68:LOWER_PATTERN7=8'hFF; 

default:LOWER_PATTERN7=8'h00;
endcase
end



/**************************UPPER_PATTERN0*********************************/
always@(Y_index1)
begin
case(Y_index1)

8'h0F:UPPER_PATTERN0=8'hFF;

8'h10:UPPER_PATTERN0=8'h81;
8'h11:UPPER_PATTERN0=8'h91;
8'h12:UPPER_PATTERN0=8'h81;
8'h13:UPPER_PATTERN0=8'hFF;
8'h14:UPPER_PATTERN0=8'h81;
8'h15:UPPER_PATTERN0=8'h91;
8'h16:UPPER_PATTERN0=8'h81;
8'h17:UPPER_PATTERN0=8'hFF;

8'h18:UPPER_PATTERN0=8'h01;
8'h19:UPPER_PATTERN0=8'h01;
8'h1A:UPPER_PATTERN0=8'h01;
8'h1B:UPPER_PATTERN0=8'h01;
8'h1C:UPPER_PATTERN0=8'h01;
8'h1D:UPPER_PATTERN0=8'h01;
8'h1E:UPPER_PATTERN0=8'h01;
8'h1F:UPPER_PATTERN0=8'h01;

8'h20:UPPER_PATTERN0=8'h01;
8'h21:UPPER_PATTERN0=8'h01;
8'h22:UPPER_PATTERN0=8'h01;
8'h23:UPPER_PATTERN0=8'h01;
8'h24:UPPER_PATTERN0=8'h01;
8'h25:UPPER_PATTERN0=8'h01;
8'h26:UPPER_PATTERN0=8'h01;
8'h27:UPPER_PATTERN0=8'h01;

8'h28:UPPER_PATTERN0=8'h01;
8'h29:UPPER_PATTERN0=8'h01;
8'h2A:UPPER_PATTERN0=8'h01;
8'h2B:UPPER_PATTERN0=8'h01;
8'h2C:UPPER_PATTERN0=8'h01;
8'h2D:UPPER_PATTERN0=8'h01;
8'h2E:UPPER_PATTERN0=8'h01;
8'h2F:UPPER_PATTERN0=8'h01;

8'h30:UPPER_PATTERN0=8'h01;
8'h31:UPPER_PATTERN0=8'h01;
8'h32:UPPER_PATTERN0=8'h01;
8'h33:UPPER_PATTERN0=8'h01;
8'h34:UPPER_PATTERN0=8'h01;
8'h35:UPPER_PATTERN0=8'h01;
8'h36:UPPER_PATTERN0=8'h01;
8'h37:UPPER_PATTERN0=8'h01;

8'h38:UPPER_PATTERN0=8'h01;
8'h39:UPPER_PATTERN0=8'h01;
8'h3A:UPPER_PATTERN0=8'h01;
8'h3B:UPPER_PATTERN0=8'h01;
8'h3C:UPPER_PATTERN0=8'h01;
8'h3D:UPPER_PATTERN0=8'h01;
8'h3E:UPPER_PATTERN0=8'h01;
8'h3F:UPPER_PATTERN0=8'h01;

8'h40:UPPER_PATTERN0=8'h01; 
8'h41:UPPER_PATTERN0=8'h01; 
8'h42:UPPER_PATTERN0=8'h01; 
8'h43:UPPER_PATTERN0=8'h01; 
8'h44:UPPER_PATTERN0=8'h01; 
8'h45:UPPER_PATTERN0=8'h01; 
8'h46:UPPER_PATTERN0=8'h01; 
8'h47:UPPER_PATTERN0=8'h01;

8'h48:UPPER_PATTERN0=8'h01;
8'h49:UPPER_PATTERN0=8'h01; 
8'h4A:UPPER_PATTERN0=8'h01; 
8'h4B:UPPER_PATTERN0=8'h01; 
8'h4C:UPPER_PATTERN0=8'h01; 
8'h4D:UPPER_PATTERN0=8'h01; 
8'h4E:UPPER_PATTERN0=8'h01; 
8'h4F:UPPER_PATTERN0=8'h01; 

8'h50:UPPER_PATTERN0=8'h01; 
8'h51:UPPER_PATTERN0=8'h01; 
8'h52:UPPER_PATTERN0=8'h01; 
8'h53:UPPER_PATTERN0=8'h01; 
8'h54:UPPER_PATTERN0=8'h01; 
8'h55:UPPER_PATTERN0=8'h01; 
8'h56:UPPER_PATTERN0=8'h01; 
8'h57:UPPER_PATTERN0=8'h01;

8'h58:UPPER_PATTERN0=8'h01;
8'h59:UPPER_PATTERN0=8'h01; 
8'h5A:UPPER_PATTERN0=8'h01; 
8'h5B:UPPER_PATTERN0=8'h01; 
8'h5C:UPPER_PATTERN0=8'h01; 
8'h5D:UPPER_PATTERN0=8'h01; 
8'h5E:UPPER_PATTERN0=8'h01; 
8'h5F:UPPER_PATTERN0=8'h01; 

8'h60:UPPER_PATTERN0=8'h09; 
8'h61:UPPER_PATTERN0=8'hD5; 
8'h62:UPPER_PATTERN0=8'hC9; 
8'h63:UPPER_PATTERN0=8'hFF; 
8'h64:UPPER_PATTERN0=8'hFF; 
8'h65:UPPER_PATTERN0=8'hC9; 
8'h66:UPPER_PATTERN0=8'hD5; 
8'h67:UPPER_PATTERN0=8'h09;
 
8'h68:UPPER_PATTERN0=8'hFF; 

default:UPPER_PATTERN0=8'h00;
endcase
end

/**************************UPPER_PATTERN1*********************************/
always@(Y_index1)
begin
case(Y_index1)

8'h0F:UPPER_PATTERN1=8'hFF;

8'h10:UPPER_PATTERN1=8'h01;
8'h11:UPPER_PATTERN1=8'h41;
8'h12:UPPER_PATTERN1=8'hB3;
8'h13:UPPER_PATTERN1=8'h15;
8'h14:UPPER_PATTERN1=8'hB9;
8'h15:UPPER_PATTERN1=8'h11;
8'h16:UPPER_PATTERN1=8'hB1;
8'h17:UPPER_PATTERN1=8'h41;

8'h18:UPPER_PATTERN1=8'h01;
8'h19:UPPER_PATTERN1=8'h01;
8'h1A:UPPER_PATTERN1=8'h01;
8'h1B:UPPER_PATTERN1=8'h01;
8'h1C:UPPER_PATTERN1=8'h01;
8'h1D:UPPER_PATTERN1=8'h01;
8'h1E:UPPER_PATTERN1=8'h01;
8'h1F:UPPER_PATTERN1=8'h01;

8'h20:UPPER_PATTERN1=8'h01;
8'h21:UPPER_PATTERN1=8'h01;
8'h22:UPPER_PATTERN1=8'h01;
8'h23:UPPER_PATTERN1=8'h01;
8'h24:UPPER_PATTERN1=8'h01;
8'h25:UPPER_PATTERN1=8'h01;
8'h26:UPPER_PATTERN1=8'h01;
8'h27:UPPER_PATTERN1=8'h01;

8'h28:UPPER_PATTERN1=8'h01;
8'h29:UPPER_PATTERN1=8'h01;
8'h2A:UPPER_PATTERN1=8'h01;
8'h2B:UPPER_PATTERN1=8'h01;
8'h2C:UPPER_PATTERN1=8'h01;
8'h2D:UPPER_PATTERN1=8'h01;
8'h2E:UPPER_PATTERN1=8'h01;
8'h2F:UPPER_PATTERN1=8'h01;

8'h30:UPPER_PATTERN1=8'h01;
8'h31:UPPER_PATTERN1=8'h01;
8'h32:UPPER_PATTERN1=8'h01;
8'h33:UPPER_PATTERN1=8'h01;
8'h34:UPPER_PATTERN1=8'h01;
8'h35:UPPER_PATTERN1=8'h01;
8'h36:UPPER_PATTERN1=8'h01;
8'h37:UPPER_PATTERN1=8'h01;

8'h38:UPPER_PATTERN1=8'h01;
8'h39:UPPER_PATTERN1=8'h01;
8'h3A:UPPER_PATTERN1=8'h01;
8'h3B:UPPER_PATTERN1=8'h01;
8'h3C:UPPER_PATTERN1=8'h01;
8'h3D:UPPER_PATTERN1=8'h01;
8'h3E:UPPER_PATTERN1=8'h01;
8'h3F:UPPER_PATTERN1=8'h01;

8'h40:UPPER_PATTERN1=8'h01; 
8'h41:UPPER_PATTERN1=8'h01; 
8'h42:UPPER_PATTERN1=8'h01; 
8'h43:UPPER_PATTERN1=8'h01; 
8'h44:UPPER_PATTERN1=8'h01; 
8'h45:UPPER_PATTERN1=8'h01; 
8'h46:UPPER_PATTERN1=8'h01; 
8'h47:UPPER_PATTERN1=8'h01;

8'h48:UPPER_PATTERN1=8'h01;
8'h49:UPPER_PATTERN1=8'h01; 
8'h4A:UPPER_PATTERN1=8'h01; 
8'h4B:UPPER_PATTERN1=8'h01; 
8'h4C:UPPER_PATTERN1=8'h01; 
8'h4D:UPPER_PATTERN1=8'h01; 
8'h4E:UPPER_PATTERN1=8'h01; 
8'h4F:UPPER_PATTERN1=8'h01; 

8'h50:UPPER_PATTERN1=8'h01; 
8'h51:UPPER_PATTERN1=8'h01; 
8'h52:UPPER_PATTERN1=8'h01; 
8'h53:UPPER_PATTERN1=8'h01; 
8'h54:UPPER_PATTERN1=8'h01; 
8'h55:UPPER_PATTERN1=8'h01; 
8'h56:UPPER_PATTERN1=8'h01; 
8'h57:UPPER_PATTERN1=8'h01;

8'h58:UPPER_PATTERN1=8'h01;
8'h59:UPPER_PATTERN1=8'h01; 
8'h5A:UPPER_PATTERN1=8'h01; 
8'h5B:UPPER_PATTERN1=8'h01; 
8'h5C:UPPER_PATTERN1=8'h01; 
8'h5D:UPPER_PATTERN1=8'h01; 
8'h5E:UPPER_PATTERN1=8'h01; 
8'h5F:UPPER_PATTERN1=8'h01; 

8'h60:UPPER_PATTERN1=8'h55; 
8'h61:UPPER_PATTERN1=8'h05; 
8'h62:UPPER_PATTERN1=8'h57; 
8'h63:UPPER_PATTERN1=8'h05; 
8'h64:UPPER_PATTERN1=8'h55; 
8'h65:UPPER_PATTERN1=8'h01; 
8'h66:UPPER_PATTERN1=8'h01; 
8'h67:UPPER_PATTERN1=8'h01;
 
8'h68:UPPER_PATTERN1=8'hFF; 

default:UPPER_PATTERN1=8'h00;
endcase
end


/**************************UPPER_PATTERN2*********************************/
always@(Y_index1)
begin
case(Y_index1)

8'h0F:UPPER_PATTERN2=8'hFF;
8'h68:UPPER_PATTERN2=8'hFF; 

default:UPPER_PATTERN2=8'h00;
endcase
end

/**************************UPPER_PATTERN3*********************************/
always@(Y_index1)
begin
case(Y_index1)

8'h0F:UPPER_PATTERN3=8'hFF;
8'h68:UPPER_PATTERN3=8'hFF; 

default:UPPER_PATTERN3=8'h00;
endcase
end

/**************************UPPER_PATTERN4*********************************/
always@(Y_index1)
begin
case(Y_index1)

8'h0F:UPPER_PATTERN4=8'h01;

8'h10:UPPER_PATTERN4=8'h01;
8'h11:UPPER_PATTERN4=8'h01;
8'h12:UPPER_PATTERN4=8'h01;
8'h13:UPPER_PATTERN4=8'h01;
8'h14:UPPER_PATTERN4=8'h01;
8'h15:UPPER_PATTERN4=8'h01;
8'h16:UPPER_PATTERN4=8'h01;
8'h17:UPPER_PATTERN4=8'h01;

8'h18:UPPER_PATTERN4=8'h01;
8'h19:UPPER_PATTERN4=8'h01;
8'h1A:UPPER_PATTERN4=8'h01;
8'h1B:UPPER_PATTERN4=8'h01;
8'h1C:UPPER_PATTERN4=8'h01;
8'h1D:UPPER_PATTERN4=8'h01;
8'h1E:UPPER_PATTERN4=8'h01;
8'h1F:UPPER_PATTERN4=8'h01;

8'h20:UPPER_PATTERN4=8'h01;
8'h21:UPPER_PATTERN4=8'h01;
8'h22:UPPER_PATTERN4=8'h01;
8'h23:UPPER_PATTERN4=8'h01;
8'h24:UPPER_PATTERN4=8'h01;
8'h25:UPPER_PATTERN4=8'h01;
8'h26:UPPER_PATTERN4=8'h01;
8'h27:UPPER_PATTERN4=8'h01;

8'h28:UPPER_PATTERN4=8'h01;
8'h29:UPPER_PATTERN4=8'h01;
8'h2A:UPPER_PATTERN4=8'h01;
8'h2B:UPPER_PATTERN4=8'h01;
8'h2C:UPPER_PATTERN4=8'h01;
8'h2D:UPPER_PATTERN4=8'h01;
8'h2E:UPPER_PATTERN4=8'h01;
8'h2F:UPPER_PATTERN4=8'h01;

8'h30:UPPER_PATTERN4=8'h01;
8'h31:UPPER_PATTERN4=8'h01;
8'h32:UPPER_PATTERN4=8'h01;
8'h33:UPPER_PATTERN4=8'h01;
8'h34:UPPER_PATTERN4=8'h01;
8'h35:UPPER_PATTERN4=8'h01;
8'h36:UPPER_PATTERN4=8'h01;
8'h37:UPPER_PATTERN4=8'h01;

8'h38:UPPER_PATTERN4=8'h01;
8'h39:UPPER_PATTERN4=8'h01;
8'h3A:UPPER_PATTERN4=8'h01;
8'h3B:UPPER_PATTERN4=8'h01;
8'h3C:UPPER_PATTERN4=8'h01;
8'h3D:UPPER_PATTERN4=8'h01;
8'h3E:UPPER_PATTERN4=8'h01;
8'h3F:UPPER_PATTERN4=8'h01;

8'h40:UPPER_PATTERN4=8'h01; 
8'h41:UPPER_PATTERN4=8'h01; 
8'h42:UPPER_PATTERN4=8'h01; 
8'h43:UPPER_PATTERN4=8'h01; 
8'h44:UPPER_PATTERN4=8'h01; 
8'h45:UPPER_PATTERN4=8'h01; 
8'h46:UPPER_PATTERN4=8'h01; 
8'h47:UPPER_PATTERN4=8'h01;

8'h48:UPPER_PATTERN4=8'h01;
8'h49:UPPER_PATTERN4=8'h01; 
8'h4A:UPPER_PATTERN4=8'h01; 
8'h4B:UPPER_PATTERN4=8'h01; 
8'h4C:UPPER_PATTERN4=8'h01; 
8'h4D:UPPER_PATTERN4=8'h01; 
8'h4E:UPPER_PATTERN4=8'h01; 
8'h4F:UPPER_PATTERN4=8'h01; 

8'h50:UPPER_PATTERN4=8'h01; 
8'h51:UPPER_PATTERN4=8'h01; 
8'h52:UPPER_PATTERN4=8'h01; 
8'h53:UPPER_PATTERN4=8'h01; 
8'h54:UPPER_PATTERN4=8'h01; 
8'h55:UPPER_PATTERN4=8'h01; 
8'h56:UPPER_PATTERN4=8'h01; 
8'h57:UPPER_PATTERN4=8'h01;

8'h58:UPPER_PATTERN4=8'h01;
8'h59:UPPER_PATTERN4=8'h01; 
8'h5A:UPPER_PATTERN4=8'h01; 
8'h5B:UPPER_PATTERN4=8'h01; 
8'h5C:UPPER_PATTERN4=8'h01; 
8'h5D:UPPER_PATTERN4=8'h01; 
8'h5E:UPPER_PATTERN4=8'h01; 
8'h5F:UPPER_PATTERN4=8'h01; 

8'h60:UPPER_PATTERN4=8'h01; 
8'h61:UPPER_PATTERN4=8'h01; 
8'h62:UPPER_PATTERN4=8'h01; 
8'h63:UPPER_PATTERN4=8'h01; 
8'h64:UPPER_PATTERN4=8'h01; 
8'h65:UPPER_PATTERN4=8'h01; 
8'h66:UPPER_PATTERN4=8'h01; 
8'h67:UPPER_PATTERN4=8'h01;
 
8'h68:UPPER_PATTERN4=8'h01; 

default:UPPER_PATTERN4=8'h00;
endcase
end


/**************************Figure_PATTERN0*********************************/
always@(P_index) 
begin 
case(P_index) 
8'h00:Figure_PATTERN0=8'h08;
8'h01:Figure_PATTERN0=8'h7E;
8'h02:Figure_PATTERN0=8'hCA;
8'h03:Figure_PATTERN0=8'h63;
8'h04:Figure_PATTERN0=8'h63;
8'h05:Figure_PATTERN0=8'hCA;
8'h06:Figure_PATTERN0=8'h7E;
8'h07:Figure_PATTERN0=8'h08;
default:Figure_PATTERN0=8'h00; 
endcase 
end


/**************************Figure_PATTERN1*********************************/
always@(P_index) 
begin 
case(P_index) 
8'h00:Figure_PATTERN1=8'h08;
8'h01:Figure_PATTERN1=8'h7E;
8'h02:Figure_PATTERN1=8'hCA;
8'h03:Figure_PATTERN1=8'h6B;
8'h04:Figure_PATTERN1=8'h6B;
8'h05:Figure_PATTERN1=8'hCA;
8'h06:Figure_PATTERN1=8'h7E;
8'h07:Figure_PATTERN1=8'h08;
default:Figure_PATTERN1=8'h00; 
endcase 
end


/**************************Figure_PATTERN2*********************************/
always@(P_index) 
begin 
case(P_index) 
8'h00:Figure_PATTERN2=8'h09;
8'h01:Figure_PATTERN2=8'h7F;
8'h02:Figure_PATTERN2=8'hCB;
8'h03:Figure_PATTERN2=8'h63;
8'h04:Figure_PATTERN2=8'h63;
8'h05:Figure_PATTERN2=8'hCB;
8'h06:Figure_PATTERN2=8'h7F;
8'h07:Figure_PATTERN2=8'h09;
default:Figure_PATTERN2=8'h00; 
endcase 
end


/**************************Figure_PATTERN3*********************************/
always@(P_index) 
begin 
case(P_index) 
8'h00:Figure_PATTERN3=8'h09;
8'h01:Figure_PATTERN3=8'h7F;
8'h02:Figure_PATTERN3=8'hCB;
8'h03:Figure_PATTERN3=8'h6B;
8'h04:Figure_PATTERN3=8'h6B;
8'h05:Figure_PATTERN3=8'hCB;
8'h06:Figure_PATTERN3=8'h7F;
8'h07:Figure_PATTERN3=8'h09;
default:Figure_PATTERN3=8'h00; 
endcase 
end

endmodule
