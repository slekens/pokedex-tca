import Foundation

/// Modelo mínimo de Pokémon usado en la lista.
///
/// Contiene lo suficiente para pintar la fila y navegar al detalle.
/// Las estadísticas completas viven en `PokemonDetail`.
struct Pokemon: Equatable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let spriteURL: URL?
    let types: [String]
}
