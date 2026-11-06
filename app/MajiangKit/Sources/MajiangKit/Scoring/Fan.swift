import Foundation

/// 台湾 16 张麻将台种。
public enum Fan: Int, CaseIterable, Codable, Sendable {
    // 庄家与连拉
    case dealer = 1
    case dealerStreak

    // 门清、自摸与求人
    case concealedHand
    case selfDrawn
    case concealedSelfDrawn
    case allMelded
    case halfMelded

    // 独听
    case singleWait
    case edgeWait
    case closedWait

    // 花牌
    case seatFlower
    case flowerSet
    case eightImmortals
    case sevenRobbingOne

    // 字牌（三元牌、四喜风牌）
    case redDragon
    case greenDragon
    case whiteDragon
    case prevalentWind
    case seatWind
    case littleThreeDragons
    case bigThreeDragons
    case littleFourWinds
    case bigFourWinds

    // 牌型台数
    case pingHu
    case allPungs
    case halfFlush
    case fullFlush
    case allHonors
    case threeConcealedPungs
    case fourConcealedPungs
    case fiveConcealedPungs
    case liguLigu

    // 特殊状况
    case kongReplacement
    case robbingTheKong
    case lastTileDraw
    case lastTileClaim
    case tenhou
    case chiihou
    case renhou

    // 基础胡牌（0 台屁胡）
    case chickenHand

    // 兼容旧版别名
    public static let chinitsu = Fan.fullFlush
    public static let honitsu = Fan.halfFlush
    public static let toitoi = Fan.allPungs
    public static let pinfu = Fan.pingHu
    public static let menzenTsumo = Fan.concealedSelfDrawn
    public static let sanankou = Fan.threeConcealedPungs
    public static let suuankou = Fan.fourConcealedPungs
    public static let shousangen = Fan.littleThreeDragons
    public static let daisangen = Fan.bigThreeDragons
    public static let shousuushii = Fan.littleFourWinds
    public static let daisuushii = Fan.bigFourWinds
    public static let tsuuiisou = Fan.allHonors
    public static let rinshan = Fan.kongReplacement
    public static let chankan = Fan.robbingTheKong
    public static let haitei = Fan.lastTileDraw
    public static let houtei = Fan.lastTileClaim
    public static let outWithReplacementTile = Fan.kongReplacement
    public static let sevenPairs = Fan.liguLigu
    public static let chiitoitsu = Fan.liguLigu

    /// 标准台数。
    public var points: Int {
        switch self {
        case .chickenHand:
            return 0
        case .dealer,
             .concealedHand,
             .selfDrawn,
             .halfMelded,
             .singleWait,
             .edgeWait,
             .closedWait,
             .seatFlower,
             .redDragon,
             .greenDragon,
             .whiteDragon,
             .prevalentWind,
             .seatWind,
             .kongReplacement,
             .robbingTheKong,
             .lastTileDraw,
             .lastTileClaim:
            return 1
        case .dealerStreak,
             .allMelded,
             .flowerSet,
             .pingHu,
             .threeConcealedPungs:
            return 2
        case .concealedSelfDrawn:
            return 3
        case .littleThreeDragons,
             .allPungs,
             .halfFlush:
            return 4
        case .fourConcealedPungs:
            return 5
        case .eightImmortals,
             .sevenRobbingOne,
             .bigThreeDragons,
             .littleFourWinds,
             .fullFlush,
             .fiveConcealedPungs,
             .liguLigu,
             .renhou:
            return 8
        case .bigFourWinds,
             .allHonors,
             .tenhou,
             .chiihou:
            return 16
        }
    }

    /// 是否属于花牌相关台种（用于「不计花牌」家规过滤）。
    public var isFlowerFan: Bool {
        switch self {
        case .seatFlower, .flowerSet, .eightImmortals, .sevenRobbingOne:
            return true
        default:
            return false
        }
    }

    /// 是否属于庄家/连拉台种。
    public var isDealerFan: Bool {
        self == .dealer || self == .dealerStreak
    }

    /// 是否为大牌（8 台及以上）。
    public var isYakuman: Bool { points >= 8 }

    public func effectivePoints(isMenzen: Bool) -> Int {
        points
    }

    public var name: String {
        switch self {
        case .dealer: return "庄家"
        case .dealerStreak: return "连庄拉庄"
        case .concealedHand: return "门清"
        case .selfDrawn: return "自摸"
        case .concealedSelfDrawn: return "门清一摸三"
        case .allMelded: return "全求人"
        case .halfMelded: return "半求人"
        case .singleWait: return "单吊"
        case .edgeWait: return "边张"
        case .closedWait: return "坎张"
        case .seatFlower: return "正花"
        case .flowerSet: return "花杠"
        case .eightImmortals: return "八仙过海"
        case .sevenRobbingOne: return "七抢一"
        case .redDragon: return "红中"
        case .greenDragon: return "青发"
        case .whiteDragon: return "白板"
        case .prevalentWind: return "圈风刻"
        case .seatWind: return "门风刻"
        case .littleThreeDragons: return "小三元"
        case .bigThreeDragons: return "大三元"
        case .littleFourWinds: return "小四喜"
        case .bigFourWinds: return "大四喜"
        case .pingHu: return "平胡"
        case .allPungs: return "碰碰胡"
        case .halfFlush: return "混一色"
        case .fullFlush: return "清一色"
        case .allHonors: return "字一色"
        case .threeConcealedPungs: return "三暗刻"
        case .fourConcealedPungs: return "四暗刻"
        case .fiveConcealedPungs: return "五暗刻"
        case .liguLigu: return "呖咕呖咕"
        case .kongReplacement: return "杠上开花"
        case .robbingTheKong: return "抢杠"
        case .lastTileDraw: return "海底捞月"
        case .lastTileClaim: return "河底捞鱼"
        case .tenhou: return "天胡"
        case .chiihou: return "地胡"
        case .renhou: return "人胡"
        case .chickenHand: return "屁胡"
        }
    }

