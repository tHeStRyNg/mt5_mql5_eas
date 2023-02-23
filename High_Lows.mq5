//+------------------------------------------------------------------+
//|                                                    High_Lows.mq5 |
//|                                Copyright 2023, Algorithmic, GMBH |
//|                                      https://www.algorithmic.one |
//+------------------------------------------------------------------+
/* Important - https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes */

#property copyright "Copyright 2023, Algorithmic, GMBH"
#property link      "https://www.algorithmic.one"
#property version   "1.00"

int MAX_CANDLES = 100;

MqlRates candles[];
double closes[];


int OnInit() {

   ArraySetAsSeries(candles, true);
   ArraySetAsSeries(closes, true);
   
   // Loading the candles
   CopyRates(_Symbol, _Period, 0, MAX_CANDLES, candles);
   
   // Setting the lines
   ObjectCreate(0, "CustomHigh", OBJ_HLINE, 0, 0, candles[0].close);
   ObjectCreate(0, "CustomLow", OBJ_HLINE, 0, 0, candles[0].close);
   
   return INIT_SUCCEEDED;
}


void OnTick(void) {

   // Loading the candles
   CopyRates(_Symbol, _Period, 0, MAX_CANDLES, candles);

   // Getting all the closes
   CopyClose(_Symbol, _Period, 0, MAX_CANDLES, closes);
   
   int index_highest = ArrayMaximum(closes, 0, 50);
   int index_lowest = ArrayMinimum(closes, 0, 50);
 
   // Setting the color
   ObjectSetInteger(0, "CustomHigh", OBJPROP_COLOR, C'68,248,248');
   ObjectSetInteger(0, "CustomLow", OBJPROP_COLOR, clrAqua);
   
   // Setting the width
   ObjectSetInteger(0, "CustomHigh", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "CustomLow", OBJPROP_WIDTH, 2);
   
   // Moving the line to the last close
   ObjectMove(0, "CustomHigh", 0, 0, candles[index_highest].close);
   ObjectMove(0, "CustomLow", 0, 0, candles[index_lowest].close);
 }