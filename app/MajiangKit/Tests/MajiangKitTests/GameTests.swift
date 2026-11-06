import XCTest
@testable import MajiangKit

final class GameTests: XCTestCase {
    private func makeGame(swap: Bool = false) -> Game {
        var rules = GameRules()
        rules.swapSeatsEachRound = swap
        rules.yuanPerPoint = 1
        return Game(players: ["杨", "小周", "阿乐", "老王"].map { Player(name: $0) }, rules: rules)
    }

    private func win(_ winner: Int, discarder: Int?, fan: Int, flowers: Int = 0) -> WinRecord {
        WinRecord(
            winner: winner,
            discarder: discarder,
            hand: nil,
            context: WinContext(flowerCount: flowers),
            fans: [FanEntry(fan: .allPungs, count: 1, han: max(0, fan - flowers))],
            flowerFan: flowers
        )
    }

    func testTaiwaneseBasePlusTaiAndStreakPayments() {
        // 默认 300/100（底 300，每台 100）
        // 1. 闲家(2) 胡 闲家(1) 放枪 4 台（不计庄家台）：300 + 4×100 = 700
        XCTAssertEqual(
            Payment.winDeltas(winner: 2, discarder: 1, dealer: 0, streak: 2, totalFan: 4),
            [0, -700, 700, 0]
        )

        // 2. 庄家(0，连一拉一 streak=1，庄家连拉 3 台) 胡 闲家(1) 放枪，牌型 4 台：300 + (4+3)×100 = 1000
        XCTAssertEqual(
            Payment.winDeltas(winner: 0, discarder: 1, dealer: 0, streak: 1, totalFan: 4),
            [1000, -1000, 0, 0]
        )

        // 3. 闲家(2) 胡 庄家(0，连二拉二 streak=2，庄家连拉 5 台) 放枪，牌型 4 台：300 + (4+5)×100 = 1200
        XCTAssertEqual(
            Payment.winDeltas(winner: 2, discarder: 0, dealer: 0, streak: 2, totalFan: 4),
            [-1200, 0, 1200, 0]
        )

        // 4. 庄家(0，首庄 streak=0，庄家 1 台) 自摸，牌型 4 台：三家各付 300 + (4+1)×100 = 800
        XCTAssertEqual(
            Payment.winDeltas(winner: 0, discarder: nil, dealer: 0, streak: 0, totalFan: 4),
            [2400, -800, -800, -800]
        )

        // 5. 闲家(2) 自摸，牌型 4 台，庄家(0) 连一拉一（+3 台）：
        //    两闲家(1, 3) 各付 300 + 4×100 = 700；庄家(0) 付 300 + (4+3)×100 = 1000
        XCTAssertEqual(
            Payment.winDeltas(winner: 2, discarder: nil, dealer: 0, streak: 1, totalFan: 4),
            [-1000, -700, 2400, -700]
        )

        // 诈胡罚分：赔三家各 800 分
        XCTAssertEqual(Payment.falseWinDeltas(offender: 3, penalty: 800), [800, 800, 800, -2400])
    }

    func testPresetsAndFanCap() {
        var rules = GameRules.standard
        rules.yuanPerPoint = 2
        XCTAssertTrue(rules.scoresLike(.standard), "汇率不算桌规差异")
        XCTAssertEqual(GameRules.standard.basePoints, 300)
        XCTAssertEqual(GameRules.standard.taiPoints, 100)
        XCTAssertEqual(GameRules.beginner.basePoints, 100)
        XCTAssertEqual(GameRules.beginner.taiPoints, 20)
        XCTAssertEqual(GameRules.casual.basePoints, 50)
        XCTAssertEqual(GameRules.casual.taiPoints, 20)
        XCTAssertEqual(GameRules.standard.totalHands, 16)
        XCTAssertEqual(GameRules.standard.minimumFan, 0)

        // 封顶 8 台：闲家互放枪 12 台按 8 台算 -> 300 + 8×100 = 1100
        var capped = GameRules.standard
        capped.fanCap = 8
        XCTAssertEqual(
            Payment.winDeltas(winner: 3, discarder: 2, dealer: 0, totalFan: 12, rules: capped),
            [0, 0, -1100, 1100]
        )
    }

