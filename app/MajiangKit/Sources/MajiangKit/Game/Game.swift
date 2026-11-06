import Foundation

public struct Player: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

/// 台湾 16 张麻将牌局规则。默认采用台湾常见「底 300 / 台 100」、一雀四圈（16 任庄）、计花牌、严格平胡。
public struct GameRules: Hashable, Codable, Sendable {
    /// 每 1 分折合多少元（默认 1 分 = 1 元，底 300 台 100 即直接对应金额）。
    public var yuanPerPoint: Double = 1
    /// 底分（默认 300，常见 300/100、100/20、50/20）。
    public var basePoints: Int = 300
    /// 每台金额（默认 100）。
    public var taiPoints: Int = 100
    /// 起胡台数（台湾麻将默认 0 台即可胡屁胡）。
    public var minimumFan: Int = 0
    /// 是否计算花牌台数（正花、花杠、八仙过海）。
    public var includeFlowers: Bool = true
    /// 严格平胡（须无花、无字、全顺子、两面听、非庄家、他人放枪不自摸）。
    public var strictPingHu: Bool = true
    /// 兼容旧字段。
    public var kiriageMangan: Bool = false
    /// 每圈换座；朋友局一般不换。
    public var swapSeatsEachRound: Bool = false
    /// 诈胡（错和）赔付另外三家各多少分（默认各赔 800 分，相当于底 300 + 5 台）。
    public var falseWinPenalty: Int = 800
    /// 一雀共几任庄（默认四圈 16 任庄；两圈半庄为 8 任庄；一圈东风战为 4 任庄）。
    public var totalHands: Int = 16
    /// 封顶：一把最多按几台算（0 为不封顶）。
    public var fanCap: Int = 0
    /// 台湾麻将放枪由放枪者一家包付。
    public var onlyDiscarderPays: Bool = true

    public init() {}

    /// 标准台湾麻将桌规（底 300 / 台 100，四圈 16 任庄）。
    public static let standard = GameRules()

    /// 常见中小型家麻桌规（底 100 / 台 20，四圈 16 任庄）。
    public static var beginner: GameRules {
        var rules = GameRules()
        rules.basePoints = 100
        rules.taiPoints = 20
        rules.falseWinPenalty = 200
        return rules
    }

    /// 休闲家庭局桌规（底 50 / 台 20，四圈 16 任庄）。
    public static var casual: GameRules {
        var rules = GameRules()
        rules.basePoints = 50
        rules.taiPoints = 20
        rules.falseWinPenalty = 150
        return rules
    }

    /// 计分规则一样（不比汇率，换预设不动它）。
    public func scoresLike(_ other: GameRules) -> Bool {
        var copy = other
        copy.yuanPerPoint = yuanPerPoint
        return copy == self
    }

    /// 封顶以后这一把按几台算。
    public func cappedFan(_ fan: Int) -> Int {
        fanCap > 0 ? min(fan, fanCap) : fan
    }

    /// 一把胡牌的展示总台数（不计花牌时去掉花牌台数，再按封顶算）。
    public func paidFan(_ win: WinRecord) -> Int {
        let raw = includeFlowers ? win.totalFan : max(0, win.totalFan - win.computedFlowerTai)
        return cappedFan(raw)
    }

    /// 一把胡牌不含庄家连拉的牌型+花牌台数（供 `Payment.winDeltas` 叠加庄家连拉台使用）。
    public func paidHandFan(_ win: WinRecord) -> Int {
        if let override = win.fanOverride {
            return max(0, override)
        }
        let withoutDealer = max(0, win.totalFan - win.dealerFan)
        return includeFlowers ? withoutDealer : max(0, withoutDealer - win.computedFlowerTai)
    }

    enum CodingKeys: String, CodingKey {
        case yuanPerPoint, basePoints, taiPoints, minimumFan, includeFlowers, strictPingHu
        case kiriageMangan, swapSeatsEachRound, falseWinPenalty, totalHands, fanCap, onlyDiscarderPays
    }

