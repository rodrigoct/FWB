#include "Iot.h"
#define NEW_PRINTF_SEMANTICS
#include "printf.h"


configuration IotAppC { }

implementation {

  components  MainC, LedsC, ActiveMessageC;
  components IotC as App;
  components new AMSenderC(AM_REQ_TOPO) as SenderReq;
  components new AMReceiverC(AM_REQ_TOPO) as ReceiverReq;

  components new AMSenderC(AM_REPLY_TOPO) as SenderReply;
  components new AMReceiverC(AM_REPLY_TOPO) as ReceiverReply;

  components new TimerMilliC() as RetryTimerC;
  components new TimerMilliC() as ReplyTimerC;
  components new TimerMilliC() as PeriodicTimerC;
  components RandomC;


  components PrintfC;
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

  //Request topo
  App.SendRequest -> SenderReq;
  App.ReceiveRequest -> ReceiverReq;

  //Reply topo
  App.SendReply -> SenderReply;
  App.ReceiveReply -> ReceiverReply;

  App.RoutingAck -> ActiveMessageC;
  App.RetryTimer -> RetryTimerC;
  App.ReplyTimer -> ReplyTimerC;
  App.TimerPeriodic -> PeriodicTimerC;
  App.Random -> RandomC;

  // Change frequency
  App.CC2420Config->CC2420ControlC.CC2420Config;

} 
