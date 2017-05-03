import Foundation

var sharedCaptchaIsRun = false
var sharedCaptchaAnswer: [String : String]?

public final class Request {
    
    let rawRequest: Raw
    var config: Config
    var nexts = [((JSON) -> Request)]()
    
    init(
        of rawRequest: Raw,
        config: Config = .default
        ) {
        self.rawRequest = rawRequest
        self.config = config
    }
    
    @discardableResult
    public func next(_ next: @escaping ((JSON) -> Request)) -> Request {
        nexts = [next] + nexts
        return self
    }
    
    @discardableResult
    public func send(with callbacks: Callbacks, in session: Session? = nil) -> Task {
        let session = session ?? VK.dependencyBox.defaultSession
        return session.send(request: self, callbacks: callbacks)
    }
}

extension Request {
    enum Raw {
        case api(method: String, parameters: Parameters)
        case url(String)
        case upload(url: String, media: [Media], partType: PartType)
        
        var canSentConcurrently: Bool {
            switch self {
            case .api:
                return false
            case .url, .upload:
                return true
            }
        }
    }
}

public struct Config {
    
    static let `default` = Config()
    
    var timeout: TimeInterval
    var maxAttempts: Int
    var httpMethod: HttpMethod
    var catchErrors: Bool
    var logToConsole: Bool
    
    init(
        timeout: TimeInterval = VK.config.timeOut,
        maxAttempts: Int = VK.config.maxAttempts,
        httpMethod: HttpMethod = .GET,
        catchErrors: Bool = VK.config.catchErrors,
        logToConsole: Bool = VK.config.logToConsole
        ) {
        self.timeout = timeout
        self.maxAttempts = maxAttempts
        self.httpMethod = httpMethod
        self.catchErrors = catchErrors
        self.logToConsole = logToConsole
    }
    
    func mutated(
        timeout: TimeInterval? = nil,
        maxAttempts: Int? = nil,
        httpMethod: HttpMethod? = nil,
        catchErrors: Bool? = nil,
        logToConsole: Bool? = nil
        ) -> Config {
        return Config(
            timeout: timeout ?? self.timeout,
            maxAttempts: maxAttempts ?? self.maxAttempts,
            httpMethod: httpMethod ?? self.httpMethod,
            catchErrors: catchErrors ?? self.catchErrors,
            logToConsole: logToConsole ?? self.logToConsole
        )
    }
}

public struct Callbacks {
    
    public static let empty = Callbacks()
    
    let onSuccess: ((JSON) -> ())?
    let onError: ((Error) -> ())?
    let onProgress: ((Int64, Int64) -> ())?
    
    public init(
        onSuccess: ((JSON) -> ())? = nil,
        onError: ((Error) -> ())? = nil,
        onProgress: ((Int64, Int64) -> ())? = nil
        ) {
        self.onSuccess = onSuccess
        self.onError = onError
        self.onProgress = onProgress
    }
}

///HTTP prtocol methods. See - https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods
public enum HttpMethod: String {
    case GET, POST
}