    /// 缺的字段用默认值，以后加规则不会让旧存档读不出来。
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GameRules()
        yuanPerPoint = try c.decodeIfPresent(Double.self, forKey: .yuanPerPoint) ?? d.yuanPerPoint
        basePoints = try c.decodeIfPresent(Int.self, forKey: .basePoints) ?? d.basePoints
        taiPoints = try c.decodeIfPresent(Int.self, forKey: .taiPoints) ?? d.taiPoints
        minimumFan = try c.decodeIfPresent(Int.self, forKey: .minimumFan) ?? d.minimumFan
        includeFlowers = try c.decodeIfPresent(Bool.self, forKey: .includeFlowers) ?? d.includeFlowers
        strictPingHu = try c.decodeIfPresent(Bool.self, forKey: .strictPingHu) ?? d.strictPingHu
        kiriageMangan = try c.decodeIfPresent(Bool.self, forKey: .kiriageMangan) ?? d.kiriageMangan
        swapSeatsEachRound = try c.decodeIfPresent(Bool.self, forKey: .swapSeatsEachRound) ?? d.swapSeatsEachRound
        falseWinPenalty = try c.decodeIfPresent(Int.self, forKey: .falseWinPenalty) ?? d.falseWinPenalty
        totalHands = try c.decodeIfPresent(Int.self, forKey: .totalHands) ?? d.totalHands
        fanCap = try c.decodeIfPresent(Int.self, forKey: .fanCap) ?? d.fanCap
        onlyDiscarderPays = try c.decodeIfPresent(Bool.self, forKey: .onlyDiscarderPays) ?? d.onlyDiscarderPays
    }
}

/// 一局的结果。
public enum HandOutcome: Hashable, Codable, Sendable {
    case win(WinRecord)
    /// 流局（臭庄）：不计分，庄家继续连庄（连庄数 +1）。
    case drawn
    /// 错和（诈胡）：赔另外三家罚分，不推进局数。
    case falseWin(offender: Int)
    /// 手动记分，四个数加起来为 0。
    case manual(deltas: [Int], note: String)

    /// 这一局打完了没有（诈胡之后这一局继续打）。
    public var advancesHand: Bool {
        if case .falseWin = self { return false }
        return true
    }
}

public struct WinRecord: Hashable, Codable, Sendable {
    /// 胡牌者（玩家下标，0–3）。
    public var winner: Int
    /// 放枪者；nil 为自摸。
    public var discarder: Int?
    /// 确认后的手牌；手动输入台数时可以为空。
    public var hand: Hand?
    public var context: WinContext
    public var fans: [FanEntry]
    /// 额外附加花台（当花牌已作为 `.seatFlower` / `.flowerSet` / `.eightImmortals` 计入 `fans` 时为 0）。
    public var flowerFan: Int
    /// 兼容字段（台湾麻将不使用符数，固定为 0）。
    public var fu: Int
    /// 事后在账本里直接改了台数。有它时 `fans` 不再可信，界面清空明细，改局时也不重新算台。
    public var fanOverride: Int?

    public init(
        winner: Int,
        discarder: Int?,
        hand: Hand?,
        context: WinContext,
        fans: [FanEntry],
        flowerFan: Int = 0,
        fu: Int = 0,
        fanOverride: Int? = nil
    ) {
        self.winner = winner
        self.discarder = discarder
        self.hand = hand
        self.context = context
        self.fans = fans
        self.flowerFan = flowerFan
        self.fu = fu
        self.fanOverride = fanOverride
    }

    public init(winner: Int, discarder: Int?, hand: Hand, context: WinContext, result: ScoringResult) {
        self.init(
            winner: winner,
            discarder: discarder,
            hand: hand,
            context: context,
            fans: result.fans,
            flowerFan: result.flowerFan,
            fu: result.fu
        )
    }

    enum CodingKeys: String, CodingKey {
        case winner, discarder, hand, context, fans, flowerFan, fu, fanOverride
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        winner = try c.decode(Int.self, forKey: .winner)
        discarder = try c.decodeIfPresent(Int.self, forKey: .discarder)
        hand = try c.decodeIfPresent(Hand.self, forKey: .hand)
        context = try c.decode(WinContext.self, forKey: .context)
        fans = try c.decode([FanEntry].self, forKey: .fans)
        flowerFan = try c.decodeIfPresent(Int.self, forKey: .flowerFan) ?? 0
        fu = try c.decodeIfPresent(Int.self, forKey: .fu) ?? 0
        fanOverride = try c.decodeIfPresent(Int.self, forKey: .fanOverride)
    }

