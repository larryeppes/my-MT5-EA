//+------------------------------------------------------------------+
//|                                 Π.EA 市场深度刷单1.1 VX：My05613828.mq5 |
//|                                                             @老顽童 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "@老顽童"
#property link      "https://www.mql5.com"
#property version   "1.1"
#property  description "欢迎使用Π.EA 市场深度刷单"
#property  description "==========================="
#property  description "市场深度手数：表示盘口数据；"
#property  description "平总浮盈：平总浮盈为0，代表不启用，对应睡眠时间无效；"
#property  description "平总浮亏：平总浮盈为0，代表不启用，对应睡眠时间无效；"
#property  description "平总浮盈与平总浮亏受magic统计（请勿与其他EA magic一致；"
#property  description "止损止盈为0，代表不启用；"
#property  description "==========================="
input ENUM_ORDER_TYPE_FILLING 交易量成交指令类型 =ORDER_FILLING_FOK;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
bool w;
bool m;
int d1;
int d2;
input double 市场深度手数=500;
input double 平总浮盈=0;
input int 平总浮盈后睡眠分钟=30;
input double 平总浮亏=0;
input int 平总浮亏后睡眠分钟=30;
enum 做单
  {
   挂多单,
   挂空单,
   挂多空
  };
input 做单 做单选择=挂多空;
input string  做多分割线="------做多分割线-------";
input double 多持仓单数限制=5;
input double 多挂单点值=300;
input double 做多手数=0.01;
input double 做多止损=0;
input double 做多止盈=350;
input int 做多magic=521101;
input string  做空分割线="-----做空分割线-------";
input double 空持仓单数限制=5;
input double 空挂单点值=300;
input double 做空手数=0.01;
input double 做空止损=0;
input double 做空止盈=350;
input int 做空magic=521102;

