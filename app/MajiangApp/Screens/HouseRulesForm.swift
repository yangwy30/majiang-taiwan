import SwiftUI
import MajiangKit

/// 台湾 16 张麻将桌规表单：支持 300/100、100/20、50/20 预设，以及底分、台金、圈数、严格/宽松平胡、花牌、封顶设置。
struct HouseRulesForm: View {
    @Binding var rules: GameRules
    /// 已经打了几任庄：中途改规则时，总任庄数不能少于这个。
    var playedHands = 0
    /// 截图用：一打开就点开这一项。
    var opening: RuleItem?

    @State private var picking: RuleItem?
    @State private var showMore = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PresetTabs(rules: $rules)

            VStack(spacing: 0) {
                ForEach(RuleItem.main) { item in
                    RuleRow(item: item, rules: rules, large: true) { picking = item }
                }
            }
            .padding(.top, 4)

            Text(example)
                .font(.system(size: 14))
                .foregroundStyle(Theme.gray)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            Button {
                withAnimation(.easeOut(duration: 0.2)) { showMore.toggle() }
            } label: {
                HStack {
                    Text(moreLabel)
                    Spacer()
                    Text(showMore ? "收起" : "›")
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.text(size: 14))
            .padding(.top, 14)

            if showMore {
                VStack(spacing: 0) {
                    Hairline()
                    ForEach(RuleItem.more) { item in
                        RuleRow(item: item, rules: rules, large: false) { picking = item }
                    }
                }
            }
        }
        .sheet(item: $picking) { item in
            RulePicker(item: item, rules: $rules, playedHands: playedHands)
        }
        .onAppear {
            showMore = RuleItem.more.contains { !$0.isStandard(rules) }
            if let opening { picking = opening }
        }
    }

    private var moreLabel: String {
        let changed = RuleItem.more.filter { !$0.isStandard(rules) }.count
        return changed > 0 ? "更多桌规 · 改过 \(changed) 项" : "更多桌规"
    }

    /// 随改随算的示例句。
    private var example: String {
        let deltas = Payment.winDeltas(winner: 1, discarder: nil, dealer: 0, streak: 0, totalFan: 4, rules: rules)
        let childPay = abs(deltas[2])
        let dealerPay = abs(deltas[0])
        let total = deltas[1]
        return "比如闲家自摸 4 台（首庄 +1 台）：两家闲家各付 \(childPay)，庄家付 \(dealerPay)，共赢 \(total)。"
    }
}

// MARK: - 预设

/// 「300 / 100」「100 / 20」「50 / 20」，改过就多出一个「自己定」。
private struct PresetTabs: View {
    @Binding var rules: GameRules

    private var current: Int {
        if rules.scoresLike(.standard) { return 0 }
        if rules.scoresLike(.beginner) { return 1 }
        if rules.scoresLike(.casual) { return 2 }
        return 3
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 22) {
                tab("300 / 100", index: 0, preset: .standard)
                tab("100 / 20", index: 1, preset: .beginner)
                tab("50 / 20", index: 2, preset: .casual)
                if current == 3 { tab("自己定", index: 3, preset: nil) }
                Spacer()
            }
            Hairline()
        }
        .animation(.easeOut(duration: 0.15), value: current)
    }

    private func tab(_ label: String, index: Int, preset: GameRules?) -> some View {
        let on = current == index
        return Button {
            guard var preset else { return }
            preset.yuanPerPoint = rules.yuanPerPoint
            rules = preset
        } label: {
            Text(label)
                .font(.system(size: 15, weight: on ? .medium : .regular))
                .foregroundStyle(on ? Theme.ink : Theme.gray)
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(on ? Theme.ink : .clear).frame(height: 2)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

// MARK: - 一行

private struct RuleRow: View {
    var item: RuleItem
    var rules: GameRules
    var large: Bool
    var action: () -> Void

    var body: some View {
        let value = item.value(rules)
        let standard = item.isStandard(rules)
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(.system(size: 16))
                        if large {
                            Text(item.hint)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.gray)
                        }
                    }
                    Spacer(minLength: 8)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(value.text)
                            .font(large ? .system(size: value.isNumber ? 34 : 20, weight: standard ? .thin : .light)
                                    .monospacedDigit()
                                  : .system(size: 16, weight: standard ? .regular : .medium))
                        if !value.unit.isEmpty {
                            Text(value.unit).font(.system(size: 14))
                        }
                    }
                    .foregroundStyle(standard ? Theme.gray : Theme.ink)
                }
                .frame(minHeight: large ? 84 : 56)
                Hairline()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("点一下改")
    }
}

// MARK: - 选项

private struct RulePicker: View {
    @Environment(\.dismiss) private var dismiss
    var item: RuleItem
    @Binding var rules: GameRules
    var playedHands: Int
    @State private var customYuan = ""

