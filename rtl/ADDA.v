/*
AD7760 Control Module 
base on CSDN:https://blog.csdn.net/skybabi_/article/details/84103582
Date:2020-1-31
//尝试改进状态机 
*/
//在顶层模块中调用·AD7760模块 
module ADDA(
		input sysclk_50,      //10MHz
		input drdy_n,
		input command,
		input i_rest_n,
		output reg r_n_w,    //读写信号
		output reg cs_n,      //片选使能信??
		output reg o_rest_n,
		inout [15:0]adc_data//Modelsim里inout不能是reg只能是wire

);
//或者改用中间寄存器控制data

//初步使用CLDIV_n = 1 时钟一分频模式 ICLK=MCLK  输出数据以MCLK频率输出,控制寄存1要配置成0x0000
//配置AD7760 控制寄存器1 地址为：0x0001，默认0x001A
//控制寄存器2 地址为：0x0002，默认值0x009B，ICLK二分频，频率：ICLK = 1/2 MCLK
parameter CONTROL1_MOD_VALE = 16'h0000;
parameter CONTROL2_MOD_VALE = 16'h0022;
parameter CONTROL1_ADDRESS = 16'h0001;
parameter CONTROL2_ADDRESS = 16'h0002;
parameter MCLKFREQUENT = 10000000;//10MHz
parameter STATE0 =4'b0;//复位状态
parameter WRESET1 = 4'b0001;
parameter WRESET2 = 4'b0010;
parameter WRITECONTROL1_ADR = 4'b0011;
parameter WRITECONTROL1_ADR_END =4'b0100;
parameter WRITECONTROL1_VAL = 4'b0101;
parameter WRITECONTROL1_VAL_END = 4'b0110;
parameter WRITECONTROL2_ADR = 4'b0111;
parameter WRITECONTROL2_ADR_END = 4'd1000;
parameter WRITECONTROL2_VAL = 4'b1001;
parameter WRITECONTROL2_VAL_END = 4'b1010;
parameter WAIT_SIX_MCLK = 4'b1011;
parameter COLLECT = 4'b1100;
parameter WAIT_DRDY = 4'b1101;

localparam TICK_INIT = 1/ (0.5*MCLKFREQUENT);//初始化为二分频，TICK周期为TMCLK的两倍

//所有的initial语句内的语句构成了一个initial块。initial块从仿真0时刻开始执行，在整个仿真过程中只执行一??


reg [3:0]current_sta = STATE0;/*synthesis noprune*/
reg [3:0]next_sta = STATE0;/*synthesis noprune*/
reg [2:0]rest_cnt = 3'b0;/*synthesis noprune*/
reg [4:0]time_cnt = 5'b0;/*synthesis noprune*/ //创建打拍子的综合计时器
reg [2:0]drdy_cnt = 3'b0;
reg [15:0]adcdata;
reg [8:0]contro_set_flg = 9'd1;//多留一位用作初始状态
reg wrreq;
reg rdreq;

wire [15:0]i_fifo;
wire [7:0]o_fifo;
wire wait_six_flg;
wire mclk;
wire uart_clk;
wire rdempty,rdfull,rdusedw,wrempty,wrfull,wrusedw;


