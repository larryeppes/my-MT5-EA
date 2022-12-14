//+------------------------------------------------------------------+
//|                                                         pzfy.mq5 |
//|                                                             @老顽童 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "@老顽童"
#property link      "https://www.mql5.com"
#property version   "1.00"
input double 平总浮盈=0;
input int 平总浮盈后睡眠分钟=30;
input double 平总浮亏=0;
input int 平总浮亏后睡眠分钟=30;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
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
//---
      if(平总浮盈!=0)
      一键全平总盈利(平总浮盈);
   if(平总浮亏!=0)
      一键全平总亏损(平总浮亏);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void              一键全平总盈利(double 总盈利)
  {
   double 浮动总盈亏=0;
   double 浮动总利息=0;
   double 总盈亏=0;
//==============遍历所有持仓订单=======================
   for(int i=0; i<PositionsTotal(); i++)
     {
      if(PositionGetTicket(i)>0)
        {
         浮动总盈亏+=PositionGetDouble(POSITION_PROFIT);
         浮动总利息+=PositionGetDouble(POSITION_SWAP);
        }
     }
//===========计算出浮动总盈亏==========================

   总盈亏=浮动总盈亏+浮动总利息;
//==========判断总盈亏是否大于设定的总盈利============
   if(总盈亏>=总盈利)
     {
      //======执行一键多空全平操作=====================
      for(int i=PositionsTotal()-1; i>=0; i--)
        {
         if(PositionGetTicket(i)>0)

           {
            //==========如果持仓订单为多单，则执行平多单操作=======
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               //=======声明并初始化交易请求和交易请求结果=========
               MqlTradeRequest request= {};
               MqlTradeResult  result= {};
               //=======填充结构体参数=============================
               request.action=TRADE_ACTION_DEAL;
               request.type_filling=0;
               request.magic=PositionGetInteger(POSITION_MAGIC);
               request.position=PositionGetInteger(POSITION_TICKET);
               request.volume=PositionGetDouble(POSITION_VOLUME);
               request.symbol=PositionGetString(POSITION_SYMBOL);
               request.price=SymbolInfoDouble(request.symbol,SYMBOL_BID);
               request.deviation=20;
               request.type=ORDER_TYPE_SELL;
               request.comment=PositionGetString(POSITION_COMMENT);
               //========发送交易请求===============================
               bool X=OrderSend(request,result);
               if(X==false)
                 {
                  Print("订单发送失败代码："+IntegerToString(GetLastError()));
                  Print("交易返回代码："+IntegerToString(result.retcode));
                 }
              }
            //==========如果持仓订单为空单，则执行平空单操作=======
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               //=======声明并初始化交易请求和交易请求结果=========
               MqlTradeRequest request= {};
               MqlTradeResult  result= {};
               //=======填充结构体参数=============================
               request.action=TRADE_ACTION_DEAL;
               request.type_filling=0;
               request.magic=PositionGetInteger(POSITION_MAGIC);
               request.position=PositionGetInteger(POSITION_TICKET);
               request.volume=PositionGetDouble(POSITION_VOLUME);
               request.symbol=PositionGetString(POSITION_SYMBOL);
               request.price=SymbolInfoDouble(request.symbol,SYMBOL_ASK);
               request.deviation=20;
               request.type=ORDER_TYPE_BUY;
               request.comment=PositionGetString(POSITION_COMMENT);
               //========发送交易请求===============================
               bool X=OrderSend(request,result);
               if(X==false)
                 {
                  Print("订单发送失败代码："+IntegerToString(GetLastError()));
                  Print("交易返回代码："+IntegerToString(result.retcode));
                 }

              }
            Sleep(平总浮盈后睡眠分钟*60*1000);
           }

        }
     }
  };
//+------------------------------------------------------------------+
void            一键全平总亏损(double 总亏损)
  {
   double 浮动总盈亏=0;
   double 浮动总利息=0;
   double 总盈亏=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if(PositionGetTicket(i)>0)
        {
         浮动总盈亏+=PositionGetDouble(POSITION_PROFIT);
         浮动总利息+=PositionGetDouble(POSITION_SWAP);
        }
     }
   总盈亏=浮动总盈亏+浮动总利息;

   if(总盈亏<=总亏损)
     {
      for(int i=PositionsTotal()-1; i>=0; i--)
        {
         if(PositionGetTicket(i)>0)

           {
            //==========如果持仓订单为多单，则执行平多单操作=======
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               //=======声明并初始化交易请求和交易请求结果=========
               MqlTradeRequest request= {};
               MqlTradeResult  result= {};
               //=======填充结构体参数=============================
               request.action=TRADE_ACTION_DEAL;
               request.type_filling=0;
               request.magic=PositionGetInteger(POSITION_MAGIC);
               request.position=PositionGetInteger(POSITION_TICKET);
               request.volume=PositionGetDouble(POSITION_VOLUME);
               request.symbol=PositionGetString(POSITION_SYMBOL);
               request.price=SymbolInfoDouble(request.symbol,SYMBOL_BID);
               request.deviation=20;
               request.type=ORDER_TYPE_SELL;
               request.comment=PositionGetString(POSITION_COMMENT);
               //========发送交易请求===============================
               bool X=OrderSend(request,result);
               if(X==false)
                 {
                  Print("订单发送失败代码："+IntegerToString(GetLastError()));
                  Print("交易返回代码："+IntegerToString(result.retcode));
                 }

              }
            //==========如果持仓订单为空单，则执行平空单操作=======
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               //=======声明并初始化交易请求和交易请求结果=========
               MqlTradeRequest request= {};
               MqlTradeResult  result= {};
               //=======填充结构体参数=============================
               request.action=TRADE_ACTION_DEAL;
               request.type_filling=0;
               request.magic=PositionGetInteger(POSITION_MAGIC);
               request.position=PositionGetInteger(POSITION_TICKET);
               request.volume=PositionGetDouble(POSITION_VOLUME);
               request.symbol=PositionGetString(POSITION_SYMBOL);
               request.price=SymbolInfoDouble(request.symbol,SYMBOL_ASK);
               request.deviation=20;
               request.type=ORDER_TYPE_BUY;
               request.comment=PositionGetString(POSITION_COMMENT);
               //========发送交易请求===============================
               bool X=OrderSend(request,result);
               if(X==false)
                 {
                  Print("订单发送失败代码："+IntegerToString(GetLastError()));
                  Print("交易返回代码："+IntegerToString(result.retcode));
                 }

              }
            Sleep(平总浮亏后睡眠分钟*60*1000);
           }

        }
     }
  };