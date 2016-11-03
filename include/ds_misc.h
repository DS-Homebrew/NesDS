/*

#define PM_SOUND		0x01
#define PM_BOTTOMLIGHT	0x04
#define PM_TOPLIGHT		0x08
#define PM_LED_SLOW		0x10
#define PM_LED_FAST		0x30
#define PM_OFF			0x40

/////////////////////////
//FIFO
//////////////////////////

#define IRQ_FIFO_SEND 0x20000
#define IRQ_FIFO_RECV 0x40000

#define FIFO_INTR				*(vu16*)0x4000180
#define REG_FIFO_CNT            *(vu16*)0x4000184
#define REG_FIFO_SEND           *(vu32*)0x4000188
#define REG_FIFO_RECV           *(vu32*)0x4100000

#define FIFO_INTR_I                  0x4000
#define FIFO_INTR_IREQ               0x2000
#define FIFO_INTR_STATUS_OUT         0x0f00
#define FIFO_INTR_STATUS_IN          0x000f

#define FIFO_CNT_ENABLE		0x8000
#define FIFO_CNT_ERR		0x4000
#define FIFO_CNT_RECV_IRQ	0x0400
#define FIFO_CNT_RECV_FULL	0x0200
#define FIFO_CNT_RECV_EMPTY	0x0100
#define FIFO_CNT_SEND_CLEAR	0x0008
#define FIFO_CNT_SEND_IRQ	0x0004
#define FIFO_CNT_SEND_FULL	0x0002
#define FIFO_CNT_SEND_EMPTY	0x0001

enum errmsg {FAIL_SEND_FULL,FAIL_SEND_ERR,FAIL_RECV_EMPTY,FAIL_RECV_ERR,SUCCESS};

static inline void fifo_init() {
	REG_FIFO_CNT =	FIFO_CNT_SEND_CLEAR | FIFO_CNT_RECV_IRQ | FIFO_CNT_ENABLE | FIFO_CNT_ERR;
}

#define TOUCH_CNTRL_X1   (*(vu8*)0x027FFCDC)	//pixel positions of the two points you click when calibrating 
#define TOUCH_CNTRL_Y1   (*(vu8*)0x027FFCDD) 
#define TOUCH_CNTRL_X2   (*(vu8*)0x027FFCE2) 
#define TOUCH_CNTRL_Y2   (*(vu8*)0x027FFCE3) 

#define TOUCH_CAL_X1   (*(vu16*)0x027FFCD8) 	//corresponding touchscreen values
#define TOUCH_CAL_Y1   (*(vu16*)0x027FFCDA) 
#define TOUCH_CAL_X2   (*(vu16*)0x027FFCDE) 
#define TOUCH_CAL_Y2   (*(vu16*)0x027FFCE0) 
*/