import Foundation

/// 照片拍不出来、要从牌局或用户确认里拿的台湾 16 张麻将算台条件。
public struct WinContext: Hashable, Codable, Sendable {
    public var prevalentWind: Wind
    public var seatWind: Wind
    public var selfDrawn: Bool
    /// 是否为本局庄家。
    public var isDealer: Bool
    /// 庄家连庄次数（连 N 拉 N 中的 N，庄家连拉共 `2N + 1` 台）。
    public var streakCount: Int
    /// 摸到的具体花牌集合（春夏秋冬 / 梅兰竹菊）。
    public var flowers: Set<FlowerTile>
    /// 花牌数量或正花台数（当未指定具体 `flowers` 集合时的兜底计数）。
    public var flowerCount: Int
    /// 是否启用严格平胡（无花、无字、全顺子、两面听、非庄家、他人放枪不自摸）。
    public var strictPingHu: Bool
    /// 海底捞月（自摸）/ 河底捞鱼（放枪）。
    public var lastTileOfWall: Bool
    /// 兼容旧字段。
    public var lastTileOfItsKind: Bool
    /// 杠上开花（自摸）/ 抢杠（放枪）。
    public var kongInvolved: Bool
    /// 天胡（庄家起手配牌直接胡牌，16 台）。
    public var tenhou: Bool
    /// 地胡（闲家首巡摸第一张牌自摸，16 台）。
    public var chiihou: Bool
    /// 人胡（首巡胡别人打出的第一张牌，8 台）。
    public var renhou: Bool
    /// 七抢一（持 7 朵花抢别人第 8 朵花，8 台）。
    public var sevenRobbingOne: Bool
    /// 八仙过海（持全部 8 朵花胡牌，8 台）。
    public var eightImmortals: Bool

    // 兼容旧字段
    public var riichi: Bool
    public var doubleRiichi: Bool
    public var ippatsu: Bool

    public init(
        prevalentWind: Wind = .east,
        seatWind: Wind = .east,
        selfDrawn: Bool = false,
        isDealer: Bool = false,
        streakCount: Int = 0,
        flowers: Set<FlowerTile> = [],
        flowerCount: Int = 0,
        strictPingHu: Bool = true,
        lastTileOfWall: Bool = false,
        lastTileOfItsKind: Bool = false,
        kongInvolved: Bool = false,
        tenhou: Bool = false,
        chiihou: Bool = false,
        renhou: Bool = false,
        sevenRobbingOne: Bool = false,
        eightImmortals: Bool = false,
        riichi: Bool = false,
        doubleRiichi: Bool = false,
        ippatsu: Bool = false
    ) {
        self.prevalentWind = prevalentWind
        self.seatWind = seatWind
        self.selfDrawn = selfDrawn
        self.isDealer = isDealer
        self.streakCount = streakCount
        self.flowers = flowers
        self.flowerCount = flowerCount
        self.strictPingHu = strictPingHu
        self.lastTileOfWall = lastTileOfWall
        self.lastTileOfItsKind = lastTileOfItsKind
        self.kongInvolved = kongInvolved
        self.tenhou = tenhou
        self.chiihou = chiihou
        self.renhou = renhou
        self.sevenRobbingOne = sevenRobbingOne
        self.eightImmortals = eightImmortals
        self.riichi = riichi
        self.doubleRiichi = doubleRiichi
        self.ippatsu = ippatsu
    }

