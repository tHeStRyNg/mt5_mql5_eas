//+------------------------------------------------------------------+
//|                                                   Break_Even.mq5 |
//|                                Copyright 2023, Algorithmic, GMBH |
//|                                      https://www.algorithmic.one |
//+------------------------------------------------------------------+
/* Important - https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes */

#property copyright "Copyright 2023, Algorithmic, GMBH"
#property link      "https://www.algorithmic.one"
#property version   "1.00"

#include <Trade/Trade.mqh>

/* HANDLER */
int MACD_h;

/* ARRAYS WHERE INDICATOR DATA IS STORED */
double MACD[];
double SIGNAL[];

/* FOR OPENING OPERATIONS */
CTrade trade;
ulong trade_ticket = 0;
bool time_passed = true;
double open_price = 0;

//  500€ -> 0.02
// 1000€ -> 0.05
// 2000€ -> 0.1
// 1500€ -> 0.07
double get_lotage() {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   return NormalizeDouble((balance/1000)*0.01, 2);
}

int OnInit() {
   /* HANDLER INIT */
   MACD_h = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
   
   ArraySetAsSeries(MACD, true);
   ArraySetAsSeries(SIGNAL, true);

   return(INIT_SUCCEEDED);
}

void OnTick() {
   /* INDICATOR DATA SAVE */
   CopyBuffer(MACD_h, 0, 1, 4, MACD);
   CopyBuffer(MACD_h, 1, 1, 4, SIGNAL);
   
   /* CHECKING FOR OPEN OPERATIONS*/
   if (PositionSelectByTicket(trade_ticket) == false && trade_ticket != 0) {
      // RESET TRADE FLAGS
      trade_ticket = 0;
      open_price = 0;
   } 
   
   /*  BREAK EVEN  */
   else if (trade_ticket != 0 && open_price != 0) {
      double profit = PositionGetDouble(POSITION_PROFIT);
      
      if (profit >= 0.5) {
         trade.PositionModify(trade_ticket, open_price, 0);
         open_price = 0;
      }
   }
   /*  BREAK EVEN  */
   
   
   if ( // BUY CHECK
      MACD[1] < SIGNAL[1] && MACD[0] > SIGNAL[0]      // CROSS TRIGGER
      && trade_ticket <= 0 && time_passed == true
      ) {
      /* ACTUAL PRICE */
      double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      open_price = Ask;
      
      //--- OPEN BUY - ASK
      double lotage = get_lotage();
      trade.Buy(lotage, _Symbol, Ask, Ask-100*_Point, 0, NULL);
      trade_ticket = trade.ResultOrder();

      time_passed = false;
      
      EventSetTimer(PeriodSeconds(PERIOD_CURRENT)*3);
      
   } else if ( // SELL CHECK
   MACD[1] > SIGNAL[1] && MACD[0] <  SIGNAL[0]      // CROSS TRIGGER
   && trade_ticket <= 0 && time_passed == true
   ) {
      /* ACTUAL PRICE */
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      open_price = Bid;
      
      //--- OPEN SELL - BID
      double lotage = get_lotage();      
      trade.Sell(lotage, _Symbol, Bid, Bid+100*_Point, 0, NULL);
      trade_ticket = trade.ResultOrder();
      
      time_passed = false;
      
      EventSetTimer(PeriodSeconds(PERIOD_CURRENT)*3);
   }
}

void OnTimer() {
   time_passed = true;
}