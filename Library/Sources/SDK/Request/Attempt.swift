import Foundation

protocol Attempt: class {
    init(
        request: URLRequest,
        timeout: TimeInterval,
        session: VKURLSession,
        callbacks: AttemptCallbacks
    )
    
    func cancel()
}

final class AttemptImpl: Operation, Attempt {
    
    private let request: URLRequest
    private let timeout: TimeInterval
    private var task: VKURLSessionTask?
    private let urlSession: VKURLSession
    private let callbacks: AttemptCallbacks
    
    init(
        request: URLRequest,
        timeout: TimeInterval,
        session: VKURLSession,
        callbacks: AttemptCallbacks
        ) {
        self.request = request
        self.timeout = timeout
        self.urlSession = session
        self.callbacks = callbacks
        super.init()
    }
    
    override func main() {
        let semaphore = DispatchSemaphore(value: 0)
        
        let completion: (Data?, URLResponse?, Error?) -> () = { [weak self] data, response, error in
            defer {
                semaphore.signal()
            }
            
            guard let `self` = self, !self.isCancelled else { return }
            
            if let error = error {
                self.callbacks.onFinish(.error(.urlRequestError(error)))
            }
            else if let data = data {
                self.callbacks.onFinish(Response(data))
            }
            else {
                self.callbacks.onFinish(.error(.unexpectedResponse))
            }
        }
        
        task = urlSession.dataTask(with: request, completionHandler: completion)
        task?.addObserver(self, forKeyPath: #keyPath(URLSessionTask.countOfBytesReceived), options: .new, context: nil)
        task?.addObserver(self, forKeyPath: #keyPath(URLSessionTask.countOfBytesSent), options: .new, context: nil)
        task?.resume()
        
        semaphore.wait()
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
        ) {
        guard let keyPath = keyPath else { return }
        guard let task = task else { return }
        
        switch keyPath {
        case (#keyPath(URLSessionTask.countOfBytesSent)):
            callbacks.onSent(task.countOfBytesSent, task.countOfBytesExpectedToSend)
        case(#keyPath(URLSessionTask.countOfBytesReceived)):
            callbacks.onRecive(task.countOfBytesReceived, task.countOfBytesExpectedToReceive)
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func cancel() {
        super.cancel()
        task?.cancel()
    }
    
    deinit {
        task?.removeObserver(self, forKeyPath: #keyPath(URLSessionTask.countOfBytesReceived))
        task?.removeObserver(self, forKeyPath: #keyPath(URLSessionTask.countOfBytesSent))
    }
}

struct AttemptCallbacks {
    let onFinish: (Response) -> ()
    let onSent: (_ total: Int64, _ of: Int64) -> ()
    let onRecive: (_ total: Int64, _ of: Int64) -> ()
    
    init(
        onFinish: @escaping ((Response) -> ()) = { _ in },
        onSent: @escaping ((_ total: Int64, _ of: Int64) -> ()) = { _, _ in },
        onRecive: @escaping ((_ total: Int64, _ of: Int64) -> ()) = { _, _ in }
        ) {
        self.onFinish = onFinish
        self.onSent = onSent
        self.onRecive = onRecive
    }
    
    static var `default`: AttemptCallbacks {
        return AttemptCallbacks()
    }
}
