import Foundation

/// Cliente HTTP mínimo contra la PokeAPI.
///
/// Vive fuera del reducer porque hace red. La feature accede a estas
/// funciones a través de `PokemonClient`, que es el que se puede sustituir
/// en los tests.
enum PokeAPI {
    static let baseURL = URL(string: "https://pokeapi.co/api/v2")!

    // MARK: - Listado

    static func fetchPokemons(limit: Int, offset: Int) async throws -> [Pokemon] {
        var components = URLComponents(url: baseURL.appendingPathComponent("pokemon"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let page = try JSONDecoder().decode(PokemonListPageDTO.self, from: data)

        // La página trae solo nombre y URL; para tipos y sprite hay que
        // pedir el detalle de cada uno. Lo hacemos concurrentemente.
        return try await withThrowingTaskGroup(of: (Int, Pokemon).self) { group in
            for (index, entry) in page.results.enumerated() {
                group.addTask {
                    let detail = try await Self.fetchPokemonDetailRaw(from: entry.url)
                    return (index, Self.mapListItem(from: detail))
                }
            }

            var indexed: [(Int, Pokemon)] = []
            for try await item in group {
                indexed.append(item)
            }
            return indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    // MARK: - Detalle

    static func fetchPokemonDetail(id: Int) async throws -> PokemonDetail {
        let url = baseURL.appendingPathComponent("pokemon/\(id)")
        let raw = try await fetchPokemonDetailRaw(from: url)
        return PokemonDetail(
            id: raw.id,
            height: raw.height,
            weight: raw.weight,
            abilities: raw.abilities.map(\.ability.name)
        )
    }

    // MARK: - Búsqueda

    /// La PokeAPI no tiene búsqueda por prefijo. Traemos la lista completa
    /// (~1300 nombres) una sola vez y filtramos en memoria.
    static func search(_ query: String) async throws -> [Pokemon] {
        try await allNames.value
            .filter { $0.name.contains(query.lowercased()) }
            .prefix(20)
            .concurrentMap { entry in
                let raw = try await fetchPokemonDetailRaw(from: entry.url)
                return Self.mapListItem(from: raw)
            }
    }

    // MARK: - Por tipo

    /// Devuelve los primeros `limit` Pokémon que tienen cualquiera de los
    /// tipos indicados. Si `types` está vacío, delega al listado normal.
    static func fetchPokemons(limit: Int, offset: Int, types: Set<PokemonType>) async throws -> [Pokemon] {
        guard !types.isEmpty else {
            return try await fetchPokemons(limit: limit, offset: offset)
        }

        // Unimos IDs de los tipos seleccionados y traemos los primeros N.
        var ids: Set<Int> = []
        for type in types {
            let url = baseURL.appendingPathComponent("type/\(type.rawValue)")
            let (data, _) = try await URLSession.shared.data(from: url)
            let container = try JSONDecoder().decode(TypePageDTO.self, from: data)
            for item in container.pokemon {
                if let id = Self.extractID(from: item.pokemon.url) {
                    ids.insert(id)
                }
            }
        }

        let sortedIDs = ids.sorted().dropFirst(offset).prefix(limit)
        return try await sortedIDs.concurrentMap { id in
            let raw = try await Self.fetchPokemonDetailRaw(from: baseURL.appendingPathComponent("pokemon/\(id)"))
            return Self.mapListItem(from: raw)
        }
    }

    // MARK: - Internos

    /// Cache one-shot con los ~1300 nombres para la búsqueda por prefijo.
    private static let allNames = Task<[NamedEntry], Error> {
        var components = URLComponents(url: baseURL.appendingPathComponent("pokemon"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "limit", value: "2000")]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let page = try JSONDecoder().decode(PokemonListPageDTO.self, from: data)
        return page.results
    }

    private static func fetchPokemonDetailRaw(from url: URL) async throws -> PokemonDetailDTO {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(PokemonDetailDTO.self, from: data)
    }

    private static func mapListItem(from dto: PokemonDetailDTO) -> Pokemon {
        Pokemon(
            id: dto.id,
            name: dto.name,
            spriteURL: dto.sprites.frontDefault.flatMap(URL.init(string:)),
            types: dto.types.map(\.type.name)
        )
    }

    private static func extractID(from url: String) -> Int? {
        // .../pokemon/25/ -> 25
        let trimmed = url.hasSuffix("/") ? String(url.dropLast()) : url
        return trimmed.split(separator: "/").last.flatMap { Int($0) }
    }
}

// MARK: - DTOs

private struct PokemonListPageDTO: Decodable, Sendable {
    let results: [NamedEntry]
}

private struct NamedEntry: Decodable, Sendable {
    let name: String
    let url: URL
}

private struct PokemonDetailDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let abilities: [AbilityWrapper]
    let sprites: Sprites
    let types: [TypeSlot]

    struct AbilityWrapper: Decodable, Sendable {
        let ability: Named
    }
    struct Sprites: Decodable, Sendable {
        let frontDefault: String?
        enum CodingKeys: String, CodingKey { case frontDefault = "front_default" }
    }
    struct TypeSlot: Decodable, Sendable {
        let type: Named
    }
    struct Named: Decodable, Sendable {
        let name: String
    }
}

private struct TypePageDTO: Decodable, Sendable {
    let pokemon: [Slot]

    struct Slot: Decodable, Sendable {
        let pokemon: PokemonRef
    }
    struct PokemonRef: Decodable, Sendable {
        let name: String
        let url: String
    }
}

// MARK: - Helper

private extension Sequence where Element: Sendable {
    /// Ejecuta `transform` concurrentemente y preserva orden de entrada.
    func concurrentMap<T: Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async throws -> [T] {
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for (index, element) in enumerated() {
                group.addTask {
                    (index, try await transform(element))
                }
            }
            var indexed: [(Int, T)] = []
            for try await item in group {
                indexed.append(item)
            }
            return indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }
}
