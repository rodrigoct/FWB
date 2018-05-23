/*
Topologia fixa. Pai salvo

			        0
				  /   \
				 1     2
				/ \   / \
			   3   4  5  6
				



root = 0 parent(0) = -1
parent(1) = 0
parent(2) = 0
parent(3) = 1
parent(4) = 1
parent(5) = 2
parent(6) = 2
*/

#include <Timer.h>
#include "Iot.h"
#include "AM.h"
#include "Serial.h"
#include "printf.h"
#define RETRY_TIME 2
#define TAM_BUF 20

module IotC {

    provides interface Init;

    uses{
        interface Boot;
        interface Leds;

		interface AMPacket;
		interface AMSend as SendRequest;
		interface AMSend as SendReply;
		interface Receive as ReceiveRequest;
		interface Receive as ReceiveReply;
		interface SplitControl as RadioControl;
		interface PacketAcknowledgements as RoutingAck;

		//serial
		interface SplitControl as SerialControl;
	    interface AMSend as UartSend[am_id_t id];

    	interface Packet as UartPacket;
    	interface AMPacket as UartAMPacket;
    	interface AMPacket as RadioAMPacket;

	 //    interface AMSend as UartSend[am_id_t id];
	 //    interface Receive as UartReceive[am_id_t id];
	 //    interface Packet as UartPacket;
	 //    interface AMPacket as UartAMPacket;

        interface Timer<TMilli> as RetryTimer;
        interface Timer<TMilli> as ReplyTimer;
        interface Timer<TMilli> as TimerPeriodic;

        interface Random;
    }
}

