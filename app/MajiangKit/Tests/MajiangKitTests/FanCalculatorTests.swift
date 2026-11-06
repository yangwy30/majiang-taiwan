import XCTest
@testable import MajiangKit

final class FanCalculatorTests: XCTestCase {
    func testTaiwaneseTaiTableBasics() {
        XCTAssertEqual(Fan.dealer.points, 1)
        XCTAssertEqual(Fan.dealerStreak.points, 2)
        XCTAssertEqual(Fan.concealedHand.points, 1)
        XCTAssertEqual(Fan.selfDrawn.points, 1)
        XCTAssertEqual(Fan.concealedSelfDrawn.points, 3)
        XCTAssertEqual(Fan.allMelded.points, 2)
        XCTAssertEqual(Fan.halfMelded.points, 1)
        XCTAssertEqual(Fan.pingHu.points, 2)
        XCTAssertEqual(Fan.allPungs.points, 4)
        XCTAssertEqual(Fan.halfFlush.points, 4)
        XCTAssertEqual(Fan.fullFlush.points, 8)
        XCTAssertEqual(Fan.allHonors.points, 16)
        XCTAssertEqual(Fan.threeConcealedPungs.points, 2)
        XCTAssertEqual(Fan.fourConcealedPungs.points, 5)
        XCTAssertEqual(Fan.fiveConcealedPungs.points, 8)
        XCTAssertEqual(Fan.liguLigu.points, 8)
        XCTAssertEqual(Fan.seatFlower.points, 1)
        XCTAssertEqual(Fan.flowerSet.points, 2)
        XCTAssertEqual(Fan.eightImmortals.points, 8)
        XCTAssertEqual(Fan.sevenRobbingOne.points, 8)
        XCTAssertEqual(Fan.littleThreeDragons.points, 4)
        XCTAssertEqual(Fan.bigThreeDragons.points, 8)
        XCTAssertEqual(Fan.littleFourWinds.points, 8)
        XCTAssertEqual(Fan.bigFourWinds.points, 16)
    }

    func testMenzenTsumoIsThreeTai() throws {
        // 门清一摸三（3 台）：门前清 17 张自摸（不混花色、含刻子避免平胡）
        let hand = Hand(concealed: Tile.parseList("111m 234m 456p 678s 234s 99p"), winningTile: Tile(.bamboo, 2))
        let result = try FanCalculator.score(hand, context: WinContext(selfDrawn: true)).get()
        XCTAssertTrue(result.contains(.concealedSelfDrawn))
        XCTAssertFalse(result.contains(.concealedHand))
        XCTAssertFalse(result.contains(.selfDrawn))
        XCTAssertEqual(result.totalFan, 3)
    }

    func testPingHuStrictAndLenient() throws {
        // 5 组全顺子 + 无花 + 无字 + 两面听（23m 听 1/4m）
        let hand = Hand(concealed: Tile.parseList("234m 456m 234p 678p 345s 66s"), winningTile: Tile(.characters, 4))

        // 闲家、他人放枪：门清(1) + 平胡(2) = 3 台
        let ronResult = try FanCalculator.score(hand, context: WinContext(selfDrawn: false, isDealer: false, strictPingHu: true)).get()
        XCTAssertTrue(ronResult.contains(.pingHu))
        XCTAssertTrue(ronResult.contains(.concealedHand))
        XCTAssertEqual(ronResult.totalFan, 3)

        // 严格平胡下：自摸不计平胡，庄家不计平胡，有花不计平胡
        let tsumoStrict = try FanCalculator.score(hand, context: WinContext(selfDrawn: true, isDealer: false, strictPingHu: true)).get()
        XCTAssertFalse(tsumoStrict.contains(.pingHu))

        let dealerStrict = try FanCalculator.score(hand, context: WinContext(selfDrawn: false, isDealer: true, strictPingHu: true)).get()
        XCTAssertFalse(dealerStrict.contains(.pingHu))

        let flowerStrict = try FanCalculator.score(hand, context: WinContext(selfDrawn: false, flowers: [.spring], strictPingHu: true)).get()
        XCTAssertFalse(flowerStrict.contains(.pingHu))

        // 宽松平胡下：自摸也可计平胡
        let tsumoLenient = try FanCalculator.score(hand, context: WinContext(selfDrawn: true, isDealer: false, strictPingHu: false)).get()
        XCTAssertTrue(tsumoLenient.contains(.pingHu))
    }

