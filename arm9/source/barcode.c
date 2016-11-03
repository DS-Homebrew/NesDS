#include <nds.h>
#include "ds_misc.h"
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
void setbarcodedata( char *code, int len )
{
	/*
	if( rom->GetPROM_CRC() == 0x67898319 ) {	// Barcode World (J)
		SetBarcode2Data( code, len );
		return;
	}*/

	int	i, j, count = 0;

	for( i = 0; i < len; i++ ) {
		code[i] = code[i]-'0';
	}

	for( i = 0; i < 32; i++ ) {
		barcode_data[count++] = 0x08;
	}

	barcode_data[count++] = 0x00;
	barcode_data[count++] = 0x08;
	barcode_data[count++] = 0x00;

	if( len == 13 ) {
		for( i = 0; i < 6; i++ ) {
			if( prefix_parity_type[(int)code[0]][i] ) {
				for( j = 0; j < 7; j++ ) {
					barcode_data[count++] = data_left_even[(int)code[i+1]][j]?0x00:0x08;
				}
			} else {
				for( j = 0; j < 7; j++ ) {
					barcode_data[count++] = data_left_odd[(int)code[i+1]][j]?0x00:0x08;
				}
			}
		}

		barcode_data[count++] = 0x08;
		barcode_data[count++] = 0x00;
		barcode_data[count++] = 0x08;
		barcode_data[count++] = 0x00;
		barcode_data[count++] = 0x08;

		for( i = 7; i < 13; i++ ) {
			for( j = 0; j < 7; j++ ) {
				barcode_data[count++] = data_right[(int)code[i]][j]?0x00:0x08;
			}
		}
	} 
	else if( len == 8 ) {
		int	sum = 0;
		for( i = 0; i < 7; i++ ) {
			sum += (i&1)?code[i]:(code[i]*3);
		}
		code[7] = (10-(sum%10))%10;

		for( i = 0; i < 4; i++ ) {
			for( j = 0; j < 7; j++ ) {
				barcode_data[count++] = data_left_odd[(int)code[i]][j]?0x00:0x08;
			}
		}

		barcode_data[count++] = 0x08;
		barcode_data[count++] = 0x00;
		barcode_data[count++] = 0x08;
		barcode_data[count++] = 0x00;
		barcode_data[count++] = 0x08;

		for( i = 4; i < 8; i++ ) {
			for( j = 0; j < 7; j++ ) {
				barcode_data[count++] = data_right[(int)code[i]][j]?0x00:0x08;
			}
		}
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

/*
unsigned char NES::Barcode2( void )
{
	unsigned char ret = 0x00;

	if( !m_bBarcode2 || m_Barcode2seq < 0 )
		return	ret;

	switch( m_Barcode2seq ) {
		case	0:
			m_Barcode2seq++;
			m_Barcode2ptr = 0;
			ret = 0x04;		// d3
			break;

		case	1:
			m_Barcode2seq++;
			m_Barcode2bit = m_Barcode2data[m_Barcode2ptr];
			m_Barcode2cnt = 0;
			ret = 0x04;		// d3
			break;

		case	2:
			ret = (m_Barcode2bit&0x01)?0x00:0x04;	// Bit rev.
			m_Barcode2bit >>= 1;
			if( ++m_Barcode2cnt > 7 ) {
				m_Barcode2seq++;
			}
			break;
		case	3:
			if( ++m_Barcode2ptr > 19 ) {
				m_bBarcode2 = FALSE;
				m_Barcode2seq = -1;
			} else {
				m_Barcode2seq = 1;
			}
			break;
		default:
			break;
	}

	return	ret;
}

void	NES::SetBarcode2Data( LPBYTE code, INT len )
{
	DEBUGOUT( "NES::SetBarcodeData2 code=%s len=%d\n", code, len );

	if( len < 13 )
		return;

	m_bBarcode2   = TRUE;
	m_Barcode2seq = 0;
	m_Barcode2ptr = 0;

	::strcpy( (char*)m_Barcode2data, (char*)code );

	m_Barcode2data[13] = 'S';
	m_Barcode2data[14] = 'U';
	m_Barcode2data[15] = 'N';
	m_Barcode2data[16] = 'S';
	m_Barcode2data[17] = 'O';
	m_Barcode2data[18] = 'F';
	m_Barcode2data[19] = 'T';
}*/