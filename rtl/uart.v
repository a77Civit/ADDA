/* 针对fifo的输出串并转换并且发出的并行信号
转换为串行信号再使用波特率时钟将信号
将数据发送出去寄存器的操作下发送出去 
date：20200203
author ：Civi Cheng

*/
module (
    input [15:0] paralle_data,
    input sysclk_12,
    input i_rest_n,
    input rdempty,//读空呈高电平发送停止；//
    output reg tx_data
    
);
parameter BAUD_RATE = 115200;//默认115200可以传参数改变
parameter CLK_FREQURENCE = 12000000;//12MHz输入时钟
parameter TIM_CNT = CLK_FREQURENCE/BAUD_RATE;//计算每位信号发送需要的计数次数

wire uart_en;
wire send_sta_flg;//发送状态标志位
wire en_flg;
wire bit_flg;//0为发送低位，1为发送高位
reg [7:0]data_buf;
reg [3:0]tim_cnt;
reg [15:0]paralle_data_inputbuf;
//reg [1:0]sb_cnt;
reg uart_en_d0,uart_en_d1;

assign uart_en = ~rdempty;
assign en_flg = (~uart_en_d1) & uart_en_d0;
//将使能信号延迟两个周期
always@(posedge sysclk_12 or negedge i_rest_n)
begin
    if(!i_rest_n)
        begin 
            uart_en_d0 <= 1'b0;
            uart_en_d1 <= 1'b0; 
        end
    else
        begin
            uart_en_d0 <= uart_en;
            uart_en_d1 <= uart_en_d0;
        end

end

always@(posedge sysclk_12 or negedge i_rest_n)
begin
    if(!i_rest_n)
        begin
            paralle_data_inputbuf <= 16'd0;
            send_sta_flg <= 1'b0;
            sb_cnt <= 2'b0;
        end
    else
        begin
            send_sta_flg <= 1'b1;
            if(en_flg)
                begin
                    if(!bit_flg)//若为0则发送低位若为1则发送高位 没发送完一次取反
                        begin
                            data_buf <= paralle_data_inputbuf[7:0];//寄存待发送的数据
                        end
                    else 
                        begin
                            data_buf <= paralle_data_inputbuf[8:15];
                            
                        end
                        
                end
        end
end


//具体的信号传输模块
always@(posedge sysclk_12 or negedge i_rest_n)
begin
    if (!i_rest_n) begin
        tx_data <= 1'b1;//空闲状态为高电平，开始位为拉低低电平
    end else
        begin
            if(send_sta_flg)
                begin
                    case (tim_cnt)
                4'd0:
                    tx_data <= 1'b0;//起始位信号
                4'd1:
                    tx_data <= data_buf[0];
                4'd2: 
                    tx_data <= data_buf[1];
                4'd3: 
                    tx_data <= data_buf[2];
                4'd4:
                    tx_data <= data_buf[3];
                4'd5:
                    tx_data <= data_buf[4];
                4'd6:
                    tx_data <= data_buf[5];
                4'd7: 
                    tx_data <= data_buf[6];
                4'd8:
                    tx_data <= data_buf[7];
                4'd9:
                    tx_data <= 1'b1;//结束位
                    bit_flg <= ~bit_flg;
                default:
                    endcase
                end
            else 
                tx_data <= 1'b1;
        end
end





endmodule // 
