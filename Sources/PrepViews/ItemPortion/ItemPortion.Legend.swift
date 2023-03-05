import SwiftUI
import SwiftHaptics
import PrepCoreDataStack

//MARK: - Legend

extension ItemPortion {
    struct Legend: View {
        
        @Environment(\.colorScheme) var colorScheme
        
        let spacing: CGFloat = 2
        let colorSize: CGFloat = 10
        let cornerRadius: CGFloat = 2
        
        let barCornerRadius: CGFloat = 3.5
        let barHeight: CGFloat = 14

        /// Note: We're using an `@ObservedObject` here instead of `@EnvironmentObject` so that
        /// we are able to set the internal `showingLegend` bool during initialization as opposed to in the
        /// `onAppear` modifier—which causes it to be temporarily whatever value we set it with and
        /// then animate to the actual value saved in `UserOptions`, causing a jump in the height
        /// when transitioning between types.
        @ObservedObject var model: Model
//        @EnvironmentObject var model: Model
        @State var showingLegend: Bool
        
        let didUpdateUser = NotificationCenter.default.publisher(for: .didUpdateUser)
        
        init(model: Model) {
            self.model = model
            _showingLegend = State(initialValue: UserManager.showingLegendForPortion)
        }
    }
}

extension ItemPortion.Legend {
    
    var body: some View {
        VStack(alignment: .leading) {
            legendButton
            if showingLegend {
                grid
            }
        }
        .onReceive(didUpdateUser, perform: didUpdateUser)
    }
    
    func didUpdateUser(notification: Notification) {
        withAnimation {
            showingLegend = UserManager.showingLegendForPortion
        }
    }
    
    var legendButton: some View {
        func tapped() {
            Haptics.feedback(style: .soft)
            withAnimation {
                showingLegend.toggle()
                UserManager.showingLegendForPortion = showingLegend
            }
        }
        
        var label: some View {
            HStack(spacing: 5) {
                Text("\(showingLegend ? "Hide" : "Show") Legend")
                Image(systemName: "chevron.right")
                    .rotationEffect(showingLegend ? .degrees(90) : .degrees(0))
                    .font(.caption2)
                    .imageScale(.small)
            }
        }
        
        var legacyView: some View {
            label
                .foregroundColor(showingLegend ? .accentColor : .secondary)
                .onTapGesture { tapped() }
        }
        
        var button: some View {
            Button {
                tapped()
            } label: {
                label
                    .bold()
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.accentColor.opacity(
                                colorScheme == .dark ? 0.1 : 0.15
                            ))
                    )
            }
        }
        