    var body: some View {
        let options = item.options(playedHands: playedHands, current: rules)
        VStack(alignment: .leading, spacing: 0) {
            Text(item.title)
                .font(.system(size: 17, weight: .semibold))
                .padding(.top, 30)
            Text(item.note)
                .font(.system(size: 14))
                .foregroundStyle(Theme.gray)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.bottom, 10)

            ForEach(options) { option in
                let selected = option.isSelected(rules)
                Button {
                    option.apply(&rules)
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Text(option.label)
                            .font(.system(size: 17, weight: selected ? .semibold : .regular))
                        Spacer()
                        if let tag = option.tag {
                            Text(tag).font(.system(size: 14)).foregroundStyle(Theme.gray)
                        }
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .opacity(selected ? 1 : 0)
                    }
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!option.enabled)
                .opacity(option.enabled ? 1 : 0.35)
                .accessibilityAddTraits(selected ? .isSelected : [])
                Hairline(color: Theme.lineSoft)
            }

            if item == .rate {
                HStack {
                    Text("其他").font(.system(size: 17))
                    Spacer()
                    TextField("填一个数", text: $customYuan)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text("元").foregroundStyle(Theme.gray)
                }
                .frame(height: 52)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .foregroundStyle(Theme.ink)
        .presentationDetents([.height(height(options.count))])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(Theme.white)
        .onChange(of: customYuan) { _, text in
            if let value = Double(text.replacingOccurrences(of: ",", with: ".")), value > 0 {
                rules.yuanPerPoint = value
            }
        }
    }

    private func height(_ count: Int) -> CGFloat {
        CGFloat(110 + (count + (item == .rate ? 1 : 0)) * 53)
    }
}

// MARK: - 规则项

enum RuleItem: String, Identifiable, CaseIterable {
    case base, tai, rounds, pingHu, flowers
    case minimum, cap, penalty, rate, swap

    var id: String { rawValue }

    static let main: [RuleItem] = [.base, .tai, .rounds, .pingHu, .flowers]
    static let more: [RuleItem] = [.minimum, .cap, .penalty, .rate, .swap]

    var title: String {
        switch self {
        case .base: return "底"
        case .tai: return "每台"
        case .rounds: return "圈数"
        case .pingHu: return "平胡规则"
        case .flowers: return "花牌"
        case .minimum: return "起胡台数"
        case .cap: return "封顶"
        case .penalty: return "诈胡赔付"
        case .rate: return "1 分折算"
        case .swap: return "每圈换座"
        }
    }

    var hint: String {
        switch self {
        case .base: return "每胡一把固定的基本底分（常见 300、100、50）"
        case .tai: return "每多 1 台加收多少（常见 100、50、20）"
        case .rounds: return "一雀四圈（东南西北 16 任庄，连庄不扣任数）"
        case .pingHu: return "严格平胡须无花、无字、两面听、非庄家、不自摸"
        case .flowers: return "正花 1 台、一台花（花杠）2 台、八仙过海 8 台"
        case .minimum, .cap, .penalty, .rate, .swap: return ""
        }
    }

    var note: String {
        switch self {
        case .base: return "台湾麻将采用「底 + 台」制：单家应付 = 底 + 台数 × 每台金额。常见搭配有 300/100、100/20、50/20。"
        case .tai: return "每 1 台对应的金额。庄家连 N 拉 N 时，庄家与闲家之间额外加收 2N+1 台。"
        case .rounds: return "标准打一雀四圈（东南西北共 16 任庄，庄家连庄或臭庄时继续连庄，北风北下庄完雀）。时间紧可打两圈或一圈。"
        case .pingHu: return "台湾麻将严格平胡要求：无花、无字、5 组全顺子、两面听牌、非庄家、他人放枪不自摸；宽松平胡允许自摸或庄家计平胡。"
        case .flowers: return "对应自己门风（1 东春梅、2 南夏兰、3 西秋竹、4 北冬菊）每朵 1 台，集齐春夏秋冬或梅兰竹菊一组计 2 台，八仙过海 8 台。"
        case .minimum: return "台湾麻将默认 0 台即可胡牌（屁胡只收底分）。部分家规要求至少 1 台或 2 台起胡。"
        case .cap: return "默认不封顶。怕一把大牌输太多可以设 8 台或 16 台封顶。"
        case .penalty: return "推倒了却凑不成 17 张胡牌，赔另外三家各这么多分，这一局接着打。"
        case .rate: return "默认 1 分 = 1 元（即底 300 台 100 直接就是金额）。如需按比例折算可在此调整。"
        case .swap: return "朋友局一般固定座位不换座。"
        }
    }

    func isStandard(_ rules: GameRules) -> Bool {
        let standard = GameRules.standard
        switch self {
        case .base: return rules.basePoints == standard.basePoints
        case .tai: return rules.taiPoints == standard.taiPoints
        case .rounds: return rules.totalHands == standard.totalHands
        case .pingHu: return rules.strictPingHu == standard.strictPingHu
        case .flowers: return rules.includeFlowers == standard.includeFlowers
        case .minimum: return rules.minimumFan == standard.minimumFan
        case .cap: return rules.fanCap == standard.fanCap
        case .penalty: return rules.falseWinPenalty == standard.falseWinPenalty
        case .rate: return rules.yuanPerPoint == standard.yuanPerPoint
        case .swap: return rules.swapSeatsEachRound == standard.swapSeatsEachRound
        }
    }

