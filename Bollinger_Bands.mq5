//+------------------------------------------------------------------+
//|                                              Bollinger_Bands.mq5 |
//|                                Copyright 2023, Algorithmic, GMBH |
//|                                      https://www.algorithmic.one |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Algorithmic, GMBH"
#property link      "https://www.algorithmic.one"
#property version   "1.00"

/* IMPORTANT ERROR CODES - https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes */

// We import MQH Trade Library so we can do Operations
#include <Trade/Trade.mqh>
// We create an object which allows us to open operations
CTrade trade;
// Variable to hold the ticket information
ulong trade_ticket;

// Manager for Indicator Bollinger Bands
int bollinger_h;

// Arrays to store the lines of the bollinger bands
double bollinger_up[];
double bollinger_dw[];

// Arrays to save the candles
MqlRates velas[];

// Function to confirm the BUY condition
bool condicion_compra() {
   // If the close of the candle is above the infirior band line,
   // and the open of the candle is below the Infirior band line
   // Then we BUY
   return velas[0].close > bollinger_dw[0] && velas[0].low < bollinger_dw[0];
}

// Function to confirm the SELL condition
bool condicion_venta() {
   // If the close of the candle is below the infirior band line,
   // and the open of the candle is above the Infirior band line
   // Then we SELL
   return velas[0].close < bollinger_up[0] && velas[0].high > bollinger_up[0];
}

// Función para comprobar si hay una operación abierta
bool operacion_cerrada() {
   return !PositionSelectByTicket(trade_ticket);
}

// Function to check if we are in a New Candle
int bars;
bool nueva_vela() {
   int current_bars = Bars(_Symbol, _Period);
   if (current_bars != bars) {
      bars = current_bars;
      return true;
   }
   
   return false;
}

// Event that initializes the Bot
int OnInit() {
   // Initiation of the indicator for Bollinger Bands
   bollinger_h = iBands(_Symbol, _Period, 20, 0, 2, PRICE_CLOSE);
   if (bollinger_h == INVALID_HANDLE) {
      Print("ERROR STARTING THE INDICATOR");
      return INIT_FAILED;
   }
   
   // INITIALIZATION OF THE ARRAYS TO STORE THE DATA
   ArraySetAsSeries(bollinger_up, true);
   ArraySetAsSeries(bollinger_dw, true);
   ArraySetAsSeries(velas, true);

   return INIT_SUCCEEDED;
}

// EVENT TO CLOSE THE INDICATOR WHEN WE CLOSE THE BOT
void OnDeinit(const int reason) {
   if (bollinger_h != INVALID_HANDLE) IndicatorRelease(bollinger_h);
}

// EVENT TO EXECUTE ON EVERY TICK
void OnTick() {
   // WE STORE IN THE ARRAYS THE REQUIRED INFO
   // WE SAVE USING F1 WITH iBands FUNCTION, TO KNOW WHICH BUFFER
   // EACH LINE HAS
   CopyBuffer(bollinger_h, UPPER_BAND, 0, 1, bollinger_up);
   CopyBuffer(bollinger_h, LOWER_BAND, 0, 1, bollinger_dw);
   CopyRates(_Symbol, _Period, 0, 1, velas);

   // BUY CONDITION
   if (condicion_compra() && nueva_vela() && operacion_cerrada()) {
      // WE OBTAIN THE ASK PRICE OF THE MARKET
      double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      
      // WE OPEN THE BUY ORDER AND SAVE THE POSITION TICKET INFO
      trade.Buy(0.1, _Symbol, Ask, Ask-50*_Point, Ask+150*_Point);
      trade_ticket = trade.ResultOrder();
      
   // SELL CONDITION
   } else if (condicion_venta() && nueva_vela() && operacion_cerrada()) {
      // WE OBTAIN THE BID MARKET VALUE
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   
      // WE OPEN THE SELL ORDER AND SAVE THE POSITION TICKET INFO
      trade.Sell(0.1, _Symbol, Bid, Bid+50*_Point, Bid+150*_Point);
      trade_ticket = trade.ResultOrder();
   }
}