    func testDealerStreakAndRotationRules() throws {
        var game = makeGame()
        XCTAssertEqual(game.dealer, 0)
        XCTAssertEqual(game.currentStreak, 0)
        XCTAssertEqual(game.prevalentWind, .east)
        XCTAssertEqual((0..<4).map { game.seatWind(of: $0) }, [.east, .south, .west, .north])

        // 1. 庄家(0) 胡牌 -> 庄家连庄（连一拉一），座位门风不变
        try game.recordWin(win(0, discarder: 1, fan: 2))
        XCTAssertEqual(game.dealer, 0)
        XCTAssertEqual(game.currentStreak, 1)
        XCTAssertEqual(game.dealerTai(ofHand: game.currentHandIndex), 3)
        XCTAssertEqual((0..<4).map { game.seatWind(of: $0) }, [.east, .south, .west, .north])

        // 2. 流局（臭庄） -> 庄家继续连庄（连二拉二），庄家连拉变 5 台
        try game.recordDraw()
        XCTAssertEqual(game.dealer, 0)
        XCTAssertEqual(game.currentStreak, 2)
        XCTAssertEqual(game.dealerTai(ofHand: game.currentHandIndex), 5)

        // 3. 闲家(2) 自摸 2 台 -> 庄家(0) 额外付连二拉二 5 台（共 7 台 = 1000），两闲家各付 2 台（500），随后庄家下庄！
        try game.recordWin(win(2, discarder: nil, fan: 2))
        XCTAssertEqual(game.records.last?.deltas, [-1000, -500, 2000, -500])
        XCTAssertEqual(game.dealer, 1, "闲家胡牌后下庄轮转至 1 号玩家")
        XCTAssertEqual(game.currentStreak, 0, "新庄家连庄数归零")
        XCTAssertEqual((0..<4).map { game.seatWind(of: $0) }, [.north, .east, .south, .west])
    }

    func testChangingRulesRecomputesEveryHand() throws {
        var game = makeGame()
        // 闲家 2 胡 闲家 1 放枪 4 台：默认 300/100 付 700
        try game.recordWin(win(2, discarder: 1, fan: 4))
        XCTAssertEqual(game.scores, [0, -700, 700, 0])

        // 改成 100/20：100 + 4×20 = 180
        let rules100_20 = GameRules.beginner
        let preview = try game.changingRules(rules100_20)
        XCTAssertEqual(preview.scores, [0, -180, 180, 0])
        XCTAssertEqual(game.scores, [0, -700, 700, 0], "预览不改原来的牌局")

        try game.changeRules(rules100_20)
        XCTAssertEqual(game.scores, [0, -180, 180, 0])
        XCTAssertEqual(game.scores.reduce(0, +), 0)

        // 中途改成不计花牌：去掉花牌台数再算
        var flowerGame = makeGame()
        try flowerGame.recordWin(win(2, discarder: 1, fan: 5, flowers: 2)) // 含 2 朵花共 5 台 = 800
        XCTAssertEqual(flowerGame.scores[2], 800)
        var noFlowers = flowerGame.rules
        noFlowers.includeFlowers = false
        try flowerGame.changeRules(noFlowers)
        XCTAssertEqual(flowerGame.scores[2], 600) // 去掉 2 台花变 3 台 = 300 + 300 = 600
    }

    func testEditingAnEarlierWinRecomputesStreakAndLedger() throws {
        var game = makeGame()
        // 第 1 局：庄家(0) 胡 1 放枪 2 台（含庄家 1 台 -> 300 + 300 = 600），进入连一拉一
        let first = try game.recordWin(win(0, discarder: 1, fan: 2))
        // 第 2 局（此时庄 0 连一拉一 +3 台）：闲家 2 自摸 2 台 -> 庄 0 付 300+500=800，闲 1/3 各付 300+200=500
        try game.recordWin(win(2, discarder: nil, fan: 2))
        XCTAssertEqual(game.records[1].deltas, [-800, -500, 1800, -500])

        // 把第 1 局改成闲家 2 胡 3 放枪 2 台 -> 第 1 局庄家下庄，第 2 局变成庄家 1 首庄（+1 台）！
        var fixed = win(2, discarder: 3, fan: 2)
        fixed.context = game.records[0].outcome.win!.context
        try game.replace(first.id, with: .win(fixed))
        XCTAssertEqual(game.records[0].deltas, [0, 0, 500, -500])
        // 第 2 局此时庄家是 1（首庄 +1 台），闲家 2 自摸 2 台 -> 庄 1 付 600，闲 0/3 各付 500
        XCTAssertEqual(game.records[1].deltas, [-500, -600, 1600, -500])
    }

