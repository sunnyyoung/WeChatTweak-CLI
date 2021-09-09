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

- macOS 10.11 or later.

## Install

### Homebrew

You can install [wechattweak-cli](https://github.com/Sunnyyoung/WeChatTweak-CLI) via Homebrew.

```bash
$ brew tap sunnyyoung/repo
$ brew install wechattweak-cli
```

### Manual

1. Download the [wechattweak-cli](https://github.com/Sunnyyoung/WeChatTweak-CLI/releases/latest/download/wechattweak-cli)
2. Remove file attributes: `xattr -d com.apple.quarantine wechattweak-cli`
3. Make sure the binary executable: `chmod + x wechattweak-cli`
4. Run: `wechattweak-cli --install`

## Usage

```bash
$ sudo wechattweak-cli --install   # Install
$ sudo wechattweak-cli --uninstall # Uninstall
```

For more usage, run: `wechattweak-cli --help`.

## TODO

- [x] Add homebrew support
- [ ] Add upgrade action

## License

The [Apache License 2.0](LICENSE).
