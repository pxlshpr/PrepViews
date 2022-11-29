import SwiftUI

struct Colors {
    struct Nutrient {
        struct Highlighted {
            struct Value {
                static let light = Color(.label)
                static let dark = Color(.label)
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
            struct Background {
                struct Carb {
                    static let light = Color(hex: "FFE798")
                    static let dark = Color(hex: "987A20")
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Fat {
                    static let light = Color(hex: "EAB0FF")
                    static let dark = Color(hex: "740773")
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Protein {
                    static let light = Color(hex: "BAE2E3")
                    static let dark = Color(hex: "3D969A")
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
            }
            struct Unit {
                static let light = Color(.secondaryLabel)
                static let dark = Color(.secondaryLabel)
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
        }

        struct Regular {
            struct Value {
                static let light = Color(hex: "DFD6FF")
                static let dark = Color(hex: "DFD6FF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
            struct Background {
                static let light = Color(hex: "9678FF")
                static let dark = Color(hex: "A78EFF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
            struct Unit {
                static let light = Color(hex: "C9BAFF")
                static let dark = Color(hex: "C9BAFF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
        }
        struct Zero {
            struct Value {
                static let light = Color(hex: "DFD6FF")
                static let dark = Color(hex: "DFD6FF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
            struct Background {
                static let light = Color(hex: "8562FF")
                static let dark = Color(hex: "9678FF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
            struct Unit {
                static let light = Color(hex: "C9BAFF")
                static let dark = Color(hex: "C9BAFF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
        }
        
        struct Muted {
            struct Regular {
                struct Value {
                    static let light = Color(.secondaryLabel)
                    static let dark = Color(.secondaryLabel)
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Background {
                    static let light = Color(hex: "E9E9EB")
                    static let dark = Color(hex: "39393D")
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Unit {
                    static let light = Color(.tertiaryLabel)
                    static let dark = Color(.tertiaryLabel)
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
            }
            struct Zero {
                struct Value {
                    static let light = Color(.tertiaryLabel)
                    static let dark = Color(.tertiaryLabel)
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Background {
                    static let light = Color(hex: "EEEEF0")
                    static let dark = Color(hex: "313135")
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Unit {
                    static let light = Color(.quaternaryLabel)
                    static let dark = Color(.quaternaryLabel)
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
            }
        }
    }
}

