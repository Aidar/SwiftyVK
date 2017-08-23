public extension VK.Api {
    public struct Custom {
        public static func method(name: String, parameters: Parameters = .empty) -> CustomMethod {
            return CustomMethod(method: name, parameters: parameters)
        }
        
        public static func remote(method: String) -> CustomMethod {
            return self.method(name: "execute.\(method)")
        }
        
        public static func execute(code: String, config: Config = .default) -> Request {
            return CustomMethod(method: "execute", parameters: [.code: code]).request(with: config)
        }
    }
}

// Do not use this class directly. Use Api.Custom
public class CustomMethod {
    public let method: String
    public let parameters: Parameters
    
    init(method: String, parameters: Parameters = .empty) {
        self.method = method
        self.parameters = parameters
    }
    
    public func request(with config: Config = .default) -> Request {
        return Request(of: .api(method: method, parameters: parameters), config: config)
    }
    
    @discardableResult
    public func send(with callbacks: Callbacks, in session: Session? = nil) -> Task {
        return request().send(with: callbacks, in: session)
    }
}
