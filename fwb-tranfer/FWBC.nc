/*
Topologia fixa. Pai salvo.

			        0
				  /   \
				 1     2
				/ \   / 
			   3   4  5  
				



root = 0 parent(0) = -1
parent(1) = 0    
parent(2) = 0
parent(3) = 1
parent(4) = 1
parent(5) = 2

TS
1->0 : #1,4
2->0 : #2,3
3->1 : #2
4->1 : #3
5->2 : #1

#Tempo de um quadro
timeFrame

#TODO
Considerando cada slot de tempo como 1 segundo -> Diminuir
*/


#include <Timer.h>
#include "FWB.h"
#include "AM.h"
#include "Serial.h"
//#include "printf.h"


#define RETRY_TIME 2
#define TAM_BUF 20

module FWBC {

    provides interface Init;

    uses{
        interface Boot;
        interface Leds;

		interface AMPacket;
		interface AMSend as SendData;
		interface Receive as ReceiveData;
		interface SplitControl as RadioControl;

		//serial
		// interface SplitControl as SerialControl;
		// interface AMSend as UartSend[am_id_t id];
	 	// interface Receive as UartReceive[am_id_t id];
	 	// interface Packet as UartPacket;
	 	// interface AMPacket as UartAMPacket;

        interface Timer<TMilli> as RetryTimer;
        interface Timer<TMilli> as TimerPeriodic;
        interface Timer<TMilli> as TimerPeriodic2;
        interface Timer<TMilli> as TimerPeriodic3;

        interface Random;

        //CC2420
        interface CC2420Config;
    }
}

