#ifndef S_VRC6_H__
#define S_VRC6_H__

#ifdef __cplusplus
extern "C" {
#endif

void VRC6SoundInstall(void);
Int32 VRC6SoundRender1(void);
Int32 VRC6SoundRender2(void);
Int32 VRC6SoundRender3(void);
void VRC6SoundWrite9000(Uint address, Uint value);
void VRC6SoundWriteA000(Uint address, Uint value);
void VRC6SoundWriteB000(Uint address, Uint value);

#ifdef __cplusplus
}
#endif

#endif /* S_VRC6_H__ */
