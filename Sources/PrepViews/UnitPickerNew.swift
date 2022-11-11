/**
 
 This should eventually replace `UnitPicker`.
 
 */
import SwiftUI
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar

//MARK: - Logic
extension UnitPickerGrid {
    /**
     We're currently only showing the AddSize button if the the flag is true in addition to the sizes list being empty
     */
    var shouldShowAddSizeButton: Bool {
        allowAddSize && (standardSizes + volumePrefixedSizes).isEmpty
    }
    
    var shouldShowServing: Bool {
        includeServing && filteredType == nil
    }
    
    var typesWithOptions: [UnitType] {
        [UnitType.weight, UnitType.volume, UnitType.size]
    }

    var weightUnits: [WeightUnit] {
        [.g, .oz, .mg, .lb, .kg]
    }

    var volumeUnits: [VolumeUnit] {
        [.cup, .mL, .fluidOunce, .teaspoon, .tablespoon, .liter, .pint, .quart, .gallon]
    }
    
    //MARK: Actions
    func pickedUnit(unit: FormUnit) {
        didPickUnit(unit)
        Haptics.feedback(style: .heavy)
        dismiss()
    }
}


protocol Option {
    var optionId: String { get }
    var optionTitle: String { get }
    var optionDetail: String { get }
}

extension FormSize: Option {
    var optionId: String {
        self.id
    }
    
    var optionTitle: String {
        self.name
    }
    
    var optionDetail: String {
        self.scaledAmountString
    }
}

extension WeightUnit: Option {
    var optionId: String {
        "\(self.rawValue)"
    }
    
    var optionTitle: String {
        self.description.lowercased()
    }
    
    var optionDetail: String {
        self.shortDescription
    }
}

extension VolumeUnit: Option {
    var optionId: String {
        "\(self.rawValue)"
    }
    
    var optionTitle: String {
        self.description.lowercased()
    }
    
    var optionDetail: String {
        self.shortDescription
    }
}

struct VolumePrefixedSizeOption {
    let size: FormSize
    let volumeUnit: VolumeUnit
}

extension VolumePrefixedSizeOption: Option {
    var optionId: String {
        "\(self.size.id)\(volumeUnit.rawValue)"
    }
    
    var optionTitle: String {
        "\(volumeUnit.shortDescription)"
    }
    
    var optionDetail: String {
        size.scaledAmountString(for: volumeUnit, using: .defaultUnits)
    }
}

extension FormSize {
    var volumePrefixedSizeOptions: [VolumePrefixedSizeOption] {
        let volumeUnits: [VolumeUnit] = [.cup, .mL, .fluidOunce, .teaspoon, .tablespoon]
        return volumeUnits.map {
            VolumePrefixedSizeOption(size: self, volumeUnit: $0)
        }
    }
    
    func scaledAmount(for volumeUnit: VolumeUnit, using userVolumeUnits: UserExplicitVolumeUnits) -> Double {
        guard let volumePrefixUnit else { return scaledAmount }
        let from = userVolumeUnits.volumeExplicitUnit(for: volumePrefixUnit)
        let to = userVolumeUnits.volumeExplicitUnit(for: volumeUnit)
        let scale = to.scale(against: from)
        return scaledAmount * scale
    }
    
    func scaledAmountString(for volumeUnit: VolumeUnit, using userVolumeUnits: UserExplicitVolumeUnits) -> String {
        guard volumePrefixUnit != nil else { return scaledAmountString }
        return "\(scaledAmount(for: volumeUnit, using: userVolumeUnits).cleanAmount) \(unit.shortDescription)"
    }
}


struct ServingOption {
    let description: String
}

extension ServingOption: Option {
    var optionId: String {
        "_serving"
    }
    
    var optionTitle: String {
        "serving"
    }
    
    var optionDetail: String {
        description
    }
}

public struct UnitPickerGrid: View {
    
    @Environment(\.dismiss) var dismiss
    @Namespace var namespace
    
    @State var isGrid: Bool = false
    @State var type: UnitType
    @State var pickedUnit: FormUnit

    @State var pickedVolumePrefixUnit: FormUnit = .volume(.cup)
    
    var includeServing: Bool
    var includeVolumes: Bool
    var includeWeights: Bool
    var allowAddSize: Bool
    var filteredType: UnitType?
    var servingDescription: String?
    
    var didPickUnit: (FormUnit) -> ()
    var didTapAddSize: (() -> ())?

    let standardSizes: [FormSize]
    let volumePrefixedSizes: [FormSize]
    
