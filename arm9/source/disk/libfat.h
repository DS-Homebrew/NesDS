#ifndef libfat_snemulds
#define libfat_snemulds

#include "fatfile.h"
#include "fatdir.h"

const devoptab_t dotab_fat = {
	"fat",
	sizeof (FILE_STRUCT),
	_FAT_open_r,
	_FAT_close_r,
	_FAT_write_r,
	_FAT_read_r,
	_FAT_seek_r,
	_FAT_fstat_r,
	_FAT_stat_r,
	_FAT_link_r,
	_FAT_unlink_r,
	_FAT_chdir_r,
	_FAT_rename_r,
	_FAT_mkdir_r,
	sizeof (DIR_STATE_STRUCT),
	_FAT_diropen_r,
	_FAT_dirreset_r,
	_FAT_dirnext_r,
	_FAT_dirclose_r,
	_FAT_statvfs_r,
	_FAT_ftruncate_r,
	_FAT_fsync_r,
	NULL,	// Device data
	NULL,
	NULL
};


#endif

#ifdef __cplusplus
extern "C" {
#endif

extern bool fatMount (const char* name, const DISC_INTERFACE* interface, sec_t startSector, uint32_t cacheSize, uint32_t SectorsPerPage);
extern bool fatMountSimple (const char* name, const DISC_INTERFACE* interface);
extern void fatUnmount (const char* name);
extern bool fatInit (uint32_t cacheSize, bool setAsDefaultDevice);
extern bool fatInitDefault (void);
extern void fatGetVolumeLabel (const char* name, char *label);

#ifdef __cplusplus
}
#endif
