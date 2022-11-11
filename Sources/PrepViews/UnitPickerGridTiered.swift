/**
 
 This should eventually replace `UnitPicker`.
 
 */
import SwiftUI
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar

//MARK: - Logic
extension UnitPickerGridTiered {
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

enum UnitGroup {
    case sizes
    case weights
    case volumes
    var description: String {
        switch self {
        case .sizes:
            return "Sizes"
        case .weights:
            return "Weights"
        case .volumes:
            return "Volumes"
        }
    }
}

public struct UnitPickerGridTiered: View {
    
    @Environment(\.dismiss) var dismiss
    @Namespace var namespace
    
    @State var isGrid: Bool
    @State var type: UnitType
    @State var pickedUnit: FormUnit

    @State var pickedVolumePrefixUnit: FormUnit = .volume(.cup)
    
    @State var pickedGroup: UnitGroup? = nil
    
    let includeServing: Bool
    let includeVolumes: Bool
    let includeWeights: Bool
    let allowsCompactMode: Bool
    let allowAddSize: Bool
    let filteredType: UnitType?
    let servingDescription: String?
    
    let didPickUnit: (FormUnit) -> ()
    let didTapAddSize: (() -> ())?

    let standardSizes: [FormSize]
    let volumePrefixedSizes: [FormSize]
    
    public init(
        pickedUnit unit: FormUnit = .weight(.g),
        includeServing: Bool = true,
        includeWeights: Bool = true,
        includeVolumes: Bool = true,
        sizes: [FormSize],
        servingDescription: String? = nil,
        allowsCompactMode: Bool = false,
        allowAddSize: Bool = true,
        filteredType: UnitType? = nil,
        didTapAddSize: (() -> ())? = nil,
        didPickUnit: @escaping (FormUnit) -> ())
    {
        self.didPickUnit = didPickUnit
        self.didTapAddSize = didTapAddSize
        self.includeServing = includeServing
        self.allowsCompactMode = allowsCompactMode
        self.includeWeights = includeWeights
        self.includeVolumes = includeVolumes
        self.servingDescription = servingDescription
        self.allowAddSize = allowAddSize
        self.filteredType = filteredType
        
        self.standardSizes = sizes.standardSizes
        self.volumePrefixedSizes = sizes.volumePrefixedSizes
        
        _pickedUnit = State(initialValue: unit)
        _type = State(initialValue: unit.unitType)
        _isGrid = State(initialValue: !allowsCompactMode)
    }
    
    @State var presentationDetent: PresentationDetent = .medium
    
    public var body: some View {
        NavigationView {
//            longList
            content
            .navigationTitle(navigationTitleString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { trailingContent }
            .toolbar { leadingContent }
        }
        .onChange(of: type) { newValue in
            if type == .serving {
                pickedUnit(unit: .serving)
            }
        }
        .presentationDetents([.height(350), .large], selection: $presentationDetent)
        .presentationDragIndicator(.hidden)
    }

    var leadingContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if pickedGroup != nil {
                Button {
                    Haptics.feedback(style: .soft)
                    withAnimation {
                        pickedGroup = nil
                    }
                } label: {
                    Image(systemName: "chevron.backward")
                        .padding(.all.subtracting(.leading))
                        .contentShape(Rectangle())
                }
            }
        }
    }

    var trailingContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Haptics.feedback(style: .soft)
                dismiss()
            } label: {
                closeButtonLabel
            }
        }
    }
    
    var content: some View {
        FormStyledScrollView {
            if let pickedGroup {
                section(for: pickedGroup)
            } else {
                groupsGrid
            }
//            standardSizesSection
//            volumePrefixedSizesSection
//            weightUnitsSection
//            volumeUnitsSection
        }
    }
    
    let DefaultHorizontalPadding: CGFloat = 17
    let DefaultVerticalPadding: CGFloat = 15

    func options(for group: UnitGroup) -> [Option] {
        switch group {
        case .sizes:
            return []
        case .weights:
            return weightUnits.map { $0 as Option }
        case .volumes:
            return volumeUnits.map { $0 as Option }
        }
    }
    
    func section(for group: UnitGroup) -> some View {
        let options = options(for: group)
        return VStack(spacing: 7) {
            Text(group.description)
                .matchedGeometryEffect(id: "groupHeader_\(group.description)", in: namespace)
                .foregroundColor(Color(.secondaryLabel))
                .font(.footnote)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
            FlowLayout(
                mode: .scrollable,
                items: options,
                itemSpacing: 4,
                shouldAnimateHeight: .constant(true)
            ) {
                button(for: $0)
            }
//            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DefaultHorizontalPadding)
            .padding(.vertical, DefaultVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color(.secondarySystemGroupedBackground))
                    .matchedGeometryEffect(id: "groupBackground_\(group.description)", in: namespace)
            )
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    func button(for option: Option, swapColors: Bool = false) -> some View {
        PillButton(
            primaryString: option.optionTitle,
            secondaryString: option.optionDetail,
            swapColors: swapColors,
            didTap: {
//                didPickOption(option)
            }
        )
    }
    
    let columns = [ GridItem(.flexible()), GridItem(.flexible()) ]
    @State var groups: [UnitGroup] = [.sizes, .volumes, .weights]
    
    var groupsGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(groups, id: \.self) { group in
                Button {
                    withAnimation {
                        self.pickedGroup = group
                    }
                } label: {
                    Text(group.description)
                        .fixedSize()
                        .matchedGeometryEffect(id: "groupHeader_\(group.description)", in: namespace)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 150, height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(Color(.secondarySystemGroupedBackground))
                                .matchedGeometryEffect(id: "groupBackground_\(group.description)", in: namespace)
                        )
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
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


struct UnitPickerGridTiered_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Color.clear
                .sheet(isPresented: .constant(true)) {
                    UnitPickerGridTiered(
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
