module endat (
	input rst_n,
	input enc_clk,
	output oclk,
	input enc_data,
	input [9:0] enc_width,
	output reg enc_tdata,
	output reg enc_wr, // 1: write, 0: read
	output reg [39:0] enc_pos
);

reg [3:0] state;
reg [4:0] crc_data;
reg [39:0] pos_data;
reg [4:0] count;
reg [5:0] mode_cmd;
reg cken;

always @(posedge enc_clk, negedge rst_n) begin
	if(!rst_n) begin
		state <= 4'd0;
		crc_data <= 5'd0;
		pos_data <= 40'd0;
		count <= 5'd0;
		mode_cmd <= 6'b000111;
		enc_pos <= 40'd0;
		cken <= 1'b0;
		enc_wr <= 1'b0;
		enc_tdata <= 1'b0;
	end
	else begin
		case(state)
			4'd0: begin//encoder ready
				if(!enc_data) begin
					state <= state + 1'b1;
					cken <= 1'b1;
					enc_wr <= 1'b0;
				end
			end
			4'd1: begin//tST1
				state <= state + 1'b1;
			end
			4'd2: begin//tST2
				state <= state + 1'b1;
				count <= 5'd0;
				mode_cmd <= 6'b000111;//mode command
			end
			4'd3: begin//send command to encoder
				if(count > 5'd5) begin
					state <= state + 1'b1;
					enc_tdata <= 1'b0;
					enc_wr <= 1'b0;
				end
				else begin
					count <= count + 1'b1;
					enc_tdata <= mode_cmd[5];
					mode_cmd <= {mode_cmd[4:0], 1'b0};
					enc_wr <= 1'b1;//direction is output
				end
			end
			4'd4: begin//direction is input
				count <= 5'd0;
				state <= state + 1'b1;
				enc_tdata <= 1'b0;
				enc_wr <= 1'b0;
			end
			4'd5: begin//
				state <= state + 1'b1;
			end
			4'd6: begin//start
				if(enc_data) state <= state + 2'd2;
			end
			4'd7: begin//F1
				state <= state + 1'b1;
				count <= 5'd0;
			end
			4'd8: begin//F2
				state <= state + 1'b1;
				pos_data <= 0;
			end
			4'd9: begin//receive position data
				pos_data <= {pos_data[38:0], enc_data};
				if(count > enc_width-2) begin
					state <= state + 1'b1;
					count <= 5'd0;
				end
				else count <= count + 1'b1;
			end
			4'd10: begin//receive CRC data
				enc_pos <= pos_data;
				if(count > 5'd3) begin
					state <= state + 1'b1;
					crc_data <= {crc_data[3:0], enc_data};
					count <= 5'd0;
				end
				else begin
					count <= count + 1'b1;
					crc_data <= {crc_data[3:0], enc_data};
				end
			end
			4'd11: begin//end delay
				cken <= 1'b0;
				if(count == 5'd8) state <= 0;
				else count <= count + 1'b1;
			end
			default: begin
				state <= 4'd0;
			end
		endcase
	end
end

assign oclk = (cken == 1'b1)? enc_clk: 1'b1;//output clock

endmodule
