//+------------------------------------------------------------------+
//|                                                Close_Partial.mq5 |
//|                                Copyright 2023, Algorithmic, GMBH |
//|                                      https://www.algorithmic.one |
//+------------------------------------------------------------------+
/* Important - https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes */

#property copyright "Copyright 2023, Algorithmic, GMBH"
#property link      "https://www.algorithmic.one"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;
ulong trade_ticket = 0;

void OnInit() {
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      
   trade.Sell(1, _Symbol, Bid, Bid+100000*_Point, Bid-100000*_Point);
   trade_ticket = trade.ResultOrder();
}

void OnTick() {
   if (trade_ticket != 0) {
      trade.PositionClosePartial(trade_ticket, 0.2);
      trade_ticket = 0;
   }
}