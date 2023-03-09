module ssi (
	input rst_n,
	input enc_clk, //2mhz
	output oclk,
	input enc_data,
	input [9:0] enc_width,
	output reg [39:0] enc_pos
);

reg [2:0] rd_state;
reg [4:0] rd_cnt;
reg [5:0] delay_cnt;
reg [39:0] pos;
reg cken;
wire pos_bin;

always @(posedge enc_clk, negedge rst_n) begin
	if(!rst_n) begin
		rd_state <= 3'b0;
		pos <= 40'd0;
		enc_pos <= 40'd0;
		rd_cnt <= 5'd0;
		delay_cnt <= 6'd0;
		cken <= 1'b0;
	end
	else begin
		case(rd_state)
			3'b000: begin //delay 21us = 500ns * 42
				if(enc_data) begin
					rd_state <= rd_state + 1'b1;
					rd_cnt <= 5'd1;
					pos <= 40'd0;
					cken <= 1'b1;
				end
				else begin
					cken <= 1'b0;
					pos <= 32'd0;
					rd_cnt <= 5'd0;
				end
			end
			3'b001: begin//receive data
				if(rd_cnt == enc_width) begin
					rd_state <= rd_state + 1'b1;
					enc_pos <= {pos[38:0], pos_bin};
					pos <= {pos[38:0], pos_bin};
					cken <= 1'b0;
				end
				else begin
					rd_cnt <= rd_cnt + 1'b1;
					pos <= {pos[38:0], pos_bin};
				end
			end
			3'b010: begin//end delay
				if(delay_cnt == 6'd10) begin
					rd_state <= 3'd0;
					delay_cnt <= 6'd0;
				end
				else begin
					delay_cnt <= delay_cnt + 1'b1;
				end
			end
			default: begin
				rd_state <= 3'b000;
			end
		endcase
	end
end

assign pos_bin = pos[0] ^ enc_data;
//assign enc_pos = pos;
assign oclk = cken & enc_clk;

endmodule
