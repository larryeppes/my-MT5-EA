//+------------------------------------------------------------------+
//|                                                         jyzl.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
ENUM_ORDER_TYPE_FILLING  交易量指令类型;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
 交易量指令类型=交易量指令(Symbol(),交易量指令类型);
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

  }
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING  交易量指令(string 币种,ENUM_ORDER_TYPE_FILLING 指令类型)
  {
   if(SymbolInfoInteger(币种,SYMBOL_FILLING_MODE)==SYMBOL_FILLING_IOC)
      指令类型=ORDER_FILLING_IOC;
   if(SymbolInfoInteger(币种,SYMBOL_FILLING_MODE)==SYMBOL_FILLING_FOK)
      指令类型=ORDER_FILLING_FOK;
   return(指令类型);
  }
//+------------------------------------------------------------------+
