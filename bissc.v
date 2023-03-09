module bissc (
	input rst_n,
	input enc_clk,
	output oclk,
	input enc_data,
	input [9:0] enc_width,
	output [39:0] enc_pos
);

reg [2:0] state; 
reg [5:0] datacnt;
reg [39:0] mt_data;
reg [39:0] pos;
reg [5:0] crc_data;
reg cken;

always @(posedge enc_clk, negedge rst_n) begin
	if(!rst_n) begin
		state <= 3'd0;
		cken <= 1'b0;
		datacnt <= 6'd0;
		mt_data <= 40'd0;
		crc_data <= 6'd0;
		pos <= 32'd0;
	end
	else begin
		case(state)
			3'd0: begin //tout
				if(enc_data) begin
					cken <= 1'b1;
					state <= state + 1'b1;
					datacnt <= 6'd0;
				end
			end
			3'd1: begin //ACK
				if(!enc_data) state <= state + 1'b1; 
			end
			3'd2: begin //start
				if(enc_data) state <= state + 1'b1;
			end
			3'd3: begin
				state <= state + 1'b1;
				mt_data <= 0;
			end
			3'd4: begin //data receive
				if(datacnt < enc_width) begin
					mt_data <= {mt_data[38:0], enc_data};
					datacnt <= datacnt + 1'b1;
				end
				else begin
					state <= state + 1'b1;
					datacnt <= 6'd0;
					pos <= mt_data;
				end
			end
			3'd5: begin // err, warn, crc data
				if(datacnt < 6'd1) begin
					datacnt <= datacnt + 1'b1;
				end
				else if(datacnt < 6'd7) begin
					datacnt <= datacnt + 1'b1;
					crc_data <= {crc_data[4:0], enc_data};
				end
				else begin
					state <= 0;
					cken <= 1'b0;
				end
			end
			default: begin
				state <= 0;
			end
		endcase
	end
end

assign enc_pos = pos;
assign oclk = cken & enc_clk;

endmodule
