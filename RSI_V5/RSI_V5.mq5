//+------------------------------------------------------------------+
//|                                                       RSI_V5.mq5 |
//|                                Copyright 2023, Algorithmic, GMBH |
//|                                      https://www.algorithmic.one |
//+------------------------------------------------------------------+
/* Important - https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes */

#property copyright "Copyright 2023, Algorithmic, GMBH"
#property link      "https://www.algorithmic.one"
#property version   "1.00"

#property description "RSI_V5 BOT, TRIGGERS A BUY WHEN RSI <= 30 AND TRIGGERS A SELL WHEN RSI>=70 "
//---

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Expert\Money\MoneyFixedMargin.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CTrade         m_trade_BuyLimit     ;         // trade buy limit
CTrade         m_trade_BuyStopLimit  ;  
CTrade         trade;      // trade buy stop limit
CSymbolInfo    m_symbol;                     // symbol info object
//CAccountInfo   m_account;                    // account info wrapper
CMoneyFixedMargin  m_money;
CDealInfo      m_deal;
//--- input parameters
input group             "General Setting"
input double               InpVolumeLotOrRisk      = 0.01;        // The value for "Money management"
input uint                 InpStopLoss             = 200;         // Stop Loss (SL)
input uint                 InpTakeProfit           = 200;         // Take Profit (TP)
input uchar                InpMaxPositions         = 10;          // Maximum number of positions ('0' -> OFF)
input uchar                InpShift                = 2;           // Shift in bars (from 1 to 255)
input ulong                InpMagic                = 270656969;   // magic number
//---
input group             "RSI Setting"
input int                  Inp_RSI_ma_period       = 30;             // RSI: averaging period 
input ENUM_APPLIED_PRICE   Inp_RSI_applied_price= PRICE_WEIGHTED; // RSI: type of price 
input double               Inp_RSI_LevelUP         = 80;          // RSI Fast and Slow: Level UP
input double               Inp_RSI_LevelDOWN       = 20;          // RSI Fast and Slow: Level DOWN
input string               Inp_RSI_stringUP        ="Signal Sell";// RSI Fast and Slow: Level UP label
input string               Inp_RSI_stringDOWN      ="Signal Buy"; // RSI Fast and Slow: Level DOWN label
//---
ulong                      m_slippage=30;                         // slippage
double                     ExtDistance=0.0;
double                     m_lots_min=0.0;
double                     m_adjusted_point;   
bool     m_init_error               = false;                      // error on Init // point value adjusted for 3 or 5 points
int handle_MACD;
double MACD;
int    handle_iRSI;                                                // variable for storing the handle of the iRSI indicator
int count=0;
double ExtStopLoss      = 0.0;
double ExtTakeProfit    = 0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   handle_MACD=iMA(_Symbol,PERIOD_CURRENT,20,0,MODE_SMA,PRICE_CLOSE);
   if(InpShift<1)
     {
      Print("The parameter \"Shift\" can not be less than \"1\"");
      return(INIT_PARAMETERS_INCORRECT);
     }
    //--- create handle of the indicator iRSI
   handle_iRSI=iRSI(_Symbol,PERIOD_CURRENT,Inp_RSI_ma_period,Inp_RSI_applied_price);
//--- if the handle is not created 
   if(handle_iRSI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     } 
//---
   m_symbol.Name(Symbol());                                          // sets symbol name
   RefreshRates();
   m_symbol.Refresh();

   m_lots_min=m_symbol.LotsMin();

//string err_text="";
//if(!CheckVolumeValue(m_lots,err_text))
//  {
//   Print(err_text);
//   return(INIT_PARAMETERS_INCORRECT);
//  }
//---
   m_trade.SetExpertMagicNumber(InpMagic);
