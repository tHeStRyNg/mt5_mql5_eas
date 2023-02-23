//+------------------------------------------------------------------+
//|                                                    Algo_RSI_X.mq5 |
//|                                Copyright 2023, Algorithmic, GMBH |
//|                                      https://www.algorithmic.one |
//+------------------------------------------------------------------+

/* Important - https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes */

#property copyright "Copyright 2023, Algorithmic, GMBH"
#property link      "https://www.algorithmic.one"
#property version   "1.00"
#property description "Algo_RSI_X"

#property indicator_separate_window
#property indicator_buffers 9
#property indicator_plots   1
//--- plot RSIZL
#property indicator_label1  "Algo_RSI_X"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrGreen,clrMediumAquamarine,clrRed,clrLightSalmon,clrDarkGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- input parameters
input uint                 InpSmoothing1     =  15;            // First smoothing period
input uint                 InpSmoothing2     =  7;             // Second smoothing period
input double               InpFactor1        =  0.05;          // First RSI factor
input uint                 InpPeriodRSI1     =  8;             // First RSI period
input double               InpFactor2        =  0.1;           // Second RSI factor
input uint                 InpPeriodRSI2     =  21;            // Second RSI period
input double               InpFactor3        =  0.16;          // Third RSI factor
input uint                 InpPeriodRSI3     =  34;            // Third RSI period
input double               InpFactor4        =  0.26;          // Fourth RSI factor
input uint                 InpPeriodRSI4     =  55;            // Fourth RSI period
input double               InpFactor5        =  0.43;          // Fifth RSI factor
input uint                 InpPeriodRSI5     =  89;            // Fifth RSI period
input ENUM_APPLIED_PRICE   InpAppliedPrice   =  PRICE_CLOSE;   // Applied price
//--- indicator buffers
double         BufferRSIZL[];
double         BufferColors[];
double         BufferFastTrend[];
double         BufferSlowTrend[];
double         BufferRSI1[];
double         BufferRSI2[];
double         BufferRSI3[];
double         BufferRSI4[];
double         BufferRSI5[];
//--- global variables
double         smoothing1;
double         smoothing2;
double         sm_const1;
double         sm_const2;
double         factor1;
double         factor2;
double         factor3;
double         factor4;
double         factor5;
int            period1;
int            period2;
int            period3;
int            period4;
int            period5;
int            period_max;
int            handle_rsi1;
int            handle_rsi2;
int            handle_rsi3;
int            handle_rsi4;
int            handle_rsi5;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set global variables
   period1=int(InpPeriodRSI1<1 ? 1 : InpPeriodRSI1);
   period2=int(InpPeriodRSI2<1 ? 1 : InpPeriodRSI2);
   period3=int(InpPeriodRSI3<1 ? 1 : InpPeriodRSI3);
   period4=int(InpPeriodRSI4<1 ? 1 : InpPeriodRSI4);
   period5=int(InpPeriodRSI5<1 ? 1 : InpPeriodRSI5);
   period_max=fmax(period1,fmax(period2,fmax(period3,fmax(period4,period5))));
   smoothing1=(InpSmoothing1<2 ? 2.0 : InpSmoothing1);
   smoothing2=(InpSmoothing2<2 ? 2.0 : InpSmoothing2);
   sm_const1=(smoothing1-1.0)/smoothing1;
   sm_const2=(smoothing2-1.0)/smoothing2;
   factor1=InpFactor1;
   factor2=InpFactor2;
   factor3=InpFactor3;
   factor4=InpFactor4;
   factor5=InpFactor5;
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferRSIZL,INDICATOR_DATA);
   SetIndexBuffer(1,BufferColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,BufferFastTrend,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,BufferSlowTrend,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,BufferRSI1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,BufferRSI2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,BufferRSI3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,BufferRSI4,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,BufferRSI5,INDICATOR_CALCULATIONS);
//--- setting indicator parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"Algo_RSI_X");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   IndicatorSetInteger(INDICATOR_LEVELS,2);
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferRSIZL,true);
   ArraySetAsSeries(BufferColors,true);
   ArraySetAsSeries(BufferFastTrend,true);
   ArraySetAsSeries(BufferSlowTrend,true);
   ArraySetAsSeries(BufferRSI1,true);
   ArraySetAsSeries(BufferRSI2,true);
   ArraySetAsSeries(BufferRSI3,true);
   ArraySetAsSeries(BufferRSI4,true);
   ArraySetAsSeries(BufferRSI5,true);
