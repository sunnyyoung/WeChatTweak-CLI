# WeChatTweak-CLI

A command line utility to work with WeChatTweak-macOS.

## Overview

```bash
OVERVIEW: A command line utility to work with WeChatTweak-macOS.

USAGE: wechattweak-cli <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  install                 Install or upgrade tweak.
  uninstall               Uninstall tweak.
  resign                  Force resign WeChat.app
  version                 Get current version of WeChatTweak.

  See 'wechattweak-cli help <subcommand>' for detailed help.
```

## Requirements

- macOS >= 10.12
- Swift 5 Runtime Support

## Install

### Homebrew

You can install [WeChatTweak-CLI](https://github.com/sunnyyoung/WeChatTweak-CLI) via Homebrew.

```bash
$ brew install sunnyyoung/repo/wechattweak-cli
```

### Manual (**NOT RECOMMENDED**)

1. Download the [WeChatTweak-CLI](https://github.com/sunnyyoung/WeChatTweak-CLI/releases/latest/download/wechattweak-cli)
2. Remove file attributes: `xattr -d com.apple.quarantine wechattweak-cli`
3. Make sure the binary executable: `chmod +x wechattweak-cli`
4. Run: `sudo ./wechattweak-cli install`

## License

The [Apache License 2.0](LICENSE).