    /// 一句话说清这个台种怎么来的，给用户核对结果时看。
    public var explanation: String {
        switch self {
        case .dealer: return "担任本局庄家，加 1 台"
        case .dealerStreak: return "庄家连庄（连 N 拉 N），每连一庄加 2 台"
        case .concealedHand: return "没有吃、碰、明杠（暗杠不算破门清）"
        case .selfDrawn: return "自己摸进胡牌张"
        case .concealedSelfDrawn: return "门前清且自摸胡牌（门清 + 自摸 + 不求人合算 3 台）"
        case .allMelded: return "5 组面子全部吃、碰或明杠，最后单吊将眼由他人放枪"
        case .halfMelded: return "5 组面子全部吃、碰或明杠，最后单吊将眼自摸胡牌"
        case .singleWait: return "独听将眼（对子缺一张），只听唯一一张牌"
        case .edgeWait: return "12 独听 3 或 89 独听 7，只听唯一一张牌"
        case .closedWait: return "顺子中间缺一张（如 24 听 3），只听唯一一张牌"
        case .seatFlower: return "摸到对应自己门风座位的花牌（1 东春梅、2 南夏兰、3 西秋竹、4 北冬菊）"
        case .flowerSet: return "集齐春夏秋冬（四季）或梅兰竹菊（四君子）一整组 4 张花牌"
        case .eightImmortals: return "摸齐全部 8 张花牌，直接胡牌计 8 台"
        case .sevenRobbingOne: return "手握 7 张花牌，抢别人摸到的第 8 张花牌胡牌"
        case .redDragon: return "红中的一组刻子或杠"
        case .greenDragon: return "发财的一组刻子或杠"
        case .whiteDragon: return "白板的一组刻子或杠"
        case .prevalentWind: return "与本圈风向相同的一组风牌刻子或杠"
        case .seatWind: return "与自己门风相同的一组风牌刻子或杠"
        case .littleThreeDragons: return "中、发、白里有两组刻子或杠，另一组作将眼"
        case .bigThreeDragons: return "中、发、白三组都是刻子或杠"
        case .littleFourWinds: return "东、南、西、北里有三组刻子或杠，另一组作将眼"
        case .bigFourWinds: return "东、南、西、北四组都是刻子或杠"
        case .pingHu: return "无花、无字、5 组全顺子、两面听牌"
        case .allPungs: return "5 组面子全部是刻子或杠，没有顺子"
        case .halfFlush: return "整手牌只有同一种数牌加字牌"
        case .fullFlush: return "整手牌全部是同一种数牌，没有字牌"
        case .allHonors: return "整手牌全部是东南西北中发白字牌"
        case .threeConcealedPungs: return "3 组自己摸来的暗刻或暗杠"
        case .fourConcealedPungs: return "4 组自己摸来的暗刻或暗杠"
        case .fiveConcealedPungs: return "5 组全部是自己摸来的暗刻或暗杠"
        case .liguLigu: return "门前清 7 个对子加 1 组刻子（八对半，共 17 张）"
        case .kongReplacement: return "开杠或补花后摸上来的补牌自摸胡了"
        case .robbingTheKong: return "别人加杠时，抢胡那张牌"
        case .lastTileDraw: return "摸牌山最后一张牌自摸胡了"
        case .lastTileClaim: return "胡别人打出的全桌最后一张牌"
        case .tenhou: return "庄家起手配牌 17 张直接胡牌"
        case .chiihou: return "闲家第一巡无人吃碰杠花时自摸胡牌"
        case .renhou: return "第一巡无人吃碰杠花时胡别人打出的牌"
        case .chickenHand: return "基本 5 面子加 1 眼胡牌，无额外牌型台数（仅算底分）"
        }
    }
}

public struct FanEntry: Hashable, Codable, Sendable {
    public let fan: Fan
    public let count: Int
    /// 自定义台数覆盖；nil 时按 `fan.points * count`。
    public var han: Int?

    public init(fan: Fan, count: Int = 1, han: Int? = nil) {
        self.fan = fan
        self.count = count
        self.han = han
    }

    public var points: Int { han ?? (fan.points * count) }

    /// 显示名称（针对连庄显示「连N拉N」）。
    public var displayName: String {
        if fan == .dealerStreak {
            return "连\(count)拉\(count)"
        }
        return count > 1 ? "\(fan.name) ×\(count)" : fan.name
    }
}
