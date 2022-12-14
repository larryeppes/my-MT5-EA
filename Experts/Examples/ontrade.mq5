//+------------------------------------------------------------------+
//|                                                      ontrade.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#define ONTRADE_MAGIC 2373095048804
#include <Trade\Trade.mqh>
CTrade trade;

input int sleep_in_seconds      = 5;            // 休眠时间
input int days                  = 1;            // 按天计算的交易历史深度
input double vol                = 0.01;         // 开仓大小
input int multiples             = 8;            // 点差倍率
input bool buyQ                 = false;        // 首单买进

//--- 在全局范围内设置交易历史的界限
datetime start;                                 // 缓存中交易历史的开始日期
datetime end;                                   // 缓存中交易历史的结束日期
//--- 全局计数器
static int orders = 0;                                     // 活跃订单数量
static int positions = 0;                                  // 持仓数量
static int deals = 0;                                      // 交易历史缓存中的交易数量
static int history_orders = 0;                             // 交易历史缓存中的订单数量
bool started                    = false;        // 计数器相关性标识
static string info = "";
bool first_tradeQ        = true;         // 标记开始的开仓, 开仓完毕后在 OnTimer 中不再主动开仓

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(sleep_in_seconds);
//--- 设置MagicNumber 标记我们所有订单
   trade.SetExpertMagicNumber(ONTRADE_MAGIC);
//--- 交易请求将通过OrderSendAsync() 函数以非同步的模式发送
   trade.SetAsyncMode(true);
   /*color BuyColor =clrYellow;
   color SellColor=clrRed;
   //--- 请求交易历史记录
   HistorySelect(0,TimeCurrent());
   //--- 创建物件
   string name;
   uint total=HistoryDealsTotal();
   ulong ticket=0;
   double price;
   double profit;
   datetime time;
   string symbol;
   long type;
   long entry;
   //--- 所有交易
   for(uint i=0; i<total; i++)
     {
      //--- 尽力获得交易报价
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- 获得交易属性
         price =HistoryDealGetDouble(ticket,DEAL_PRICE);
         time =HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         type =HistoryDealGetInteger(ticket,DEAL_TYPE);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         //--- 只对当前交易品种
         if(price && time && symbol==Symbol())
           {
            //--- 创建价格物件
            name="TradeHistory_Deal_"+string(ticket);
            if(entry)
               ObjectCreate(0,name,OBJ_ARROW_RIGHT_PRICE,0,time,price,0,0);
            else
               ObjectCreate(0,name,OBJ_ARROW_LEFT_PRICE,0,time,price,0,0);
            //--- 设置物件属性
            ObjectSetInteger(0,name,OBJPROP_SELECTABLE,0);
            ObjectSetInteger(0,name,OBJPROP_BACK,0);
            ObjectSetInteger(0,name,OBJPROP_COLOR,type?BuyColor:SellColor);
            if(profit!=0)
               ObjectSetString(0,name,OBJPROP_TEXT,"Profit:"+string(profit));
           }
        }
     }
   //--- 应用于图表
   ChartRedraw();*/

   end = TimeCurrent();
   string startstr = TimeToString(end, TIME_DATE);
   string hms = " 00:00:01";
   if(!StringAdd(hms, startstr))
      return(INIT_FAILED);
   start = StringToTime(startstr);
   Comment("init succeeded!");
   InitCounters();
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitCounters()
  {
   end = TimeCurrent();
   string startstr = TimeToString(end, TIME_DATE);
   string hms = " 00:00:01";
   if(!StringAdd(hms, startstr))
      return;
   start = StringToTime(startstr);
   ResetLastError();
   bool selected = HistorySelect(start,end);
   if(!selected)
     {

     }
//--- 获取当前值
   if(!started)
     {
      started = true;
     }

   orders = OrdersTotal();
   positions = PositionsTotal();
   deals = HistoryDealsTotal();
   history_orders = HistoryOrdersTotal();
   int curr_deals = HistoryDealsTotal();
   int curr_history_orders = HistoryOrdersTotal();
   int curr_orders = OrdersTotal();
   int curr_positions = PositionsTotal();

   Comment(StringFormat("started: %d\nstart: %s\nend: %s\n历史活跃订单数: %d\n历史持仓数: %d\n历史交易数: %d\n历史订单数: %d\n当前活跃订单数: %d\n当前持仓数: %d\n当前交易数: %d\n当前订单数: %d",
                        started, TimeToString(start), TimeToString(end), orders, positions, deals, history_orders, curr_orders, curr_positions, curr_deals, curr_history_orders));

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

   int curr_orders = OrdersTotal();
//--- 持仓数量的变化
   int curr_positions = PositionsTotal();
//--- 交易历史缓存中的交易数量的变化
   int curr_deals = HistoryDealsTotal();
//--- 交易历史缓存中的历史订单数量的变化
   int curr_history_orders = HistoryOrdersTotal();
   double total = -1;
   string info = "";
   int buy_count = 0;
   int sell_count = 0;
   double open_buy_price = 0;
   double open_sell_price =0;
   for(int i = 0; i < curr_orders; i++)
     {
      ulong order_ticket=OrderGetTicket(i);
      string type =EnumToString(ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE)));
      string symbol = OrderGetString(ORDER_SYMBOL);
      if(symbol == Symbol() && type == "ORDER_TYPE_BUY_LIMIT")
        {
         buy_count += 1;
         open_buy_price = OrderGetDouble(ORDER_PRICE_OPEN);
        }
      else
         if(symbol == Symbol() && type == "ORDER_TYPE_SELL_LIMIT")
           {
            sell_count += 1;
            open_sell_price = OrderGetDouble(ORDER_PRICE_OPEN);
           }
         else
           {
            continue;
           }
      info = StringFormat("order_ticket: %d\ntype: %s\nsymbol: %s\n%s", order_ticket, type, symbol, info);
     }
   info = StringFormat("%s\nfirst_tradeQ: %d\nbuy_count: %d\nsell_count: %d\nopen_buy_price: %.5f\nopen_sell_price: %.5f\nstarted: %d\ntotal: %.2f\nstart: %s\nend: %s\n历史活跃订单数: %d\n历史持仓数: %d\n历史交易数: %d\n历史订单数: %d\n当前活跃订单数: %d\n当前持仓数: %d\n当前交易数: %d\n当前订单数: %d",
                       info,
                       first_tradeQ,
                       buy_count,
                       sell_count,
                       open_buy_price,
                       open_sell_price,
                       PositionSelect(Symbol()),
                       total,
                       TimeToString(start),
                       TimeToString(end),
                       orders, // 历史活跃订单数
                       positions, // 历史持仓数
                       deals, // 历史交易数
                       history_orders, // 历史订单数
                       curr_orders, // 当前活跃订单数
                       curr_positions, // 当前持仓数
                       curr_deals, // 当前交易数
                       curr_history_orders // 当前订单数
                      );
   Comment(info);
