import Foundation

/// 照片拍不出来、要用户在核对页勾一下的特殊胡牌情况（杠上开花、海底捞月、河底捞鱼、抢杠、七抢一、天地人胡）。
public enum SpecialWin: String, CaseIterable, Hashable, Codable, Sendable {
    /// 杠上开花：开杠或补花后摸牌自摸，1 台。
    case kongReplacement
    /// 海底捞月：牌山最后一张自摸，1 台。
    case lastTileDraw
    /// 河底捞鱼：全桌最后一张放枪胡牌，1 台。
    case lastTileClaim
    /// 抢杠：别人加杠时抢胡，1 台。
    case robbingTheKong
    /// 七抢一：手握 7 张花牌抢别人第 8 张花，8 台。
    case sevenRobbingOne
    /// 天胡：庄家起手配牌 17 张直接胡牌，16 台。
    case tenhou
    /// 地胡：闲家首巡自摸胡牌，16 台。
    case chiihou
    /// 人胡：首巡胡别人打出的第一张牌，8 台。
    case renhou

    public var name: String {
        switch self {
        case .kongReplacement: return "杠上开花"
        case .lastTileDraw: return "海底捞月"
        case .lastTileClaim: return "河底捞鱼"
        case .robbingTheKong: return "抢杠"
        case .sevenRobbingOne: return "七抢一"
        case .tenhou: return "天胡"
        case .chiihou: return "地胡"
        case .renhou: return "人胡"
        }
    }

    public var fan: Fan {
        switch self {
        case .kongReplacement: return .kongReplacement
        case .lastTileDraw: return .lastTileDraw
        case .lastTileClaim: return .lastTileClaim
        case .robbingTheKong: return .robbingTheKong
        case .sevenRobbingOne: return .sevenRobbingOne
        case .tenhou: return .tenhou
        case .chiihou: return .chiihou
        case .renhou: return .renhou
        }
    }

    /// 勾选上这一项加几台。
    public var fanPoints: Int { fan.points }

    /// 一句白话说明。
    public var plain: String {
        switch self {
        case .kongReplacement: return "开杠或补花后摸进补牌，正好自摸胡了"
        case .lastTileDraw: return "摸铁门前最后一张牌时自摸胡了"
        case .lastTileClaim: return "胡的是别人打出的全桌最后一张牌"
        case .robbingTheKong: return "别人加杠时，正好抢胡他加的那张牌"
        case .sevenRobbingOne: return "自己摸到 7 张花牌，抢胡别人摸到的第 8 张花牌"
        case .tenhou: return "庄家起手配牌 17 张直接胡牌"
        case .chiihou: return "闲家第一巡无人吃碰杠时自摸胡牌"
        case .renhou: return "第一巡无人吃碰杠时胡别人打出的牌"
        }
    }

    /// 这手牌下能不能选；不能选时返回原因（界面用来置灰）。
    public func unavailableReason(hand: Hand, selfDrawn: Bool) -> String? {
        let isMenzen = hand.melds.allSatisfy { $0.kind == .kong && $0.isConcealed }
        switch self {
        case .kongReplacement:
            return selfDrawn ? nil : "杠上开花只能是自摸"
        case .lastTileDraw:
            return selfDrawn ? nil : "海底捞月只能是自摸"
        case .lastTileClaim:
            return selfDrawn ? "河底捞鱼只能是放枪" : nil
        case .robbingTheKong:
            guard !selfDrawn else { return "抢杠只能是放枪" }
            let ownCopies = hand.allTiles.filter { $0 == hand.winningTile }.count
            return ownCopies > 1 ? "手牌里已经有 \(ownCopies) 张 \(hand.winningTile.displayName)，别人没法加杠这张" : nil
        case .sevenRobbingOne:
            return nil
        case .tenhou:
            guard selfDrawn else { return "天胡只能是自摸" }
            guard isMenzen else { return "有吃、碰、明杠时不能算天胡" }
            return nil
        case .chiihou:
            guard selfDrawn else { return "地胡只能是自摸" }
            guard isMenzen else { return "有吃、碰、明杠时不能算地胡" }
            return nil
        case .renhou:
            guard !selfDrawn else { return "人胡只能是别人放枪" }
            guard isMenzen else { return "有吃、碰、明杠时不能算人胡" }
            return nil
        }
    }

    /// 跟这一项不能同时选的（选了新的就把冲突的旧项替掉）。
    public var conflicts: Set<SpecialWin> {
        switch self {
        case .kongReplacement:
            return [.lastTileDraw, .lastTileClaim, .robbingTheKong, .tenhou, .chiihou, .renhou]
        case .lastTileDraw:
            return [.kongReplacement, .lastTileClaim, .robbingTheKong, .tenhou, .chiihou, .renhou]
        case .lastTileClaim:
            return [.kongReplacement, .lastTileDraw, .robbingTheKong, .tenhou, .chiihou, .renhou]
        case .robbingTheKong:
            return [.kongReplacement, .lastTileDraw, .lastTileClaim, .tenhou, .chiihou, .renhou]
        case .sevenRobbingOne:
            return [.tenhou, .chiihou, .renhou]
        case .tenhou:
            return [.kongReplacement, .lastTileDraw, .lastTileClaim, .robbingTheKong, .sevenRobbingOne, .chiihou, .renhou]
        case .chiihou:
            return [.kongReplacement, .lastTileDraw, .lastTileClaim, .robbingTheKong, .sevenRobbingOne, .tenhou, .renhou]
        case .renhou:
            return [.kongReplacement, .lastTileDraw, .lastTileClaim, .robbingTheKong, .sevenRobbingOne, .tenhou, .chiihou]
        }
    }

