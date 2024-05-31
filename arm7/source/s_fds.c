#include "nestypes.h"

extern void FDSSoundInstall1(void);
extern void FDSSoundInstall2(void);
extern void FDSSoundInstall3(void);
extern int FDSSoundInstallExt(void);
void (*FDSSoundWriteHandler)(Uint address, Uint value);
// Only one FDS Sound engine is being used for some reason...
void FDSSoundInstall(void)
{

		FDSSoundInstall3();
}