//---
   string err_text="";
   if(!CheckVolumeValue(InpVolumeLotOrRisk,err_text))
        {
         if(MQLInfoInteger(MQL_TESTER)) // when testing, we will only output to the log about incorrect input parameters
            Print(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
         else // if the Expert Advisor is run on the chart, tell the user about the error
            Alert(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
         //---
         m_init_error=true;
         return(INIT_SUCCEEDED);
        }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
 
void OnTick()
  {
//--- we work only at the time of the birth of new bar
   //CheckPositionProfit();
   static datetime PrevBars=0;
   datetime time_0=iTime(_Symbol,Period(),0);            
   if(m_init_error)
      return;
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   double volume=InpVolumeLotOrRisk;
   volume= NormalizeDouble (volume,DigitsLots());
   volume=CheckVolumeValue(volume);
    if (!CheckMoneyForTrade( _Symbol ,volume, ORDER_TYPE_BUY ) || !CheckMoneyForTrade( _Symbol ,volume, ORDER_TYPE_SELL ) )
   {
      
      return ;
   }
     
         RSI_Alert();
   
        
   return;
  }
 //+----------------------------------------------- -------------------+   
int DigitsLots( void )
{
   return ( int )( MathLog ( 1.0 / SymbolInfoDouble ( _Symbol , SYMBOL_VOLUME_STEP ))/ MathLog ( 10.0 ));
}
//+----------------------------------------------- -------------------+ 
double CheckVolumeValue( double volume)
  {
//--- minimum allowable volume for trading operations 
   double min_volume= SymbolInfoDouble ( Symbol (), SYMBOL_VOLUME_MIN );
   if (volume<min_volume)
     {
      PrintFormat ( "SYMBOL_VOLUME_MIN=%.2f" ,min_volume);
      volume=min_volume;
     }

//--- maximum allowable volume for trading operations 
   double max_volume= SymbolInfoDouble ( Symbol (), SYMBOL_VOLUME_MAX );
   if (volume>max_volume)
     {
      PrintFormat ( "SYMBOL_VOLUME_MAX=%.2f" ,max_volume);
      volume=max_volume;
     }

//--- get the minimum volume gradation 
   double volume_step= SymbolInfoDouble ( Symbol (), SYMBOL_VOLUME_STEP );

   int ratio=( int ) MathRound (volume/volume_step);
   if ( MathAbs (ratio*volume_step-volume)> 0.0000001 )
     {
      PrintFormat ( "SYMBOL_VOLUME_STEP=%.2f, %.2f" ,
                               volume_step,ratio*volume_step);
                               volume=ratio*volume_step;
     }
   return volume;
  }
 //+----------------------------------------------- -------------------+ 
bool CheckMoneyForTrade( string symb, double lots, ENUM_ORDER_TYPE type)
  {
//--- get the opening price 
   MqlTick mqltick;
   SymbolInfoTick (symb,mqltick);
   double price=mqltick.ask;
   if (type== ORDER_TYPE_SELL )
      price=mqltick.bid;
//--- values ​​of required and free margin 
   double margin,free_margin= AccountInfoDouble ( ACCOUNT_MARGIN_FREE );
   //--- call the check function 
   if (! OrderCalcMargin (type,symb,lots,price,margin))
     {
      //--- something went wrong, report and return false 
      Print ( "Error in " , __FUNCTION__ , " code=" , GetLastError ());
      return ( false );
     }
   //--- if there are not enough funds to carry out the operation 
   if (margin>free_margin)
     {
      //--- report an error and return false 
      Print ( "Not enough money for " , EnumToString (type), " " ,lots, " " ,symb, " Error code=" , GetLastError ());
      return ( false );
     }
//--- check was successful 
   return ( true );
  }
 void RSI_Alert()
 {
   double rsi[];
   static datetime PrevBars=0;
   ArraySetAsSeries(rsi,true);
   int buffer=0,start_pos=0,count=3;
   bool res=true;
   if(!iGetArray(handle_iRSI,0,start_pos,count,rsi))
     {
      PrevBars=0; return;
     }
  bool Buy_Condition =(rsi[0]<=Inp_RSI_LevelDOWN);
  bool Sell_Condition =(rsi[0]>=Inp_RSI_LevelUP);     
      if(Buy_Condition)
        {         
            //count++;
            res=SendNotification(Inp_RSI_stringDOWN);
            OpenPosition(POSITION_TYPE_BUY);                      
            //OpenBuy(InpMagic,NormalizeDouble(InpVolumeLotOrRisk,2),InpStopLoss,InpTakeProfit,"RSI_V5");
            
            
        }
     if(Sell_Condition)
     {                  
         //count++;
         res=SendNotification(Inp_RSI_stringUP);
         OpenPosition(POSITION_TYPE_SELL);
     }
     
      if(!res)
     {
      Print("Message sending failed");
     }
   else
     {
      Print("Message sent");
     }
 }
 //+------------------------------------------------------------------+
//| Open positions                                                   |
//+------------------------------------------------------------------+
void OpenPosition(const ENUM_POSITION_TYPE pos_type)
  {
//--- check Freeze and Stops levels
/*
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask	            |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid	            |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order	       |  Bid	            |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy position            |  Bid	            |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL 
                           |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell position           |  Ask	            |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
                           
   Buying is done at the Ask price                 |  Selling is done at the Bid price
   ------------------------------------------------|----------------------------------
   TakeProfit        >= Bid                        |  TakeProfit        <= Ask
   StopLoss          <= Bid	                       |  StopLoss          >= Ask
   TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
   Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
*/
   if(!RefreshRates() || !m_symbol.Refresh())
      return;
//--- FreezeLevel -> for pending order and modification
   double freeze_level=m_symbol.FreezeLevel()*m_symbol.Point();
   if(freeze_level==0.0)
      freeze_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
   freeze_level*=1.1;
//--- StopsLevel -> for TakeProfit and StopLoss
   double stop_level=m_symbol.StopsLevel()*m_symbol.Point();
   if(stop_level==0.0)
      stop_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
   stop_level*=1.1;

   if(freeze_level<=0.0 || stop_level<=0.0)
      return;
//---
   if(pos_type==POSITION_TYPE_BUY)
     {
      double price=m_symbol.Ask();
      double sl=(InpStopLoss==0)?0.0:price-ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:price+ExtTakeProfit;
      //if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
        {
         OpenBuy(InpMagic,NormalizeDouble(InpVolumeLotOrRisk,2),InpStopLoss,InpTakeProfit,"RSI_V5");
         return;
        }
     }
   if(pos_type==POSITION_TYPE_SELL)
     {
      double price=m_symbol.Bid();
      double sl=(InpStopLoss==0)?0.0:price+ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:price-ExtTakeProfit;
      //if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
        {
         OpenSell(InpMagic,NormalizeDouble(InpVolumeLotOrRisk,2),InpStopLoss,InpTakeProfit,"RSI_V5");
         return;
        }
     }
  }
 //+------------------------------------------------------------------+
//| Get value of buffers                                             |
//+------------------------------------------------------------------+
double iGetArray(const int handle,const int buffer,const int start_pos,const int count,double &arr_buffer[])
  {
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
//--- reset error code 
   ResetLastError();
//--- fill a part of the iBands array with values from the indicator buffer
   int copied=CopyBuffer(handle,buffer,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
   return(result);
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }

//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
uint OpenSell(int magic,double lot,double StopLoss,double TakeProfit, string comment)
  {
//--- PREPARE THE SELL ORDER
   
   MqlTradeRequest req= {};
   req.action =TRADE_ACTION_DEAL;
   req.symbol =_Symbol;
   req.magic  = magic;
   req.volume = lot;
   req.type   = ORDER_TYPE_SELL;
   req.price  = SymbolInfoDouble(req.symbol,SYMBOL_BID);
   if(TakeProfit==0)
      req.tp = 0.0;
   if(TakeProfit!=0)
      req.tp = SymbolInfoDouble(req.symbol,SYMBOL_BID)-TakeProfit*SymbolInfoDouble(NULL,SYMBOL_POINT);
      //req.tp =SymbolInfoDouble(req.symbol,SYMBOL_BID)*(1-TakeProfit);
   if(StopLoss==0)
      req.sl     = 0.0;
   if(StopLoss!=0)
      req.sl     = SymbolInfoDouble(req.symbol,SYMBOL_ASK)+StopLoss*SymbolInfoDouble(NULL,SYMBOL_POINT);
   req.comment =comment;
   MqlTradeResult result= {0};
   if(IsFillingTypeAllowed(req.symbol,SYMBOL_FILLING_FOK))
      req.type_filling = ORDER_FILLING_FOK;
   else
      if(IsFillingTypeAllowed(req.symbol,SYMBOL_FILLING_IOC))
         req.type_filling = ORDER_FILLING_IOC;
   OrderSend(req,result);
//--- write the server reply to log
   Print(__FUNCTION__,":",result.comment);
   if(result.retcode==10016)
      Print(result.bid,result.ask,result.price);
//--- return code of the trade server reply
   return result.retcode;
  }
  uint OpenBuy(int magic,double lot,double StopLoss,double TakeProfit, string comment)
  {
//--- PREPARE THE BUY ORDER
   MqlTradeRequest req= {};
   req.action =TRADE_ACTION_DEAL;
   req.symbol =_Symbol;
   req.magic  = magic;
   req.volume = lot;
   req.type   = ORDER_TYPE_BUY;
   req.price  = SymbolInfoDouble(req.symbol,SYMBOL_ASK);
   if(TakeProfit==0)
      req.tp = 0.0;
   if(TakeProfit!=0)
      req.tp = SymbolInfoDouble(req.symbol,SYMBOL_ASK)+TakeProfit*SymbolInfoDouble(NULL,SYMBOL_POINT);
      //req.tp = SymbolInfoDouble(req.symbol,SYMBOL_ASK)*(1+TakeProfit);
   if(StopLoss==0)
      req.sl     = 0.0;
   if(StopLoss!=0)
      req.sl     = SymbolInfoDouble(req.symbol,SYMBOL_BID)-StopLoss*SymbolInfoDouble(NULL,SYMBOL_POINT);
   req.comment =comment;
   MqlTradeResult result= {0};
   if(IsFillingTypeAllowed(req.symbol,SYMBOL_FILLING_FOK))
      req.type_filling = ORDER_FILLING_FOK;
   else
      if(IsFillingTypeAllowed(req.symbol,SYMBOL_FILLING_IOC))
         req.type_filling = ORDER_FILLING_IOC;
   OrderSend(req,result);
//--- write the server reply to log
   Print(__FUNCTION__,":",result.comment);
   if(result.retcode==10016)
      Print(result.bid,result.ask,result.price);
//--- return code of the trade server reply
   return result.retcode;
  }
//+------------------------------------------------------------------+ 
//| Checks if the specified filling mode is allowed                  | 
//+------------------------------------------------------------------+ 
bool IsFillingTypeAllowed(string symbol,int fill_type)
  {
//--- Obtain the value of the property that describes allowed filling modes 
   int filling=(int)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
//--- Return true, if mode fill_type is allowed 
   return((filling & fill_type)==fill_type);
  }
  //+------------------------------------------------------------------+
//| Get value of buffers for the iStochastic                         |
//|  the buffer numbers are the following:                           |
//|   0 - MAIN_LINE, 1 - SIGNAL_LINE                                 |
//+------------------------------------------------------------------+
double get_Stochastic(const int buffer,const int index,const int handle_Stochastic)
  {
   double Stochastic[1];
//--- reset error code
   ResetLastError();
//--- fill a part of the iStochasticBuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_Stochastic,buffer,index,1,Stochastic)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iStochastic indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(Stochastic[0]);
  }

//+------------------------------------------------------------------+ 
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Stochastic Oscillator                                            |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Is position exists                                               |
//+------------------------------------------------------------------+
bool IsPositionExists(void)
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Check the correctness of the position volume                     |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=m_symbol.LotsMin();
   if(volume<min_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="English")
         error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      else
         error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol.LotsMax();
   if(volume>max_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="English")
         error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      else
         error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }
//--- get minimal step of volume changing
   double volume_step=m_symbol.LotsStep();
   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="English")
         error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                        volume_step,ratio*volume_step);
      else
         error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                        volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Lot Check                                                        |
//+------------------------------------------------------------------+
double LotCheck(double lots,CSymbolInfo &symbol)
  {
//--- calculate maximum volume
   double volume=NormalizeDouble(lots,2);
   double stepvol=symbol.LotsStep();
   if(stepvol>0.0)
      volume=stepvol*MathFloor(volume/stepvol);
//---
   double minvol=symbol.LotsMin();
   if(volume<minvol)
      volume=0.0;
//---
   double maxvol=symbol.LotsMax();
   if(volume>maxvol)
      volume=maxvol;
//---
   return(volume);
  }
  //+------------------------------------------------------------------+
//| Calculate all positions                                          |
//+------------------------------------------------------------------+
int CalculateAllPositions(void)
  {
   int total=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==_Symbol && m_position.Magic()==InpMagic)
            total++;
//---
   return(total);
  }