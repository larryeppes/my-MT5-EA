//+------------------------------------------------------------------+
//|                                                         open.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#define OPEN_MAGIC 2373095048802

input double threshold           = 0.03;          // 止损点差
input int sleep_time             = 2;             // 休眠时间
input double my_profit           = 100;           // 最小盈利点
input string start_time          = " 21:45:00";   // 交易开始时间
input string end_time            = " 21:50:00";   // 交易结束时间
input double slip_bound          = 0.04;          // 小于此点差上界购入
input double vol                 = 0.01;          // 开仓大小
input double danger_diff         = 0.3;           // 高危点差
input double stop_vol            = 0.01;          // 停损仓位
input double clear_rate          = 0.3;           // 低于全仓位的此比例清仓
input int open_count             = 20;            // 开仓量上界
input bool incrementQ            = false;         // 是否无风险加仓

static bool newdayQ              = false;
static string start_order_time   = "";
static string end_order_time     = "";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(sleep_time);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   string comm = "";
   static int symbol_number=0;
//--- don't process if timeout
   datetime current_time = TimeCurrent();
   int dayofweekno = DayOfWeekNo(current_time);
// 判断是否在交易日中
   if(!(dayofweekno <= 5 && dayofweekno >= 1))
     {
      return;
     }
//--- check for data
   if(!newdayQ)
     {
      start_order_time = TimeToString(current_time, TIME_DATE);
      end_order_time = TimeToString(current_time, TIME_DATE);
      //---
      if(!StringAdd(end_order_time, end_time))
         return;
      if(!StringAdd(start_order_time, start_time))
         return;
      newdayQ = true; // 当天交易只执行一次时间设置, 提升程序运行效率
     }
   comm=comm+StringFormat(" current time: %s\r\n",TimeToString(current_time));
   comm=comm+StringFormat(" start time: %s\r\n",TimeToString(start_order_time));
   comm=comm+StringFormat(" end time: %s\r\n",TimeToString(end_order_time));
   comm=comm+StringFormat(" symbol total: %d\r\n", SymbolsTotal(true));
   comm=comm+StringFormat(" symbol number: %d\r\n", symbol_number);
   comm=comm+StringFormat(" last sync time: %s\r\n", TimeToString(SymbolInfoInteger(Symbol(), SYMBOL_TIME)));
// 判断是否是交易时间
   if(current_time < end_order_time && current_time > start_order_time)
     {
      int i = 0; // 轮询所有标的的指标记录
      int totalsymbol = SymbolsTotal(true);
      while(i<totalsymbol)
        {
         string symbol = SymbolName((symbol_number % totalsymbol), true);
         /*if(StringFind(symbol, ".", 0) == -1)
           {
            comm=StringFormat(" irregular symbol id: %s and symbol id: %d\r\n", symbol, (symbol_number % totalsymbol));
            symbol_number+=1;
            i++;
            continue;
           }*/
         if(symbol == "CHPT.N" || symbol == "S92G.DE" || (symbol == "ARLG.DE") || (symbol == "CNPP.PA") || (symbol == "LAGA.PA") || (symbol == "FDJ.PA"))
           {
            symbol_number+=1;
            i++;
            continue;
           }
         comm="symbole name is: "+symbol+"\r\n";
         comm=comm+StringFormat(" 正在处理的 symbol id: %s and symbol id: %d\r\n", symbol, (symbol_number % totalsymbol));
         if(handle(symbol))
           {
            // 有交易产生的处理
            symbol_number+=1;
            Comment(comm);
            return;
           }
         // 没有交易产生的处理
         symbol_number++;
         i++;
        }
      // 交易时间段内的交易策略到此结束
     }
   else
     {
      newdayQ = false; // 用来重新读取当日日期
      // 选择交易品种, 清仓
      if(PositionSelect(Symbol()))
        {
         // 不在交易时间段内的情况
         // 如果有仓位则清空仓位
         // 获取仓位
         double total = PositionGetDouble(POSITION_VOLUME);
        }
     }

   Comment(comm);
  }