    enum CodingKeys: String, CodingKey {
        case prevalentWind, seatWind, selfDrawn, isDealer, streakCount
        case flowers, flowerCount, strictPingHu
        case lastTileOfWall, lastTileOfItsKind, kongInvolved
        case tenhou, chiihou, renhou, sevenRobbingOne, eightImmortals
        case riichi, doubleRiichi, ippatsu
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        prevalentWind = try c.decodeIfPresent(Wind.self, forKey: .prevalentWind) ?? .east
        seatWind = try c.decodeIfPresent(Wind.self, forKey: .seatWind) ?? .east
        selfDrawn = try c.decodeIfPresent(Bool.self, forKey: .selfDrawn) ?? false
        isDealer = try c.decodeIfPresent(Bool.self, forKey: .isDealer) ?? false
        streakCount = try c.decodeIfPresent(Int.self, forKey: .streakCount) ?? 0
        flowers = try c.decodeIfPresent(Set<FlowerTile>.self, forKey: .flowers) ?? []
        flowerCount = try c.decodeIfPresent(Int.self, forKey: .flowerCount) ?? 0
        strictPingHu = try c.decodeIfPresent(Bool.self, forKey: .strictPingHu) ?? true
        lastTileOfWall = try c.decodeIfPresent(Bool.self, forKey: .lastTileOfWall) ?? false
        lastTileOfItsKind = try c.decodeIfPresent(Bool.self, forKey: .lastTileOfItsKind) ?? false
        kongInvolved = try c.decodeIfPresent(Bool.self, forKey: .kongInvolved) ?? false
        tenhou = try c.decodeIfPresent(Bool.self, forKey: .tenhou) ?? false
        chiihou = try c.decodeIfPresent(Bool.self, forKey: .chiihou) ?? false
        renhou = try c.decodeIfPresent(Bool.self, forKey: .renhou) ?? false
        sevenRobbingOne = try c.decodeIfPresent(Bool.self, forKey: .sevenRobbingOne) ?? false
        eightImmortals = try c.decodeIfPresent(Bool.self, forKey: .eightImmortals) ?? false
        riichi = try c.decodeIfPresent(Bool.self, forKey: .riichi) ?? false
        doubleRiichi = try c.decodeIfPresent(Bool.self, forKey: .doubleRiichi) ?? false
        ippatsu = try c.decodeIfPresent(Bool.self, forKey: .ippatsu) ?? false
    }
}

public struct ScoringResult: Hashable, Codable, Sendable {
    public let fans: [FanEntry]
    /// 额外附加花台（当花牌已作为 `.seatFlower` / `.flowerSet` / `.eightImmortals` 计入 `fans` 时为 0）。
    public let flowerFan: Int
    /// 兼容字段（台湾麻将不使用符数，固定为 0）。
    public let fu: Int

    public init(fans: [FanEntry], flowerFan: Int = 0, fu: Int = 0) {
        self.fans = fans
        self.flowerFan = flowerFan
        self.fu = fu
    }

    /// 包含在 `fans` 或 `flowerFan` 中的花牌总台数。
    public var computedFlowerTai: Int {
        flowerFan + fans.filter(\.fan.isFlowerFan).reduce(0) { $0 + $1.points }
    }

    /// 包含在 `fans` 中的庄家与连庄拉庄台数。
    public var dealerFan: Int {
        fans.filter(\.fan.isDealerFan).reduce(0) { $0 + $1.points }
    }

    /// 不含花牌台数的台数合计。
    public var fanWithoutFlowers: Int {
        fans.filter { !$0.fan.isFlowerFan }.reduce(0) { $0 + $1.points }
    }

    /// 含花牌的总台数。
    public var totalFan: Int {
        fans.reduce(0) { $0 + $1.points } + flowerFan
    }

    public var isYakuman: Bool {
        fans.contains { $0.fan.isYakuman }
    }

    /// 够不够起胡台数（台湾麻将默认 0 台即可屁胡）。
    public func meetsMinimum(_ minimum: Int = 0) -> Bool {
        totalFan >= minimum
    }

    public func contains(_ fan: Fan) -> Bool {
        fans.contains { $0.fan == fan }
    }
}

public enum ScoringError: Error, Hashable, Sendable {
    case wrongTileCount
    case tileMoreThanFour
    case notAWin
}