    public static func apply(_ set: Set<SpecialWin>, to context: inout WinContext) {
        context.lastTileOfWall = set.contains(.lastTileDraw) || set.contains(.lastTileClaim)
        context.kongInvolved = set.contains(.kongReplacement) || set.contains(.robbingTheKong)
        context.sevenRobbingOne = set.contains(.sevenRobbingOne)
        context.tenhou = set.contains(.tenhou)
        context.chiihou = set.contains(.chiihou)
        context.renhou = set.contains(.renhou)
    }

    public static func from(_ context: WinContext) -> Set<SpecialWin> {
        var result: Set<SpecialWin> = []
        if context.lastTileOfWall { result.insert(context.selfDrawn ? .lastTileDraw : .lastTileClaim) }
        if context.kongInvolved { result.insert(context.selfDrawn ? .kongReplacement : .robbingTheKong) }
        if context.sevenRobbingOne { result.insert(.sevenRobbingOne) }
        if context.tenhou { result.insert(.tenhou) }
        if context.chiihou { result.insert(.chiihou) }
        if context.renhou { result.insert(.renhou) }
        return result
    }
}

/// 改一张牌（或补一张漏读的牌）就能胡的建议。
public struct FixSuggestion: Hashable, Sendable {
    /// `concealed` 里的下标；nil 表示不是改某一张，而是补一张。
    public let index: Int?
    public let from: Tile?
    public let to: Tile
    public let result: ScoringResult

    /// 拍照识别最容易把同花色点数看差一两点，排在前面。
    var distance: Int {
        guard let from else { return 0 }
        if from.suit == to.suit { return from.isHonor ? 3 : abs(from.rank - to.rank) }
        return 10
    }
}

public enum WinAssistant {
    /// 胡不了时用人话告诉用户为什么。能胡时返回 nil。
    public static func explain(_ hand: Hand, context: WinContext = WinContext(), minimumFan: Int = 0) -> String? {
        switch FanCalculator.score(hand, context: context) {
        case .success(let result):
            if result.meetsMinimum(minimumFan) { return nil }
            return "只有 \(result.totalFan) 台，本桌规则要满 \(minimumFan) 台才能胡。"
        case .failure(.wrongTileCount):
            let expected = 17 - hand.melds.count * 3
            return "张数不对：立牌应该是 \(expected) 张，现在是 \(hand.concealed.count) 张（台湾麻将和牌共 17 张）。"
        case .failure(.tileMoreThanFour):
            let names = hand.overusedTiles.map(\.displayName).joined(separator: "、")
            return "\(names) 超过了 4 张，一定有牌认错了。"
        case .failure(.notAWin):
            return "这副牌凑不成胡牌（台湾 16 张麻将需要 5 组面子加 1 对将眼，或呖咕呖咕）。"
        }
    }

    /// 识别差一张导致胡不了时，找出改哪一张（或补哪一张）就能胡。
    public static func fixSuggestions(
        for hand: Hand,
        context: WinContext = WinContext(),
        minimumFan: Int = 0,
        limit: Int = 4
    ) -> [FixSuggestion] {
        guard hand.melds.allSatisfy(\.isValid) else { return [] }
        let expected = 17 - hand.melds.count * 3

        if hand.concealed.count == expected - 1 {
            return FanCalculator.waitingTiles(melds: hand.melds, standing: hand.concealed).compactMap { tile in
                let candidate = Hand(melds: hand.melds, concealed: hand.concealed + [tile], winningTile: tile)
                guard case .success(let result) = FanCalculator.score(candidate, context: context),
                      result.meetsMinimum(minimumFan) else { return nil }
                return FixSuggestion(index: nil, from: nil, to: tile, result: result)
            }
        }

        guard hand.concealed.count == expected else { return [] }
        if FanCalculator.isWinningShape(hand) { return [] }

        var suggestions: [FixSuggestion] = []
        let used = Dictionary(grouping: hand.allTiles, by: { $0 }).mapValues(\.count)
        let winIsLast = hand.concealed.last == hand.winningTile

        for i in hand.concealed.indices {
            let original = hand.concealed[i]
            for replacement in Tile.all where replacement != original {
                if (used[replacement] ?? 0) >= 4 { continue }
                var copy = hand.concealed
                copy[i] = replacement
                let win = (i == copy.count - 1 && winIsLast) ? replacement : hand.winningTile
                let candidate = Hand(melds: hand.melds, concealed: copy, winningTile: win)
                guard case .success(let result) = FanCalculator.score(candidate, context: context),
                      result.meetsMinimum(minimumFan) else { continue }
                suggestions.append(FixSuggestion(index: i, from: original, to: replacement, result: result))
            }
        }

        suggestions.sort { ($0.distance, $0.index ?? 0) < ($1.distance, $1.index ?? 0) }
        var seen = Set<Int>()
        return suggestions.filter { s in
            guard let i = s.index else { return true }
            return seen.insert(i).inserted
        }
        .prefix(limit)
        .map { $0 }
    }
}