    func testDealerAndStreakTai() throws {
        // 庄家连二拉二（庄家 1 台 + 连2拉2 4 台 = 5 台）+ 门清(1) = 6 台
        let hand = Hand(concealed: Tile.parseList("111m 234m 456p 678s 234s 99p"), winningTile: Tile(.bamboo, 4))
        let context = WinContext(selfDrawn: false, isDealer: true, streakCount: 2)
        let result = try FanCalculator.score(hand, context: context).get()
        XCTAssertTrue(result.contains(.dealer))
        XCTAssertTrue(result.contains(.dealerStreak))
        XCTAssertEqual(result.dealerFan, 5)
        XCTAssertEqual(result.totalFan, 6)
    }

    func testUniqueWaitSingleEdgeClosed() throws {
        // 边张独听：12m 独听 3m（只听 3m 一张）
        let edgeHand = Hand(concealed: Tile.parseList("123m 456p 789p 234s 678s 99s"), winningTile: Tile(.characters, 3))
        let edgeRes = try FanCalculator.score(edgeHand, context: WinContext(selfDrawn: false)).get()
        XCTAssertTrue(edgeRes.contains(.edgeWait))

        // 坎张独听：24m 独听 3m
        let closedHand = Hand(concealed: Tile.parseList("234m 456p 789p 234s 678s 99s"), winningTile: Tile(.characters, 3))
        let closedRes = try FanCalculator.score(closedHand, context: WinContext(selfDrawn: false)).get()
        XCTAssertTrue(closedRes.contains(.closedWait))

        // 单吊独听：11m 单吊 1m（与 456m 不相连，唯一听 1m）
        let singleHand = Hand(concealed: Tile.parseList("456m 456p 789p 234s 678s 11m"), winningTile: Tile(.characters, 1))
        let singleRes = try FanCalculator.score(singleHand, context: WinContext(selfDrawn: false)).get()
        XCTAssertTrue(singleRes.contains(.singleWait))
    }

    func testAllMeldedAndHalfMelded() throws {
        let melds: [Meld] = [
            .chow(Tile(.characters, 1))!,
            .chow(Tile(.characters, 4))!,
            .pung(Tile(.dots, 2)),
            .pung(Tile(.bamboo, 5)),
            .pung(Tile(.bamboo, 8))
        ]
        let hand = Hand(melds: melds, concealed: Tile.parseList("99p"), winningTile: Tile(.dots, 9))

        // 全求人（他人放枪）：2 台，不重复计单吊
        let ronRes = try FanCalculator.score(hand, context: WinContext(selfDrawn: false)).get()
        XCTAssertTrue(ronRes.contains(.allMelded))
        XCTAssertFalse(ronRes.contains(.singleWait))
        XCTAssertEqual(ronRes.totalFan, 2)

        // 半求人（自摸）：半求人 1 台 + 自摸 1 台 = 2 台
        let tsumoRes = try FanCalculator.score(hand, context: WinContext(selfDrawn: true)).get()
        XCTAssertTrue(tsumoRes.contains(.halfMelded))
        XCTAssertTrue(tsumoRes.contains(.selfDrawn))
        XCTAssertEqual(tsumoRes.totalFan, 2)
    }

    func testLiguLiguEightTai() throws {
        // 呖咕呖咕（7 对子 + 1 刻子 = 17 张，8 台）
        let hand = Hand(concealed: Tile.parseList("111m 22m 44m 66p 88p 33s 55s 77s"), winningTile: Tile(.bamboo, 7))
        let result = try FanCalculator.score(hand, context: WinContext(selfDrawn: false)).get()
        XCTAssertTrue(result.contains(.liguLigu))
        XCTAssertTrue(result.contains(.concealedHand))
        XCTAssertEqual(result.totalFan, 9)
    }

    func testFlowersSeatFlowerSetAndEightImmortals() throws {
        let hand = Hand(concealed: Tile.parseList("111m 234m 456p 678s 234s 99p"), winningTile: Tile(.bamboo, 2))

        // 东家（1 花）摸到春、梅（2 朵正花）+ 夏（非正花不计台）：正花 ×2 = 2 台
        let eastFlowers: Set<FlowerTile> = [.spring, .plum, .summer]
        let res1 = try FanCalculator.score(hand, context: WinContext(seatWind: .east, selfDrawn: false, flowers: eastFlowers)).get()
        XCTAssertTrue(res1.contains(.seatFlower))
        XCTAssertEqual(res1.computedFlowerTai, 2)

        // 春夏秋冬全齐（花杠 2 台）+ 梅（东家正花 1 台）= 3 台花
        let seasonSetPlusPlum: Set<FlowerTile> = [.spring, .summer, .autumn, .winter, .plum]
        let res2 = try FanCalculator.score(hand, context: WinContext(seatWind: .east, selfDrawn: false, flowers: seasonSetPlusPlum)).get()
        XCTAssertTrue(res2.contains(.flowerSet))
        XCTAssertTrue(res2.contains(.seatFlower))
        XCTAssertEqual(res2.computedFlowerTai, 3)

        // 8 朵花全齐：八仙过海 8 台
        let allEight = Set(FlowerTile.allCases)
        let res3 = try FanCalculator.score(hand, context: WinContext(seatWind: .east, selfDrawn: false, flowers: allEight)).get()
        XCTAssertTrue(res3.contains(.eightImmortals))
        XCTAssertEqual(res3.computedFlowerTai, 8)
    }

