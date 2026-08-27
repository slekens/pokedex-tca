import ComposableArchitecture
import Foundation

/// Cliente inyectable para todas las peticiones a la PokeAPI.
///
/// Struct de closures (no protocolo) para permitir en tests sustituir
/// solo la función que interesa sin implementar toda la interfaz.
struct PokemonClient: Sendable {
    var fetchList: @Sendable (_ limit: Int, _ offset: Int, _ types: Set<PokemonType>) async throws -> [Pokemon]
    var fetchDetail: @Sendable (_ id: Int) async throws -> PokemonDetail
    var search: @Sendable (_ query: String) async throws -> [Pokemon]
}

extension PokemonClient: DependencyKey {
    static let liveValue = PokemonClient(
        fetchList: { limit, offset, types in
            try await PokeAPI.fetchPokemons(limit: limit, offset: offset, types: types)
        },
        fetchDetail: { id in
            try await PokeAPI.fetchPokemonDetail(id: id)
        },
        search: { query in
            try await PokeAPI.search(query)
        }
    )

    static let testValue = PokemonClient(
        fetchList: { _, _, _ in [] },
        fetchDetail: { _ in
            PokemonDetail(id: 0, height: 0, weight: 0, abilities: [])
        },
        search: { _ in [] }
    )
}

extension DependencyValues {
    var pokemonClient: PokemonClient {
        get { self[PokemonClient.self] }
        set { self[PokemonClient.self] = newValue }
    }
}
