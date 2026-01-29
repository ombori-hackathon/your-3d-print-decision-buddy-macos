import Foundation

// MARK: - Enums

enum SkillLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case pro

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .pro: return "Professional"
        }
    }
}

enum UseCase: String, Codable, CaseIterable, Identifiable {
    case hobby
    case engineering
    case art
    case production

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hobby: return "Hobby/Personal"
        case .engineering: return "Engineering/Prototyping"
        case .art: return "Art/Creative"
        case .production: return "Production/Business"
        }
    }
}

enum PrinterType: String, Codable, CaseIterable, Identifiable {
    case fdm
    case resin
    case sls

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fdm: return "FDM (Filament)"
        case .resin: return "Resin (SLA/MSLA)"
        case .sls: return "SLS (Powder)"
        }
    }
}

enum MotionSystem: String, Codable, CaseIterable, Identifiable {
    case corexy
    case bedslinger

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .corexy: return "CoreXY"
        case .bedslinger: return "Bed Slinger"
        }
    }
}

// MARK: - Printer Models

struct PrinterListItem: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let manufacturer: String
    let price: Double
    let printerType: String
    let skillLevels: [String]
    let useCases: [String]
    let buildVolumeX: Int
    let buildVolumeY: Int
    let buildVolumeZ: Int
    let enclosure: Bool
    let autoLeveling: Bool
    let multiColor: Bool
    let motionSystem: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, manufacturer, price, enclosure
        case printerType = "printer_type"
        case skillLevels = "skill_levels"
        case useCases = "use_cases"
        case buildVolumeX = "build_volume_x"
        case buildVolumeY = "build_volume_y"
        case buildVolumeZ = "build_volume_z"
        case autoLeveling = "auto_leveling"
        case multiColor = "multi_color"
        case motionSystem = "motion_system"
        case imageUrl = "image_url"
    }

    var buildVolumeDescription: String {
        "\(buildVolumeX) × \(buildVolumeY) × \(buildVolumeZ) mm"
    }

    var motionSystemDisplay: String {
        guard let system = motionSystem else { return "N/A" }
        return system == "corexy" ? "CoreXY" : "Bed Slinger"
    }
}

struct Printer: Codable, Identifiable {
    let id: Int
    let name: String
    let manufacturer: String
    let description: String?
    let price: Double
    let printerType: String
    let skillLevels: [String]
    let useCases: [String]
    let buildVolumeX: Int
    let buildVolumeY: Int
    let buildVolumeZ: Int
    let materials: [String]
    let maxSpeed: Int?
    let layerResolution: Double?
    let enclosure: Bool
    let autoLeveling: Bool
    let multiColor: Bool
    let connectivity: [String]
    let noiseLevel: String?
    let motionSystem: String?
    let productUrl: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, manufacturer, description, price, materials, enclosure, connectivity
        case printerType = "printer_type"
        case skillLevels = "skill_levels"
        case useCases = "use_cases"
        case buildVolumeX = "build_volume_x"
        case buildVolumeY = "build_volume_y"
        case buildVolumeZ = "build_volume_z"
        case maxSpeed = "max_speed"
        case layerResolution = "layer_resolution"
        case autoLeveling = "auto_leveling"
        case multiColor = "multi_color"
        case noiseLevel = "noise_level"
        case motionSystem = "motion_system"
        case productUrl = "product_url"
        case imageUrl = "image_url"
    }

    var buildVolumeDescription: String {
        "\(buildVolumeX) × \(buildVolumeY) × \(buildVolumeZ) mm"
    }

    var motionSystemDisplay: String {
        guard let system = motionSystem else { return "N/A" }
        return system == "corexy" ? "CoreXY" : "Bed Slinger"
    }
}

// MARK: - Quiz Models

struct QuizAnswers: Codable {
    let skillLevel: String
    let useCase: String
    let budgetMin: Double
    let budgetMax: Double
    let preferEnclosure: Bool
    let preferAutoLeveling: Bool

    enum CodingKeys: String, CodingKey {
        case skillLevel = "skill_level"
        case useCase = "use_case"
        case budgetMin = "budget_min"
        case budgetMax = "budget_max"
        case preferEnclosure = "prefer_enclosure"
        case preferAutoLeveling = "prefer_auto_leveling"
    }
}

struct RecommendationResult: Codable, Identifiable {
    let printer: PrinterListItem
    let matchScore: Int
    let reasons: [String]

    var id: Int { printer.id }

    enum CodingKeys: String, CodingKey {
        case printer, reasons
        case matchScore = "match_score"
    }
}
