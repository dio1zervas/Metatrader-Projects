//+------------------------------------------------------------------+
//|                                                       expert.mq5 |
//|                                                   Copyright 2021,|
//|                                       Dionisios Theonas ZERVAS . |
//|                                                                  |
//+------------------------------------------------------------------+

input double   LotSize=0.1;
input int      StopLoss=50;
input int      TakeProfit=50;
input int      MaxTrades=7;   
input int      StartTime=9;
input int      StopTime=13;
input group    "Indicator"
input int      MAPeriod=21;
input ENUM_MA_METHOD MAMethod=MODE_EMA;
input ENUM_APPLIED_PRICE Price=PRICE_CLOSE;
//---
int handleMA=INVALID_HANDLE;
#include <Trade\Trade.mqh>
CTrade trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if((handleMA = iMA(_Symbol,_Period, MAPeriod, 0, MAMethod,Price))==INVALID_HANDLE)
      return(INIT_PARAMETERS_INCORRECT);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   IndicatorRelease(handleMA);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   datetime curDay=iTime(_Symbol,PERIOD_D1,0);
   datetime curTime=iTime(_Symbol,_Period,0);
   static datetime preDay=0,preTime=curTime;
   if(preDay==curDay || preTime==curTime)
      return;
//---
   int losses=HistoryDealGetStreak();
   if(losses==WRONG_VALUE)
     {
      preDay=curDay;
      return;
     }   
//---
   bool tradeTime=IsTradeTime(StartTime,StopTime);
   ulong ticket;
   ENUM_POSITION_TYPE type;
   PositionGetTicketType(ticket,type);
   ENUM_SIGNAL_TYPE signal=Signal();
//---
   if(tradeTime && type==WRONG_VALUE && signal==SIGNAL_BULL && losses<MaxTrades*2)
     {
      //ask is the real time price we are going to have action (buy)
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      //STOP LOSS Variable
      double sl = ask-StopLoss*_Point;
      //TAKE PROFIT Variable
      double tp = ask+TakeProfit*_Point;
   	
   	if(trade.Buy(LotSize*(1<<(losses/2)),_Symbol,ask,sl,tp,NULL))
         preTime=curTime;
     }
//---
   if(tradeTime && type==WRONG_VALUE && signal==SIGNAL_BEAR && losses<MaxTrades*2)
     {
      //bid is the real time price we are going to have action (sell)
      double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      //STOP LOSS Variable
      double sl = bid+StopLoss*_Point;
      //TAKE PROFIT Variable
      double tp = bid-TakeProfit*_Point;
      
      if(trade.Sell(LotSize*(1<<(losses/2)),_Symbol,bid,sl,tp,NULL))
      	preTime=curTime;		
     }
//---
   //if(type==POSITION_TYPE_BUY && signal==SIGNAL_BEAR)
   //   trade.PositionClose(ticket);  
//---
   //if(type==POSITION_TYPE_SELL && signal==SIGNAL_BULL)
   //   trade.PositionClose(ticket);   
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int HistoryDealGetStreak()
  {
//---
   HistorySelect(iTime(_Symbol,PERIOD_D1,0),TimeLocal());
   int total=HistoryDealsTotal();
   ulong ticket;
   int losses=0;
   for(int i=total-1;i>=0;i--)
     {
      if((ticket=HistoryDealGetTicket(i))>0)
        { 
         if(HistoryDealGetDouble(ticket,DEAL_PROFIT)>0)
            return(WRONG_VALUE);
         losses++;
        }
     }  
//---
   return(losses);
  }   
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsTradeTime(int start_time,int stop_time)
  {
   MqlDateTime dt;
   TimeToStruct(TimeLocal(),dt);
//---
   return(dt.hour>=start_time && dt.hour<stop_time);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PositionGetTicketType(ulong& ticket,ENUM_POSITION_TYPE& type)
  {
   int total=PositionsTotal();
   if(total==0)
     {
      ticket=type=WRONG_VALUE; 
      return;
     }
   ticket=PositionGetTicket(0);
   type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE); 
//---
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_TYPE
  {
   SIGNAL_NONE,
   SIGNAL_BULL,
   SIGNAL_BEAR
  };
//---
ENUM_SIGNAL_TYPE Signal()
  {
   double MABuffer[];
   MqlRates Rates[];
   ArraySetAsSeries(MABuffer,true);
   if(CopyBuffer(handleMA,0,1,1,MABuffer)==-1 || CopyRates(_Symbol,_Period,1,1,Rates)==-1)
      return(SIGNAL_NONE);
//---
   return((MABuffer[0]>Rates[0].open && MABuffer[0]<Rates[0].close)?SIGNAL_BULL:(MABuffer[0]<Rates[0].open && MABuffer[0]>Rates[0].close)?SIGNAL_BEAR:SIGNAL_NONE);
  }   
  
//+------------------------------------------------------------------+
