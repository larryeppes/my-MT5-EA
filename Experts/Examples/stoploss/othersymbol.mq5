//+------------------------------------------------------------------+
//|                                                     stoploss.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2009-2017, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property version     "5.50"
#property description "It is important to make sure that the expert works with a normal"
#property description "chart and the user did not make any mistakes setting input"
#property description "variables (Lots, TakeProfit, TrailingStop) in our case,"
#property description "we check TakeProfit on a chart of more than 2*trend_period bars"

#define STOPLOSS_MAGIC 2373095048802
//---
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

input double threshold          = 0.02;          // price difference threshold
input bool active_order         = true;          // automate perform deal
input double position_vol       = 0.02;          // open position volume
input double my_profit          = 0;             // my profit for JPY or 0.01 for USD
input bool buy_start            = false;         // buy in if there is empty position or not
input string start_time         = " 16:35:00";
input string end_time           = " 21:50:00";
input double danger_diff        = 0.3;           // 高危点差
input string symbol             = "GYC.DE";

static int sleep_time_in_seconds = 0;

//+------------------------------------------------------------------+
//|                                                                  |
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
   static datetime limit_time = 0; // last trade processing time + timeout
//--- don't process if timeout
   datetime current_time = TimeCurrent();
   int dayofweekno = DayOfWeekNo(current_time);
// 判断是否在交易日中
   if(!(dayofweekno <= 5 && dayofweekno >= 1))
     {
      return;
     }
// 避免过于高频交易的判断, 这里使用每隔至少1秒进行一次自动化交易
   if(current_time >= limit_time)
     {
      //--- check for data
      string start_order_time = TimeToString(current_time, TIME_DATE);
      string end_order_time = TimeToString(current_time, TIME_DATE);
      //---
      if(!StringAdd(end_order_time, end_time))
         return;
      if(!StringAdd(start_order_time, start_time))
         return;
      // 判断是否是交易时间
      if(current_time < end_order_time && current_time > start_order_time)
        {
         double total = 0;
         // 选择交易品种
         if(PositionSelect(symbol))
           {
            // 获取仓位
            total = PositionGetDouble(POSITION_VOLUME);


            // 有仓位的操作
            if(total > 0.001)
              {
               // 获取仓位买卖属性
               ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               // 获取仓位开仓价格
               double position_price = PositionGetDouble(POSITION_PRICE_OPEN);
               // 获取当前价格
               double current_bid_price = SymbolInfoDouble(symbol, SYMBOL_BID);
               double current_ask_price = SymbolInfoDouble(symbol, SYMBOL_ASK);
               double price_diff = current_ask_price - current_bid_price;
               // 卖出仓位处理方式
               if(type == POSITION_TYPE_SELL)
                 {
                  // 处理高风险点差异常状态的订单
                  if(price_diff > danger_diff)
                    {
                     buy(total);
                     return;
                    }
                  // 获取当前价格
                  if(current_bid_price > position_price + threshold || PositionGetDouble(POSITION_PROFIT) > my_profit)
                    {
                     // 当前价格不好或者有利润的的时候修改开仓
                     buy(total);
                     sell(total);
                    }
                 }
               // 买进仓位的处理, 和上面相反
               if(type == POSITION_TYPE_BUY)
                 {
                  // 处理高风险点差异常状态的订单
                  if(price_diff > 0.3)
                    {
                     sell(total);
                     return;
                    }
                  if(current_ask_price < position_price - threshold || PositionGetDouble(POSITION_PROFIT) > my_profit)
                    {
                     sell(total);
                     buy(total);
                    }
                 }
               PrintFormat("Symbol %s: total position: %.2f, position type: %s, position price: %.2f, current ask price: %.2f, current bid price: %.2f", symbol, total, EnumToString(type), position_price, current_ask_price, current_bid_price);
               // 有仓位的订单处理完毕
              }


           }
         // 判断是否需要自动开单
         if(active_order)
           {
            // 点差过大时不开仓
            double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
            double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
            PrintFormat("----------------------------------------the diff:%.2f", ask - bid);
            if(ask - bid > 0.15)
              {
               sleep_time_in_seconds = sleep_time_in_seconds + 5;
               PrintFormat("============================ 高风险时刻: %d's =========================================", sleep_time_in_seconds);
               if(sleep_time_in_seconds > 60 * 5)
                  sleep_time_in_seconds = 60 * 5;
               limit_time = current_time + sleep_time_in_seconds;
               return;
              }
            sleep_time_in_seconds = 0;
            // 判断是否有仓位, 只处理没有开仓的情况, 开始一笔卖出仓位
            if(total < 0.001)
              {
               if(buy_start)
                 {
                  buy(position_vol);
                 }
               else
                 {
                  sell(position_vol);
                 }
              }
           }
        }
      else
        {
         // 选择交易品种
         if(PositionSelect(symbol))
           {
            // 不在交易时间段内的情况
            // 如果有仓位则清空仓位
            // 获取仓位
            double total = PositionGetDouble(POSITION_VOLUME);
            // 有仓位的操作
            if(total > 0.001)
              {
               // 获取仓位买卖属性
               ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

               // 卖出仓位处理方式
               if(type == POSITION_TYPE_SELL)
                 {
                  buy(total);
                 }

               // 买进仓位的处理, 和上面相反
               if(type == POSITION_TYPE_BUY)
                 {
                  sell(total);
                 }
              }
           }
        }

      limit_time = current_time + 1;
      // PrintFormat("Last Errors: %s", GetLastError());
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int buy(double position_vol)
  {
   ulong slip = 10;
   return MarketOrder(ORDER_TYPE_BUY, position_vol, slip, STOPLOSS_MAGIC);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int sell(double position_vol)
  {
   ulong slip = 10;

   return MarketOrder(ORDER_TYPE_SELL, position_vol, slip, STOPLOSS_MAGIC);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MarketOrder(ENUM_ORDER_TYPE type, double volume, ulong slip, ulong magicnumber, ulong pos_ticket = 0)
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
   request.magic = magicnumber;

   if(!OrderSend(request, result))
     {
      PrintFormat("OrderSend %s %s %.2f at %.5f error %d", request.symbol, EnumToString(type), volume, request.price, GetLastError());
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
      return(false);
     }

   PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
   return(true);
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
//|                                                                  |
//+------------------------------------------------------------------+
string DayOfWeek(const datetime time)
  {
   MqlDateTime dt;
   string day = "";
   TimeToStruct(time, dt);
   switch(dt.day_of_week)
     {
      case 0:
         day = EnumToString(SUNDAY);
         break;
      case 1:
         day = EnumToString(MONDAY);
         break;
      case 2:
         day = EnumToString(TUESDAY);
         break;
      case 3:
         day = EnumToString(WEDNESDAY);
         break;
      case 4:
         day = EnumToString(THURSDAY);
         break;
      case 5:
         day = EnumToString(FRIDAY);
         break;
      case 6:
         day = EnumToString(SATURDAY);
         break;
     }
   return day;
  }
//+------------------------------------------------------------------+
