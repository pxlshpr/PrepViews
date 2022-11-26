import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepMocks
import SwiftUIPager

struct MealItemNutrientMeters: View {
    
    @StateObject var viewModel: ViewModel

    @State var showingDaily: Bool
    @State var pagerHeight: CGFloat

    @StateObject var page: Page = .first()
    var items = Array(0..<2)

    init(
        foodItem: MealFoodItem,
        meal: DayMeal,
        day: Day,
        shouldCreateSubgoals: Bool = true
    ) {
        let viewModel = ViewModel(
            foodItem: foodItem,
            meal: meal,
            day: day,
            shouldCreateSubgoals: shouldCreateSubgoals
        )
        _viewModel = StateObject(wrappedValue: viewModel)
        
        let showingDaily = true
        _showingDaily = State(initialValue: showingDaily)
        _pagerHeight = State(initialValue: calculateHeight(numberOfRows: showingDaily ? 6 : 4))
    }
    
    var header: some View {
        HStack(alignment: .center) {
            dailyOrMealPicker
                .textCase(.none)
            Spacer()
            goalSetPicker
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
    
    var footer: some View {
        Text("Brighter colored components indicate what this meal will be adding.")
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(Color(.secondaryLabel))
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    var goalSetPicker: some View {
        if showingDaily {
            dietPicker
                .transition(.move(edge: .leading)
                    .combined(with: .opacity)
                    .combined(with: .scale)
                )
        } else {
            mealTypePicker
                .transition(.move(edge: .trailing)
                    .combined(with: .opacity)
                    .combined(with: .scale)
                )
        }
    }
    
    var dietPicker: some View {
        picker()
    }
    
    var mealTypePicker: some View {
        picker()
    }
    
    func picker() -> some View {
        HStack(spacing: 2) {
            Text("🫃🏽")
            Text("Cutting")
                .font(.footnote)
                .bold()
                .foregroundColor(.accentColor)
            Image(systemName: "chevron.up.chevron.down")
                .foregroundColor(Color(.tertiaryLabel))
                .font(.footnote)
                .imageScale(.small)
        }
        .padding(.vertical, 5.5)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .foregroundColor(Color(.tertiarySystemFill))
        )
    }
    
    var dailyOrMealPicker: some View {
        let binding = Binding<Bool>(
            get: { showingDaily },
            set: { newValue in
                withAnimation {
                    showingDaily = newValue
                    page.update(showingDaily ? .moveToFirst : .moveToLast)
                    pagerHeight = calculateHeight(numberOfRows: showingDaily ? 6 : 4)
                }
            }
        )
        return Picker("", selection: binding) {
            Text("Nutrients").tag(true)
            Text("Diet").tag(false)
            Text("Meal Type").tag(false)
        }
        .pickerStyle(.segmented)
//        .frame(width: 150)
    }
    
    var arrow: some View {
        Image(systemName: "arrowshape.forward.fill")
            .rotationEffect(.degrees(90))
            .foregroundColor(Color(.quaternaryLabel))
    }
    
    var pager: some View {
        Pager(
            page: page,
            data: items,
            id: \.self,
            content: { index in
                TempExampleMeters(isLong: index == 0)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)
            }
        )
        .pagingPriority(.simultaneous)
        .onPageWillTransition({ result in
            switch result {
            case .success(let transition):
                withAnimation {
                    showingDaily = transition.currentPage == 1
//                    pagerHeight = showingDaily ? 200 : 140
                    pagerHeight = calculateHeight(numberOfRows: showingDaily ? 6 : 4)
                }
            case .failure:
                break
            }
        })
        .frame(height: pagerHeight)
    }
    
    var body: some View {
        Group {
            arrow
            VStack(spacing: 7) {
                header
                pager
                footer
            }
            .padding(.top, 10)
        }
    }
}

//MARK: - View Model

extension MealItemNutrientMeters {
    class ViewModel: ObservableObject {
        
        let foodItem: MealFoodItem
        let meal: DayMeal
        let day: Day
        let shouldCreateSubgoals: Bool
        
        init(foodItem: MealFoodItem, meal: DayMeal, day: Day, shouldCreateSubgoals: Bool) {
            self.foodItem = foodItem
            self.day = day
            self.meal = meal
            self.shouldCreateSubgoals = shouldCreateSubgoals
        }
    }
}

extension MealItemNutrientMeters.ViewModel {
    var diet: GoalSet? {
        day.goalSet
    }
    