//+------------------------------------------------------------------+
bool handle(string symbol)
  {
   if(PositionSelect(symbol))
     {
      // 有持仓
      // 处理有仓位的情况
      double total = PositionGetDouble(POSITION_VOLUME);
      if(total > 0.001)
        {
         // 获取仓位买卖属性
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         // 获取仓位开仓价格
         double position_price = PositionGetDouble(POSITION_PRICE_OPEN);
         // 获取当前价格
         double current_bid_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         double current_ask_price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         double price_diff = current_ask_price - current_bid_price;
         // 卖出仓位处理方式
         if(type == POSITION_TYPE_SELL)
           {
            // 处理高风险点差异常状态的订单
            if(price_diff > danger_diff)
              {
               buy(symbol, stop_vol);
               return true;
              }
            if(total < vol / 3 && incrementQ)
              {
               sell(symbol, 0.01 * MathRound(100 * (vol - total)));
               return true;
              }
            // 获取当前价格
            if(current_bid_price > position_price + threshold || PositionGetDouble(POSITION_PROFIT) < 0)
              {
               // 当前价格不好或者有利润的的时候修改开仓
               double amount_real = 0.4/(-PositionGetDouble(POSITION_PROFIT)/(total/0.01));
               double amount = 0.01*floor(amount_real);

               if(amount < 0.01)
                 {
                  return false;
                 }
               buy(symbol, amount);
               return true;
              }
            if(PositionGetDouble(POSITION_PROFIT) >= my_profit || total < clear_rate * vol)
              {
               // 当前价格不好或者有利润的的时候修改开仓
               buy(symbol, total);
               return true;
              }
            if(-PositionGetDouble(POSITION_PROFIT)/(total/0.01) < 1/4 && total < vol && incrementQ)
              {
               sell(symbol, 0.01 * MathRound(100 * (vol - total)));
               return true;
              }
           }
         // 买进仓位的处理, 和上面相反
         if(type == POSITION_TYPE_BUY)
           {
            // 处理高风险点差异常状态的订单
            if(price_diff > danger_diff)
              {
               sell(symbol, stop_vol);
               return true;
              }
            if(total < vol / 3 && incrementQ)
              {
               buy(symbol, 0.01 * MathRound(100 * (vol - total)));
               return true;
              }
            if(current_ask_price < position_price - threshold  || PositionGetDouble(POSITION_PROFIT) < 0)
              {
               double amount_real = 0.3/(-PositionGetDouble(POSITION_PROFIT)/(total/0.01));
               double amount = 0.01*floor(amount_real);
               if(amount < 0.01)
                 {
                  return false;
                 }
               sell(symbol, amount);
               return true;
              }
            if(PositionGetDouble(POSITION_PROFIT) >= my_profit || total < clear_rate * vol)
              {
               sell(symbol, total);
               return true;
              }
            if(-PositionGetDouble(POSITION_PROFIT)/(total/0.01) < 1/4 && total < vol && incrementQ)
              {
               buy(symbol, 0.01 * MathRound(100 * (vol - total)));
               return true;
              }
           }
         PrintFormat("Symbol %s: total position: %.2f, position type: %s, position price: %.2f, current ask price: %.2f, current bid price: %.2f", Symbol(), total, EnumToString(type), position_price, current_ask_price, current_bid_price);
         // 有仓位的订单处理完毕
         return false;
        }
      return false;
     }
   else
     {
      if(open_position(symbol))
        {
         return true;
        }
      return false;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool open_position(string symbol)
  {
   int rnd = 0;
// 选择交易品种
   if(SymbolSelect(symbol, true))
     {
      // 获取仓位
      double current_bid_price = SymbolInfoDouble(symbol, SYMBOL_BID);
      double current_ask_price = SymbolInfoDouble(symbol, SYMBOL_ASK);

      if(current_ask_price - current_bid_price <= slip_bound && PositionsTotal() <= open_count && current_ask_price >= 0 && current_ask_price <= 150)
        {
         rnd = MathRand()%100;

         if(rnd < 40)
           {
            buy(symbol, vol);
            Sleep(300);
            buy(symbol, vol);
            Sleep(300);
            buy(symbol, vol);
            return true;
           }
         else
           {
            sell(symbol, vol);
            Sleep(300);
            sell(symbol, vol);
            Sleep(300);
            sell(symbol, vol);
            return true;
           }
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int DayOfWeekNo(const datetime time)
  {
   MqlDateTime dt;
   string day = "";
   TimeToStruct(time, dt);
   return dt.day_of_week;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int buy(string symbol, double vol)
  {
   ulong slip = 10;
   return MarketOrder(symbol, ORDER_TYPE_BUY, vol, slip, OPEN_MAGIC);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int sell(string symbol, double vol)
  {
   ulong slip = 10;

   return MarketOrder(symbol, ORDER_TYPE_SELL, vol, slip, OPEN_MAGIC);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MarketOrder(string symbol, ENUM_ORDER_TYPE type, double volume, ulong slip, ulong magicnumber, ulong pos_ticket = 0)
  {
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   double price = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(type == ORDER_TYPE_BUY)
      price = SymbolInfoDouble(symbol, SYMBOL_ASK);

   request.action = TRADE_ACTION_DEAL;
   request.position = pos_ticket;
   request.symbol = symbol;
   request.volume = volume;
   request.type = type;
   request.type_filling = ORDER_FILLING_IOC;
   request.price = price;
   request.deviation = slip;
   request.comment = StringFormat("vol = %.2f", volume);
   request.magic = magicnumber;

   if(!OrderSend(request, result))
     {
      PrintFormat("OrderSend %s %s %.2f at %.5f error %d", request.symbol, EnumToString(type), volume, request.price, GetLastError());
      // PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
      return(false);
     }

// PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
   return(true);
  }
//+------------------------------------------------------------------+
