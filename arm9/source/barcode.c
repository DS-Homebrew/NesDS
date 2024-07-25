#include <nds.h>
#include "c_defs.h"

char prefix_parity_type[10][6] = {
	{0,0,0,0,0,0}, {0,0,1,0,1,1}, {0,0,1,1,0,1}, {0,0,1,1,1,0},
	{0,1,0,0,1,1}, {0,1,1,0,0,1}, {0,1,1,1,0,0}, {0,1,0,1,0,1},
	{0,1,0,1,1,0}, {0,1,1,0,1,0}
};
char data_left_odd[10][7] = {
	{0,0,0,1,1,0,1}, {0,0,1,1,0,0,1}, {0,0,1,0,0,1,1}, {0,1,1,1,1,0,1},
	{0,1,0,0,0,1,1}, {0,1,1,0,0,0,1}, {0,1,0,1,1,1,1}, {0,1,1,1,0,1,1},
	{0,1,1,0,1,1,1}, {0,0,0,1,0,1,1}
};
char data_left_even[10][7] = {
	{0,1,0,0,1,1,1}, {0,1,1,0,0,1,1}, {0,0,1,1,0,1,1}, {0,1,0,0,0,0,1},
	{0,0,1,1,1,0,1}, {0,1,1,1,0,0,1}, {0,0,0,0,1,0,1}, {0,0,1,0,0,0,1},
	{0,0,0,1,0,0,1}, {0,0,1,0,1,1,1}
};
char data_right[10][7] = {
	{1,1,1,0,0,1,0}, {1,1,0,0,1,1,0}, {1,1,0,1,1,0,0}, {1,0,0,0,0,1,0},
	{1,0,1,1,1,0,0}, {1,0,0,1,1,1,0}, {1,0,1,0,0,0,0}, {1,0,0,0,1,0,0},
	{1,0,0,1,0,0,0}, {1,1,1,0,1,0,0}
};

unsigned char barcode_data[256];
void setbarcodedata(char *code, int len) {
	/*
	if( rom->GetPROM_CRC() == 0x67898319 ) {	// Barcode World (J)
		SetBarcode2Data( code, len );
		return;
	}*/

	int i, j, count = 0;

	for (i = 0; i < len; i++) {
		code[i] = code[i]-'0';
	}

	for (i = 0; i < 32; i++) {
		barcode_data[count++] = 0x08;
	}

	barcode_data[count++] = 0x00;
	barcode_data[count++] = 0x08;
	barcode_data[count++] = 0x00;

	int sum = 0;

	switch (len) {
		case 13:
			for (i = 0; i < 6; i++) {
				if (prefix_parity_type[(int)code[0]][i]) {
					for (j = 0; j < 7; j++) {
						barcode_data[count++] = data_left_even[(int)code[i+1]][j]?0x00:0x08;
					}
				} else {
					for (j = 0; j < 7; j++) {
						barcode_data[count++] = data_left_odd[(int)code[i+1]][j]?0x00:0x08;
					}
				}
			}

			barcode_data[count++] = 0x08;
			barcode_data[count++] = 0x00;
			barcode_data[count++] = 0x08;
			barcode_data[count++] = 0x00;
			barcode_data[count++] = 0x08;

			for (i = 7; i < 13; i++) {
				for (j = 0; j < 7; j++) {
					barcode_data[count++] = data_right[(int)code[i]][j] ? 0x00 : 0x08;
				}
			}
			break;
		case 8:
			for (i = 0; i < 7; i++) {
				sum += (i & 1) ? code[i] : (code[i] * 3);
			}
			code[7] = (10 - (sum % 10)) % 10;

			for (i = 0; i < 4; i++) {
				for (j = 0; j < 7; j++) {
					barcode_data[count++] = data_left_odd[(int)code[i]][j] ? 0x00 : 0x08;
				}
			}

			barcode_data[count++] = 0x08;
			barcode_data[count++] = 0x00;
			barcode_data[count++] = 0x08;
			barcode_data[count++] = 0x00;
			barcode_data[count++] = 0x08;

			for (i = 4; i < 8; i++) {
				for (j = 0; j < 7; j++) {
					barcode_data[count++] = data_right[(int)code[i]][j]?0x00:0x08;
				}
			}
			break;
	}

	barcode_data[count++] = 0x00;
	barcode_data[count++] = 0x08;
	barcode_data[count++] = 0x00;

	for( i = 0; i < 32; i++ ) {
		barcode_data[count++] = 0x08;
	}

	barcode_data[count++] = 0xFF;

	__barcode = 1;
	__barcode_out = 0x08;
}
