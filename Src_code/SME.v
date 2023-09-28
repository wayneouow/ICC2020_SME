module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg valid;

parameter IDLE 		= 3'd0;
parameter STR		= 3'd1;
parameter PTRN		= 3'd2;
parameter WORKING 	= 3'd3;
parameter OUTPUT 	= 3'd4;
reg [2:0] state, next_state;

reg [7:0] str_reg [0:31];
reg [7:0] ptrn_reg [0:7];
reg [5:0] cnt_str;
reg [5:0] cnt_str_buf;
reg [4:0] cnt_ptrn;

reg [2:0] working_st; 

reg [1:0]done;	//0 -> not yet
				//1 -> unmatch
				//2 -> match

reg [5:0] i_str, i_str_re;
reg [4:0] i_ptrn;
reg [4:0] cnt_match;

reg [1:0] special_detecter 	//0 -> no
							//1 -> ^ only
							//2 -> $ only
							//3 -> ^...$ 


always@(posedge clk or posedge reset)begin
    if(reset) begin
        state <= IDLE;
    else
		state <= next_state;	
end

always@(*) begin
    case(state)
    IDLE:
		begin
			if(isstring == 1'b1) 
				next_state = STR;
			else if(ispattern == 1'd1)
				next_state = PTRN;
			else
				next_state = IDLE;
		end
    STR: 
		begin
			if(isstring == 1'b1)
				next_state = STR;
			else 
				next_state = PTRN;
		end
    PTRN:
		begin
			if(ispattern == 1'b1)
				next_state = STR;
			else
				next_state = WORKING;
		end
    WORKING:
		begin
			if(done == 1'b1)
				next_state = OUTPUT;
			else
				next_state = WORKING;
		end
    OUTPUT:
		begin
			if(isstring == 1'b1)
				next_state = STR;
			else if(ispattern == 1'b1) 
				next_state = PTRN;
			else 
				next_state = IDLE;
		end
		
    default:
		next_state = IDLE;
		
    endcase 
end

always@(posedge clk or posedge reset) begin
	if(reset)
		special_detecter <= 2'b0;
	else if(ispattern)
	begin	
		case(chardata)
		
		8'h5E:
			special_detecter <= special_detecter + 2'b01;
		8'h24:
			special_detecter <= special_detecter + 2'b10;
		default
			special_detecter <= special_detecter 

		endcase
	end
end

//str_reg
integer  idx;
always@(posedge clk or posedge reset) begin
    if(reset)
        for(idx=0; idx<32; idx=idx+1)
            str_reg[idx] <= 8'd0;

    else if(state == OUTPUT && next_state == STR)
		str_reg[0] <= chardata;
    else if(isstring == 1'b1) 
		str_reg[cnt_str] <= chardata;
end

//cnt_str

always@(posedge clk or posedge reset) begin
    if(state == OUTPUT && next_state == STR)
		cnt_str = 6'd0;
    else if(state == IDLE && next_state == STR) 
		cnt_str = 6'd0;
    else if(isstring == 1'b1)
		cnt_str = cnt_str_buf + 1;
    else 
		cnt_str = cnt_str_buf;
end

//ptrn_reg
always@(posedge clk or posedge reset) begin
    if(reset)
        for(idx=0;idx<8;idx=idx+1)
            ptrn_reg[idx] <= 8'd0;
      
    else if(ispattern == 1'd1)
		ptrn_reg[cnt_ptrn] <= chardata;
end

always@(posedge clk or posedge reset) begin
    if(reset)
		cnt_str_buf <= 6'd0;
    else if(isstring == 1'b1)
		cnt_str_buf <= cnt_str;
end

//pattern counter
always@(posedge clk or posedge reset) begin
    if(reset)
		cnt_ptrn <= 5'd0;
    else if(ispattern == 1'b1)
		cnt_ptrn <= cnt_ptrn + 1;
    else if(next_state == OUTPUT) 
		cnt_ptrn <= 5'd0;
end


//valid//
always@(posedge clk or posedge reset) begin
    if(reset)
		valid <= 1'd0;
    else if(next_state == OUTPUT)
		valid <= 1'd1;
    else
		valid <= 1'd0;
end

//output

always@(posedge clk or posedge reset) begin
	if(reset)
		i_str	<= 6'd0;
		i_ptrn 	<= 5'd0;
		match_index	<= 5'd0;
		cnt_match <= 5'd0;
		done 	<= 2'b00;

	end

	else if((i_str == cnt_str)||(cnt_match == cnt_ptrn))begin
		if(cnt_match == cnt_ptrn)
			done <= 2'd2;
		else
			done <= 2'd1;
		
	end
	
	else if(state == WORKING)
	begin
		if(special_detecter == 2'b00)begin //no special sign
			if(string_reg[i_str] == pattern_reg[i_ptrn] || pattern_reg[i_ptrn] == 8'h2E)begin
				i_ptrn <= i_ptrn +1;
				i_str  <= i_str  +1;
				cnt_match <= cnt_match + 5'd1;
				if(i_ptrn == 5'd0)
					match_index <= i_str;
					
			else begin
				i_str  <= i_str_re;
				i_ptrn <= 0;
				cnt_match <= 0;
			end	
		end
	
		else if(special_detecter == 2'b01)begin //^ at head
			
		end
			
		else if(special_detecter == 2'b10)begin //& at tail
			
		end
		
		else if(special_detecter == 2'b11)begin // ^.....$
			
		end
	end
	
	
end



endmodule
