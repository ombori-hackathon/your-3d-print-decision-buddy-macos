import Foundation

// MARK: - Solution Step

struct SolutionStep: Codable, Identifiable, Hashable {
    let step: Int
    let title: String
    let description: String
    let tip: String?

    var id: Int { step }
}

// MARK: - Print Issue List Item (for grid view)

struct PrintIssueListItem: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String
    let printerType: String
    let difficultyLevel: String
    let category: String?
    let symptoms: [String]
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, symptoms
        case printerType = "printer_type"
        case difficultyLevel = "difficulty_level"
        case imageUrl = "image_url"
    }

    var printerTypeEnum: MaterialType? {
        MaterialType(rawValue: printerType)
    }

    var difficultyLevelEnum: DifficultyLevel? {
        DifficultyLevel(rawValue: difficultyLevel)
    }

    var symptomsPreview: String {
        symptoms.prefix(2).joined(separator: ", ")
    }
}

// MARK: - Print Issue (full detail)

struct PrintIssue: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let printerType: String
    let difficultyLevel: String
    let category: String?
    let symptoms: [String]
    let causes: [String]
    let solutions: [SolutionStep]
    let relatedMaterials: [String]
    let preventionTips: [String]
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, symptoms, causes, solutions
        case printerType = "printer_type"
        case difficultyLevel = "difficulty_level"
        case relatedMaterials = "related_materials"
        case preventionTips = "prevention_tips"
        case imageUrl = "image_url"
    }

    var printerTypeEnum: MaterialType? {
        MaterialType(rawValue: printerType)
    }

    var difficultyLevelEnum: DifficultyLevel? {
        DifficultyLevel(rawValue: difficultyLevel)
    }
}

// MARK: - Filter Model

struct TroubleshootingFilters {
    var printerType: MaterialType?
    var difficultyLevel: DifficultyLevel?
    var search: String = ""

    var isEmpty: Bool {
        printerType == nil && difficultyLevel == nil && search.isEmpty
    }

    var hasSearch: Bool {
        !search.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
