import Foundation
import MajiangKit

extension HandRecord {
    /// 胡牌的那一局才有。
    var win: WinRecord? {
        if case .win(let win) = outcome { return win }
        return nil
    }

    var isWin: Bool { win != nil }

    /// 账本里的一行标题：「莉莉胡 · 阿强放枪 · 碰碰胡 · 4 台」「这局臭庄」。
    func title(in game: Game) -> String {
        let name = { (i: Int) in game.players[i].name }
        switch outcome {
        case .win(let win):
            var parts = [win.discarder.map { "\(name(win.winner))胡 · \(name($0))放枪" } ?? "\(name(win.winner))自摸"]
            if let top = win.fans.first(where: { !$0.fan.isDealerFan }), top.points >= 2 {
                parts.append(top.fan.name)
            }
            let paid = game.rules.paidFan(win)
            parts.append("\(paid) 台")
            return parts.joined(separator: " · ")
        case .drawn:
            return "这局臭庄（流局连庄）"
        case .falseWin(let offender):
            return "\(name(offender))诈胡"
        case .manual(_, let note):
            return note.isEmpty ? "直接改分" : "直接改分 · \(note)"
        }
    }

    /// 标题下面一行：谁付了多少。
    func detail(in game: Game) -> String {
        if case .drawn = outcome {
            let dealerName = game.players[game.dealer(ofHand: handIndex)].name
            let nextStreak = game.streak(ofHand: handIndex) + 1
            return "不计分，\(dealerName)继续连庄（连\(nextStreak)拉\(nextStreak)）"
        }
        let losers = deltas.indices.filter { deltas[$0] < 0 }
        var groups: [(amount: Int, players: [Int])] = []
        for i in losers {
            if let g = groups.firstIndex(where: { $0.amount == deltas[i] }) {
                groups[g].players.append(i)
            } else {
                groups.append((deltas[i], [i]))
            }
        }
        groups.sort { $0.amount < $1.amount }
        return groups.map { group in
            let names = group.players.map { game.players[$0].name }.joined(separator: "、")
            return group.players.count > 1 ? "\(names)各 \(Theme.signed(group.amount))" : "\(names) \(Theme.signed(group.amount))"
        }
        .joined(separator: "，")
    }

    /// 右边的数字：胡牌的人赢了多少；诈胡的人赔了多少；流局、直接改分不显示。
    var headline: Int? {
        switch outcome {
        case .win(let win): deltas[win.winner]
        case .falseWin(let offender): deltas[offender]
        case .drawn, .manual: nil
        }
    }
}

extension Game {
    /// 「¥76」「−¥12.5」。
    func moneyText(_ points: Int) -> String {
        let value = money(forPoints: points)
        let text = abs(value).formatted(.number.precision(.fractionLength(0...2)))
        return value < 0 ? "−$\(text)" : "$\(text)"
    }

    /// 现在打到的那一局。
    var displayHand: Int { currentHandIndex }

    /// 「东圈 · 第 1 庄（连1拉1）」。
    var handLabel: String {
        let h = displayHand
        let wind = prevalentWind(ofHand: h).name
        let slot = dealerSlot(ofHand: h) + 1
        let s = streak(ofHand: h)
        if s > 0 {
            return "\(wind)圈 · 第 \(slot) 庄 · 连\(s)拉\(s)"
        }
        return "\(wind)圈 · 第 \(slot) 庄"
    }

    /// 规则一行：「台湾 16 张 · 底 300 台 100」。
    var rulesSummary: String { rules.summary }

    /// 结果页和「这一局」底下的「底 + 台」与庄家连拉收付说明。
    func paymentExplanation(_ win: WinRecord, deltas: [Int]) -> String {
        let base = rules.basePoints
        let taiVal = rules.taiPoints
        let handTai = rules.paidHandFan(win)
        let streakCount = win.context.streakCount
        let dealerExtra = Payment.dealerTai(streak: streakCount)
        let streakLabel = streakCount > 0 ? "庄家连\(streakCount)拉\(streakCount)（+\(dealerExtra) 台）" : "庄家（+1 台）"

        var lines: [String] = []
        if let discarder = win.discarder {
            if win.context.isDealer {
                let totalTai = rules.cappedFan(handTai + dealerExtra)
                lines.append("庄家胡放枪：底 \(base) + \(totalTai) 台 × \(taiVal)（含\(streakLabel)），由放枪的\(players[discarder].name)一家付 \(deltas[win.winner])。")
            } else if abs(deltas[discarder]) == Payment.points(forTai: handTai + dealerExtra, rules: rules) && dealerExtra > 0 && Payment.points(forTai: handTai + dealerExtra, rules: rules) != Payment.points(forTai: handTai, rules: rules) {
                let totalTai = rules.cappedFan(handTai + dealerExtra)
                lines.append("闲家胡庄家放枪：底 \(base) + \(totalTai) 台 × \(taiVal)（牌型 \(handTai) 台 + \(streakLabel)），由庄家\(players[discarder].name)付 \(deltas[win.winner])。")
            } else {
                let totalTai = rules.cappedFan(handTai)
                lines.append("闲家互放枪：底 \(base) + \(totalTai) 台 × \(taiVal)（不计庄家台），由放枪的\(players[discarder].name)一家付 \(deltas[win.winner])。")
            }
        } else if win.context.isDealer {
            let totalTai = rules.cappedFan(handTai + dealerExtra)
            let each = Payment.points(forTai: handTai + dealerExtra, rules: rules)
            lines.append("庄家自摸：底 \(base) + \(totalTai) 台 × \(taiVal)（含\(streakLabel)），三家闲家各付 \(each)，共赢 \(deltas[win.winner])。")
        } else {
            let childTai = rules.cappedFan(handTai)
            let dealerTai = rules.cappedFan(handTai + dealerExtra)
            let childPay = Payment.points(forTai: handTai, rules: rules)
            let dealerPay = Payment.points(forTai: handTai + dealerExtra, rules: rules)
            lines.append("闲家自摸：另外两家闲家各付 \(childPay)（底 \(base) + \(childTai) 台 × \(taiVal)），庄家多算\(streakLabel)付 \(dealerPay)（底 \(base) + \(dealerTai) 台 × \(taiVal)），共赢 \(deltas[win.winner])。")
        }
        if rules.yuanPerPoint != 1 {
            lines.append("按 1 分 = \(rules.yuanPerPoint.yuanText) 元，\(players[win.winner].name)这局赢 \(moneyText(deltas[win.winner]))。")
        }
        return lines.joined(separator: "\n")
    }

