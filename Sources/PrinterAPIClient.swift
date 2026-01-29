import Foundation

actor PrinterAPIClient {
    private let baseURL: String

    init(baseURL: String = "http://localhost:8000") {
        self.baseURL = baseURL
    }

    // MARK: - Fetch Printers List

    struct PrinterFilters {
        var priceMin: Double?
        var priceMax: Double?
        var skillLevel: String?
        var useCase: String?
        var printerType: String?
        var motionSystem: String?
        var hasEnclosure: Bool?
        var hasMultiColor: Bool?

        init(
            priceMin: Double? = nil,
            priceMax: Double? = nil,
            skillLevel: String? = nil,
            useCase: String? = nil,
            printerType: String? = nil,
            motionSystem: String? = nil,
            hasEnclosure: Bool? = nil,
            hasMultiColor: Bool? = nil
        ) {
            self.priceMin = priceMin
            self.priceMax = priceMax
            self.skillLevel = skillLevel
            self.useCase = useCase
            self.printerType = printerType
            self.motionSystem = motionSystem
            self.hasEnclosure = hasEnclosure
            self.hasMultiColor = hasMultiColor
        }
    }

    func fetchPrinters(filters: PrinterFilters = PrinterFilters()) async throws -> [PrinterListItem] {
        var components = URLComponents(string: "\(baseURL)/printers")!
        var queryItems: [URLQueryItem] = []

        if let priceMin = filters.priceMin {
            queryItems.append(URLQueryItem(name: "price_min", value: String(priceMin)))
        }
        if let priceMax = filters.priceMax {
            queryItems.append(URLQueryItem(name: "price_max", value: String(priceMax)))
        }
        if let skillLevel = filters.skillLevel {
            queryItems.append(URLQueryItem(name: "skill_level", value: skillLevel))
        }
        if let useCase = filters.useCase {
            queryItems.append(URLQueryItem(name: "use_case", value: useCase))
        }
        if let printerType = filters.printerType {
            queryItems.append(URLQueryItem(name: "printer_type", value: printerType))
        }
        if let motionSystem = filters.motionSystem {
            queryItems.append(URLQueryItem(name: "motion_system", value: motionSystem))
        }
        if let hasEnclosure = filters.hasEnclosure {
            queryItems.append(URLQueryItem(name: "has_enclosure", value: String(hasEnclosure)))
        }
        if let hasMultiColor = filters.hasMultiColor {
            queryItems.append(URLQueryItem(name: "has_multi_color", value: String(hasMultiColor)))
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([PrinterListItem].self, from: data)
    }

    // MARK: - Fetch Single Printer

    func fetchPrinter(id: Int) async throws -> Printer {
        let url = URL(string: "\(baseURL)/printers/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Printer.self, from: data)
    }

    // MARK: - Get Recommendations

    func getRecommendations(answers: QuizAnswers) async throws -> [RecommendationResult] {
        let url = URL(string: "\(baseURL)/printers/recommend")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(answers)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([RecommendationResult].self, from: data)
    }

    // MARK: - Health Check

    func checkHealth() async throws -> String {
        let url = URL(string: "\(baseURL)/health")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(HealthResponse.self, from: data)
        return response.status
    }

    // MARK: - Fetch Materials List

    func fetchMaterials(filters: MaterialFilters = MaterialFilters()) async throws -> [MaterialListItem] {
        var components = URLComponents(string: "\(baseURL)/materials")!
        var queryItems: [URLQueryItem] = []

        if let materialType = filters.materialType {
            queryItems.append(URLQueryItem(name: "material_type", value: materialType.rawValue))
        }
        if let difficultyLevel = filters.difficultyLevel {
            queryItems.append(URLQueryItem(name: "difficulty_level", value: difficultyLevel.rawValue))
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([MaterialListItem].self, from: data)
    }

    // MARK: - Fetch Single Material

    func fetchMaterial(id: Int) async throws -> Material {
        let url = URL(string: "\(baseURL)/materials/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Material.self, from: data)
    }

    // MARK: - Fetch Troubleshooting Issues

    func fetchTroubleshooting(filters: TroubleshootingFilters = TroubleshootingFilters()) async throws -> [PrintIssueListItem] {
        var components = URLComponents(string: "\(baseURL)/troubleshooting")!
        var queryItems: [URLQueryItem] = []

        if let printerType = filters.printerType {
            queryItems.append(URLQueryItem(name: "printer_type", value: printerType.rawValue))
        }
        if let difficultyLevel = filters.difficultyLevel {
            queryItems.append(URLQueryItem(name: "difficulty_level", value: difficultyLevel.rawValue))
        }
        if filters.hasSearch {
            queryItems.append(URLQueryItem(name: "search", value: filters.search))
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([PrintIssueListItem].self, from: data)
    }

    // MARK: - Fetch Single Troubleshooting Issue

    func fetchTroubleshootingIssue(id: Int) async throws -> PrintIssue {
        let url = URL(string: "\(baseURL)/troubleshooting/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(PrintIssue.self, from: data)
    }
}