//--- create RSI's handles
   ResetLastError();
   handle_rsi1=iRSI(NULL,PERIOD_CURRENT,period1,InpAppliedPrice);
   if(handle_rsi1==INVALID_HANDLE)
     {
      Print("The iRSI(",(string)period1,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
   handle_rsi2=iRSI(NULL,PERIOD_CURRENT,period2,InpAppliedPrice);
   if(handle_rsi2==INVALID_HANDLE)
     {
      Print("The iRSI(",(string)period2,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
   handle_rsi3=iRSI(NULL,PERIOD_CURRENT,period3,InpAppliedPrice);
   if(handle_rsi3==INVALID_HANDLE)
     {
      Print("The iRSI(",(string)period3,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
   handle_rsi4=iRSI(NULL,PERIOD_CURRENT,period4,InpAppliedPrice);
   if(handle_rsi4==INVALID_HANDLE)
     {
      Print("The iRSI(",(string)period4,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
   handle_rsi5=iRSI(NULL,PERIOD_CURRENT,period5,InpAppliedPrice);
   if(handle_rsi5==INVALID_HANDLE)
     {
      Print("The iRSI(",(string)period5,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- Установка массивов буферов как таймсерий
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
//--- Проверка и расчёт количества просчитываемых баров
   if(rates_total<fmax(period_max,4)) return 0;
//--- Проверка и расчёт количества просчитываемых баров
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-period_max-2;
      ArrayInitialize(BufferRSIZL,0);
      ArrayInitialize(BufferColors,4);
      ArrayInitialize(BufferFastTrend,0);
      ArrayInitialize(BufferSlowTrend,0);
      ArrayInitialize(BufferRSI1,0);
      ArrayInitialize(BufferRSI2,0);
      ArrayInitialize(BufferRSI3,0);
      ArrayInitialize(BufferRSI4,0);
      ArrayInitialize(BufferRSI5,0);
     }
//--- Подготовка данных
   int count=(limit>1 ? rates_total : 1),copied=0;
   copied=CopyBuffer(handle_rsi1,0,0,count,BufferRSI1);
   if(copied!=count) return 0;
   copied=CopyBuffer(handle_rsi2,0,0,count,BufferRSI2);
   if(copied!=count) return 0;
   copied=CopyBuffer(handle_rsi3,0,0,count,BufferRSI3);
   if(copied!=count) return 0;
   copied=CopyBuffer(handle_rsi4,0,0,count,BufferRSI4);
   if(copied!=count) return 0;
   copied=CopyBuffer(handle_rsi5,0,0,count,BufferRSI5);
   if(copied!=count) return 0;

//--- Расчёт индикатора
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      double RSI1=BufferRSI1[i];
      double RSI2=BufferRSI2[i];
      double RSI3=BufferRSI3[i];
      double RSI4=BufferRSI4[i];
      double RSI5=BufferRSI5[i];

      double Osc1=factor1*RSI1;
      double Osc2=factor2*RSI2;
      double Osc3=factor3*RSI3;
      double Osc4=factor4*RSI4;
      double Osc5=factor5*RSI5;

      BufferFastTrend[i]=Osc1+Osc2+Osc3+Osc4+Osc5;
      BufferSlowTrend[i]=BufferFastTrend[i]/smoothing1+BufferSlowTrend[i+1]*sm_const1;
      BufferRSIZL[i]=(BufferFastTrend[i]-BufferSlowTrend[i])/(smoothing2*Point())+BufferRSIZL[i+1]*sm_const2;
      
      if(BufferRSIZL[i]>0)
         BufferColors[i]=(BufferRSIZL[i]>BufferRSIZL[i+1] ? 0 : BufferRSIZL[i]<BufferRSIZL[i+1] ? 1 : 4);
      else
         BufferColors[i]=(BufferRSIZL[i]<BufferRSIZL[i+1] ? 2 : BufferRSIZL[i]>BufferRSIZL[i+1] ? 3 : 4);
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
