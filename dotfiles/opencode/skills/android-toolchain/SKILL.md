---
name: android-toolchain
description: >
  Toolchain de Android en ~/lotus-android-toolchain: env.sh, SDK, NDK, CMake,
  Qt 6.6.3, androiddeployqt y adb. Usar antes de compilar una app Qt/QML para
  Android arm64 o de instalar cualquier herramienta Android.
---

# Android

## 7. Android

Todo vive en `~/lotus-android-toolchain/`. **Antes de compilar: `source ~/lotus-android-toolchain/env.sh`**
(define `ANDROID_SDK_ROOT`, `ANDROID_HOME`, `ANDROID_NDK_ROOT`, `QT_PREFIX`,
`QT_HOST_PATH`, `CMAKE_PREFIX_PATH`). Sin ese `source` no hay SDK.

- SDK: `~/lotus-android-toolchain/android-sdk`
- NDK: `27.0.12077973`
- build-tools: `34.0.0` (`aapt2`, `apksigner`, `zipalign`, `d8`, `aidl`)
- Plataforma: **solo `android-34`**
- cmake: `3.22.1` · cmdline-tools: `latest` (`sdkmanager`, `avdmanager`)
- JDK 17: `~/lotus-android-toolchain/jdk-17.0.20.1+1`
- Qt: `qt-android/6.6.3/android_arm64_v8a` + host `qt-host/6.6.3/gcc_64`
- Objetivo: apps **Qt/QML para Android arm64** vía `androiddeployqt`.
- `adb` del sistema en `/usr/bin/adb`.
- **No instalado** (no lo uses en instrucciones): gradle, kotlin, flutter, scrcpy,
  apktool, waydroid, emulador de Android. Si hace falta, dilo y pide permiso antes
  de instalar nada.