implementation {


	/*keeps track of whether the radio is on.*/
	int16_t parent; //Node keep only one parent in requisition mode


	/*keeps track of whether the radio is on.*/
	bool radioOn = FALSE;

	bool running = FALSE;
	
	bool sending = FALSE;

	uint16_t seqnoReqTopo = 0;
	uint16_t seqnoAux = 0;
	uint16_t seqnoReplyTopo = 0;
	uint8_t hops = 255;

	uint8_t count = 1;
	uint8_t seqno = 1;


	uint16_t seqnoOrigTopo = 1;
	uint16_t seqnoOrigData = 1;

	message_t dataMsgBuffer;
	message_t topoMsgBuffer;

	bool retransmitting = FALSE;
	bool retransmittingRequest = FALSE;
	bool retransmittingRequestData = FALSE;
	bool bTxRequest = FALSE;
	bool createPkt = FALSE;

	uint16_t window = 500;

	uint16_t bufferTopo_ids[TAM_BUF];
	uint16_t bufferData_ids[TAM_BUF];
	uint8_t pos_bufferTopo = 0;
	uint8_t pos_bufferData = 0;

	uint16_t counter[TOTAL_NODES];
	uint16_t descendants = 0;
	uint16_t time = 30;
	uint16_t maxTime = 30000; // 30 s
	uint16_t timeFrame = 700;
	bool stopBeacons = FALSE;

	uint8_t channel;


	void initTransmission() {
		
		call Leds.led0Toggle();
		call Leds.led1Toggle();


		//########Inicializa parents of nodes and frequencies ######//
		if (TOS_NODE_ID == 0) {
			parent = -1; // root node
			//call CC2420Config.setChannel(18);
			channel = call CC2420Config.getChannel();
			dbg("Channel", "Get channel %d \n",channel);
		} else if ( (TOS_NODE_ID == 1) ) {
			parent = 0;
			//call CC2420Config.setChannel(18);
			call TimerPeriodic.startOneShot(200);
			call TimerPeriodic2.startOneShot(600);
			call TimerPeriodic3.startOneShot(700);
		} else if ( (TOS_NODE_ID == 2) ) {
			parent = 0;
			//call CC2420Config.setChannel(18);
			call TimerPeriodic.startOneShot(400);
			call TimerPeriodic2.startOneShot(500);
		} else if ((TOS_NODE_ID == 3) ) {
			parent = 1;
			call TimerPeriodic.startOneShot(400);
		} else if ((TOS_NODE_ID == 4) ) {
			parent = 1;
			call TimerPeriodic.startOneShot(500);
		}  else if ((TOS_NODE_ID == 5) ) {
			parent = 2;
			//call CC2420Config.setChannel(12);
			call TimerPeriodic.startOneShot(200);
		} 
		// else if ((TOS_NODE_ID == 6) ) {
		// 	parent = 9;
		// 	//call CC2420Config.setChannel(11);
		// } else if ( (TOS_NODE_ID == 8) || (TOS_NODE_ID == 9) ) {
		// 	parent = 7;
		// 	//call CC2420Config.setChannel(15);
		// }

		channel = call CC2420Config.getChannel();
		dbg("Channel", "Get channel %d \n",channel);
		// call SerialControl.start();
		dbg("Boot", "Application booted.\n");
	}
	void initData(){
		error_t eval;		
		data_to_topo_t* dataMsg = (data_to_topo_t*) call SendData.getPayload(&dataMsgBuffer, sizeof(data_to_topo_t) );
		dataMsg->seqno = seqno;
		dataMsg->request_id = parent;
		dataMsg->hops = 0;
		dataMsg->count = descendants;
		dataMsg->start = 20;

		if(sending){
			return;
		}

		 eval = call SendData.send(AM_BROADCAST_ADDR, &dataMsgBuffer, sizeof(data_to_topo_t));
		 if (eval == SUCCESS) {
		 	sending = TRUE;
		 	seqno++;
		 	dbg("SendData", ">> Send data to: %d. Time: %s\n", parent, sim_time_string());
			call Leds.led2Toggle();
			//call Leds.led1Toggle();
		 	
		}
	}


	void initStartData() {
		error_t eval;		
		data_to_topo_t* dataMsg = (data_to_topo_t*) call SendData.getPayload(&dataMsgBuffer, sizeof(data_to_topo_t) );
		dataMsg->seqno = seqno;
		dataMsg->request_id = parent;
		dataMsg->hops = 0;
		dataMsg->count = descendants;
		dataMsg->start = 70;
		call Leds.led0Toggle();
		call Leds.led1Toggle();

		if(sending){
			return;
		}

		 eval = call SendData.send(AM_BROADCAST_ADDR, &dataMsgBuffer, sizeof(data_to_topo_t));
		 if (eval == SUCCESS) {
		 	sending = TRUE;
		 	seqno++;
		 	dbg("SendData", ">> Send data to: %d. Time: %s\n", parent, sim_time_string());
		 	call Leds.led0Toggle();
			//call Leds.led0Toggle();
			//call Leds.led1Toggle();
		}
	}

    bool check_node(uint16_t origin, uint16_t buf[TAM_BUF]){
        uint8_t i;
        for(i = 0; i < TAM_BUF; i++){

        	if(buf[i] == origin){
        	    return TRUE;
        	}
        }
        return FALSE;
    }

    void clean_buffer(){
    	uint8_t i;
  	    for(i = 0; i < TAM_BUF; i++){
            bufferTopo_ids[i] = 0;
        	bufferData_ids[i] = 0;
        }
    }

    void clean_counter(){
    	uint8_t i;
  	    for(i = 0; i < TOTAL_NODES; i++) {
            counter[i] = 0;
  	    }
    }

    void count_descendants(){
    	uint8_t i;
    	descendants = 0;
  	    for(i = 0; i < TOTAL_NODES; i++) {
            descendants += counter[i];
  	    }
  	    dbg("Descendants", "descendants %d\n", descendants);
  	    //printf("Descendentes: %u\n", descendants);

    }

    void changed_counter(uint16_t origin, uint16_t count, uint16_t counter[TOTAL_NODES]){
    	dbg("RequestTopo", "[Request topology] Changed counter Check if count change of node %d count: %d %d\n", origin, count, counter[origin]);
    	if (counter[origin] < count) {
    		counter[origin] = count; //Update counter[]
    		dbg("Descendants", "Count changed to %d\n  Reset timer", counter[origin]);
    		time = 30;
    	}
    }

	task void sendDataTask() {
		
		error_t eval;
		
		bTxRequest = TRUE;

		if (sending) {
			return;
		}
		
		dbg("SendData", "Task sendDataTask Retransmit %s\n", sim_time_string());
		
		eval = call SendData.send(AM_BROADCAST_ADDR,
					    &dataMsgBuffer,
					    sizeof(data_to_topo_t));		

		if (eval == SUCCESS) {
			sending = TRUE;
		}

	}

	command error_t Init.init() {
		radioOn = FALSE;
		running = FALSE;
		return SUCCESS;
	}

	event void Boot.booted() { 
		call RadioControl.start();
		clean_buffer();
		clean_counter();

	}

	event void RadioControl.startDone(error_t error) {
		if (error != SUCCESS) {
			call RadioControl.start();
		} else {
			radioOn = TRUE;
			//###########START NODE########//
			if (TOS_NODE_ID != 70) {
				//call CC2420Config.setChannel(18);
				channel = call CC2420Config.getChannel();
				dbg("START", "Start node Get channel %d \n",channel);
				initStartData();
				initTransmission(); //#TODO Toggle
			}
		}
	}

	event void RadioControl.stopDone(error_t error) {
		radioOn = FALSE;
	}


	event void SendData.sendDone(message_t* msg, error_t error) {
		bool dropped = FALSE;
		if ((msg != &dataMsgBuffer)) {
			return;
		}
		sending = FALSE;
			if(TOS_NODE_ID == 0)
				return;

	    if (error == EBUSY) {
	      retransmittingRequest = TRUE;
	      call RetryTimer.startOneShot(RETRY_TIME);
	      dbg("Boot", "Retransmite SendData BUSY.\n");
	      return;
	    }

	    retransmittingRequest = FALSE;
	 

	}


	event void RetryTimer.fired() {
	    if (retransmittingRequest && bTxRequest) {
  			post sendDataTask();

    	}
	}

	event void TimerPeriodic.fired() {
		//time = time*2;
		dbg("Time", "TimerPeriodic Send data: \n");
		call TimerPeriodic.startPeriodic(timeFrame);
		initData();
		// if (time > maxTime) {
		// 	dbg("Time", "Stop time: %d %d\n", time, maxTime);
		// 	call TimerPeriodic.stop();
		// }
	}

	event void TimerPeriodic2.fired() {
		dbg("Time", "TimerPeriodic2 Send data: \n");
		call TimerPeriodic2.startPeriodic(timeFrame);
		initData();
	}

	event void TimerPeriodic3.fired() {
		dbg("Time", "TimerPeriodic3 Send data: \n");
		call TimerPeriodic3.startPeriodic(timeFrame);
		initData();
	}

	event message_t* ReceiveData.receive(message_t* msg, void* payload, uint8_t len) {
	
		uint8_t type = call AMPacket.type(msg);
		am_addr_t from;
		am_addr_t request_id;
		data_to_topo_t* rcvData;
		uint8_t hops_rcv;
		uint8_t start;
		uint16_t counterDescendants;


		from = call AMPacket.source(msg);
		rcvData = (data_to_topo_t*)payload;
		seqnoAux = rcvData->seqno;
		request_id = rcvData->request_id;
		hops_rcv = rcvData->hops;
		counterDescendants = rcvData->count + 1;
		start = rcvData->start;
		//printf("Origin: %u Packet: %u\n", from, seqnoAux);

		//if(start == 70) {
		//	initTransmission();
		//}

		// if this select source is for me
		if (request_id == TOS_NODE_ID){
			dbg("ReceivedData", "Mensagem de %d eh p mim seqno %hhu: %s\n", from, seqnoAux, sim_time_string());
			//printf("Origin: %u Packet: %u\n", from, seqnoAux);
			dbg("Channel", "Get channel %d \n",channel);

			if(TOS_NODE_ID == 0){
				dbg("ROOT", "ROOT Mensagem de %d eh p mim seqno %hhu: %s\n", from, seqnoAux, sim_time_string());
				return msg;
			}
		}

	return msg;

	}

	event void CC2420Config.syncDone(error_t err) {}
}