    /// 包含在 `fans` 中的庄家与连庄拉庄台数合计。
    public var dealerFan: Int {
        fans.filter(\.fan.isDealerFan).reduce(0) { $0 + $1.points }
    }

    /// 包含在 `fans` 或 `flowerFan` 中的花牌台数合计。
    public var computedFlowerTai: Int {
        flowerFan + fans.filter(\.fan.isFlowerFan).reduce(0) { $0 + $1.points }
    }

    public var totalFan: Int {
        fanOverride ?? (fans.reduce(0) { $0 + $1.points } + flowerFan)
    }

    public var isSelfDrawn: Bool { discarder == nil }
}

public struct HandRecord: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    /// 第几局（0 起），诈胡记在当前局上。
    public var handIndex: Int
    public var outcome: HandOutcome
    /// 四个玩家本局的得失分，下标同 `Game.players`。
    public var deltas: [Int]
    public var date: Date

    public init(id: UUID = UUID(), handIndex: Int, outcome: HandOutcome, deltas: [Int], date: Date = Date()) {
        self.id = id
        self.handIndex = handIndex
        self.outcome = outcome
        self.deltas = deltas
        self.date = date
    }
}

public enum GameError: Error, Hashable, Sendable {
    case finished
    case invalidPlayer
    case discarderIsWinner
    case belowMinimumFan(Int)
    case deltasMustSumToZero
    case recordNotFound
    case tooManyHands(Int)

    public var message: String {
        switch self {
        case .finished: return "这场牌局已经打完了"
        case .invalidPlayer: return "玩家不对"
        case .discarderIsWinner: return "放枪的人不能是胡牌的人"
        case .belowMinimumFan(let fan):
            return "只有 \(fan) 台，不够本桌起胡台数"
        case .deltasMustSumToZero: return "四个人的得失分加起来要等于 0"
        case .recordNotFound: return "找不到这一局"
        case .tooManyHands(let total): return "这样改就超过 \(total) 任庄了"
        }
    }
}