    /// 「这一局」牌下面的一句话：「自己摸到 7饼，自摸胡了。」「阿强打出 6饼，莉莉胡了。」
    func winSentence(_ win: WinRecord) -> String? {
        guard let tile = win.hand?.winningTile.displayName else { return nil }
        let winner = players[win.winner].name
        guard let discarder = win.discarder.map({ players[$0].name }) else {
            return win.context.kongInvolved ? "开杠或补花后摸进 \(tile)，自摸胡了。" : "自己摸到 \(tile)，自摸胡了。"
        }
        return win.context.kongInvolved ? "\(discarder)加杠的 \(tile) 被抢，\(winner)胡牌。" : "\(discarder)打出 \(tile)，\(winner)胡牌。"
    }
}

extension GameRules {
    /// 底台描述，如「底 300 / 台 100」。
    var baseTaiLabel: String {
        "底 \(basePoints) / 台 \(taiPoints)"
    }

    /// 跟标准 300/100 桌规不一样的地方，一项一个短语。
    var houseRuleParts: [String] {
        let standard = GameRules.standard
        var parts: [String] = []
        if basePoints != standard.basePoints || taiPoints != standard.taiPoints {
            parts.append("\(basePoints)/\(taiPoints)")
        }
        if totalHands != standard.totalHands {
            parts.append(totalHands == 4 ? "一圈 4 庄" : totalHands == 8 ? "两圈 8 庄" : "\(totalHands) 庄")
        }
        if minimumFan != standard.minimumFan {
            parts.append("\(minimumFan) 台起胡")
        }
        if !strictPingHu {
            parts.append("宽松平胡")
        }
        if fanCap > 0 {
            parts.append("封顶 \(fanCap) 台")
        }
        if !includeFlowers {
            parts.append("不计花牌")
        }
        if falseWinPenalty != standard.falseWinPenalty {
            parts.append("诈胡赔 \(falseWinPenalty)")
        }
        if swapSeatsEachRound {
            parts.append("每圈换座")
        }
        return parts
    }

    /// 分享图、结算页：「台湾 16 张 · 底 300 / 台 100」。
    var summary: String {
        var items = ["台湾 16 张", baseTaiLabel]
        let extras = houseRuleParts.filter { $0 != "\(basePoints)/\(taiPoints)" }
        items.append(contentsOf: extras)
        if yuanPerPoint != 1 {
            items.append("1 分 = \(yuanPerPoint.yuanText) 元")
        }
        return items.joined(separator: " · ")
    }

    /// 开局页那一行：「底 300 / 台 100 · 四圈」「底 100 / 台 20 · 四圈」。
    var shortSummary: String {
        let rounds = totalHands == 16 ? "四圈" : totalHands == 8 ? "两圈" : totalHands == 4 ? "一圈" : "\(totalHands) 庄"
        var text = "\(baseTaiLabel) · \(rounds)"
        if yuanPerPoint != 1 {
            text += " · 1 分 \(yuanPerPoint.yuanText) 元"
        }
        return text
    }

    /// 牌桌顶上那一行，只有桌规跟标准不一样时才有。
    var houseRuleBadge: String? {
        let house = houseRuleParts
        guard !house.isEmpty || yuanPerPoint != 1 else { return nil }
        var items = ["桌规"] + (house.isEmpty ? [baseTaiLabel] : house)
        if yuanPerPoint != 1 {
            items.append("1 分 \(yuanPerPoint.yuanText) 元")
        }
        return items.joined(separator: " · ")
    }
}

extension Date {
    /// 「10月25日 周六」。
    var dayLabel: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        let c = calendar.dateComponents([.month, .day, .weekday], from: self)
        return "\(c.month!)月\(c.day!)日 \(calendar.shortWeekdaySymbols[c.weekday! - 1])"
    }
}
