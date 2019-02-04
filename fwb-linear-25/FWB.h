#ifndef FWB_H
#define FWB_H


#define TOTAL_NODES 6
enum {
    //AM TYPES
    AM_DATA_TOPO = 0x1,
};


typedef nx_struct data_to_topo{
    nx_uint16_t        seqno;
    nx_uint8_t         hops;
    nx_uint16_t        request_id;
    nx_uint16_t        count;
    nx_uint8_t         start; //70 to init
} data_to_topo_t;     



#endif