/// 一场台湾 16 张麻将牌局：四个人、规则、每一局的记录。
/// 圈风、门风、庄家、连庄数（连 N 拉 N）均由历史记录动态推导：
/// - 庄家胡牌或流局（臭庄）时：**庄家连庄**（`streak += 1`，庄家与门风不变）。
/// - 闲家胡牌时：**庄家下庄**（`streak = 0`，轮转至下一家做庄）。
public struct Game: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    /// 开局时的座位：下标 0 东、1 南、2 西、3 北。东家是第一局的起庄。
    public var players: [Player]
    /// 用这台手机的人是 `players` 里的第几个（牌桌图上画在最下面，首页历史显示他的输赢）。
    public var me: Int
    public var rules: GameRules
    public private(set) var records: [HandRecord]

    public init(
        id: UUID = UUID(),
        players: [Player],
        me: Int = 0,
        rules: GameRules = GameRules(),
        startedAt: Date = Date()
    ) {
        precondition(players.count == 4, "台湾麻将固定 4 人")
        precondition((0..<4).contains(me), "我必须是四个人之一")
        self.id = id
        self.players = players
        self.me = me
        self.rules = rules
        self.records = []
        self.startedAt = startedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, startedAt, endedAt, players, me, rules, records
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        startedAt = try c.decode(Date.self, forKey: .startedAt)
        endedAt = try c.decodeIfPresent(Date.self, forKey: .endedAt)
        players = try c.decode([Player].self, forKey: .players)
        let me = try c.decodeIfPresent(Int.self, forKey: .me) ?? 0
        self.me = (0..<4).contains(me) ? me : 0
        rules = try c.decodeIfPresent(GameRules.self, forKey: .rules) ?? GameRules()
        records = try c.decodeIfPresent([HandRecord].self, forKey: .records) ?? []
    }

    // MARK: - 局数、圈风、门风、庄家与连拉状态推导

    private struct HandState: Hashable {
        /// 庄家已轮转次数（0 起；每 4 次轮转为一圈：0..3 东圈，4..7 南圈，8..11 西圈，12..15 北圈）。
        var rotation: Int
        /// 当前庄家连庄次数（0 为首庄，1 为连一拉一，N 为连 N 拉 N）。
        var streak: Int
    }

    /// 推导第 `targetHand` 局（0 起）的 `(rotation, streak)` 状态。
    private func state(ofHand targetHand: Int) -> HandState {
        var rotation = 0
        var streak = 0
        var hand = 0

        for record in records {
            if hand == targetHand {
                return HandState(rotation: rotation, streak: streak)
            }
            guard record.outcome.advancesHand else { continue }
            let currentRound = min(rotation / 4, 3)
            let currentDealer = seating(ofRound: currentRound)[rotation % 4]

            switch record.outcome {
            case .win(let win):
                if win.winner == currentDealer {
                    // 庄家胡牌：连庄
                    streak += 1
                } else {
                    // 闲家胡牌：下庄轮转至下一家
                    rotation += 1
                    streak = 0
                }
            case .drawn:
                // 臭庄（流局）：庄家连庄
                streak += 1
            case .manual:
                rotation += 1
                streak = 0
            case .falseWin:
                break
            }
            hand += 1
        }

        if targetHand <= hand {
            return HandState(rotation: rotation, streak: streak)
        }
        // 超出已记录局数时，按每局正常下庄推算
        return HandState(rotation: rotation + (targetHand - hand), streak: 0)
    }

    /// 已经打完的局数（含连庄局），也就是当前是第几局（0 起）。
    public var currentHandIndex: Int { records.filter(\.outcome.advancesHand).count }

    /// 已经完成的庄家任数（下庄次数）。
    public var completedRotations: Int { state(ofHand: currentHandIndex).rotation }

    /// 牌局是否结束：手动结束，或已完成全部庄家任数（如四圈 16 任庄北风北下庄）。
    public var isFinished: Bool { endedAt != nil || completedRotations >= rules.totalHands }

    /// 还剩几任庄。
    public var remainingHands: Int { max(0, rules.totalHands - completedRotations) }

    /// 某局处于第几圈（0 东圈、1 南圈、2 西圈、3 北圈），超过 4 圈按北圈算。
    public func roundIndex(ofHand hand: Int) -> Int {
        min(state(ofHand: hand).rotation / 4, 3)
    }

    /// 某局是当前圈的第几任庄（0..3，对应东、南、西、北四任庄）。
    public func dealerSlot(ofHand hand: Int) -> Int {
        state(ofHand: hand).rotation % 4
    }

    /// 某局庄家的连庄次数 $N$（0 为无连庄，$N \ge 1$ 为连 $N$ 拉 $N$）。
    public func streak(ofHand hand: Int) -> Int {
        state(ofHand: hand).streak
    }

    /// 当前局庄家的连庄次数 $N$。
    public var currentStreak: Int {
        streak(ofHand: currentHandIndex)
    }

    /// 某局庄家连拉合计台数（$2N + 1$ 台：庄家 1 台 + 连 $N$ 拉 $N$ $2N$ 台）。
    public func dealerTai(ofHand hand: Int) -> Int {
        Payment.dealerTai(streak: streak(ofHand: hand))
    }

    public func prevalentWind(ofHand hand: Int) -> Wind {
        Wind(rawValue: roundIndex(ofHand: hand))!
    }

    public var prevalentWind: Wind { prevalentWind(ofHand: currentHandIndex) }

    /// 这一圈里，桌子东南西北四个位置上坐的是谁（玩家下标）。
    public func seating(ofRound round: Int) -> [Int] {
        guard rules.swapSeatsEachRound else { return [0, 1, 2, 3] }
        let table = [[0, 1, 2, 3], [1, 0, 3, 2], [2, 3, 1, 0], [3, 2, 0, 1]]
        return table[min(max(round, 0), 3)]
    }

    /// 某局里玩家坐在哪个位置（0 东位 … 3 北位）。
    public func position(of player: Int, inHand hand: Int) -> Int {
        seating(ofRound: roundIndex(ofHand: hand)).firstIndex(of: player)!
    }

    /// 某局的庄家（玩家下标）。
    public func dealer(ofHand hand: Int) -> Int {
        seating(ofRound: roundIndex(ofHand: hand))[dealerSlot(ofHand: hand)]
    }

    public var dealer: Int { dealer(ofHand: currentHandIndex) }

    /// 某局玩家的门风：庄家是东（1 花），下家是南（2 花），对家是西（3 花），上家是北（4 花）。
    public func seatWind(of player: Int, inHand hand: Int) -> Wind {
        let offset = (position(of: player, inHand: hand) - dealerSlot(ofHand: hand) + 4) % 4
        return Wind(rawValue: offset)!
    }

    public func seatWind(of player: Int) -> Wind { seatWind(of: player, inHand: currentHandIndex) }

    /// 当前局某个玩家胡牌时的 `WinContext`（圈风、门风、是否庄家、连庄数、严格平胡已填好）。
    public func winContext(for winner: Int, inHand hand: Int? = nil) -> WinContext {
        let h = hand ?? currentHandIndex
        return WinContext(
            prevalentWind: prevalentWind(ofHand: h),
            seatWind: seatWind(of: winner, inHand: h),
            isDealer: winner == dealer(ofHand: h),
            streakCount: streak(ofHand: h),
            strictPingHu: rules.strictPingHu
        )
    }

    // MARK: - 分数

    /// 每个人的累计净得失分（四家之和恒为 0）。
    public var scores: [Int] {
        records.reduce(into: [0, 0, 0, 0]) { total, record in
            for i in 0..<4 { total[i] += record.deltas[i] }
        }
    }

    /// 分数折合多少元（台湾麻将底+台直接对应金额，按 `points * yuanPerPoint` 计算）。
    public func money(forPoints points: Int) -> Double {
        Double(points) * rules.yuanPerPoint
    }

    /// 本场赢最多的一手胡牌。
    public var biggestWin: (record: HandRecord, win: WinRecord)? {
        records.compactMap { record -> (HandRecord, WinRecord)? in
            if case .win(let win) = record.outcome { return (record, win) }
            return nil
        }
        .max { ($0.0.deltas[$0.1.winner], $0.1.totalFan) < ($1.0.deltas[$1.1.winner], $1.1.totalFan) }
    }

    // MARK: - 记分

    @discardableResult
    public mutating func recordWin(_ win: WinRecord) throws -> HandRecord {
        guard !isFinished else { throw GameError.finished }
        try validate(.win(win))
        let handIdx = currentHandIndex
        let reconciledWin = reconciled(win, inHand: handIdx, edited: false)
        return append(.win(reconciledWin), deltas: deltas(for: .win(reconciledWin), inHand: handIdx))
    }

    @discardableResult
    public mutating func recordDraw() throws -> HandRecord {
        guard !isFinished else { throw GameError.finished }
        return append(.drawn, deltas: [0, 0, 0, 0])
    }

    @discardableResult
    public mutating func recordFalseWin(offender: Int) throws -> HandRecord {
        guard !isFinished else { throw GameError.finished }
        try validate(.falseWin(offender: offender))
        let handIdx = currentHandIndex
        return append(.falseWin(offender: offender), deltas: deltas(for: .falseWin(offender: offender), inHand: handIdx))
    }

    @discardableResult
    public mutating func recordManual(deltas: [Int], note: String = "") throws -> HandRecord {
        guard !isFinished else { throw GameError.finished }
        try validate(.manual(deltas: deltas, note: note))
        return append(.manual(deltas: deltas, note: note), deltas: deltas)
    }

    /// 撤销最后一条记录。
    @discardableResult
    public mutating func undoLast() -> HandRecord? {
        guard !records.isEmpty else { return nil }
        endedAt = nil
        return records.removeLast()
    }

    public mutating func end(at date: Date = Date()) {
        endedAt = date
    }

    // MARK: - 改以前的局

    public mutating func replace(_ id: UUID, with outcome: HandOutcome) throws {
        self = try replacing(id, with: outcome)
    }

    public func replacing(_ id: UUID, with outcome: HandOutcome) throws -> Game {
        guard let index = records.firstIndex(where: { $0.id == id }) else { throw GameError.recordNotFound }
        var copy = self
        copy.records[index].outcome = outcome
        try copy.reflow(edited: id)
        return copy
    }

    public mutating func changeRules(_ newRules: GameRules) throws {
        self = try changingRules(newRules)
    }

    public func changingRules(_ newRules: GameRules) throws -> Game {
        var copy = self
        copy.rules = newRules
        try copy.reflow(edited: nil)
        return copy
    }

    /// 按现在的起胡台数，不够台数的胡牌（中途调高了起胡台数时会有）。
    public var winsBelowMinimum: [HandRecord] {
        records.filter { record in
            guard case .win(let win) = record.outcome else { return false }
            return rules.paidFan(win) < rules.minimumFan
        }
    }

    /// 删掉某一局，后面的跟着重算。
    public mutating func remove(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records.remove(at: index)
        try? reflow(edited: nil)
    }

    private mutating func reflow(edited: UUID?) throws {
        var hand = 0
        for i in records.indices {
            records[i].handIndex = hand
            let isEdited = records[i].id == edited
            if case .win(let win) = records[i].outcome {
                records[i].outcome = .win(reconciled(win, inHand: hand, edited: isEdited))
            }
            if isEdited { try validate(records[i].outcome) }
            records[i].deltas = deltas(for: records[i].outcome, inHand: hand)
            if records[i].outcome.advancesHand { hand += 1 }
        }
        guard completedRotations <= rules.totalHands else { throw GameError.tooManyHands(rules.totalHands) }
    }

    private func reconciled(_ win: WinRecord, inHand hand: Int, edited: Bool) -> WinRecord {
        let currentDealer = dealer(ofHand: hand)
        let currentStreak = streak(ofHand: hand)
        var context = win.context
        context.prevalentWind = prevalentWind(ofHand: hand)
        context.seatWind = seatWind(of: win.winner, inHand: hand)
        context.selfDrawn = win.isSelfDrawn
        context.isDealer = (win.winner == currentDealer)
        context.streakCount = currentStreak
        context.strictPingHu = rules.strictPingHu
        if context.selfDrawn != win.context.selfDrawn {
            context.kongInvolved = false
            context.lastTileOfWall = false
        }

        var updated = win
        updated.context = context
        if let tiles = win.hand, win.fanOverride == nil,
           case .success(let result) = FanCalculator.score(tiles, context: context),
           edited || result.meetsMinimum(rules.minimumFan) {
            updated.fans = result.fans
            updated.flowerFan = result.flowerFan
            updated.fu = result.fu
        } else if win.hand == nil && win.fanOverride == nil && !win.fans.isEmpty {
            // 无具体手牌但有台种明细时，同步更新庄家与连拉台种
            let hadDealerFan = win.fans.contains(where: \.fan.isDealerFan)
            if hadDealerFan {
                var nonDealerEntries = win.fans.filter { !$0.fan.isDealerFan }
                if context.isDealer {
                    nonDealerEntries.append(FanEntry(fan: .dealer, count: 1))
                    if currentStreak > 0 {
                        nonDealerEntries.append(FanEntry(fan: .dealerStreak, count: currentStreak))
                    }
                }
                updated.fans = nonDealerEntries.sorted { ($0.points, -$0.fan.rawValue) > ($1.points, -$1.fan.rawValue) }
            }
        }
        return updated
    }

    private func validate(_ outcome: HandOutcome) throws {
        switch outcome {
        case .win(let win):
            guard (0..<4).contains(win.winner) else { throw GameError.invalidPlayer }
            if let discarder = win.discarder {
                guard (0..<4).contains(discarder) else { throw GameError.invalidPlayer }
                guard discarder != win.winner else { throw GameError.discarderIsWinner }
            }
            let effectiveFan = rules.includeFlowers ? win.totalFan : max(0, win.totalFan - win.computedFlowerTai)
            guard effectiveFan >= rules.minimumFan else { throw GameError.belowMinimumFan(effectiveFan) }
        case .drawn:
            break
        case .falseWin(let offender):
            guard (0..<4).contains(offender) else { throw GameError.invalidPlayer }
        case .manual(let deltas, _):
            guard deltas.count == 4, deltas.reduce(0, +) == 0 else { throw GameError.deltasMustSumToZero }
        }
    }

    private func deltas(for outcome: HandOutcome, inHand handIndex: Int) -> [Int] {
        switch outcome {
        case .win(let win):
            return Payment.winDeltas(
                winner: win.winner,
                discarder: win.discarder,
                dealer: dealer(ofHand: handIndex),
                streak: streak(ofHand: handIndex),
                totalFan: rules.paidHandFan(win),
                dealerFanIncluded: false,
                fu: win.fu,
                rules: rules
            )
        case .drawn:
            return [0, 0, 0, 0]
        case .falseWin(let offender):
            return Payment.falseWinDeltas(offender: offender, penalty: rules.falseWinPenalty)
        case .manual(let deltas, _):
            return deltas
        }
    }

    private mutating func append(_ outcome: HandOutcome, deltas: [Int]) -> HandRecord {
        let record = HandRecord(handIndex: currentHandIndex, outcome: outcome, deltas: deltas)
        records.append(record)
        return record
    }
}

