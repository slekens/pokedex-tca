import Foundation

/// Datos extra que se cargan al abrir el detalle de un Pokémon.
struct PokemonDetail: Equatable, Sendable {
    let id: Int
    let height: Int
    let weight: Int
    let abilities: [String]
}
