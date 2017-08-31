public protocol Method: SendableMethod {
    func configure(with config: Config) -> SuccessableFailbaleMethod
    func onSuccess(_ clousure: @escaping (Data) -> ()) -> FailableConfigurableMethod
    func onError(_ clousure: @escaping (VKError) -> ()) -> SuccessableConfigurableMethod
}

public protocol SendableMethod {
    func toRequest() -> Request
}

public extension SendableMethod {
    @discardableResult
    func send() -> Task {
        return send(in: nil)
    }
    
    @discardableResult
    func send(in session: Session?) -> Task {
        guard let session = session ?? VK.sessions?.default else {
            fatalError("You must call VK.prepareForUse function to start using SwiftyVK!")
        }
        
        return session.send(method: self)
    }
}