//上电后就写寄存器，CLDVIV_N = 1；使ICLK = MCLK
assign adc_data = (wrreq == 1'b1)?(16'bz):(adcdata);//读取数据时释放总线
assign wait_six_flg = (time_cnt == 4'd6)?(1'b1):(1'b0);//只用一次
assign i_fifo = (wrreq == 1)?(adc_data):(16'bz);

//pll无输出，原因未明用50Mhz 时钟顶替
ip u_pll(
	.inclk0(sysclk_50),
	.areset(~i_rest_n),//高电平有效的复位信号
	.c0(mclk),
	.c1(uart_clk)
);
 

fifo	u_fifo (
	.aclr ( ~i_rest_n ),
	.data ( i_fifo ),
	.rdclk ( uart_clk ),
	.rdreq ( rdreq ),
	.wrclk ( mclk ),
	.wrreq ( wrreq ),
	.q ( o_fifo ),
	.rdempty ( rdempty ),
	.rdfull ( rdfull ),
	.rdusedw ( rdusedw ),
	.wrempty ( wrempty ),
	.wrfull ( wrfull ),
	.wrusedw ( wrusedw )
	);

initial
begin
wrreq = 1'b0;
//adcdata = 16'b0;
//current_sta = STATE0;
//next_sta = WRESET1;
end



//上电的默认的时候 ICLK周期是MCLK的两倍，频率是一半
//三段式状态机
//第一段同步时序描述状态机的转换转移这一事实，并兼任复位计数器
always@(posedge mclk or negedge i_rest_n)//尝试加上下降沿的cs？
begin
	if (!i_rest_n) begin
		current_sta <= STATE0;
		rest_cnt <= 3'b0;
		time_cnt <= 5'b0;
	end
//强制异步复位清零
	else
		begin
			if (current_sta != next_sta) begin
				current_sta <= next_sta;
				rest_cnt <= 3'd0;
				time_cnt <= 5'd0;
				//状态不一样才跳转否则保持
			end
			else
		//否则current不变，计数器继续计数。
				begin
						rest_cnt <= rest_cnt + 3'b001;//复位状态做复位mclk技术
						time_cnt <= time_cnt + 5'b00001;
						/* if(time_cnt == 5'd7)begin
							contro_set_flg <= {contro_set_flg[7:0],contro_set_flg[8]};//移位
							time_cnt <= 5'd0;
						end
						else begin
							contro_set_flg <= contro_set_flg;//空置不能写time_cnt = time_cnt不然计数会卡死在这里
						end */
				end
		end
end


//第二段组合逻辑描述状态转移条件
//rest_cnt的清零要在状态转化之后才能进行。
always@(*)
begin
	if (!i_rest_n) begin
		next_sta <= STATE0;
	end 
	else begin
		case(current_sta)
			STATE0:
				begin
					next_sta <= WRESET1;
				end
			WRESET1:
				begin 
					if (rest_cnt == 1) begin//至少低电平一个周期
						next_sta <= WRESET2;
					end
					else
						next_sta <= WRESET1;
				end
			WRESET2:
				begin
					if ((rest_cnt == 2)) begin//高电平至少保持两个时钟周期
						next_sta <= WRITECONTROL1_ADR; 
					end
					else
						next_sta <= WRESET2;
				end
			WRITECONTROL1_ADR:
				begin
					if ((time_cnt == 5'd7)) begin//持续4个ICLK周期 上电默认CKDIV = 0；二分频,即8个MCLK
						next_sta <= WRITECONTROL1_ADR_END;
					end
					else
						next_sta <= WRITECONTROL1_ADR;
				end
			WRITECONTROL1_ADR_END:
				begin 
					if ((time_cnt == 5'd7)) begin//过度状态结束标志符
						next_sta <= WRITECONTROL1_VAL;
					end
					else
						next_sta <= WRITECONTROL1_ADR_END;
				end
			WRITECONTROL1_VAL:
				begin
					if ((time_cnt == 5'd7)) //持续4个ICLK周期 上电默认CKDIV = 0；二分频
						next_sta <= WRITECONTROL1_VAL_END;
					else
						next_sta <= WRITECONTROL1_VAL;
				end
			WRITECONTROL1_VAL_END:
			begin
				if ((time_cnt == 5'd8)) //过度状态结束标志符
					next_sta <= WRITECONTROL2_ADR;
				else
					next_sta <= WRITECONTROL1_VAL_END;
			end
			WRITECONTROL2_ADR:
			begin
				if ((time_cnt == 5'd7)) //持续4个ICLK周期 上电默认CKDIV = 0；二分频
					next_sta <= WRITECONTROL2_ADR_END;
				else
					next_sta <= WRITECONTROL2_ADR;
			end
			WRITECONTROL2_ADR_END:
			begin
					next_sta <= WRITECONTROL2_VAL;
				if ((time_cnt == 5'd7)) //过度状态结束标志符
					next_sta <= WRITECONTROL2_VAL;
				else
					next_sta <= WRITECONTROL2_ADR_END;
			end
			WRITECONTROL2_VAL:
			begin
				if ((time_cnt == 5'd7)) //持续4个ICLK周期 上电默认CKDIV = 0；二分频
					next_sta <= WRITECONTROL2_VAL_END;
				else
					next_sta <= WRITECONTROL2_VAL;
			end
			WRITECONTROL2_VAL_END:
			begin
				if((wait_six_flg == 1'b1)&&(command == 1'b1))//过度状态结束标志符
					next_sta <= WAIT_DRDY;//此状态过后配置完成，ICLK = MCLK
				else
				next_sta <= WRITECONTROL2_VAL_END;
			end

			WAIT_DRDY:
				if(command == 0)
					next_sta <= STATE0;

			default:
				next_sta <= STATE0;
		endcase
	end
end	

//第三段描各个状态的输出//drdy部分另外一个模块写
always@(*)begin

case(current_sta)
	STATE0:
		begin
			o_rest_n <= 1'b1;
			cs_n <= 1'b1;
			r_n_w <= 1'b1;
			adcdata <= 16'd0;
		end
	WRESET1:
		o_rest_n <= 1'b0;
	WRESET2:
		o_rest_n <= 1'b1;//延时到了拉高复位信号线要保持两个时钟周期
	
	WRITECONTROL1_ADR:
	begin
		adcdata <= CONTROL1_ADDRESS;
		cs_n <= 1'b0;
	end
	WRITECONTROL1_ADR_END:
	begin
		adcdata <= 16'bz;
		cs_n <= 1'b1;
	end	
	WRITECONTROL1_VAL:
	begin
		adcdata <= CONTROL1_MOD_VALE;
		cs_n <= 1'b0;
	end
	WRITECONTROL1_VAL_END:
	begin
		adcdata <= 16'bz;
		cs_n <= 1'b1;
	end
	WRITECONTROL2_ADR:
	begin
		adcdata <= CONTROL2_ADDRESS;
		cs_n <= 1'b0;
	end
	WRITECONTROL2_ADR_END:
	begin
		adcdata <= 16'bz;
		cs_n <= 1'b1;
	end
	WRITECONTROL2_VAL:
	begin
		adcdata <= CONTROL2_MOD_VALE;
		cs_n <= 1'b0;
	end
	WRITECONTROL2_VAL_END:
	begin
		cs_n <= 1'b1;//最后写完后拉高之后等待至少六个MCLK，退出写模式？
		adcdata <= 16'bz;//总线回复高阻，释放总线，方便接下来读取数据

	end

	WAIT_DRDY://拉低片选和读线，等待drdy上升沿
	begin
		wrreq <= 1'b0;
		cs_n <= 1'b0;
		r_n_w <= 1'b0;//先拉低cs和读写信号，等待drdy信号号再读取输出数据
		if (drdy_n == 1'b1) begin
			wrreq <= 1'b1;
		end else begin
			wrreq <= 1'b0;
		end

	end

	default:
		begin
			o_rest_n <= 1'b1;
			cs_n <= 1'b1;
			r_n_w <= 1'b1;
			adcdata <= 16'd0;
		end
endcase

end

endmodule