    public init(
        pickedUnit unit: FormUnit = .weight(.g),
        includeServing: Bool = true,
        includeWeights: Bool = true,
        includeVolumes: Bool = true,
        sizes: [FormSize],
        servingDescription: String? = nil,
        allowAddSize: Bool = true,
        filteredType: UnitType? = nil,
        didTapAddSize: (() -> ())? = nil,
        didPickUnit: @escaping (FormUnit) -> ())
    {
        self.didPickUnit = didPickUnit
        self.didTapAddSize = didTapAddSize
        self.includeServing = includeServing
        self.includeWeights = includeWeights
        self.includeVolumes = includeVolumes
        self.servingDescription = servingDescription
        self.allowAddSize = allowAddSize
        self.filteredType = filteredType
        
        self.standardSizes = sizes.standardSizes
        self.volumePrefixedSizes = sizes.volumePrefixedSizes
        
        _pickedUnit = State(initialValue: unit)
        _type = State(initialValue: unit.unitType)
    }
    
    @State var presentationDetent: PresentationDetent = .medium
    
    public var body: some View {
        NavigationView {
//            longList
            content
            .navigationTitle(navigationTitleString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { gridButton }
            .toolbar { closeButton }
        }
        .onChange(of: type) { newValue in
            if type == .serving {
                pickedUnit(unit: .serving)
            }
        }
        .presentationDetents([.medium, .large], selection: $presentationDetent)
        .presentationDragIndicator(.hidden)
    }
    
    var closeButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                Haptics.feedback(style: .soft)
                dismiss()
            } label: {
                closeButtonLabel
            }
        }
    }
    
    var gridButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Haptics.feedback(style: .rigid)
                withAnimation {
                    isGrid.toggle()
                    if isGrid {
                        presentationDetent = .large
                    }
                }
            } label: {
                Image(systemName: isGrid ? "square.grid.3x2.fill" : "square.grid.3x2")
                    .imageScale(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var content: some View {
        FormStyledScrollView {
            standardSizesSection
            volumePrefixedSizesSection
            weightUnitsSection
            volumeUnitsSection
        }
    }
    
    var standardSizeOptions: [Option] {
        var options: [Option] = []
        if includeServing {
            options.append(ServingOption(description: servingDescription ?? ""))
        }
        options.append(contentsOf: standardSizes.map{ $0 as Option})
        return options
    }
    

    @ViewBuilder
    var standardSizesSection: some View {
        if !standardSizes.isEmpty {
            OptionsSection(
                header: "Sizes",
                options: standardSizeOptions,
                isGrid: $isGrid
            ) { option in
                guard let size = option as? FormSize else { return }
                pickedUnit(unit: .size(size, nil))
            }
        }
    }

    @ViewBuilder
    var volumePrefixedSizesSection: some View {
        ForEach(volumePrefixedSizes, id: \.self) {
            volumePrefixedSizeSection(for: $0)
        }
    }
    
    func volumePrefixedSizeSection(for size: FormSize) -> some View {
        OptionsSection(
            header: size.name,
            options: size.volumePrefixedSizeOptions,
            isGrid: $isGrid
        ) { option in
            guard let option = option as? VolumePrefixedSizeOption else { return }
            pickedUnit(unit: .size(option.size, option.volumeUnit))
        }
    }

    @ViewBuilder
    var weightUnitsSection: some View {
        if includeWeights {
            OptionsSection(
                header: "Weights",
                options: weightUnits,
                isGrid: $isGrid,
                swapColors: true
            ) { option in
                guard let weightUnit = option as? WeightUnit else { return }
                pickedUnit(unit: .weight(weightUnit))
            }
        }
    }

    @ViewBuilder
    var volumeUnitsSection: some View {
        if includeVolumes {
            OptionsSection(
                header: "Volumes",
                options: volumeUnits,
                isGrid: $isGrid,
                swapColors: true
            ) { option in
                guard let volumeUnit = option as? VolumeUnit else { return }
                pickedUnit(unit: .volume(volumeUnit))
            }
        }
    }


    //MARK: - Legacy
    
    var longList: some View {
        List {
            if let filteredType = filteredType {
                Section {
                    filteredList(for: filteredType)
                }
            } else {
                if !standardSizes.isEmpty {
                    Section("Sizes") {
                        standardSizeContents
                    }
                }
                if !volumePrefixedSizes.isEmpty {
                    Section("Volume-named Sizes") {
                        volumePrefixedSizeContents
                    }
                }
                if shouldShowAddSizeButton {
                    Section {
                        addSizeButton
                    }
                }
                if shouldShowServing {
                    Section {
                        servingButton
                    }
                }
                Section {
                    weightUnitButton(for: .g)
                    volumeUnitButton(for: .mL)
                }
                Section("Other Units") {
                    DisclosureGroup("Weights") {
                        weightsGroupContents
                    }
                    DisclosureGroup("Volumes") {
                        volumesGroupContents
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func filteredList(for type: UnitType) -> some View {
        switch type {
        case .weight:
            weightsGroupContents
        case .volume:
            volumesGroupContents
        case .size:
            sizesGroupContents
        default:
            EmptyView()
        }
    }
    
    //MARK: - Components
    
    var typePicker: some View {
        Picker("", selection: $type) {
            ForEach(typesWithOptions, id: \.self) {
                Text($0.description).tag($0)
            }
        }
    }
    
    var navigationTitleString: String {
        let name: String
        if let filteredType = filteredType {
            name = filteredType.description.lowercased() + " unit"
        } else {
            name = "unit"
        }
        return "Choose a \(name)"
    }
    
    func weightUnitButton(for weightUnit: WeightUnit) -> some View {
        Button {
            pickedUnit(unit: .weight(weightUnit))
        } label: {
            HStack {
                Text(weightUnit.description)
                    .textCase(.lowercase)
                    .foregroundColor(.primary)
                Spacer()
                Text(weightUnit.shortDescription)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.borderless)
    }
    
    func volumeUnitButton(for volumeUnit: VolumeUnit) -> some View {
        Button {
            pickedUnit(unit: .volume(volumeUnit))
        } label: {
            HStack {
                Text(volumeUnit.description)
                    .textCase(.lowercase)
                    .foregroundColor(.primary)
                Spacer()
                Text(volumeUnit.shortDescription)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.borderless)
    }
    
    //MARK: - Group Contents
    var weightsGroupContents: some View {
        ForEach(weightUnits, id: \.self) { weightUnit in
            weightUnitButton(for: weightUnit)
        }
    }
    
    var volumesGroupContents: some View {
        ForEach(volumeUnits, id: \.self) { volumeUnit in
            volumeUnitButton(for: volumeUnit)
        }
    }
    
    func volumePrefixes(for size: FormSize) -> some View {
        ForEach(volumeUnits, id: \.self) { volumeUnit in
            Button {
                pickedUnit(unit: .size(size, volumeUnit))
            } label: {
                HStack {
                    HStack(spacing: 0) {
                        Text(volumeUnit.description)
                            .textCase(.lowercase)
                            .foregroundColor(.primary)
                        Text(", ")
                            .foregroundColor(Color(.tertiaryLabel))
                        Text(size.name)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Spacer()
                    Text(volumeUnit.shortDescription)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.borderless)
        }
    }

    var standardSizeContents: some View {
        ForEach(standardSizes, id: \.self) { sizeField in
            sizeButton(for: sizeField)
        }
    }
    
    @ViewBuilder
    func sizeButton(for size: FormSize) -> some View {
        Button {
            pickedUnit(unit: .size(size, nil))
        } label: {
            HStack {
                Text(size.name)
                    .foregroundColor(.primary)
                Spacer()
                HStack {
                    Text(size.scaledAmountString)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .buttonStyle(.borderless)
    }
    
    var volumePrefixedSizeContents: some View {
        ForEach(volumePrefixedSizes, id: \.self) { size in
            volumePrefixedSizeGroup(for: size)
        }
    }
    
    @ViewBuilder
    func volumePrefixedSizeGroup(for size: FormSize) -> some View {
        DisclosureGroup(size.name) {
            volumePrefixes(for: size)
        }
    }
    
    var sizesGroupContents: some View {
        Group {
            if !standardSizes.isEmpty {
                Section {
                    standardSizeContents
                }
            }
            if !volumePrefixedSizes.isEmpty {
                Section("Volume-prefixed") {
                    volumePrefixedSizeContents
                }
            }
            if allowAddSize {
                Section {
                    addSizeButton
                }
            }
        }
    }

    //MARK: - Buttons
    
    var addSizeButton: some View {
        Button {
            didTapAddSize?()
        } label: {
            HStack {
                Text("Add a size")
                Spacer()
            }
        }
        .buttonStyle(.borderless)
        .contentShape(Rectangle())
    }
    
    var servingButton: some View {
        Button {
            pickedUnit(unit: .serving)
        } label: {
            HStack {
                Text("Serving")
                    .textCase(.lowercase)
                    .foregroundColor(.primary)
                Spacer()
                if let servingDescription = servingDescription {
                    Text(servingDescription)
                        .foregroundColor(Color(.secondaryLabel))
                }
//                if case .serving = pickedUnit {
//                    Image(systemName: "checkmark")
//                        .foregroundColor(.accentColor)
//                }
            }
        }
        .buttonStyle(.borderless)
    }
}

let mockSizes: [FormSize] = [
    FormSize(quantity: 1, volumePrefixUnit: .volume(.cup), name: "chopped", amount: 240, unit: .weight(.g)),
    FormSize(quantity: 1, volumePrefixUnit: .volume(.cup), name: "sliced", amount: 100, unit: .weight(.g)),
    FormSize(quantity: 1, name: "large", amount: 70, unit: .weight(.g)),
    FormSize(quantity: 1, name: "medium", amount: 40, unit: .weight(.g)),
    FormSize(quantity: 1, name: "small", amount: 35, unit: .weight(.g)),
    FormSize(quantity: 1, name: "slice", amount: 10, unit: .weight(.g)),
    FormSize(quantity: 1, name: "extra large", amount: 110, unit: .weight(.g)),
]

let mockServingDescription = "1 cup chopped (240 mL)"

struct UnitPickerGrid_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Color.clear
                .sheet(isPresented: .constant(true)) {
                    UnitPickerGrid(
                        pickedUnit: .weight(.g),
                        includeServing: true,
                        sizes: mockSizes,
                        servingDescription: mockServingDescription,
                        allowAddSize: true,
                        filteredType: nil,
                        didTapAddSize: {
                            
                        },
                        didPickUnit: { _ in
                            
                        }
                    )
                }
        }
    }
}

struct UnitPicker_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Color.clear
                .sheet(isPresented: .constant(true)) {
                    UnitPicker(
                        pickedUnit: .weight(.g),
                        includeServing: true,
                        sizes: mockSizes,
                        servingDescription: mockServingDescription,
                        allowAddSize: true,
                        filteredType: nil,
                        didTapAddSize: {
                            
                        },
                        didPickUnit: { _ in
                            
                        }
                    )
                }
        }
    }
}

struct PillButton: View {
    
    let didTap: (() -> ())?
    
    let primaryString: String
    let secondaryString: String
    let swapColors: Bool
    
    init(primaryString: String, secondaryString: String, swapColors: Bool = false, didTap: (() -> ())? = nil) {
        self.primaryString = primaryString
        self.secondaryString = secondaryString
        self.swapColors = swapColors
        self.didTap = didTap
    }
    
    @ViewBuilder
    var body: some View {
        if let didTap {
            Button {
                didTap()
            } label: {
                label
            }
        } else {
            label
        }
    }
    
    var primaryColor: Color {
        swapColors ? Color(.tertiaryLabel) : Color(.secondaryLabel)
    }

    var secondaryColor: Color {
        swapColors ? Color(.secondaryLabel) : Color(.tertiaryLabel)
    }

    var label: some View {
        ZStack {
            Capsule(style: .continuous)
                .foregroundColor(Color(.secondarySystemFill))
            HStack(spacing: 5) {
                if primaryString != secondaryString {
                    Text(primaryString)
                        .foregroundColor(primaryColor)
                }
                Text(secondaryString)
                    .foregroundColor(secondaryColor)
            }
            .frame(height: 25)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
        .fixedSize(horizontal: true, vertical: true)
    }
}

struct OptionsSection: View {
    
    @Namespace var namespace
    @State var isGrid: Bool = false
    
    let header: String
    let allowCompactView: Bool
    let swapColors: Bool
    let options: [any Option]
    var isGridExternal: Binding<Bool>?
    
    let didPickOption: ((Option) -> ())
    
    init(header: String, options: [any Option], allowCompactView: Bool = false, isGrid: Binding<Bool>? = nil, swapColors: Bool = false, didPickOption: @escaping ((Option) -> ())) {
        self.header = header
        self.allowCompactView = allowCompactView
        self.options = options
        self.swapColors = swapColors
        self.isGridExternal = isGrid
        self.didPickOption = didPickOption
    }
    
    var body: some View {
        FormStyledSection(header: headerView, horizontalPadding: 0) {
            content
        }
    }
    
    var headerView: some View {
        HStack {
            Text(header)
            Spacer()
            if allowCompactView && isGridExternal == nil {
                Button {
                    Haptics.feedback(style: .soft)
                    withAnimation {
                        isGrid.toggle()
                    }
                } label: {
                    Image(systemName: isGrid ? "square.grid.3x2.fill" : "square.grid.3x2")
                }
            }
        }
    }
    
    var shouldShowAsGrid: Bool {
        if let isGridExternal {
            return isGridExternal.wrappedValue
        }
        
        return isGrid || !allowCompactView
    }
    
    @ViewBuilder
    var content: some View {
        if shouldShowAsGrid {
            grid
        } else {
            horizontalScrollView
        }
    }
    
    var grid: some View {
        FlowLayout(
            mode: .scrollable,
            items: options,
            itemSpacing: 4,
            shouldAnimateHeight: .constant(true)
        ) {
            button(for: $0)
        }
        .padding(.horizontal, 17)
    }
    
    var horizontalScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(options, id: \.self.optionId) {
                    button(for: $0)
                }
            }
            .padding(.horizontal, 17)
        }
    }
    
    func button(for option: Option) -> some View {
        PillButton(
            primaryString: option.optionTitle,
            secondaryString: option.optionDetail,
            swapColors: swapColors,
            didTap: {
                didPickOption(option)
            }
        )
            .matchedGeometryEffect(id: option.optionId, in: namespace)
    }
    
}