/// 台湾 16 张麻将算台引擎（纯 Swift 实现，5 面子 + 1 眼 = 17 张，支持呖咕呖咕、八仙过海、七抢一）。
public enum FanCalculator {
    public static func score(_ hand: Hand, context: WinContext = WinContext()) -> Result<ScoringResult, ScoringError> {
        guard hand.hasValidTileCount else { return .failure(.wrongTileCount) }
        guard hand.overusedTiles.isEmpty else { return .failure(.tileMoreThanFour) }

        let candidates = evaluateAllCandidates(hand: hand, context: context)
        if let best = candidates.max(by: isBetterCandidate) {
            return .success(best)
        }

        // 八仙过海（8 朵花）或七抢一即使手牌未凑成 5 面子 + 1 眼也可直接胡牌
        if context.eightImmortals || context.flowers.count == 8 || context.flowerCount >= 8 || context.sevenRobbingOne {
            var entries: [FanEntry] = []
            appendDealerFans(to: &entries, context: context)
            appendFlowerFans(to: &entries, context: context)
            let sorted = sortEntries(entries)
            return .success(ScoringResult(fans: sorted, flowerFan: 0, fu: 0))
        }

        return .failure(.notAWin)
    }

    /// 只看 17 张牌型能不能胡（5 面子 + 1 眼，或门清呖咕呖咕）。
    public static func isWinningShape(_ hand: Hand) -> Bool {
        guard hand.hasValidTileCount, hand.overusedTiles.isEmpty else { return false }
        if hand.melds.isEmpty && isLiguLiguShape(hand.concealed) {
            return true
        }
        return !standardDecompositions(concealed: hand.concealed, neededGroups: 5 - hand.melds.count).isEmpty
    }

    /// 16 张待胡牌（含副露时立牌为 `16 - 3 * 副露数`）听哪些牌。已满 4 张的牌不算。
    public static func waitingTiles(melds: [Meld] = [], standing: [Tile]) -> [Tile] {
        guard melds.count * 3 + standing.count == 16, melds.allSatisfy(\.isValid) else { return [] }
        let used = Dictionary(grouping: melds.flatMap(\.tiles) + standing, by: { $0 }).mapValues(\.count)
        guard used.values.allSatisfy({ $0 <= 4 }) else { return [] }

        return Tile.all.filter { candidate in
            guard (used[candidate] ?? 0) < 4 else { return false }
            let hand = Hand(melds: melds, concealed: standing + [candidate], winningTile: candidate)
            return isWinningShape(hand)
        }
    }

    // MARK: - 高点法候选评估

    private static func isBetterCandidate(_ a: ScoringResult, _ b: ScoringResult) -> Bool {
        if a.totalFan != b.totalFan { return a.totalFan < b.totalFan }
        return a.fans.count < b.fans.count
    }

    private static func evaluateAllCandidates(hand: Hand, context: WinContext) -> [ScoringResult] {
        var results: [ScoringResult] = []
        let isMenzen = hand.melds.allSatisfy { $0.kind == .kong && $0.isConcealed }

        // 计算听牌张数量，以判断是否为真独听（只听唯一 1 种牌）
        let isUniqueWait: Bool = {
            var standing = hand.concealed
            guard let winIdx = standing.lastIndex(of: hand.winningTile) else { return false }
            standing.remove(at: winIdx)
            return waitingTiles(melds: hand.melds, standing: standing).count == 1
        }()

        // 1. 呖咕呖咕（门前清 7 对子 + 1 刻子 = 17 张）
        if hand.melds.isEmpty && isLiguLiguShape(hand.concealed) {
            results.append(scoreLiguLigu(hand: hand, context: context))
        }

        // 2. 标准形（5 面子 + 1 眼 = 17 张）
        let needed = 5 - hand.melds.count
        let decomps = standardDecompositions(concealed: hand.concealed, neededGroups: needed)
        let winTile = hand.winningTile
        for decomp in decomps {
            var targets = Set<WaitTarget>()
            if decomp.pair == winTile {
                targets.insert(.tanki)
            }
            for (idx, group) in decomp.groups.enumerated() {
                switch group {
                case .pung(let tile) where tile == winTile:
                    targets.insert(.group(index: idx, wait: .shanpon))
                case .chow(let start) where start.suit == winTile.suit && (start.rank...(start.rank + 2)).contains(winTile.rank):
                    let r = start.rank
                    let w = winTile.rank
                    let wait: WaitKind
                    if w == r + 1 {
                        wait = .kanchan
                    } else if (r == 1 && w == 3) || (r == 7 && w == 7) {
                        wait = .penchan
                    } else {
                        wait = .ryanmen
                    }
                    targets.insert(.group(index: idx, wait: wait))
                default:
                    break
                }
            }
            if targets.isEmpty {
                targets.insert(.tanki)
            }
            for target in targets {
                results.append(
                    scoreStandard(
                        hand: hand,
                        decomp: decomp,
                        target: target,
                        isMenzen: isMenzen,
                        isUniqueWait: isUniqueWait,
                        context: context
                    )
                )
            }
        }

        return results
    }

