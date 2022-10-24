import XCTest
@testable import SingleRunnable

final class SingleRunnableTests: XCTestCase {
    enum RunState: Hashable {
        case startRun(Int)
        case endSleep(Int)
    }
    
    class SingleTaskCounter: SingleRunnable {
        var log: [Date: RunState] = [:]
        func run(_ count: Int) async throws -> RunState {
            log[Date()] = .startRun(count)
            return try await Self.singleRun(name: "\(Self.self)") { [weak self] in
                self?.log[Date()] = .endSleep(count)
                return .endSleep(count)
            }
        }
    }
    
    func test並列で２度実行した場合() async throws {
        let single = SingleTaskCounter()
        async let firstTask = single.run(1)
        async let secondTask = single.run(2)
        let (firstResult, secondResult) = try await (firstTask, secondTask)
        
        // Logの順番を確認。2回目スタート後に1回目が終了することで並列で処理されていることが確認できる。
        let times = single.log.keys.sorted()
        XCTAssertEqual(single.log[times[0]], .startRun(1), "1回目スタート")
        XCTAssertEqual(single.log[times[1]], .startRun(2), "2回目スタート")
        XCTAssertEqual(single.log[times[2]], .endSleep(1), "1回目終了")
        XCTAssertEqual(times.count, 3, "Logは3つのみ（2回目は1回目の処理の結果を受け取るのでTaskを作成しない）")
        
        // ２回目も１回目の結果が返ってきていることを確認
        XCTAssertEqual(firstResult, .endSleep(1))
        XCTAssertEqual(secondResult, .endSleep(1))
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