/// 台湾 16 张麻将「底 + 台」与庄家连拉收付计算。
public enum Payment {
    /// 庄家连 $N$ 拉 $N$ 的庄家连拉总台数：$2N + 1$ 台（庄家 1 台 + 连 $N$ 拉 $N$ $2N$ 台）。
    public static func dealerTai(streak: Int) -> Int {
        1 + 2 * max(0, streak)
    }

    /// 给定台数对应的单家应付金额：$\text{底} + (\text{封顶后台数} \times \text{每台金额})$。
    public static func points(forTai tai: Int, rules: GameRules = .standard) -> Int {
        rules.basePoints + rules.cappedFan(max(0, tai)) * rules.taiPoints
    }

    /// 兼容旧接口。
    public static func ceil100(_ value: Int) -> Int {
        guard value > 0 else { return 0 }
        return ((value + 99) / 100) * 100
    }

    /// 兼容旧接口：返回给定台数的单家应付金额。
    public static func basePoints(han: Int, fu: Int = 0, kiriageMangan: Bool = false) -> Int {
        points(forTai: han, rules: .standard)
    }

    /// 台湾麻将大牌称号（满 8 台及以上返回对应提示，否则返回 nil）。
    public static func limitName(han: Int, fu: Int = 0, kiriageMangan: Bool = false) -> String? {
        if han >= 16 { return "大满贯" }
        if han >= 8 { return "满贯" }
        return nil
    }