    // MARK: - 牌型拆解

    private enum ConcealedGroup: Hashable {
        case chow(Tile)
        case pung(Tile)
    }

    private struct Decomposition: Hashable {
        var groups: [ConcealedGroup]
        var pair: Tile
    }

    private enum WaitKind: Hashable {
        case ryanmen
        case shanpon
        case kanchan
        case penchan
        case tanki
    }

    private enum WaitTarget: Hashable {
        case tanki
        case group(index: Int, wait: WaitKind)

        var waitKind: WaitKind {
            switch self {
            case .tanki: return .tanki
            case .group(_, let wait): return wait
            }
        }
    }

    /// 呖咕呖咕（八对半）：17 张立牌由 1 组刻子（3 张）加 7 个对子（14 张，允许四张相同牌拆成两对）组成。
    private static func isLiguLiguShape(_ tiles: [Tile]) -> Bool {
        guard tiles.count == 17 else { return false }
        let counts = Dictionary(grouping: tiles, by: { $0 }).mapValues(\.count)
        let oddCounts = counts.values.filter { $0 % 2 == 1 }
        let evenCounts = counts.values.filter { $0 % 2 == 0 }
        return oddCounts == [3] && evenCounts.allSatisfy { $0 == 2 || $0 == 4 }
    }

    private static func standardDecompositions(concealed: [Tile], neededGroups: Int) -> [Decomposition] {
        guard neededGroups >= 0, concealed.count == neededGroups * 3 + 2 else { return [] }
        var counts = [Int](repeating: 0, count: 34)
        for t in concealed { counts[tileIndex(t)] += 1 }

        var unique = Set<Decomposition>()
        for pairIdx in 0..<34 where counts[pairIdx] >= 2 {
            counts[pairIdx] -= 2
            let pairTile = tileFromIndex(pairIdx)
            var current: [ConcealedGroup] = []
            func search(_ remaining: Int) {
                if remaining == 0 {
                    let sortedGroups = current.sorted { lhs, rhs in
                        switch (lhs, rhs) {
                        case (.chow(let a), .chow(let b)): return a < b
                        case (.pung(let a), .pung(let b)): return a < b
                        case (.chow, .pung): return true
                        case (.pung, .chow): return false
                        }
                    }
                    unique.insert(Decomposition(groups: sortedGroups, pair: pairTile))
                    return
                }
                guard let first = counts.firstIndex(where: { $0 > 0 }) else { return }
                let tile = tileFromIndex(first)

                if counts[first] >= 3 {
                    counts[first] -= 3
                    current.append(.pung(tile))
                    search(remaining - 1)
                    current.removeLast()
                    counts[first] += 3
                }

                if first < 27 && (first % 9) <= 6 && counts[first + 1] > 0 && counts[first + 2] > 0 {
                    counts[first] -= 1
                    counts[first + 1] -= 1
                    counts[first + 2] -= 1
                    current.append(.chow(tile))
                    search(remaining - 1)
                    current.removeLast()
                    counts[first] += 1
                    counts[first + 1] += 1
                    counts[first + 2] += 1
                }
            }
            search(neededGroups)
            counts[pairIdx] += 2
        }
        return Array(unique)
    }