    func value(_ rules: GameRules) -> (text: String, unit: String, isNumber: Bool) {
        switch self {
        case .base: return ("\(rules.basePoints)", "", true)
        case .tai: return ("\(rules.taiPoints)", "/台", true)
        case .rounds:
            if rules.totalHands == 16 { return ("四圈 16 庄", "", false) }
            if rules.totalHands == 8 { return ("两圈 8 庄", "", false) }
            if rules.totalHands == 4 { return ("一圈 4 庄", "", false) }
            return ("\(rules.totalHands)", "庄", true)
        case .pingHu: return (rules.strictPingHu ? "严格" : "宽松", "", false)
        case .flowers: return (rules.includeFlowers ? "计花牌" : "不计", "", false)
        case .minimum: return ("\(rules.minimumFan) 台", "", false)
        case .cap: return rules.fanCap > 0 ? ("\(rules.fanCap) 台", "", false) : ("不封顶", "", false)
        case .penalty: return ("\(rules.falseWinPenalty)", "", false)
        case .rate: return ("\(rules.yuanPerPoint.yuanText) 元", "", false)
        case .swap: return (rules.swapSeatsEachRound ? "换" : "不换", "", false)
        }
    }

    func options(playedHands: Int, current: GameRules) -> [RuleOption] {
        switch self {
        case .base:
            var values = [300, 200, 100, 50, 500]
            if !values.contains(current.basePoints) { values.append(current.basePoints); values.sort() }
            return values.map { RuleOption.choice(\.basePoints, $0, "底 \($0)") }
        case .tai:
            var values = [100, 50, 20, 10, 200]
            if !values.contains(current.taiPoints) { values.append(current.taiPoints); values.sort() }
            return values.map { RuleOption.choice(\.taiPoints, $0, "每台 \($0)") }
        case .rounds:
            return [(16, "一雀四圈（东南西北 16 任庄）"), (8, "两圈半场（东南 8 任庄）"), (4, "一圈快局（东风 4 任庄）")].map { hands, label in
                var option = RuleOption.choice(\.totalHands, hands, label)
                option.enabled = hands >= playedHands
                return option
            }
        case .pingHu:
            return [true, false].map {
                RuleOption.choice(\.strictPingHu, $0, $0 ? "严格平胡（无花无字、非庄家、他人放枪）" : "宽松平胡（自摸或庄家也可计平胡）")
            }
        case .flowers:
            return [true, false].map { RuleOption.choice(\.includeFlowers, $0, $0 ? "计花牌（正花、花杠、八仙过海）" : "不计花牌") }
        case .minimum:
            return [0, 1, 2, 4].map { RuleOption.choice(\.minimumFan, $0, $0 == 0 ? "0 台起胡（可屁胡）" : "\($0) 台起胡") }
        case .cap:
            return [(0, "不封顶"), (16, "16 台封顶"), (8, "8 台封顶")].map {
                RuleOption.choice(\.fanCap, $0.0, $0.1)
            }
        case .penalty:
            var values = [800, 500, 200, 150]
            if !values.contains(current.falseWinPenalty) { values.append(current.falseWinPenalty) }
            return values.map { RuleOption.choice(\.falseWinPenalty, $0, "每家 \($0)") }
        case .rate:
            var values = [0.5, 1.0, 2.0, 5.0]
            if !values.contains(current.yuanPerPoint) { values.append(current.yuanPerPoint); values.sort() }
            return values.map { RuleOption.choice(\.yuanPerPoint, $0, "\($0.yuanText) 元", marksStandard: false) }
        case .swap:
            return [false, true].map { RuleOption.choice(\.swapSeatsEachRound, $0, $0 ? "换座" : "不换") }
        }
    }
}

struct RuleOption: Identifiable {
    var label: String
    var tag: String?
    var isSelected: (GameRules) -> Bool
    var apply: (inout GameRules) -> Void
    var enabled = true

    var id: String { label }

    static func choice<T: Equatable>(
        _ keyPath: WritableKeyPath<GameRules, T>,
        _ value: T,
        _ label: String,
        tag: String? = nil,
        marksStandard: Bool = true
    ) -> RuleOption {
        let isStandard = marksStandard && GameRules.standard[keyPath: keyPath] == value
        return RuleOption(
            label: label,
            tag: isStandard ? "标准" : tag,
            isSelected: { $0[keyPath: keyPath] == value },
            apply: { $0[keyPath: keyPath] = value }
        )
    }
}

extension Double {
    var yuanText: String { formatted(.number.precision(.fractionLength(0...2)).grouping(.never)) }
}