//        return legacyView
        return button
    }
    
    var totalText: Text {
        var suffix: String {
            guard !model.componentsFromFood.isEmpty else { return "" }
            let relativeBrightness = colorScheme == .light ? "lighter" : "darker"
            return " (\(relativeBrightness))"
        }
        switch model.portionPage {
        case .nutrients, .diet:
            let prefix: String
            if model.day?.date.startOfDay == Date().startOfDay {
                prefix = "Today"
            } else {
                prefix = "This day"
            }
            return Text("\(prefix)'s total **without this food**\(suffix)")
        case .meal:
            return Text("This meal's total **without this food**\(suffix)")
        }
    }
    
    var foodText: Text {
        var suffix: String {
            guard !model.componentsWithTotals.isEmpty else { return "" }
            let relativeBrightness = colorScheme == .light ? "darker" : "lighter"
            return " (\(relativeBrightness))"
        }
        return Text("What **this food** adds\(suffix)")
    }
    
    var unboundedRemainderText: some View {
        VStack(alignment: .leading) {
            Text("Remainder till your RDA* is reached:")
            HStack(spacing: 2) {
                Text("•")
                    .foregroundColor(Color(.quaternaryLabel))
                Text("If the bar is in green, this is your **upper limit**")
            }
            HStack(spacing: 2) {
                Text("•")
                    .foregroundColor(Color(.quaternaryLabel))
                Text("Otherwise, it's your **minimum**")
            }
        }
    }
    
    var boundedRemainderText: some View {
        var goalDescription: String {
            switch model.portionPage {
            case .nutrients:
                return "RDA*"
//            case .meal:
//                return "meal goal"
//            case .diet:
//                return "daily goal"
            case .meal, .diet:
                return "goal"
            }
        }

        var showMinimumGoal: Bool {
            model.showFirstDashedLine || model.showSolidLine
        }
        
        return Group {
            VStack(alignment: .leading, spacing: 3) {
//                Text("Lines marking your \(goalDescription)")
                if showMinimumGoal {
                    HStack(alignment: .top, spacing: 2) {
                        if model.showSecondDashedLine {
                            Text("•")
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        if model.showFirstDashedLine && model.showSolidLine {
                            if model.showSecondDashedLine {
                                Text("Solid or first dotted line: **Minimum** \(goalDescription)")
                            } else {
                                Text("Solid or dotted line: **Minimum** \(goalDescription)")
                            }
                        } else if model.showFirstDashedLine {
                            if model.showSecondDashedLine {
                                Text("First dotted line: **Minimum** \(goalDescription)")
                            } else {
                                Text("Dotted line: **Minimum** \(goalDescription)")
                            }
                        } else if model.showSolidLine {
                            Text("Line: **Minimum** \(goalDescription)")
                        }
                    }
                }
                
                if model.showSecondDashedLine {
                    HStack(spacing: 2) {
                        if showMinimumGoal {
                            Text("•")
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        Text("Second dotted line: **Maximum** \(goalDescription)")
                    }
                }
            }
        }
    }
    
    var completeGoalsText: Text {
        var suffix: String {
//            "accomplished"
            "met"
        }
        
        switch model.portionPage {
        case .nutrients:
            return Text("RDA* \(suffix)")
        case .meal:
            return Text("Meal goal \(suffix)")
        case .diet:
            return Text("Daily goal \(suffix)")
        }
    }
    
    var excessGoalsText: Text {
        Text("Upper limit exceeded")
    }
    
    var grid: some View {
        func goalCompletionBar(isExcess: Bool) -> some View {
            var fillColor: Color {
                isExcess
                ? NutrientMeter.Model.Colors.Excess.fill
                : NutrientMeter.Model.Colors.Complete.fill
            }
            
            var placeholderColor: Color {
                isExcess
                ? NutrientMeter.Model.Colors.Excess.placeholder
                : NutrientMeter.Model.Colors.Complete.placeholder
            }
            
            var text: Text {
                isExcess
                ? excessGoalsText
                : completeGoalsText
            }
            
            return GridRow {
                HStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: barCornerRadius)
                            .fill(fillColor.gradient)
                        if !model.componentsWithTotals.isEmpty {
                            RoundedRectangle(cornerRadius: barCornerRadius)
                                .fill(placeholderColor.gradient)
                                .frame(width: barWidth / 2.0)
                        }
                    }
                }
                .frame(width: barWidth, height: barHeight)
                .cornerRadius(barCornerRadius)
                text
            }
        }
        
        @ViewBuilder
        var totalRow: some View {
            if !model.componentsWithTotals.isEmpty {
                GridRow {
                    totalColors
                    totalText
                }
            }
        }
        
        @ViewBuilder
        var foodRow: some View {
            if !model.componentsFromFood.isEmpty && !model.componentsWithTotals.isEmpty {
                GridRow {
                    foodColors
                    foodText
                }
            }
        }
        
        var showLinesRow: Bool {
            model.showSolidLine ||
            model.showFirstDashedLine ||
            model.showSecondDashedLine
        }
        
        var showDashedLine: Bool {
            model.showFirstDashedLine ||
            model.showSecondDashedLine
        }
        
        @ViewBuilder
        var linesRow: some View {
            if showLinesRow {
                GridRow(alignment: .top) {
//                GridRow {
                    ZStack(alignment: .leading) {
                        NutrientMeter.Model.Colors.Empty.fill
                            .frame(width: barWidth, height: barHeight)
                            .cornerRadius(barCornerRadius)
                        if model.showSolidLine {
                            DottedLine()
                                .stroke(style: StrokeStyle(
                                    lineWidth: 2,
                                    dash: [100])
                                )
                                .frame(width: 1)
                                .foregroundColor(Color(.systemGroupedBackground))
                                .offset(x: (barWidth / (showDashedLine ? 3.0 : 2.0)) - 1.0)
                        }
                        if model.showFirstDashedLine || model.showSecondDashedLine {
                            DottedLine()
                                .stroke(style: StrokeStyle(
                                    lineWidth: 2,
                                    dash: [2])
                                )
                                .frame(width: 1)
                                .foregroundColor(Color(.systemGroupedBackground))
                                .offset(x: (barWidth / (model.showSolidLine ? 1.5 : 2.0)) - 1.0)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: 1)
                    boundedRemainderText
                }
            }
        }
        
        @ViewBuilder
        var completionRow: some View {
            if model.showCompletion {
                goalCompletionBar(isExcess: false)
            }
        }
        
        @ViewBuilder
        var excessRow: some View {
            if model.showExcess {
                goalCompletionBar(isExcess: true)
            }
        }
        
        @ViewBuilder
        var rdaExplanation: some View {
            if model.portionPage == .nutrients && showLinesRow {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("*")
                        .font(.callout)
                        .offset(y: 3)
                    Text("**Recommended Dietary Allowance (RDA)**: Average daily level of intake sufficient to meet your nutrient requirements. [You can customise this in settings.](http://something.com)")
                }
            }
        }
        
        @ViewBuilder
        var generatedGoals: some View {
            if model.showMealSubgoals || model.showDietAutoGoals {
                GridRow {
                    Group {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "sparkles")
                                Spacer()
                            }
                        }
                        .frame(width: barWidth)
                        if model.showMealSubgoals {
                            VStack(alignment: .leading, spacing: 2) {
//                                Text("**Meal Subgoals**")
//                                Text("Calculated by taking the remainder of your goals for the day and dividing them by how many more meals your have left to plan (including this one).")
                                Text("**Calculated Goal**")
                                Text("Calculated based on your diet goals.")
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("**Implied Goal**")
//                                Text("Calculated since you have 3 of the 4 components of the energy equation in this diet. Staying within this goal will help you avoid overshooting them.")
                                Text("Calculated based on your other goals.")
                            }
                        }
                    }
                    .padding(.top, 5)
                }
            }
        }
        
        return VStack(alignment: .leading) {
            Grid(alignment: .leading) {
                totalRow
                foodRow
                completionRow
                excessRow
                linesRow
                generatedGoals
            }
            rdaExplanation
        }
    }
    
    var maxColorCount: Int {
        var count = max(model.componentsWithTotals.count, model.componentsFromFood.count)
        if model.showExcess { count += 1 }
        if model.showCompletion { count += 1 }
        return count
    }
    var barWidth: CGFloat {
        let MinimumBarWidth: CGFloat = colorSize * 2
        let count = CGFloat(maxColorCount)
        let calculated = (count * colorSize) + ((count - 1) * spacing)
        return max(MinimumBarWidth, calculated)
    }
    
    var totalColors: some View {
        HStack(spacing: spacing) {
            ForEach(model.componentsWithTotals, id: \.self) {
                colorBox($0.preppedColor)
            }
            if model.showCompletion {
                colorBox(NutrientMeter.Model.Colors.Complete.placeholder)
            }
            if model.showExcess {
                colorBox(NutrientMeter.Model.Colors.Excess.placeholder)
            }
        }
    }
    
    var foodColors: some View {
        HStack(spacing: spacing) {
            ForEach(model.componentsFromFood, id: \.self) {
                colorBox($0.eatenColor)
            }
            if model.showCompletion {
                colorBox(NutrientMeter.Model.Colors.Complete.fill)
            }
            if model.showExcess {
                colorBox(NutrientMeter.Model.Colors.Excess.fill)
            }
        }
    }
    
    func colorBox(_ color: Color) -> some View {
        color
            .frame(width: colorSize, height: colorSize)
            .cornerRadius(cornerRadius)
    }
}