    var hasDiet: Bool {
        diet != nil
    }
}

//TODO: Example Meters (To be removed)

let MeterSpacing = 5.0
let MeterHeight = 20.0
let MeterLabelFontStyle: Font.TextStyle = .body
let MeterLabelFont: Font = Font.system(MeterLabelFontStyle)

func calculateHeight(numberOfRows: Int) -> CGFloat {
    let rows = CGFloat(integerLiteral: numberOfRows)
    let meters = rows * MeterHeight
    let spacing = (rows - 1.0) * MeterSpacing
    let padding = (15.0 * 2.0)
    let extraPadding = (5.0 * 2.0)
    return meters + spacing + padding + extraPadding
}

struct TempExampleMeters: View {
    
    let isLong: Bool
 
    var body: some View {
        if isLong {
            exampleMeters2
        } else {
            exampleMeters
        }
    }
    
    var exampleMeters: some View {
        VStack {
            Grid(alignment: .leading, verticalSpacing: MeterSpacing) {
                GridRow {
                    Text("Energy")
                        .foregroundColor(NutrientMeterComponent.energy.textColor)
                        .font(MeterLabelFont)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .energy, burned: 0, planned: 170, increment: 180))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("170")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("kcal")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Carb")
                        .foregroundColor(NutrientMeterComponent.carb.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .carb, burned: 0, planned: 170, increment: 20))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("12")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Fat")
                        .foregroundColor(NutrientMeterComponent.fat.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .fat, burned: 0, planned: 70, increment: 60))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("28.5")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Protein")
                        .foregroundColor(NutrientMeterComponent.protein.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .protein, burned: 0, planned: 170, increment: 70))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("6")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
        }
    }

    var exampleMeters2: some View {
        VStack {
            Grid(alignment: .leading, verticalSpacing: MeterSpacing) {
                GridRow {
                    Text("Energy")
                        .foregroundColor(NutrientMeterComponent.energy.textColor)
                        .font(MeterLabelFont)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .energy, goal: 400, burned: 0, planned: 170, increment: 180))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("170")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("kcal")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Carb")
                        .foregroundColor(NutrientMeterComponent.carb.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .carb, goal: 400, burned: 0, planned: 170, increment: 20))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("12")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Fat")
                        .foregroundColor(NutrientMeterComponent.fat.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .fat, goal: 300, burned: 0, planned: 70, increment: 60))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("28.5")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Protein")
                        .foregroundColor(NutrientMeterComponent.protein.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .protein, goal: 300, burned: 0, planned: 170, increment: 70))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("6")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Magnesium")
                        .foregroundColor(NutrientMeterComponent.micro(name: "").textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .micro(name: "Magnesium"), goal: 440, burned: 0, planned: 170, increment: 70))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("6")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Sodium")
                        .foregroundColor(NutrientMeterComponent.micro(name: "").textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .micro(name: "Sodium"), goal: 600, burned: 0, planned: 170, increment: 70))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("6")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
        }
    }

}

//MARK: - 👁‍🗨 Previews
import SwiftUISugar
import PrepDataTypes
import PrepMocks

public struct MealItemNutrientMetersPreview: View {
    
    public init() { }
    
    public var body: some View {
        NavigationView {
            FormStyledScrollView {
                textFieldSection
                metersSection
            }
            .navigationTitle("Quantity")
        }
    }

    var metersSection: some View {
        MealItemNutrientMeters(
            foodItem: MealFoodItem(
                food: FoodMock.peanutButter,
                amount: FoodValue(value: 20, unitType: .weight, weightUnit: .g)
            ),
            meal: DayMeal(from: MealMock.preWorkoutWithItems),
            day: DayMock.cutting
        )
    }
    
    var textFieldSection: some View {
        FormStyledSection(header: Text("Weight")) {
            HStack {
                TextField("Required", text: .constant(""))
                Button {
                } label: {
                    HStack(spacing: 5) {
                        Text("g")
                        Image(systemName: "chevron.up.chevron.down")
                            .imageScale(.small)
                    }
                }
                .buttonStyle(.borderless)
            }
        }
    }

}

struct MealItemNutrientMeters_Previews: PreviewProvider {
    static var previews: some View {
//        Color.blue
        MealItemNutrientMetersPreview()
    }
}
