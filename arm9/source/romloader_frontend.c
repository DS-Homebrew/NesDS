#include <nds.h>
#include <stdio.h>
#include <unistd.h>

void SplitItemFromFullPathAlias(const char *pFullPathAlias,char *pPathAlias,char *pFilenameAlias) {
	u32 SplitPos = 0;
	{
		u32 idx = 0;
		while (1) {
			char uc = pFullPathAlias[idx];
			if(uc == 0) break;
			if(uc == '/') SplitPos = idx + 1;
			idx++;
		}
	}

	if (pPathAlias) {
		if (SplitPos <= 1) {
			pPathAlias[0] = '/';
			pPathAlias[1] = 0;
		} else {
			u32 idx = 0;
			for(; idx < SplitPos - 1; idx++){
				pPathAlias[idx] = pFullPathAlias[idx];
			}
			pPathAlias[SplitPos - 1] = 0;
		}
	}

	if(pFilenameAlias)
		strcpy(pFilenameAlias, &pFullPathAlias[SplitPos]);
}

extern int argc;
extern char **argv;
bool readFrontend(char *target)
{
	char dir[768];
	if (argc < 2)
		return false;

	SplitItemFromFullPathAlias(argv[1],dir,target);
	chdir(dir);
	return true;
}