    func testThreeFourFiveConcealedPungsAndAllPungs() throws {
        // 5 组暗刻单吊将眼：放枪也是五暗刻（8 台）+ 碰碰胡（4 台）+ 门清（1 台）+ 单吊（1 台）= 14 台
        let fiveAnkou = Hand(concealed: Tile.parseList("111m 333p 555s 777m 222s 99p"), winningTile: Tile(.dots, 9))
        let tankiRon = try FanCalculator.score(fiveAnkou, context: WinContext(selfDrawn: false)).get()
        XCTAssertTrue(tankiRon.contains(.fiveConcealedPungs))
        XCTAssertTrue(tankiRon.contains(.allPungs))

        // 双碰听牌放枪胡 2s：222s 算明刻，故为四暗刻（5 台）+ 碰碰胡（4 台）+ 门清（1 台）= 10 台
        let shanponRon = Hand(concealed: Tile.parseList("111m 333p 555s 777m 222s 99p"), winningTile: Tile(.bamboo, 2))
        let ronRes = try FanCalculator.score(shanponRon, context: WinContext(selfDrawn: false)).get()
        XCTAssertTrue(ronRes.contains(.fourConcealedPungs))
        XCTAssertTrue(ronRes.contains(.allPungs))

        // 双碰听牌自摸 2s：五暗刻（8 台）+ 碰碰胡（4 台）+ 门清一摸三（3 台）= 15 台
        let tsumoRes = try FanCalculator.score(shanponRon, context: WinContext(selfDrawn: true)).get()
        XCTAssertTrue(tsumoRes.contains(.fiveConcealedPungs))
        XCTAssertTrue(tsumoRes.contains(.allPungs))
        XCTAssertTrue(tsumoRes.contains(.concealedSelfDrawn))
        XCTAssertEqual(tsumoRes.totalFan, 15)
    }

    func testDragonsAndWinds() throws {
        // 大三元（8 台，不另计中发白单刻）
        let bigDragons = Hand(concealed: Tile.parseList("中中中 发发发 白白白 123m 456p 99s"), winningTile: Tile(.bamboo, 9))
        let bigRes = try FanCalculator.score(bigDragons, context: WinContext(selfDrawn: false)).get()
        XCTAssertTrue(bigRes.contains(.bigThreeDragons))
        XCTAssertFalse(bigRes.contains(.redDragon))

        // 小三元（4 台）
        let littleDragons = Hand(concealed: Tile.parseList("中中中 发发发 白白 123m 456p 789s"), winningTile: Tile(.bamboo, 9))
        let littleRes = try FanCalculator.score(littleDragons, context: WinContext(selfDrawn: false)).get()
        XCTAssertTrue(littleRes.contains(.littleThreeDragons))

        // 双风刻（东圈东家摸东刻 = 圈风刻 1 台 + 门风刻 1 台 = 2 台）
        let doubleEast = Hand(concealed: Tile.parseList("东东东 234m 456p 678s 234s 1p1p"), winningTile: Tile(.dots, 1))
        let eastResult = try FanCalculator.score(doubleEast, context: WinContext(prevalentWind: .east, seatWind: .east)).get()
        XCTAssertTrue(eastResult.contains(.prevalentWind))
        XCTAssertTrue(eastResult.contains(.seatWind))
    }

    func testErrors() {
        // 14 张在台湾 16 张麻将中因张数不对报错
        let short14 = Hand(concealed: Tile.parseList("123m 456m 789m 123p 11p"))
        XCTAssertEqual(FanCalculator.score(short14, context: WinContext()).failure, .wrongTileCount)

        let five = Hand(concealed: Tile.parseList("11111m 456m 789m 123p 456s"))
        XCTAssertEqual(FanCalculator.score(five, context: WinContext()).failure, .tileMoreThanFour)

        let noWin = Hand(concealed: Tile.parseList("13579m 2468p 13579s 东南西"))
        XCTAssertEqual(FanCalculator.score(noWin, context: WinContext()).failure, .notAWin)
    }

    func testWaitingTiles16() {
        // 16 张听牌：3 组顺子/刻子 + 九莲宝灯 13 张听 1..9m
        let waits = FanCalculator.waitingTiles(melds: [], standing: Tile.parseList("111p 1112345678999m"))
        XCTAssertEqual(waits, (1...9).map { Tile(.characters, $0) })
    }
}

extension Result {
    var failure: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
