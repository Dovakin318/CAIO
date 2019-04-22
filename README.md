# Description
Various camera patch for Xiaomi SDM660 running MIUI or AOSP/LOS based ROM.

# Compatibilty
- Magisk 18.1+
- Mi 6X (wayne)
  - MIUI & AOSP/LOS
- Mi A2 (jasmine_sprout)
  - AOSP/LOS (Not recommended on Stock)
- Redmi Note 5 (whyred)
  - MIUI & AOSP/LOS
- Redmi Note 6 (tulip)
  - MIUI & AOSP/LOS
 
# Features
## Basic
- Camera2 API compatibility
- (En/dis)able EIS
- Unlimited Google Photo original backup until Feb. 1st 2022
- Gimmick AI Camera (selfie, square, and portrait)
- Patch MIUI hidden features

## MIUI
- Weird Camera2API

## AOSP/LOS
- Install/replace MIUI Camera, select between Stock Mi A2, AI Part 7 or AI Part 8
- Google Camera 4K60-ish video recording (not available for Mi A2)

# Credits
- topjohnwu @ Magisk
- ahrion & zackptg5 @ Unity
- MIUI @ Xiaomi
- Hadinata & ANCIENT Family
- TadiT7 @ Github
- Manish4586, rcstar6696, rebenok90x, mracar, balazs312 @ Mi A2/6X Community
- John Fawkes
- Stallix

# Changelog
## 2019-04-22 (161)
### Basic
- Add option to remove Pixel 3XL sysconfig (Google Photo disguise)
- (whyred) Add AIpart8 module camera blobs mixups by Hadinata & ANCIENT Family
- (whyred props) change camera.is_mode to 4
- (whyred props) change camera.is_type to 4
- (whyred props) change camera.stats.test to 5

### AOSP/LOS
- Add model_front.dlc from wayne 9.4.14 dump TadiT7 @ github
- (MIUI Camera) Rename priv-app name with MemeCamera
- (MIUI Camera) Replace some libs with AI Part 8 libs by Hadinata @ ANCIENT Family
- (Replacer) Change _mktouch_ with create found Miui Camera directory along with _.replace_ file into it
- (wayne) Add few placebo vendor camera blobs

## 2019-04-21 (160)
- Regular shells error corrections
- Various system.prop modifications

## 2019-04-20 (158)
- (AOSP) Moved model_back.dlc from wayne to AOSP
- (MIUI) Corrected original ROM device features xml copying

## 2019-04-19 (157)
- (wayne) Removed placebo libs
- (MIUI) Missed device_features path

## 2019-04-18 (156)
- Correct miss-called props
- Clean up unused vars and commands
- (wayne) Added few placebo libs from Mi A2

## 2019-04-18
- Aproved by Magisk
