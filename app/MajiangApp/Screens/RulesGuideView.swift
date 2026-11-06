import SwiftUI
import MajiangKit

/// 规则和台种说明：给打台湾 16 张麻将的人看的白话速查表。
struct RulesGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private let basics: [(String, String)] = [
        ("16 张开局 · 17 张胡牌", "台湾麻将闲家开局抓 16 张牌，胡牌时共 17 张（5 组面子 + 1 对将眼；每多一个杠多 1 张）。特殊牌型「呖咕呖咕」（7 对子 + 1 刻子，共 17 张）及「八仙过海」「七抢一」也可胡牌。"),
        ("底 + 台怎么算钱", "采用「底 + 台」制（常见 300/100、100/20、50/20）：单家应付 = 底 + 总台数 × 每台金额。别人放枪由放枪者独付；自摸由另外三家各自付底加台。"),
        ("庄家与连 N 拉 N", "庄家本身加 1 台；庄家胡牌或臭庄（流局）即连庄，连 N 拉 N 额外加 2N 台（合计庄家连拉 = 2N + 1 台，如连一拉一共 3 台、连二拉二共 5 台）。注意：闲家互放枪不计庄家台；闲家自摸时，只有庄家那一份要加付庄家连拉台。"),
        ("门清一摸三", "门前清（无吃、碰、明杠）1 台，自摸 1 台；若门前清且自摸，合称「门清一摸三」（不求人），直接计 3 台。"),
        ("正花与花杠", "春夏秋冬与梅兰竹菊对应座位门风（1 东=春梅、2 南=夏兰、3 西=秋竹、4 北=冬菊），摸到自己的正花每朵 1 台；集齐春夏秋冬或梅兰竹菊一整组 4 张称「一台花 / 花杠」计 2 台；8 朵花全齐为「八仙过海」8 台。"),
    ]

    private var groups: [(points: Int, fans: [Fan])] {
        Dictionary(grouping: Fan.allCases.filter { $0 != .chickenHand }, by: \.points)
            .map { ($0.key, $0.value) }
            .sorted { $0.points < $1.points }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(basics, id: \.0) { title, text in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title).font(.system(size: 16, weight: .semibold))
                            Text(text)
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 12)
                    }

                    ForEach(groups, id: \.points) { group in
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(group.points)").font(Theme.score(28))
                            Text("台").font(Theme.serif(15))
                        }
                        .padding(.top, 28)
                        .padding(.bottom, 4)
                        ForEach(group.fans, id: \.self) { fan in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fan.name).font(.system(size: 16, weight: .medium))
                                Text(fan.explanation)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 11)
                            .overlay(alignment: .top) { Hairline() }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .page()
            .navigationTitle("台湾 16 张规则与台种")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                NavClose("关闭") { dismiss() }
            }
        }
    }
}
