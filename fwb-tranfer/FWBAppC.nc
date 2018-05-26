#include "FWB.h"
#define NEW_PRINTF_SEMANTICS
//#include "printf.h"


configuration FWBAppC { }

implementation {

  components  MainC, LedsC, ActiveMessageC;
  components FWBC as App;
  components new AMSenderC(AM_DATA_TOPO) as SenderReq;
  components new AMReceiverC(AM_DATA_TOPO) as ReceiverReq;

  components new TimerMilliC() as RetryTimerC;
  components new TimerMilliC() as PeriodicTimerC;
  components new TimerMilliC() as PeriodicTimerC2;
  components new TimerMilliC() as PeriodicTimerC3;
  components RandomC;


  //components PrintfC;
  components SerialStartC;


  //CC2420C
  components CC2420ControlC;

  //serial
  // components SerialActiveMessageC as Serial;

  // App.SerialControl -> Serial;
  
  // App.UartSend -> Serial;
  // App.UartReceive -> Serial.Receive;
  // App.UartPacket -> Serial;
  // App.UartAMPacket -> Serial;

  MainC.SoftwareInit -> App;
  App.Boot -> MainC;
  App.RadioControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.AMPacket -> ActiveMessageC;

  //Send data
  App.SendData -> SenderReq;
  App.ReceiveData -> ReceiverReq;

  App.RetryTimer -> RetryTimerC;
  App.TimerPeriodic -> PeriodicTimerC;
  App.TimerPeriodic2 -> PeriodicTimerC2;
  App.TimerPeriodic3 -> PeriodicTimerC3;
  App.Random -> RandomC;

  // Change frequency
  App.CC2420Config->CC2420ControlC.CC2420Config;

} 
