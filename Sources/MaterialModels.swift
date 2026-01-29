import Foundation

// MARK: - Enums

enum MaterialType: String, Codable, CaseIterable, Identifiable {
    case fdm
    case resin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fdm: return "FDM Filament"
        case .resin: return "Resin"
        }
    }

    var icon: String {
        switch self {
        case .fdm: return "cylinder"
        case .resin: return "drop"
        }
    }
}

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "orange"
        case .advanced: return "red"
        }
    }
}

// MARK: - Material Models

struct MaterialListItem: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let materialType: String
    let category: String?
    let difficultyLevel: String
    let printTempMin: Int?
    let printTempMax: Int?
    let pros: [String]
    let bestUses: [String]
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, pros
        case fullName = "full_name"
        case materialType = "material_type"
        case difficultyLevel = "difficulty_level"
        case printTempMin = "print_temp_min"
        case printTempMax = "print_temp_max"
        case bestUses = "best_uses"
        case imageUrl = "image_url"
    }

    var temperatureRange: String? {
        guard let min = printTempMin, let max = printTempMax else { return nil }
        return "\(min)–\(max)°C"
    }

    var materialTypeEnum: MaterialType? {
        MaterialType(rawValue: materialType)
    }

    var difficultyLevelEnum: DifficultyLevel? {
        DifficultyLevel(rawValue: difficultyLevel)
    }
}

struct CompatiblePrinter: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let manufacturer: String
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, manufacturer
        case imageUrl = "image_url"
    }
}

struct Material: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let materialType: String
    let category: String?
    let difficultyLevel: String

    // FDM temperature settings
    let printTempMin: Int?
    let printTempMax: Int?
    let bedTempMin: Int?
    let bedTempMax: Int?

    // Resin settings
    let exposureTimeS: Double?
    let uvWavelengthNm: Int?

    // Lists
    let pros: [String]
    let cons: [String]
    let bestUses: [String]
    let exampleProjects: [String]
    let printingTips: [String]
    let postProcessing: [String]

    // Properties
    let properties: [String: String]

    // Compatibility
    let printerMaterialName: String?
    let compatiblePrinters: [CompatiblePrinter]

    // Media
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, pros, cons, properties
        case fullName = "full_name"
        case materialType = "material_type"
        case difficultyLevel = "difficulty_level"
        case printTempMin = "print_temp_min"
        case printTempMax = "print_temp_max"
        case bedTempMin = "bed_temp_min"
        case bedTempMax = "bed_temp_max"
        case exposureTimeS = "exposure_time_s"
        case uvWavelengthNm = "uv_wavelength_nm"
        case bestUses = "best_uses"
        case exampleProjects = "example_projects"
        case printingTips = "printing_tips"
        case postProcessing = "post_processing"
        case printerMaterialName = "printer_material_name"
        case compatiblePrinters = "compatible_printers"
        case imageUrl = "image_url"
    }

    var printTemperatureRange: String? {
        guard let min = printTempMin, let max = printTempMax else { return nil }
        return "\(min)–\(max)°C"
    }

    var bedTemperatureRange: String? {
        guard let min = bedTempMin, let max = bedTempMax else { return nil }
        return "\(min)–\(max)°C"
    }

    var materialTypeEnum: MaterialType? {
        MaterialType(rawValue: materialType)
    }

    var difficultyLevelEnum: DifficultyLevel? {
        DifficultyLevel(rawValue: difficultyLevel)
    }
}

// MARK: - Filter Model

struct MaterialFilters {
    var materialType: MaterialType?
    var difficultyLevel: DifficultyLevel?

    var isEmpty: Bool {
        materialType == nil && difficultyLevel == nil
    }
}
