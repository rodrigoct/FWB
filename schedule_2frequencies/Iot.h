#ifndef IOT_H
#define IOT_H

//Request topo: 0x1
//Reply topo: 0x2
//Request data: 0x3
//Reply data: 0x4

#define TOTAL_NODES 7
enum {
    //AM TYPES
    AM_REQ_TOPO = 0x1,
    AM_REPLY_TOPO = 0x2,
};


typedef nx_struct request_topo{
    nx_uint16_t        seqno;
    nx_uint8_t         hops;
    nx_uint16_t        request_id;
    nx_uint16_t        count;
} request_topo_t;   

typedef nx_struct reply_topo{
    nx_uint16_t        seqno;
    nx_uint16_t        parent;
} reply_topo_t;   



#endif