//---
//InitCounters();
//--- 检查活跃订单的数量是否发生变化
   datetime current_time = TimeCurrent();
   int dayofweekno = DayOfWeekNo(current_time);
// 判断是否在交易日中
   if(!(dayofweekno <= 5 && dayofweekno >= 1))
     {
      return;
     }
// first_tradeQ: 手动配置是否开启开仓检查, 为true时只开仓一次, 为false时, 不再开仓
// 当有buy_limit和sell_limit挂单数量不匹配时, 会在后面清理挂单, 并重新挂单, 所以不需要再次开仓
   if((!PositionSelect(Symbol())) && first_tradeQ)
     {
      if(buyQ)
        {
         buy(vol, multiples);
         first_tradeQ = false;
        }
      else
        {
         sell(vol, multiples);
         first_tradeQ = false;
        }
      return;
     }
   if((buy_count != 1) || (sell_count != 1))
     {
      pending_order();
     }
   if ((buy_count ==1) && (sell_count == 1)) {
      double point=SymbolInfoDouble(Symbol(),SYMBOL_POINT);
      if (open_sell_price - open_buy_price > 500 * point) {
         pending_order();
      }
   }
   /**/
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   if(started)
     {
      SimpleTradeProcessor();
     }
   else
     {
      InitCounters();
      //Comment("refresh started");
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SimpleTradeProcessor()
  {
   end = TimeCurrent();
   string startstr = TimeToString(end, TIME_DATE);
   string hms = " 00:00:01";
   if(!StringAdd(hms, startstr))
      return;
   start = StringToTime(startstr);
   ResetLastError();
//--- 从指定的时间间隔下载交易历史到程序缓存
   bool selected=HistorySelect(start,end);
   if(!selected) {}
//--- 获取当前值
   int curr_orders = OrdersTotal();
   if(curr_orders != orders)
     {
      //--- 更新值
      orders=OrdersTotal();
     }
//--- 持仓数量的变化
   int curr_positions = PositionsTotal();
   if(curr_positions != positions)
     {
      //--- 更新值
      positions = PositionsTotal();
     }
//--- 交易历史缓存中的交易数量的变化
   int curr_deals = HistoryDealsTotal();
   if(curr_deals != deals)
     {
      //--- 更新值
      deals = HistoryDealsTotal();
      pending_order();
     }
//--- 交易历史缓存中的历史订单数量的变化
   int curr_history_orders = HistoryOrdersTotal();
   if(curr_history_orders!=history_orders)
     {
      //--- 更新值
      history_orders = HistoryOrdersTotal();
     }
   /*Comment(StringFormat("started: %d\nstart: %s\nend: %s\n历史活跃订单数: %d\n历史持仓数: %d\n历史交易数: %d\n历史订单数: %d\n当前活跃订单数: %d\n当前持仓数: %d\n当前交易数: %d\n当前订单数: %d",
                        started,
                        TimeToString(start),
                        TimeToString(end),
                        orders, // 历史活跃订单数
                        positions, // 历史持仓数
                        deals, // 历史交易数
                        history_orders, // 历史订单数
                        curr_orders, // 当前活跃订单数
                        curr_positions, // 当前持仓数
                        curr_deals, // 当前交易数
                        curr_history_orders // 当前订单数
                       ));*/
//--- 检查是否有必要更改缓存中请求的交易历史的限制
// 下面的函数有可能夹调一些历史订单数的统计, 所以有必要注释掉不用
//CheckStartDateInTradeHistory();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void pending_order()
  {
   bool clear_pending = ClearPendingOrder();
   while(!clear_pending)
     {
      Sleep(1000);
      clear_pending = ClearPendingOrder();
     }
   Sleep(500);
   bool buy_res = buy_limit(vol, multiples);
   int ind = 1;
   while((!buy_res) && (ind < 20))
     {
      Sleep(100);
      buy_res = buy_limit(vol, multiples + ind);
      ind += 1;
     }
   Sleep(500);
   bool sell_res = sell_limit(vol, multiples);
   ind = 1;
   while((!sell_res) && (ind < 20))
     {
      Sleep(100);
      sell_res = sell_limit(vol, multiples + ind);
      ind += 1;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ClearPendingOrder()
  {
   int orderstotal = OrdersTotal();
   bool result = true;
   for(int ind = 0; ind < orderstotal; ind++)
     {
      ulong order_ticket = OrderGetTicket(ind);
      string symbol =OrderGetString(ORDER_SYMBOL);
      if(symbol == Symbol())
        {
         //--- 尝试删除挂单
         bool res=trade.OrderDelete(order_ticket);
         result = result & res;
        }
     }
   return result;
  }

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
   if(trans.symbol != Symbol())
      return;
   if(trans.order_state != ORDER_STATE_PLACED && trans.type != TRADE_TRANSACTION_ORDER_ADD && trans.order_state != ORDER_STATE_CANCELED && trans.order_state != ORDER_STATE_STARTED)
     {
      info = StringFormat("order_type: %s\norder_state: %s\ndeal_type: %s\n%s",
                          EnumToString(trans.order_type),
                          EnumToString(trans.order_state),
                          trans.symbol,
                          StringSubstr(info, 0, 100));
     }
//Comment(info);
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
//---

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int buy(double position_vol, int mul)
  {
   ulong slip = 10;
   return MarketOrder(ORDER_TYPE_BUY, mul, position_vol, slip, ONTRADE_MAGIC);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int sell(double position_vol, int mul)
  {
   ulong slip = 10;
   return MarketOrder(ORDER_TYPE_SELL, mul, position_vol, slip, ONTRADE_MAGIC);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int buy_limit(double position_vol, int mul)
  {
   ulong slip = 10;
   return MarketOrder(ORDER_TYPE_BUY_LIMIT, mul, position_vol, slip, ONTRADE_MAGIC);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int sell_limit(double position_vol, int mul)
  {
   ulong slip = 10;

   return MarketOrder(ORDER_TYPE_SELL_LIMIT, mul, position_vol, slip, ONTRADE_MAGIC);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MarketOrder(ENUM_ORDER_TYPE type, int mul, double volume, ulong slip, ulong magicnumber, ulong pos_ticket = 0)
  {
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   double ask_price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double price_diff = ask_price - bid_price;

   double price = bid_price;
   if(type == ORDER_TYPE_BUY || type == ORDER_TYPE_SELL_LIMIT)
      price = ask_price;

   if(type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_SELL_LIMIT)
      request.action = TRADE_ACTION_PENDING;
   else
      request.action = TRADE_ACTION_DEAL;
   request.position = pos_ticket;
   request.symbol = Symbol();
   double position_vol = PositionGetDouble(POSITION_VOLUME);

   if(position_vol > 0.001 && position_vol < 5 && false)
     {
      request.volume = PositionGetDouble(POSITION_VOLUME);
     }
   else
     {
      request.volume = vol;
     }

   request.type = type;
   if(type == ORDER_TYPE_BUY || type == ORDER_TYPE_SELL)
      request.type_filling = ORDER_FILLING_IOC;

   double point=SymbolInfoDouble(Symbol(),SYMBOL_POINT);

   if (price_diff > 50 * point) {
      return false;
   }
   if(type == ORDER_TYPE_BUY_LIMIT)
     {
      request.price = price - mul * point;
     }
   else
      if(type == ORDER_TYPE_SELL_LIMIT)
        {
         request.price = price + mul * point;
        }
      else
        {
         request.price = price;
        }

   request.deviation = slip;
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
