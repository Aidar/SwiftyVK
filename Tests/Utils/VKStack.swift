@testable import SwiftyVK

class VKStack {
    static let delegate = SwiftyVKDelegateMock()
    
    static func mock() {
        if VK.dependenciesType != DependenciesHolderMock.self {
            VK.dependenciesType = DependenciesHolderMock.self
            VK.prepareForUse(appId: "", delegate: delegate)
        }
    }    
}
