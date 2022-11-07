import SwiftUI
import PrepDataTypes
import SwiftHaptics

public struct UnitPicker: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var type: UnitType
    @State var pickedUnit: FormUnit

    @State var pickedVolumePrefixUnit: FormUnit = .volume(.cup)
    
    var includeServing: Bool
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
        self.servingDescription = servingDescription
        self.allowAddSize = allowAddSize
        self.filteredType = filteredType
        
        self.standardSizes = sizes.standardSizes
        self.volumePrefixedSizes = sizes.volumePrefixedSizes
        
        _pickedUnit = State(initialValue: unit)
        _type = State(initialValue: unit.unitType)
    }
}

extension UnitPicker {
    
    public var body: some View {
        NavigationView {
            longList
            .navigationTitle(navigationTitleString)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: pickedUnit) { newValue in
            pickedUnitChanged(to: newValue)
        }
        .onChange(of: type) { newValue in
            if type == .serving {
                pickedUnit(unit: .serving)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
    
    //MARK: - Components
    
    /**
     We're currently only showing the AddSize button if the the flag is true in addition to the sizes list being empty
     */
    var shouldShowAddSizeButton: Bool {
        allowAddSize && (standardSizes + volumePrefixedSizes).isEmpty
    }
    
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
                    Section("Volume Prefixed Sizes") {
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
    
    var shouldShowServing: Bool {
        includeServing && filteredType == nil
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
    
    var typesWithOptions: [UnitType] {
        [UnitType.weight, UnitType.volume, UnitType.size]
    }
    
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
    
    //MARK: - Units
    
    var weightUnits: [WeightUnit] {
        [.g, .oz, .mg, .lb, .kg]
    }

    var volumeUnits: [VolumeUnit] {
        [.cup, .mL, .fluidOunce, .teaspoon, .tablespoon, .liter, .pint, .quart, .gallon]
    }
    
    //MARK: - Actions
    func pickedUnitChanged(to newUnit: FormUnit) {
//        didPickUnit(newUnit)
//        Haptics.feedback(style: .heavy)
//        dismiss()
    }
    
    func pickedUnit(unit: FormUnit) {
//        self.pickedUnit = unit
        didPickUnit(unit)
        Haptics.feedback(style: .heavy)
        dismiss()
    }
}