    private static func tileIndex(_ tile: Tile) -> Int {
        (tile.suit.rawValue - 1) * 9 + (tile.rank - 1)
    }

    private static func tileFromIndex(_ index: Int) -> Tile {
        let suit = Suit(rawValue: (index / 9) + 1)!
        return Tile(suit, (index % 9) + 1)
    }

    // MARK: - 呖咕呖咕计台

    private static func scoreLiguLigu(hand: Hand, context: WinContext) -> ScoringResult {
        var entries: [FanEntry] = []
        appendDealerFans(to: &entries, context: context)
        appendSpecialWinFans(to: &entries, isMenzen: true, isAllOpenMelds: false, context: context)
        entries.append(FanEntry(fan: .liguLigu))
        appendFlushFans(to: &entries, allTiles: hand.allTiles)
        appendFlowerFans(to: &entries, context: context)

        let sorted = sortEntries(entries)
        return ScoringResult(fans: sorted, flowerFan: 0, fu: 0)
    }

    // MARK: - 标准形计台（5 面子 + 1 眼）

    private struct ResolvedGroup {
        enum Kind {
            case chow(Tile)
            case triplet(Tile, isConcealed: Bool, isKong: Bool)
        }
        var kind: Kind

        var isChow: Bool {
            if case .chow = kind { return true }
            return false
        }

        var tripletTile: Tile? {
            if case .triplet(let t, _, _) = kind { return t }
            return nil
        }

        var isConcealedTriplet: Bool {
            if case .triplet(_, let isConcealed, _) = kind { return isConcealed }
            return false
        }
    }

