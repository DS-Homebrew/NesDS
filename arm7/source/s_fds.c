#include "nestypes.h"

static unsigned s_type = 2;
extern void FDSSoundInstall1(void);
extern void FDSSoundInstall2(void);
extern void FDSSoundInstall3(void);
extern int FDSSoundInstallExt(void);
void (*FDSSoundWriteHandler)(Uint address, Uint value);
void FDSSoundInstall(void)
{
	switch (s_type)
	{
	case 1:
		FDSSoundInstall1();
		break;
	case 3:
		FDSSoundInstall2();
		break;
	case 0:
		//if (FDSSoundInstallExt()) break; not supported
		break;
		/* fall down */
	default:
	case 2:
		FDSSoundInstall3();
		break;
	}
}

void FDSSelect(unsigned type)
{
	s_type = type;
}
