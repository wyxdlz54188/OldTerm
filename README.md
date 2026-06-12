# NewTerm for iOS 6.1

[![Build Status](https://img.shields.io/badge/build-Theos-orange.svg)]()
[![Platform](https://img.shields.io/badge/platform-iOS%206.1.3+-lightgrey.svg)]()
[![Architecture](https://img.shields.io/badge/arch-armv7%20armv7s-blue.svg)]()

**wyxdlz54188.newterm** - NewTerm terminal emulator for iOS 6.1.3 devices

## Overview

This is a port of [NewTerm](https://github.com/hbang/NewTerm) for iOS 6.1.3 devices. The original NewTerm requires iOS 14.0+, but this version has been rewritten in Objective-C to support older devices running iOS 6.1.3.

## Supported Devices

- iPhone 3GS
- iPhone 4
- iPhone 4S
- iPad 2
- iPad 3
- iPod touch (4th/5th generation)

## System Requirements

- iOS 6.1.3 or later
- Jailbroken device
- OpenSSH installed (via Cydia)

## Features

- ✅ PTY-based terminal emulation
- ✅ Local shell access
- ✅ VT100 escape sequence support
- ✅ Copy/paste support
- ✅ Monospace font rendering
- ✅ Classic green-on-black theme
- ✅ Multi-tab support (basic)
- ✅ Screen rotation support

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/wyxdlz54188/Old_IOS_TERM.git
cd Old_IOS_TERM

# Build with Theos
make package

# Install to device
make install INSTALL_TARGET_HOST=<device-ip>
```

### From .deb Package

1. Download the `.deb` package
2. Transfer to your iOS device
3. Install using:
   ```bash
   dpkg -i wyxdlz54188.newterm_1.0.0_iphoneos-arm.deb
   uicache
   ```

## Building

### Prerequisites

- macOS with Xcode 4.x or 5.x
- [Theos](https://github.com/theos/theos)
- iOS 6.0 SDK

### Build Steps

1. Install Theos:
   ```bash
   git clone --recursive https://github.com/theos/theos.git $THEOS
   ```

2. Download iOS 6.0 SDK:
   ```bash
   curl -L https://github.com/xybp888/iOS-SDKs/archive/master.tar.gz | tar xz
   mv iOS-SDKs-master/iPhoneOS6.0.sdk $THEOS/sdks/
   ```

3. Build:
   ```bash
   make package
   ```

## Differences from Original NewTerm

| Feature | Original NewTerm | iOS 6 Port |
|---------|-----------------|------------|
| Minimum iOS | 14.0 | 6.0 |
| Language | Swift | Objective-C |
| Architecture | arm64 | armv7, armv7s |
| Theos Target | iphone:latest:14.0 | iphone:6.0:6.0 |
| UI | Modern UIKit | Legacy UIKit |

## Known Limitations

- No remote SSH support (local shell only)
- Basic VT100 support (not full emulation)
- No advanced theming
- No plugin system
- No split view support

## Credits

- **Original NewTerm**: [HASHBANG Productions](https://github.com/hbang)
- **iOS 6 Port**: wyxdlz54188
- **Based on**: MobileTerminal and terminal emulation libraries

## License

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License.

## Support

- Issues: https://github.com/wyxdlz54188/Old_IOS_TERM/issues
- Package ID: `wyxdlz54188.newterm`

---

**Bringing modern terminal experience to classic iOS devices**