    private static func scoreStandard(
        hand: Hand,
        decomp: Decomposition,
        target: WaitTarget,
        isMenzen: Bool,
        isUniqueWait: Bool,
        context: WinContext
    ) -> ScoringResult {
        var groups: [ResolvedGroup] = []
        for meld in hand.melds {
            switch meld.kind {
            case .chow:
                groups.append(ResolvedGroup(kind: .chow(meld.tiles[0])))
            case .pung:
                groups.append(ResolvedGroup(kind: .triplet(meld.tiles[0], isConcealed: false, isKong: false)))
            case .kong:
                groups.append(ResolvedGroup(kind: .triplet(meld.tiles[0], isConcealed: meld.isConcealed, isKong: true)))
            }
        }
        for (idx, g) in decomp.groups.enumerated() {
            switch g {
            case .chow(let s):
                groups.append(ResolvedGroup(kind: .chow(s)))
            case .pung(let t):
                let completedByRon: Bool
                if case .group(let targetIdx, _) = target, targetIdx == idx, !context.selfDrawn {
                    completedByRon = true
                } else {
                    completedByRon = false
                }
                groups.append(ResolvedGroup(kind: .triplet(t, isConcealed: !completedByRon, isKong: false)))
            }
        }

        let pair = decomp.pair
        let wait = target.waitKind
        let allTiles = hand.allTiles

        // 全求人 / 半求人条件：5 组面子全部是副露（且无暗杠），单吊将眼
        let isAllOpenMelds = hand.melds.count == 5 && hand.melds.allSatisfy { !($0.kind == .kong && $0.isConcealed) }

        var entries: [FanEntry] = []

        // 1. 庄家与连拉
        appendDealerFans(to: &entries, context: context)

        // 2. 门清、自摸、全求人、半求人与特殊胡牌状况
        appendSpecialWinFans(to: &entries, isMenzen: isMenzen, isAllOpenMelds: isAllOpenMelds, context: context)

        // 3. 独听（单吊、边张、坎张）——全求人/半求人已隐含单吊，不重复计单吊
        if isUniqueWait && !isAllOpenMelds {
            switch wait {
            case .tanki:
                entries.append(FanEntry(fan: .singleWait))
            case .penchan:
                entries.append(FanEntry(fan: .edgeWait))
            case .kanchan:
                entries.append(FanEntry(fan: .closedWait))
            case .ryanmen, .shanpon:
                break
            }
        }

        // 4. 平胡（无花、无字、5 组全顺子、两面听；严格规矩下须非庄家且他人放枪不自摸）
        let hasNoFlowers = context.flowers.isEmpty && context.flowerCount == 0 && !context.eightImmortals && !context.sevenRobbingOne
        let hasNoHonors = !allTiles.contains(where: \.isHonor)
        let allChows = groups.count == 5 && groups.allSatisfy(\.isChow)
        let isPingHu: Bool = {
            guard hasNoFlowers && hasNoHonors && allChows && wait == .ryanmen else { return false }
            if context.strictPingHu {
                return !context.selfDrawn && !context.isDealer
            }
            return true
        }()
        if isPingHu {
            entries.append(FanEntry(fan: .pingHu))
        }

        // 5. 刻子与字牌相关台种
        let triplets = groups.compactMap(\.tripletTile)
        let tripletSet = Set(triplets)
        let ankouCount = groups.filter(\.isConcealedTriplet).count

        // 三元牌 / 小三元 / 大三元
        let dragons: [Tile] = [Tile(.honors, 5), Tile(.honors, 6), Tile(.honors, 7)]
        let dragonTripletCount = dragons.filter { tripletSet.contains($0) }.count
        if dragonTripletCount == 3 {
            entries.append(FanEntry(fan: .bigThreeDragons))
        } else if dragonTripletCount == 2 && dragons.contains(pair) {
            entries.append(FanEntry(fan: .littleThreeDragons))
        } else {
            if tripletSet.contains(Tile(.honors, 5)) { entries.append(FanEntry(fan: .redDragon)) }
            if tripletSet.contains(Tile(.honors, 6)) { entries.append(FanEntry(fan: .greenDragon)) }
            if tripletSet.contains(Tile(.honors, 7)) { entries.append(FanEntry(fan: .whiteDragon)) }
        }

        // 风牌 / 小四喜 / 大四喜
        let winds: [Tile] = [Tile(.honors, 1), Tile(.honors, 2), Tile(.honors, 3), Tile(.honors, 4)]
        let windTripletCount = winds.filter { tripletSet.contains($0) }.count
        if windTripletCount == 4 {
            entries.append(FanEntry(fan: .bigFourWinds))
        } else if windTripletCount == 3 && winds.contains(pair) {
            entries.append(FanEntry(fan: .littleFourWinds))
        } else {
            for t in triplets {
                if t == context.prevalentWind.tile { entries.append(FanEntry(fan: .prevalentWind)) }
                if t == context.seatWind.tile { entries.append(FanEntry(fan: .seatWind)) }
            }
        }

        // 碰碰胡（字一色时不重复计碰碰胡）
        let isAllHonors = allTiles.allSatisfy(\.isHonor)
        if triplets.count == 5 && !isAllHonors {
            entries.append(FanEntry(fan: .allPungs))
        }

        // 三暗刻 / 四暗刻 / 五暗刻
        if ankouCount == 5 {
            entries.append(FanEntry(fan: .fiveConcealedPungs))
        } else if ankouCount == 4 {
            entries.append(FanEntry(fan: .fourConcealedPungs))
        } else if ankouCount == 3 {
            entries.append(FanEntry(fan: .threeConcealedPungs))
        }

        // 6. 清一色 / 混一色 / 字一色
        appendFlushFans(to: &entries, allTiles: allTiles)

        // 7. 花牌台数（正花、花杠、八仙过海、七抢一）
        appendFlowerFans(to: &entries, context: context)

        let sorted = sortEntries(entries)
        return ScoringResult(fans: sorted, flowerFan: 0, fu: 0)
    }

    // MARK: - 公共台种追加辅助

