module endat22 (
	input rst_n,
	input enc_clk,
	output reg cken,
	input enc_data,
	output reg enc_tdata,
	output reg enc_wr, // 1: write, 0: read
	output reg enc_valid,
	output reg [25:0] enc_pos,
	output [4:0] crc
);

//localparam init = 4'b0000, t0 = 4'b0001, t1 = 4'b0010, mode = 4'b0011,
//				t3 = 4'b0100, t4 = 4'b0101, t5 = 4'b0110, start = 4'b0111,
//				alarm = 4'b1000, rd_data = 4'b1001, rd_crc = 4'b1010, error = 4'b1111;

reg [3:0] state;
reg [4:0] crc_data;
reg [18:0] pos_data;
reg [4:0] count;
reg [5:0] mode_cmd;

always @(posedge enc_clk, negedge rst_n) begin
	if(!rst_n) begin
		state <= 4'd0;
		crc_data <= 5'd0;
		pos_data <= 19'd0;
		count <= 5'd0;
		mode_cmd <= 6'b000111;
		enc_valid <= 1'b0;
		enc_pos <= 26'd0;
		cken <= 1'b0;
		enc_wr <= 1'b0;
		enc_tdata <= 1'b0;
	end
	else begin
		case(state)
			4'd0: begin
				if(!enc_data) begin
					state <= state + 1'b1;
					enc_valid <= 1'b0;
					cken <= 1'b1;
					enc_wr <= 1'b0;
				end
			end
			4'd1: begin
				state <= state + 1'b1;
			end
			4'd2: begin
				state <= state + 1'b1;
				count <= 5'd0;
				mode_cmd <= 6'b000111;
			end
			4'd3: begin
				if(count > 5'd5) begin
					state <= state + 1'b1;
					enc_tdata <= 1'b0;
					enc_wr <= 1'b0;
				end
				else begin
					count <= count + 1'b1;
					enc_tdata <= mode_cmd[5];
					mode_cmd <= {mode_cmd[4:0], 1'b0};
					enc_wr <= 1'b1;
				end
			end
			4'd4: begin
				count <= 5'd0;
				state <= state + 1'b1;
				enc_tdata <= 1'b0;
				enc_wr <= 1'b0;
			end
			4'd5: begin
				state <= state + 1'b1;
			end
			4'd6: begin
				/*if(!enc_data) begin
					if(count == 5'd3) state <= state + 1'b1;
					else count <= count + 1'b1;
				end
				else count <= 5'd0;*/
				if(enc_data) state <= state + 2'd2;
			end
			4'd7: begin
				state <= state + 1'b1;
				count <= 5'd0;
			end
			4'd8: begin
				state <= state + 1'b1;
			end
			4'd9: begin
				pos_data <= {enc_data, pos_data[18:1]};
				if(count > 5'd17) begin
					state <= state + 1'b1;
					count <= 5'd0;
				end
				else count <= count + 1'b1;
			end
			4'd10: begin
				enc_pos <= {7'd0, pos_data};
				if(count > 5'd3) begin
					state <= state + 1'b1;
					enc_valid <= 1'b1;
					crc_data <= {crc_data[3:0], enc_data};
					count <= 5'd0;
				end
				else begin
					count <= count + 1'b1;
					crc_data <= {crc_data[3:0], enc_data};
				end
			end
			4'd11: begin
				cken <= 1'b0;
				//if(enc_data) begin
					if(count == 5'd8) state <= 0;
					else count <= count + 1'b1;
				//end
				//else count <= 0;
			end
			default: begin
				state <= 4'd0;
			end
		endcase
	end
end

assign crc = crc_data;

endmodule
