#ifndef S_FDS_H__
#define S_FDS_H__
#ifdef __cplusplus
extern "C" {
#endif

void FDSSoundInstall(void);
void FDSSelect(unsigned type);
extern void __fastcall (*FDSSoundWriteHandler)(Uint address, Uint value);

#ifdef __cplusplus
}
#endif
#endif /* S_FDS_H__ */
