//+------------------------------------------------------------------+
//|                                                         测试时间.mq5 |
//|                                                             @老顽童 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "@老顽童 VX：My05613828"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input double 追踪止损点值=20;
//input int 做单magic=100;
int OnInit()
  {
//---
  /* datetime tm=TimeCurrent();
   string str1="Date and time with minutes: "+TimeToString(tm);
   string str2="Date only: "+TimeToString(tm,TIME_DATE);
   string str3="Time with minutes only: "+TimeToString(tm,TIME_MINUTES);
   string str4="Time with seconds only: "+TimeToString(tm,TIME_SECONDS);
   string str5="Date and time with seconds: "+TimeToString(tm,TIME_DATE|TIME_SECONDS);
//--- output results
   Alert(str1);
   Alert(str2);
   Alert(str3);
   Alert(str4);
   Alert(str5);
//---
   datetime tm1=StringToTime("23:31:57");
//--- output result
   Alert((string)tm1);*/
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---/*
追踪止损( 追踪止损点值/*,做单magic*/);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void       追踪止损(double 追踪止损/*,int Magic号码*/)
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(PositionGetTicket(i)>0)
        {
         double 交易品种点值=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT);
         double 持仓盈利点数=(PositionGetDouble(POSITION_PRICE_CURRENT)-PositionGetDouble(POSITION_PRICE_OPEN))/交易品种点值;
         double 持仓止损点数=0;
         if(PositionGetDouble(POSITION_SL)>0)
            持仓止损点数=MathAbs(PositionGetDouble(POSITION_PRICE_OPEN)-PositionGetDouble(POSITION_SL))/交易品种点值;
         Comment("持仓盈利点数: ", DoubleToString(持仓盈利点数,2), "\n持仓止损点数: ", DoubleToString(持仓止损点数,2), "\n追踪止损: ", DoubleToString(追踪止损,2));
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY/*&&PositionGetInteger(POSITION_MAGIC)==Magic号码*/)
           {
            if(持仓盈利点数>持仓止损点数+2*追踪止损)
              {
               //--- 声明并初始化交易请求和交易请求结果
               MqlTradeRequest request= {};
               MqlTradeResult result= {};

               //=======填充结构体参数=============================
               request.action=TRADE_ACTION_SLTP;
               request.position=PositionGetInteger(POSITION_TICKET);
               request.magic=PositionGetInteger(POSITION_MAGIC);
               request.symbol=PositionGetString(POSITION_SYMBOL);
               request.volume=PositionGetDouble(POSITION_VOLUME);
               request.deviation=20;
               //=========止损止盈参考价格==========================
               request.price=PositionGetDouble(POSITION_PRICE_OPEN);

               request.sl=request.price+(持仓止损点数+追踪止损)*交易品种点值;
               request.tp=PositionGetDouble(POSITION_TP);
               //========发送交易请求==============================
               bool X=OrderSend(request,result);
               if(X==false)
                 {
                  Print("订单发送失败代码："+IntegerToString(GetLastError()));
                  Print("交易返回代码："+IntegerToString(result.retcode));
                 }
              }
           }
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL/*&&PositionGetInteger(POSITION_MAGIC)==Magic号码*/)
           {
            if(-持仓盈利点数>持仓止损点数+2*追踪止损)
              {
               //--- 声明并初始化交易请求和交易请求结果
               MqlTradeRequest request= {};
               MqlTradeResult result= {};

               //=======填充结构体参数=============================
               request.action=TRADE_ACTION_SLTP;
               request.position=PositionGetInteger(POSITION_TICKET);
               request.magic=PositionGetInteger(POSITION_MAGIC);
               request.symbol=PositionGetString(POSITION_SYMBOL);
               request.volume=PositionGetDouble(POSITION_VOLUME);
               request.deviation=20;
               //=========止损止盈参考价格==========================
               request.price=PositionGetDouble(POSITION_PRICE_OPEN);

               request.sl=request.price-(持仓止损点数+追踪止损)*交易品种点值;
               request.tp=PositionGetDouble(POSITION_TP);

               //========发送交易请求==============================
               bool X=OrderSend(request,result);
               if(X==false)
                 {
                  Print("订单发送失败代码："+IntegerToString(GetLastError()));
                  Print("交易返回代码："+IntegerToString(result.retcode));
                 }
              }
           }
        }
     }
  };
//+------------------------------------------------------------------+