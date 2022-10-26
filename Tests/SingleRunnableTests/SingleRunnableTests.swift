import XCTest
@testable import SingleRunnable

final class SingleRunnableTests: XCTestCase {
    enum RunState: Hashable, CustomStringConvertible {
        case startRun(Int)
        case endSleep(Int)
        var index: Int {
            switch self {
            case let .startRun(index):
                return index
            case let .endSleep(index):
                return index
            }
        }
        var isStartState: Bool {
            switch self {
            case .startRun:
                return true
            case .endSleep:
                return false
            }
        }
        var description: String {
            switch self {
            case let .startRun(index):
                return "startRun\(index)"
            case let .endSleep(index):
                return "endSleep\(index)"
            }
        }
    }
    
    class SingleTaskCounter: SingleRunnable {
        var log: [Date: RunState] = [:]
        func run(_ count: Int, awaitMethod: (() async throws -> Void)? = nil) async throws -> RunState {
            log[Date()] = .startRun(count)
            print("💙\(count)-1", log.values)
            return try await Self.singleRun(name: "\(Self.self)") { [weak self] in
                var yieldCount = 0
                print("💙\(count)-2", self?.log.values)
                while yieldCount < 10 && self?.log.count ?? 0 < 2 {
                    print("-------------------------------------------------yield!! at:", yieldCount, self!.log.values)
                    await Task.yield()
                    yieldCount += 1
                }
                self?.log[Date()] = .endSleep(count)
                print("💙\(count)-3", self?.log.values)
                return .endSleep(count)
            }
        }
    }
    
    func test並列で２度実行した場合() async throws {
        let single = SingleTaskCounter()
        print("✨1", single.log.values)
        async let firstTask = single.run(1)
        print("✨2", single.log.values)
        print("------------------------------yield!! at:", #line)
        await Task.yield()
        print("✨3", single.log.values)
        async let secondTask = single.run(2)
        print("✨4", single.log.values)
        print("------------------------------yield!! at:", #line)
        await Task.yield()
        print("✨5", single.log.values)
        let firstResult = try await firstTask
        print("✨6", single.log.values)
        let secondResult = try await secondTask
        print("✨7", single.log.values)
        
        let times = single.log.keys.sorted()
        // Logの個数で並列で呼んだ場合に並列で同じ処理を実行できないことが確認できる
        XCTAssertEqual(times.count, 3, "Logは3つのみ（2回目は1回目の処理の結果を受け取るのでTaskを作成しない）")
        
        // Logの順番を確認。2つともスタートしてから終了することで並列で処理されていることが確認できる。
        XCTAssertEqual(single.log[times[0]]?.isStartState, true, "Log1 start")
        XCTAssertEqual(single.log[times[1]]?.isStartState, true, "Log2 start")
        XCTAssertEqual(single.log[times[2]]?.isStartState, false, "Log3 end")
                
        // 最初に実行した方のIndexとResultのIndexが一致すれば先に実行中のタスクを待っている挙動が確認できる。
        let firstStartIndex = try XCTUnwrap(single.log[times[0]]?.index)
        let endIndex = try XCTUnwrap(single.log[times[2]]?.index)
        XCTAssertEqual(firstStartIndex, endIndex, "先にスタートしたIndexでResultが返る")
        
        // ２回目も１回目の結果が返ってきていることを確認
        XCTAssertEqual(firstResult, .endSleep(endIndex), "1回目の呼び出し")
        XCTAssertEqual(secondResult, .endSleep(endIndex), "2回目の呼び出し")
    }
    
    func test直列で2度実行した場合() async throws {
        let single = SingleTaskCounter()
        let firstResult = try await single.run(1)
        let secondResult = try await single.run(2)
        
        /// Logの順番で直列に実行されていることを確認。
        let times = single.log.keys.sorted()
        XCTAssertEqual(single.log[times[0]], .startRun(1), "1回目スタート")
        XCTAssertEqual(single.log[times[1]], .endSleep(1), "1回目終了")
        XCTAssertEqual(single.log[times[2]], .startRun(2), "2回目スタート")
        XCTAssertEqual(single.log[times[3]], .endSleep(2), "2回目終了")
        XCTAssertEqual(times.count, 4, "Logは4つ")
        
        /// １回目と2回目でそれぞれの結果が返ってきていることを確認
        XCTAssertEqual(firstResult, .endSleep(1))
        XCTAssertEqual(secondResult, .endSleep(2))
    }
}