MqlBookInfo 订阅数组[];
int OnInit()
  {
//---
   EventSetTimer(1);
   MarketBookAdd(Symbol());
   w=false;
   m=false;
   d1=0;
   d2=0;
//+------------------------------------------------------------------+
//|                                 |
//+------------------------------------------------------------------+

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   EventKillTimer();
   MarketBookRelease(Symbol());
//+------------------------------------------------------------------+
//| 退出 删除挂单                               |
//+------------------------------------------------------------------+
   for(int j=OrdersTotal()-1; j>=0; j--)
     {
      if(OrderGetTicket(j)>0&&(OrderGetInteger(ORDER_MAGIC)==做多magic||OrderGetInteger(ORDER_MAGIC)==做空magic))
        {
         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request);
         ZeroMemory(result);

         request.action=TRADE_ACTION_REMOVE;
         request.symbol=OrderGetString(ORDER_SYMBOL);
         request.order=OrderGetInteger(ORDER_TICKET);
         request.magic=OrderGetInteger(ORDER_MAGIC);
         bool X= OrderSend(request,result);
         if(X=false)
           {
            PrintFormat("订单失败代码:",GetLastError());
            PrintFormat("交易返回代码：",result.retcode);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(w==false&&m==false)
     {
      Print("未捕获到市场深度数据、\n请检查盘口数据");
     }
//---

   if(平总浮盈!=0)
      一键全平总盈利(平总浮盈);
   if(平总浮亏!=0)
      一键全平总亏损(平总浮亏);
//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   OnTick();
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
//---
   w= MarketBookGet(Symbol(),订阅数组);

   if(w==true)
     {
      int x=ArraySize(订阅数组);
      for(int i=0; i<x; i++)
        {
         double 深度报价=订阅数组[i].price;
         ENUM_BOOK_TYPE 订单类型=订阅数组[i].type;
         long 交易量=订阅数组[i].volume;
         double 精准交易量=订阅数组[i].volume_real;
         //---- 统计多单数

         //      Print(深度报价);
         //      Print(订单类型);
         //    Print(交易量);
         //     Print(精准交易量);
         //---- 统计多单数
         int a=0;
         for(int j=PositionsTotal()-1; j>=0; j--)
           {
            if(PositionGetTicket(j)>0&&PositionGetInteger(POSITION_MAGIC)==做多magic)
              {
               //==========如果持仓订单为多单，则执行平多单操作=======
               if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
                 {
                  a++;
                 }
              }
           }

         //---- 统计空单数
         int b=0;
         for(int j=PositionsTotal()-1; j>=0; j--)
           {
            if(PositionGetTicket(j)>0&&PositionGetInteger(POSITION_MAGIC)==做空magic)
              {
               //==========如果持仓订单为多单，则执行平多单操作=======
               if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
                 {
                  b++;
                 }
              }
           }
         //    Print(a);
         //    Print(b);
         //-----下多挂单
         if(a<多持仓单数限制)
           {
            //----挂多
            if(做单选择==挂多单||做单选择==挂多空)
              {
               if(订单类型==BOOK_TYPE_BUY&&精准交易量>市场深度手数&&深度报价<SymbolInfoDouble(Symbol(),SYMBOL_ASK)-多挂单点值*SymbolInfoDouble(Symbol(),SYMBOL_POINT))
                 {
                  double    c1=0;
                  double   c2=0;
                  if(做多止损!=0&&做多止损<SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL))
                    {
                     c1=SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL)-做多止损;
                    }
                  if(做多止盈!=0&&做多止盈<SymbolInfoInteger(Symbol(),SYMBOL_TRADE_FREEZE_LEVEL))
                    {
                     c2=SymbolInfoInteger(Symbol(),SYMBOL_TRADE_FREEZE_LEVEL)-做多止盈;
                    }
                  一键多挂单不重复(做多magic,Symbol(),多挂单点值,做多手数,做多止损+c1,做多止盈+c2,20,IntegerToString(d1+1)+"  多挂单");
                 }
              }
           }
         //----下空挂单
         if(b<空持仓单数限制)
           {
            //---挂空
            if(做单选择==挂空单||做单选择==挂多空)
              {
               if(订单类型==BOOK_TYPE_SELL&&精准交易量>市场深度手数&&深度报价>SymbolInfoDouble(Symbol(),SYMBOL_BID)+空挂单点值*SymbolInfoDouble(Symbol(),SYMBOL_POINT))
                 {
                  double    c3=0;
                  double   c4=0;
                  if(做空止损!=0&&做空止损<SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL))
                    {
                     c3=SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL)-做空止损;
                    }
                  if(做空止盈!=0&&做空止盈<SymbolInfoInteger(Symbol(),SYMBOL_TRADE_FREEZE_LEVEL))
                    {
                     c4=SymbolInfoInteger(Symbol(),SYMBOL_TRADE_FREEZE_LEVEL)-做空止盈;
                    }
                  一键空挂单不重复(做空magic,Symbol(),空挂单点值,做空手数,做空止损+c3,做空止盈+c4,20,IntegerToString(d2+1)+"  空挂单");
                 }
              }
           }
        }//---for
      if(m==false)
        {
         Print("市场深度改变了");
         m=true;
        }
     }//---w   true

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
      if(PositionGetTicket(i)>0&&(PositionGetInteger(POSITION_MAGIC)==做多magic||PositionGetInteger(POSITION_MAGIC)==做空magic))
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
         if(PositionGetTicket(i)>0&&(PositionGetInteger(POSITION_MAGIC)==做多magic||PositionGetInteger(POSITION_MAGIC)==做空magic))

           {
            //==========如果持仓订单为多单，则执行平多单操作=======
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               //=======声明并初始化交易请求和交易请求结果=========
               MqlTradeRequest request= {};
               MqlTradeResult  result= {};
               //=======填充结构体参数=============================
               request.action=TRADE_ACTION_DEAL;
               request.type_filling=交易量成交指令类型;
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
               request.type_filling=交易量成交指令类型;
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
      if(PositionGetTicket(i)>0&&(PositionGetInteger(POSITION_MAGIC)==做多magic||PositionGetInteger(POSITION_MAGIC)==做空magic))
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
         if(PositionGetTicket(i)>0&&(PositionGetInteger(POSITION_MAGIC)==做多magic||PositionGetInteger(POSITION_MAGIC)==做空magic))

           {
            //==========如果持仓订单为多单，则执行平多单操作=======
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               //=======声明并初始化交易请求和交易请求结果=========
               MqlTradeRequest request= {};
               MqlTradeResult  result= {};
               //=======填充结构体参数=============================
               request.action=TRADE_ACTION_DEAL;
               request.type_filling=交易量成交指令类型;
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
               request.type_filling=交易量成交指令类型;
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
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void   一键多挂单不重复(int magic号码,string 品种,double 多挂单点数,double 手数,double 挂单止损,double 挂单止盈,int 滑点,string 挂多注释)

  {
   int 多挂单数量=0;
   for(int f=OrdersTotal()-1; f>=0; f--)
     {
      if(OrderGetTicket(f)>0)
        {
         if(OrderGetString(ORDER_SYMBOL)==Symbol()&&OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_LIMIT&&OrderGetInteger(ORDER_MAGIC)==magic号码)
           {
            多挂单数量=多挂单数量+1;
           }
        }
     }
   if(多挂单数量==0)
     {
      d1++;
      double 挂单进场价格=SymbolInfoDouble(品种,SYMBOL_ASK)-多挂单点数*SymbolInfoDouble(品种,SYMBOL_POINT);

      MqlTradeRequest request= {};
      MqlTradeResult  result= {};
      request.action=TRADE_ACTION_PENDING;
      request.symbol=品种;
      request.volume=手数;
      request.price=挂单进场价格;
      if(挂单止损==0)
        {
         request.sl=NULL;
        }
      else
        {
         request.sl=request.price-挂单止损*SymbolInfoDouble(request.symbol,SYMBOL_POINT);
        }
      if(挂单止盈==0)
        {
         request.tp=NULL;
        }
      else
        {
         request.tp= request.price+挂单止盈*SymbolInfoDouble(request.symbol,SYMBOL_POINT);
        }
      request.deviation=滑点;

      request.type=ORDER_TYPE_BUY_LIMIT;      //挂单类型
      request.type_filling=交易量成交指令类型;//订单执行类型
      request.type_time=ORDER_TIME_GTC;
      request.expiration=0;
      request.comment=挂多注释;
      request.magic=magic号码;

      if(!OrderSend(request,result))

         PrintFormat("订单失败代码:",GetLastError());
      PrintFormat("交易返回代码：",result.retcode);

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void   一键空挂单不重复(int magic号码,string 品种,double 空挂单点数,double 手数,double 挂单止损,double 挂单止盈,int 滑点,string 挂空注释)
  {
   int 空挂单数量=0;
   for(int f=OrdersTotal()-1; f>=0; f--)
     {
      if(OrderGetTicket(f)>0&&OrderGetString(ORDER_SYMBOL)==Symbol()&&OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_LIMIT&&OrderGetInteger(ORDER_MAGIC)==magic号码)
        {
         空挂单数量=空挂单数量+1;
        }
     }
   if(空挂单数量==0)
     {
      d2++;
      double 挂单进场价格=SymbolInfoDouble(品种,SYMBOL_BID)+空挂单点数*SymbolInfoDouble(品种,SYMBOL_POINT);

      MqlTradeRequest request= {};
      MqlTradeResult  result= {};
      request.action=TRADE_ACTION_PENDING;
      request.symbol=品种;
      request.volume=手数;
      request.price=挂单进场价格;

      if(挂单止损==0)
        {
         request.sl=NULL;
        }
      else
        {
         request.sl=request.price+挂单止损*SymbolInfoDouble(request.symbol,SYMBOL_POINT);
        }
      if(挂单止盈==0)
        {
         request.tp=NULL;
        }
      else
        {
         request.tp= request.price-挂单止盈*SymbolInfoDouble(request.symbol,SYMBOL_POINT);
        }
      request.deviation=滑点;
      request.type=ORDER_TYPE_SELL_LIMIT;      //挂单类型
      request.type_filling=交易量成交指令类型;//订单执行类型
      request.type_time=ORDER_TIME_GTC;
      request.expiration=0;
      request.comment=挂空注释;
      request.magic=magic号码;

      if(!OrderSend(request,result))

         PrintFormat("订单失败代码:",GetLastError());
      PrintFormat("交易返回代码：",result.retcode);

     }
  }
//+------------------------------------------------------------------+