implementation {


	/*keeps track of whether the radio is on.*/
	int16_t parent; //Node keep only one parent in requisition mode


	/*keeps track of whether the radio is on.*/
	bool radioOn = FALSE;

	bool running = FALSE;
	
	bool sending = FALSE;
	int mensagem_teste = 1;

	uint16_t seqnoReqTopo = 0;
	uint16_t seqnoAux = 0;
	uint16_t seqnoReplyTopo = 0;
	uint8_t hops = 255;


	uint8_t count = 1;


	uint16_t seqnoOrigTopo = 1;
	uint16_t seqnoOrigData = 1;

	message_t beaconMsgBuffer;
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
	bool stopBeacons = FALSE;


	bool   uartBusy, uartFull;
 task void uartSendTask();

task void replyTopoTask();

#if defined(PLATFORM_MICAZ)
	bool bRequestData = TRUE;
#endif



	void initBeacon(){
		error_t eval;		
		request_topo_t* beaconMsg = (request_topo_t*) call SendRequest.getPayload(&beaconMsgBuffer, sizeof(request_topo_t) );
		beaconMsg->seqno = count;
		beaconMsg->request_id = parent;
		beaconMsg->hops = 0;
		beaconMsg->count = descendants;

		if(sending){
			return;
		}
		//post replyTopoTask();
		//post replyDataTask();
		 eval = call SendRequest.send(AM_BROADCAST_ADDR, &beaconMsgBuffer, sizeof(request_topo_t));
		 if (eval == SUCCESS) {
		 	sending = TRUE;
		 	dbg("SendBeacon", ">> Send beacon to: %d. Time: %s\n", parent, sim_time_string());
		 	call Leds.led1Toggle();
		 	call Leds.led2Toggle();
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

    }

    void changed_counter(uint16_t origin, uint16_t count, uint16_t counter[TOTAL_NODES]){
    	dbg("RequestTopo", "[Request topology] Changed counter Check if count change of node %d count: %d %d\n", origin, count, counter[origin]);
    	if (counter[origin] < count) {
    		counter[origin] = count; //Update counter[]
    		dbg("Descendants", "Count changed to %d\n  Reset timer", counter[origin]);
    		time = 30;
    	}
    }

	task void sendBeaconTask() {
		uint16_t maxLength;
		uint16_t r;
		
		error_t eval;
		
		request_topo_t* beaconMsg;
		reply_topo_t* pkt;
		bTxRequest = TRUE;

		if (sending) {
			return;
		}
		
		dbg("RequestTopo", "Task sendBeaconTask\n");
		
		eval = call SendRequest.send(AM_BROADCAST_ADDR,
					    &beaconMsgBuffer,
					    sizeof(request_topo_t));		

		if (eval == SUCCESS) {
			sending = TRUE;
		}

		//Reply topo
		// r = call Random.rand16();
		// r %= window;
		// r += 200;
		// dbg("RequestTopo", "Reply topo after %d ms  Time: %s\n", r, sim_time_string());
		
		// pkt = (reply_topo_t*)call SendReply.getPayload(&topoMsgBuffer, sizeof(reply_topo_t));
		// pkt->origem = TOS_NODE_ID;
		// pkt->seqno = seqnoOrigTopo;
		// pkt->parent = parent;
		// //ownTopo = TRUE;
		// call OrigPktTimer.startOneShot(r);

	}


	task void replyTopoTask() {

		
		error_t eval;
		reply_topo_t* pkt = (reply_topo_t*)call SendReply.getPayload(&topoMsgBuffer, sizeof(reply_topo_t));
		dbg("RequestTopo", "ReplyTopoTask Time: %s\n", sim_time_string());


		if (sending) {
			dbg("RequestTopo", "Error in reply  Time: %s\n", sim_time_string());
			return;
		}

		if(createPkt) {
			dbg("RequestTopo", "replyTopoTask Create packet Time: %s\n", sim_time_string());
			pkt->seqno = seqnoOrigTopo;
			pkt->parent = parent;
		    //pkt->origem = TOS_NODE_ID;
			seqnoOrigTopo++;
			createPkt = FALSE;
		}

				
		dbg("RequestTopo", "Task ReplyTopo from node %hhu to node %hhu seqno %hhu Time: %s\n", pkt->parent , parent, pkt->seqno, sim_time_string());
		
		eval = call SendReply.send(parent, &topoMsgBuffer, sizeof(reply_topo_t));		

		if (eval == SUCCESS) {
			sending = TRUE;
			call Leds.led0Toggle();
			call Leds.led1Toggle();
		} 



	}


	command error_t Init.init() {
		radioOn = FALSE;
		running = FALSE;
		return SUCCESS;
	}

	event void Boot.booted() {
		printf("Hi I am writing to you from my TinyOS application!!\n");
		call RadioControl.start();
		call SerialControl.start();
		clean_buffer();
		clean_counter();


		//########Inicializa parents of nodes ######//
		if (TOS_NODE_ID == 0) {
			parent = -1; // root node
		} else if ( (TOS_NODE_ID == 1) || (TOS_NODE_ID == 2) ) {
			parent = 0;
		} else if ((TOS_NODE_ID == 3) || (TOS_NODE_ID == 4) ) {
			parent = 1;
		} else if ((TOS_NODE_ID == 5) || (TOS_NODE_ID == 6) ) {
			parent = 2;
		}
		

		
		call TimerPeriodic.startPeriodic(1000);
		dbg("Boot", "Application booted.\n");
	}

  	event void SerialControl.startDone(error_t error) {
    	if (error == SUCCESS) {

     	 uartFull = FALSE;
    	} else {
    		call SerialControl.start();
    	}
 	 }


	event void RadioControl.startDone(error_t error) {
		if (error != SUCCESS) {
			call RadioControl.start();
		} else {
			radioOn = TRUE;
			#if defined(PLATFORM_MICAZ)
				initBeacon();
				// if (TOS_NODE_ID == 0) {
				// 	//Request topo
				// 	initBeacon();
				// }
			#endif
		}
	}

	event void RadioControl.stopDone(error_t error) {
		radioOn = FALSE;
	}

	
  event void SerialControl.stopDone(error_t error) {}
	event void SendRequest.sendDone(message_t* msg, error_t error) {
		bool dropped = FALSE;
		if ((msg != &beaconMsgBuffer)) {
			return;
		}
		sending = FALSE;
		#if defined(PLATFORM_MICAZ)
			if(TOS_NODE_ID == 0)
				return;
		#endif

	    if (error == EBUSY) {
	      retransmittingRequest = TRUE;
	      call RetryTimer.startOneShot(RETRY_TIME);
	      dbg("Boot", "Retransmite SendRequest BUSY.\n");
	      return;
	    }

	    retransmittingRequest = FALSE;
	 

	}

	event void SendReply.sendDone(message_t* msg, error_t error) {
		bool dropped = FALSE;
		if ((msg != &topoMsgBuffer)) {
			return;
		}
		sending = FALSE;

	    if (error == EBUSY) {
	      retransmitting = TRUE;
	      call ReplyTimer.startOneShot(RETRY_TIME);
	      return;
	    }

	    retransmitting = FALSE;
	 

	}

	event void RetryTimer.fired() {
	    if (retransmittingRequest && bTxRequest) {
  			post sendBeaconTask();

    	}
	}

	event void ReplyTimer.fired() {
		dbg("RequestTopo", "Post ReplyTopoTask Time: %s\n", sim_time_string());
		post replyTopoTask();
	}

	event void TimerPeriodic.fired() {
		time = time*2;
		dbg("Time", "Periodic time: %d\n", time);
		initBeacon();
		if (time > maxTime) {
			dbg("Time", "Stop time: %d %d\n", time, maxTime);
			call TimerPeriodic.stop();
		}
	}


	// Serial


  task void uartSendTask() {
    uint8_t len;

    am_id_t id;
    am_addr_t addr, src;
    message_t* msg;
    
    //id = call RadioAMPacket.type(msg);
    //addr = call RadioAMPacket.destination(msg);
    //src = call RadioAMPacket.source(msg);
    //grp = call RadioAMPacket.group(msg);
    //call UartPacket.clear(msg);
    //call UartAMPacket.setSource(msg, src);
    //call UartAMPacket.setGroup(msg, grp);
 	if (call UartSend.send[id](src, msg, len) == SUCCESS)
      call Leds.led1Toggle();
    else
      {
	call Leds.led1Toggle();
	post uartSendTask();
      }

  }



  event void UartSend.sendDone[am_id_t id](message_t* msg, error_t error) {
    if (error != SUCCESS)
      //failBlink();
    	call Leds.led1Toggle();
    else
      atomic

    	post uartSendTask();
  }





	// Fim Serial


	event message_t* ReceiveRequest.receive(message_t* msg, void* payload, uint8_t len) {
	
		uint8_t type = call AMPacket.type(msg);
		am_addr_t from;
		am_addr_t request_id;
		request_topo_t* rcvBeacon;
		uint8_t hops_rcv;
		uint16_t counterDescendants;
		
	
		// #if defined(PLATFORM_MICAZ)
		// if(TOS_NODE_ID == 0){
		// 	return msg;
		// }
		// #endif


		from = call AMPacket.source(msg);
		rcvBeacon = (request_topo_t*)payload;
		seqnoAux = rcvBeacon->seqno;
		request_id = rcvBeacon->request_id;
		hops_rcv = rcvBeacon->hops;
		counterDescendants = rcvBeacon->count + 1;



		//dbg("RequestTopo", "Received rcvBeacon->seqno %hhu. Time: %s\n", rcvBeacon->seqno , sim_time_string());
			// if this select source is for me
			if (request_id == TOS_NODE_ID){
				dbg("RequestTopo", "Mensagem de %d eh p mim trata: %s\n", from, sim_time_string());
				dbg("RequestTopo", "[Request topology] Receive Request topo from node %d. Time %s\n", from, sim_time_string());
				dbg("Descendants", "<< Beacon received is from child? %d. Time %s\n", from, sim_time_string());
				changed_counter(from, counterDescendants, counter);
				count_descendants();
				;
				//post
			}
		post uartSendTask();
		return msg;

	}

	event message_t* ReceiveReply.receive(message_t* msg, void* payload, uint8_t len) {
			uint8_t type = call AMPacket.type(msg);
			am_addr_t from;
			am_addr_t origemPkt;
		    reply_topo_t* rcvTopo;
			from = call AMPacket.source(msg);
			rcvTopo = (reply_topo_t*)payload;
			seqnoAux = rcvTopo->seqno;

			//origemPkt = rcvTopo->origem;

			//Forward
			if(seqnoAux > seqnoReplyTopo || !check_node(origemPkt, bufferTopo_ids)){
				seqnoReplyTopo = seqnoAux;
				dbg("RequestTopo", "Receive reply topo of node %hhu origem %hhu Forward Time: %s\n", from, origemPkt, sim_time_string());
				topoMsgBuffer = *msg;
				post replyTopoTask();
			}
		
		return msg;

	}


}
