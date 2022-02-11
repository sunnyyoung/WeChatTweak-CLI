//
//  main.swift
//
//  Created by Sunny Young.
//

import Foundation
import PromiseKit
import ArgumentParser

struct Constant {
    static let url = URL(string: "https://github.com/Sunnyyoung/WeChatTweak-macOS/releases/latest/download/WeChatTweak.framework.zip")!
}

struct App {
    static let root = "/Applications"
    static let app = root.appending("/WeChat.app")
    static let macos = app.appending("/Contents/MacOS")
    static let binary = app.appending("/Contents/MacOS/WeChat")
    static let backup = app.appending("/Contents/MacOS/WeChat.bak")

    static let framework = macos.appending("/WeChatTweak.framework")
}

struct Temp {
    static let root = "/tmp"
    static let binary = root.appending("/WeChat")
    static let zip = root.appending("/WeChatTweak.zip")
}

enum CLIError: LocalizedError {
    case permission
    case downloading(Error)
    case insertDylib
    case executing(command: String, error: NSDictionary)

    var errorDescription: String? {
        switch self {
        case .permission:
            return "Please run with `sudo`."
        case let .downloading(error):
            return "Download failed with error: \(error)"
        case .insertDylib:
            return "Insert dylib failed"
        case let .executing(command, error):
            return "Execute command: \(command) failed: \(error)"
        }
    }
}

struct Install: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Install or upgrade tweak.")

    func run() throws {
        firstly {
            Command.check()
        }.then {
            Command.cleanup()
        }.then {
            Command.download()
        }.then {
            Command.unzip()
        }.then {
            Command.backup()
        }.then {
            Command.removeCodesign()
        }.then {
            Command.insert()
        }.then {
            Command.addCodesign()
        }.done {
            print("Install success!")
        }.catch { error in
            print("Install failed: \(error.localizedDescription)")
        }.finally {
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }
}

struct Uninstall: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Uninstall tweak.")

    func run() throws {
        firstly {
            Command.check()
        }.then {
            Command.cleanup()
        }.then {
            Command.restore()
        }.done {
            print("Uninstall success!")
        }.catch { error in
            print("Uninstall failed: \(error)")
        }.finally {
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }
}

struct Version: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Get current version of WeChatTweak.")

    func run() throws {
        return firstly {
            getVersion()
        }.done { version in
            print(version ?? "Unknown")
        }.catch { error in
            print("Get version failed: \(error)")
        }.finally {
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }

    func getVersion() -> Promise<String?> {
        return Promise { seal in
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: App.framework.appending("/Versions/A/Resources/Info.plist")))
                let info = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                seal.fulfill((info as? [String: Any])?["CFBundleShortVersionString"] as? String)
            } catch {
                seal.reject(error)
            }
        }
    }
}

struct Resign: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Force resign WeChat.app")

    func run() throws {
        firstly {
            Command.removeCodesign()
        }.then {
            Command.addCodesign()
        }.catch { error in
            print("Resign failed: \(error.localizedDescription)")
        }.finally {
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }
}

struct Tweak: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "wechattweak-cli",
        abstract: "A command line utility to work with WeChatTweak-macOS.",
        subcommands: [
            Install.self,
            Uninstall.self,
            Resign.self,
            Version.self
        ],
        defaultSubcommand: Self.self
    )
}

defer {
    try? FileManager.default.removeItem(atPath: Temp.zip)
    try? FileManager.default.removeItem(atPath: Temp.binary)
}

Tweak.main()
CFRunLoopRun()