    /// 台湾 16 张麻将一局胡牌的四家得失分：
    /// - 计费公式：$\text{单家应付} = \text{底} + (\text{台数} \times \text{每台金额})$
    /// - 庄家连拉台（$2N + 1$ 台）仅在**庄家与闲家之间结算**时计入：
    ///   1. 闲家 A 放枪给闲家 B：A 支付 $\text{底} + \text{牌型台} \times \text{台}$（不计庄家台）。
    ///   2. 庄家胡闲家放枪 或 闲家胡庄家放枪：放枪者支付 $\text{底} + (\text{牌型台} + 2N + 1) \times \text{台}$。
    ///   3. 庄家自摸：三家闲家各支付 $\text{底} + (\text{牌型台} + 2N + 1) \times \text{台}$。
    ///   4. 闲家自摸：另外两家闲家各支付 $\text{底} + \text{牌型台} \times \text{台}$，庄家支付 $\text{底} + (\text{牌型台} + 2N + 1) \times \text{台}$。
    public static func winDeltas(
        winner: Int,
        discarder: Int?,
        dealer: Int = 0,
        streak: Int = 0,
        totalFan: Int,
        dealerFanIncluded: Bool = false,
        fu: Int = 0,
        rules: GameRules = .standard
    ) -> [Int] {
        let extra = dealerTai(streak: streak)
        let handTai = (winner == dealer && dealerFanIncluded) ? max(0, totalFan - extra) : max(0, totalFan)
        var deltas = [0, 0, 0, 0]

        if let discarder {
            let dealerInvolved = (winner == dealer || discarder == dealer)
            let tai = handTai + (dealerInvolved ? extra : 0)
            let pay = points(forTai: tai, rules: rules)
            deltas[discarder] -= pay
            deltas[winner] += pay
        } else if winner == dealer {
            let each = points(forTai: handTai + extra, rules: rules)
            for p in 0..<4 where p != winner {
                deltas[p] -= each
                deltas[winner] += each
            }
        } else {
            let childPay = points(forTai: handTai, rules: rules)
            let dealerPay = points(forTai: handTai + extra, rules: rules)
            for p in 0..<4 where p != winner {
                let pay = (p == dealer) ? dealerPay : childPay
                deltas[p] -= pay
                deltas[winner] += pay
            }
        }
        return deltas
    }

    /// 诈胡罚分：赔另外三家各 `penalty` 分。
    public static func falseWinDeltas(offender: Int, penalty: Int) -> [Int] {
        (0..<4).map { $0 == offender ? -3 * penalty : penalty }
    }
}
