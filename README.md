# WeChatTweak-CLI

A command line utility to work with WeChatTweak-macOS.

## Overview

```bash
USAGE: tweak [--install] [--uninstall]

OPTIONS:
  --install/--uninstall   Install or Uninstall tweak (default: install)
  -h, --help              Show help information.
```

## Requirements

- macOS >= 10.11
- Swift 5 Runtime Support

## Install

### Homebrew

You can install [WeChatTweak-CLI](https://github.com/Sunnyyoung/WeChatTweak-CLI) via Homebrew.

```bash
$ brew install sunnyyoung/repo/wechattweak-cli
```

### Manual (**NOT RECOMMENDED**)

1. Download the [WeChatTweak-CLI](https://github.com/Sunnyyoung/WeChatTweak-CLI/releases/latest/download/wechattweak-cli)
2. Remove file attributes: `xattr -d com.apple.quarantine wechattweak-cli`
3. Make sure the binary executable: `chmod + x wechattweak-cli`
4. Run: `wechattweak-cli --install`

## Usage

```bash
$ sudo wechattweak-cli --install   # Install
$ sudo wechattweak-cli --uninstall # Uninstall
```

For more usage, run: `wechattweak-cli --help`.

## License

The [Apache License 2.0](LICENSE).
