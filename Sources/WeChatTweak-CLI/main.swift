import Foundation
import Security
import Alamofire
import PromiseKit
import ArgumentParser
import insert_dylib

struct Constant {
    static let url = URL(string: "https://github.com/Sunnyyoung/WeChatTweak-macOS/releases/latest/download/WeChatTweak.framework.zip")!
}

struct Location {
    static let Applications = URL(fileURLWithPath: "/Applications")
    static let Temp = URL(fileURLWithPath: "/tmp")
    static let zip = URL(fileURLWithPath: "/tmp/Tweak.zip")
    static let binary = URL(fileURLWithPath: "/tmp/WeChat")
}

struct App {
    static let app = "WeChat.app"
    static let macos = app.appending("/Contents/MacOS")
    static let binary = app.appending("/Contents/MacOS/WeChat")
    static let backup = app.appending("/Contents/MacOS/WeChat.bak")
}

struct Framework {
    static let framework = "WeChatTweak.framework"
    static let binary = framework.appending("/WeChatTweak")
}

enum CLIError: Error {
    case downloading(Error)
    case insertDylib
    case executing(command: String, error: NSDictionary)
}

enum Action: String, EnumerableFlag {
    case install
    case uninstall
}

struct Tweak: ParsableCommand {
    @Flag(help: "Install or Uninstall tweak")
    var action = Action.install

    func run() throws {
        switch action {
        case .install:
            firstly {
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
            }.then {
                move()
            }.done {
                print("Install success!")
                cleanup().done { Darwin.exit(EXIT_SUCCESS) }
            }.catch { error in
                print("Install failed: \(error)")
                cleanup().done { Darwin.exit(EXIT_FAILURE) }
            }
        case .uninstall:
            firstly {
                cleanup()
            }.then {
                restore()
            }.then {
                move()
            }.done {
                print("Uninstall success!")
                cleanup().done { Darwin.exit(EXIT_SUCCESS) }
            }.catch { error in
                print("Uninstall failed: \(error)")
                cleanup().done { Darwin.exit(EXIT_FAILURE) }
            }
        }
    }
}

private extension Tweak {
    func backup() -> Promise<Void> {
        return Promise { seal in
            do {
                print("Backup WeChat...")
                try FileManager.default.copyItem(
                    at: Location.Applications.appendingPathComponent(App.app),
                    to: Location.Temp.appendingPathComponent(App.app)
                )
                try FileManager.default.copyItem(
                    at: Location.Temp.appendingPathComponent(App.binary),
                    to: Location.Temp.appendingPathComponent(App.backup)
                )
                seal.fulfill(())
            } catch {
                seal.reject(error)
            }
        }
    }

    func restore() -> Promise<Void> {
        return Promise { seal in
            do {
                print("Restore WeChat...")
                try FileManager.default.copyItem(
                    at: Location.Applications.appendingPathComponent(App.app),
                    to: Location.Temp.appendingPathComponent(App.app)
                )
                try FileManager.default.removeItem(
                    at: Location.Temp.appendingPathComponent(App.binary)
                )
                try FileManager.default.moveItem(
                    at: Location.Temp.appendingPathComponent(App.backup),
                    to: Location.Temp.appendingPathComponent(App.binary)
                )
                try? FileManager.default.removeItem(
                    at: Location.Temp.appendingPathComponent(App.macos).appendingPathComponent(Framework.framework)
                )
                seal.fulfill(())
            } catch {
                seal.reject(error)
            }
        }
    }

    private func download() -> Promise<Void> {
        return Promise { seal in
            print("Download resource...")
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                return (Location.zip, [.removePreviousFile])
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
        return execute(
            command: "unzip \(Location.zip.path) -d \(Location.Temp.appendingPathComponent(App.macos).path)"
        )
    }

    private func insert() -> Promise<Void> {
        return Promise { seal in
            print("Insert dylib...")
            insert_dylib.insert(
                "@executable_path/WeChatTweak.framework/WeChatTweak",
                Location.Temp.appendingPathComponent(App.binary).path
            ) == EXIT_SUCCESS ? seal.fulfill(()) : seal.reject(CLIError.insertDylib)
        }
    }

    private func codesign() -> Promise<Void> {
        return firstly {
            Promise.value(
                try FileManager.default.moveItem(
                    at: Location.Temp.appendingPathComponent(App.binary),
                    to: Location.binary
                )
            )
        }.then {
            execute(
                command: "codesign --force --deep --sign - \(Location.binary.path)"
            )
        }.then {
            Promise.value(
                try FileManager.default.moveItem(
                    at: Location.binary,
                    to: Location.Temp.appendingPathComponent(App.binary)
                )
            )
        }
    }

    private func move() -> Promise<Void> {
        return execute(
            command: "rm -rf \(Location.Applications.appendingPathComponent(App.app).path); mv \(Location.Temp.appendingPathComponent(App.app).path) \(Location.Applications.appendingPathComponent(App.app).path)",
            privilege: true
        )
    }

    @discardableResult
    private func cleanup() -> Guarantee<Void> {
        return Guarantee { seal in
            print("Cleanup...")
            try? FileManager.default.removeItem(at: Location.zip)
            try? FileManager.default.removeItem(at: Location.Temp.appendingPathComponent(App.app))
            seal(())
        }
    }
}

private extension Tweak {
    func execute(command: String, privilege: Bool = false) -> Promise<Void> {
        return Promise { seal in
            print("Execute command: \(privilege ? "sudo " : "")\(command)")
            var error: NSDictionary?
            let source: String = {
                if privilege {
                    return "do shell script \"\(command)\" with administrator privileges"
                } else {
                    return "do shell script \"\(command)\""
                }
            }()
            guard let script = NSAppleScript(source: source) else {
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

Tweak.main()
RunLoop.main.run()