    private static func appendDealerFans(to entries: inout [FanEntry], context: WinContext) {
        guard context.isDealer else { return }
        entries.append(FanEntry(fan: .dealer, count: 1))
        if context.streakCount > 0 {
            entries.append(FanEntry(fan: .dealerStreak, count: context.streakCount))
        }
    }

    private static func appendSpecialWinFans(
        to entries: inout [FanEntry],
        isMenzen: Bool,
        isAllOpenMelds: Bool,
        context: WinContext
    ) {
        // 天胡 / 地胡 / 人胡
        if context.tenhou {
            entries.append(FanEntry(fan: .tenhou))
        } else if context.chiihou {
            entries.append(FanEntry(fan: .chiihou))
        } else if context.renhou {
            entries.append(FanEntry(fan: .renhou))
        }

        // 门清 / 自摸 / 门清一摸三 / 全求人 / 半求人
        if isMenzen {
            if context.selfDrawn {
                entries.append(FanEntry(fan: .concealedSelfDrawn))
            } else {
                entries.append(FanEntry(fan: .concealedHand))
            }
        } else if isAllOpenMelds {
            if context.selfDrawn {
                entries.append(FanEntry(fan: .halfMelded))
                entries.append(FanEntry(fan: .selfDrawn))
            } else {
                entries.append(FanEntry(fan: .allMelded))
            }
        } else if context.selfDrawn {
            entries.append(FanEntry(fan: .selfDrawn))
        }

        // 杠上开花 / 抢杠 / 海底捞月 / 河底捞鱼
        if context.kongInvolved {
            entries.append(FanEntry(fan: context.selfDrawn ? .kongReplacement : .robbingTheKong))
        } else if context.lastTileOfWall {
            entries.append(FanEntry(fan: context.selfDrawn ? .lastTileDraw : .lastTileClaim))
        }
    }

    private static func appendFlushFans(to entries: inout [FanEntry], allTiles: [Tile]) {
        if allTiles.allSatisfy(\.isHonor) {
            entries.append(FanEntry(fan: .allHonors))
            return
        }
        let suitedSuits = Set(allTiles.filter(\.isSuited).map(\.suit))
        let hasHonors = allTiles.contains(where: \.isHonor)
        if suitedSuits.count == 1 {
            if hasHonors {
                entries.append(FanEntry(fan: .halfFlush))
            } else {
                entries.append(FanEntry(fan: .fullFlush))
            }
        }
    }

    private static func appendFlowerFans(to entries: inout [FanEntry], context: WinContext) {
        if context.sevenRobbingOne {
            entries.append(FanEntry(fan: .sevenRobbingOne))
            return
        }
        if context.eightImmortals || context.flowers.count == 8 || context.flowerCount >= 8 {
            entries.append(FanEntry(fan: .eightImmortals))
            return
        }
        if !context.flowers.isEmpty {
            let seatNum = context.seatWind.seatNumber
            var flowerSets = 0
            var seatFlowers = 0

            // 春夏秋冬（四季）
            if FlowerTile.seasons.isSubset(of: context.flowers) {
                flowerSets += 1
            } else if context.flowers.contains(where: { $0.isSeason && $0.seatNumber == seatNum }) {
                seatFlowers += 1
            }

            // 梅兰竹菊（四君子）
            if FlowerTile.plants.isSubset(of: context.flowers) {
                flowerSets += 1
            } else if context.flowers.contains(where: { !$0.isSeason && $0.seatNumber == seatNum }) {
                seatFlowers += 1
            }

            if flowerSets > 0 {
                entries.append(FanEntry(fan: .flowerSet, count: flowerSets))
            }
            if seatFlowers > 0 {
                entries.append(FanEntry(fan: .seatFlower, count: seatFlowers))
            }
        } else if context.flowerCount > 0 {
            entries.append(FanEntry(fan: .seatFlower, count: context.flowerCount))
        }
    }

    private static func sortEntries(_ entries: [FanEntry]) -> [FanEntry] {
        entries.sorted { ($0.points, -$0.fan.rawValue) > ($1.points, -$1.fan.rawValue) }
    }
}
