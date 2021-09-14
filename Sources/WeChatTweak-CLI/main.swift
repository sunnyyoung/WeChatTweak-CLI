import Foundation
import Security
import Alamofire
import PromiseKit
import ArgumentParser
import insert_dylib

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

enum Action: String, EnumerableFlag {
    case install
    case uninstall
}

struct Tweak: ParsableCommand {
    @Flag(help: "Install or Uninstall tweak")
    var action: Action

    func run() throws {
        switch action {
        case .install:
            firstly {
                check()
            }.then {
                cleanup()
            }.then {
                backup()
            }.then {
                download()
            }.then {
                unzip()
            }.then {
                insert()
            }.then {
                codesign()
            }.done {
                print("Install success!")
            }.catch { error in
                print("Install failed: \(error.localizedDescription)")
            }.finally {
                CFRunLoopStop(CFRunLoopGetCurrent())
            }
        case .uninstall:
            firstly {
                check()
            }.then {
                cleanup()
            }.then {
                restore()
            }.done {
                print("Uninstall success!")
            }.catch { error in
                print("Uninstall failed: \(error)")
            }.finally {
                CFRunLoopStop(CFRunLoopGetCurrent())
            }
        }
    }
}

// MARK: Steps
private extension Tweak {
    func check() -> Promise<Void> {
        return getuid() == 0 ? .value(()) : .init(error: CLIError.permission)
    }

    private func cleanup() -> Guarantee<Void> {
        return Guarantee { seal in
            try? FileManager.default.removeItem(atPath: Temp.zip)
            try? FileManager.default.removeItem(atPath: Temp.binary)
            seal(())
        }
    }

    func backup() -> Promise<Void> {
        print("------ Backup ------")
        return Promise { seal in
            do {
                if FileManager.default.fileExists(atPath: App.backup) {
                    print("WeChat.bak exists, skip it...")
                } else {
                    try FileManager.default.copyItem(atPath: App.binary, toPath: App.backup)
                    print("Created WeChat.bak...")
                }
                seal.fulfill(())
            } catch {
                seal.reject(error)
            }
        }
    }

    func restore() -> Promise<Void> {
        print("------ Restore ------")
        return Promise { seal in
            do {
                if FileManager.default.fileExists(atPath: App.backup) {
                    try FileManager.default.removeItem(atPath: App.binary)
                    try FileManager.default.moveItem(atPath: App.backup, toPath: App.binary)
                    try? FileManager.default.removeItem(atPath: App.framework)
                    print("Restored WeChat...")
                } else {
                    print("WeChat.bak not exists, skip it...")
                }
                seal.fulfill(())
            } catch {
                seal.reject(error)
            }
        }
    }

    private func download() -> Promise<Void> {
        print("------ Download ------")
        return Promise { seal in
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                return (.init(fileURLWithPath: Temp.zip), [.removePreviousFile])
            }
            Alamofire.download(Constant.url, to: destination).response { response in
                if let error = response.error {
                    seal.reject(CLIError.downloading(error))
                } else {
                    seal.fulfill(())
                }
            }
        }
    }

    private func unzip() -> Promise<Void> {
        print("------ Unzip ------")
        return execute(command: "rm -rf \(App.framework); unzip \(Temp.zip) -d \(App.macos)")
    }

    private func insert() -> Promise<Void> {
        print("------ Insert Dylib ------")
        return Promise { seal in
            insert_dylib.insert("@executable_path/WeChatTweak.framework/WeChatTweak", App.binary) == EXIT_SUCCESS ? seal.fulfill(()) : seal.reject(CLIError.insertDylib)
        }
    }

    private func codesign() -> Promise<Void> {
        print("------ Codesign ------")
        return firstly {
            execute(command: "cp \(App.binary) \(Temp.binary)")
        }.then {
            execute(command: "codesign --force --deep --sign - \(Temp.binary)")
        }.then {
            execute(command: "cp \(Temp.binary) \(App.binary)")
        }
    }
}

// MARK: Command
private extension Tweak {
    func execute(command: String) -> Promise<Void> {
        return Promise { seal in
            print("Execute command: \(command)")
            var error: NSDictionary?
            guard let script = NSAppleScript(source: "do shell script \"\(command)\"") else {
                return seal.reject(CLIError.executing(command: command, error: ["error": "Create script failed."]))
            }
            script.executeAndReturnError(&error)
            if let error = error {
                seal.reject(CLIError.executing(command: command, error: error))
            } else {
                seal.fulfill(())
            }
        }
    }
}

defer {
    try? FileManager.default.removeItem(atPath: Temp.zip)
    try? FileManager.default.removeItem(atPath: Temp.binary)
}

Tweak.main()
CFRunLoopRun()