    func testRemovingAHandMovesLaterWinsAndRescoresWinds() throws {
        var game = makeGame()
        // 第 1 局闲家 2 胡牌，使庄家下庄到 1 号玩家
        let first = try game.recordWin(win(2, discarder: 0, fan: 1))
        // 第 2 局（庄 1）老王（下标 3，此时门风为西）胡牌：西风刻
        let tiles = Hand(concealed: Tile.parseList("西西西 白白白 123m 456m 789p 9m9m"), winningTile: Tile(.characters, 9))
        let context = game.winContext(for: 3)
        let result = try FanCalculator.score(tiles, context: context).get()
        XCTAssertTrue(result.contains(.seatWind))
        try game.recordWin(WinRecord(winner: 3, discarder: 0, hand: tiles, context: context, result: result))

        game.remove(first.id)
        XCTAssertEqual(game.records.count, 1)
        XCTAssertEqual(game.records[0].handIndex, 0)
        let moved = try XCTUnwrap(game.records[0].outcome.win)
        XCTAssertEqual(moved.context.seatWind, .north, "挪回第一局，老王是北家")
        XCTAssertFalse(moved.fans.contains { $0.fan == .seatWind })
    }

    func testGameFinishesAfterSixteenRotations() throws {
        var game = makeGame()
        for _ in 0..<16 {
            let nonDealer = (game.dealer + 1) % 4
            try game.recordWin(win(nonDealer, discarder: game.dealer, fan: 1))
        }
        XCTAssertTrue(game.isFinished)
        XCTAssertThrowsError(try game.recordDraw())
    }

    func testFixSuggestionsFindMisreadPip17Tiles() {
        let tiles = Tile.parseList("111p 234p 567p 123m 999p 5p 4p") // 4p 应为 5p（共 17 张）
        let hand = Hand(concealed: tiles, winningTile: tiles.last)
        let suggestions = WinAssistant.fixSuggestions(for: hand, context: WinContext())
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertEqual(suggestions.first?.from?.suit, .dots)
        XCTAssertEqual(suggestions.first.map { abs($0.from!.rank - $0.to.rank) }, 1)

        // 少读一张（16 张）：补一张就能胡
        let short = Hand(concealed: Tile.parseList("111p 234p 567p 123m 999p 5p"), winningTile: Tile(.dots, 5))
        let add = WinAssistant.fixSuggestions(for: short, context: WinContext())
        XCTAssertTrue(add.contains { $0.to == Tile(.dots, 5) })
        XCTAssertTrue(add.allSatisfy { $0.index == nil })
    }
}

final class ArchiveAndParsingTests: XCTestCase {
    func testOldArchiveWithMissingFieldsStillLoads() throws {
        let json = #"{"games":[{"id":"6E897041-FD3D-4426-B080-2D7BC6E72995","startedAt":"2026-10-26T04:00:00Z","players":[{"id":"6E897041-FD3D-4426-B080-2D7BC6E72991","name":"a"},{"id":"6E897041-FD3D-4426-B080-2D7BC6E72992","name":"b"},{"id":"6E897041-FD3D-4426-B080-2D7BC6E72993","name":"c"},{"id":"6E897041-FD3D-4426-B080-2D7BC6E72994","name":"d"}],"rules":{"yuanPerPoint":2}}]}"#
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let archive = try decoder.decode(GameArchive.self, from: Data(json.utf8))
        XCTAssertEqual(archive.games.first?.rules.yuanPerPoint, 2)
        XCTAssertEqual(archive.games.first?.rules.totalHands, 16)
        XCTAssertEqual(archive.version, 1)
        XCTAssertEqual(archive.games.first?.me, 0)
    }

    func testSpecialWinConflicts() {
        XCTAssertTrue(SpecialWin.kongReplacement.conflicts.contains(.lastTileDraw))
        XCTAssertTrue(SpecialWin.lastTileClaim.conflicts.contains(.robbingTheKong))
        XCTAssertTrue(SpecialWin.tenhou.conflicts.contains(.chiihou))
    }
}

private extension HandOutcome {
    var win: WinRecord? {
        if case .win(let win) = self { return win }
        return nil
    }
}
