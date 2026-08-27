import ComposableArchitecture
import Foundation

/// Clave con nombre para el `Set<Int>` de favoritos.
///
/// Centralizar la clave evita typos y unifica el valor por defecto
/// (un set vacío). Persistida en disco como JSON en el contenedor de la app.
extension SharedReaderKey where Self == FileStorageKey<Set<Int>>.Default {
    static var favorites: Self {
        Self[
            .fileStorage(URL.documentsDirectory.appending(path: "favorites.json")),
            default: []
        ]
    }
}
