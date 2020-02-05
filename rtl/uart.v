/* 针对fifo的输出串并转换并且发出的并行信号
转换为串行信号再使用波特率时钟将信号
将数据发送出去寄存器的操作下发送出去 
date：20200203
author ：Civi Cheng

*/
module uart(
    input [7:0] paralle_data,
    input sysclk_12,
    input i_rest_n,
    input rdempty,//读空呈高电平发送停止；//
    input uart_en,
    output reg tx_data
    
);
parameter BAUD_RATE = 115200;//默认115200可以传参数改变
parameter CLK_FREQURENCE = 50000000;//50MHz输入时钟
parameter BIT_CNT = CLK_FREQURENCE/BAUD_RATE;//计算每位信号发送需要的计数次数


wire en_flg;
reg [7:0]data_buf;
reg [3:0]tim_cnt;
reg [15:0]clk_cnt;
reg uart_en_d0,uart_en_d1;

reg send_sta_flg;//发送状态标志位
//捕获使能信号的上升沿，配合下面的延迟两个周期
//制造了一个时钟周期的
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
            data_buf <= 16'd0;
            send_sta_flg <= 1'b0;
        end
    else
        begin
            if(en_flg)
                begin
                        send_sta_flg <= 1'b1;
                        data_buf <= paralle_data;
                end
            else
                begin
                    if ((tim_cnt == 4'd9)&&(clk_cnt == BIT_CNT/2)) //发送完成并再停止位的一半结束发送过程
                        begin
                            data_buf <= 8'd0;
                            send_sta_flg <= 1'b0;
                        end 
                    else 
                        begin
                            data_buf <= data_buf;//否则保持不变
                            send_sta_flg <= send_sta_flg;
                        end
                end
        end
end


//计数模块
always@(posedge sysclk_12 or negedge i_rest_n)
begin
    if (!i_rest_n)
        begin
            tim_cnt <= 4'd0;
            clk_cnt <= 16'd0;
        end 
    else 
        begin
            if(send_sta_flg)
                begin
                    if (clk_cnt < BIT_CNT-1)//每比特传输所需的时间的计数
                        begin
                            clk_cnt <= clk_cnt + 1'b1;
                            tim_cnt <= tim_cnt;
                        end 
                    else 
                        begin
                            tim_cnt <= tim_cnt + 1'b1;
                            clk_cnt <= 16'd0;
                        end
                end
            else
                begin
                    clk_cnt <= 16'd0;
                    tim_cnt <= 4'd0;//不在发送过程就清零
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
                default:;
                    endcase
                end
            else 
                tx_data <= 1'b1;
        end
end





endmodule // 
