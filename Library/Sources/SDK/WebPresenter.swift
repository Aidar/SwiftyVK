protocol WebPresenter: class {
    func presentWith(urlRequest: URLRequest) throws -> String
    func dismiss()
}

enum WebControllerResult {
    case response(URL?)
    case error(Error)
}

private enum WebPresenterResult {
    case response(String)
    case error(Error)
}

private enum HandledResult {
    case response(String)
    case fail
    case nothing
}

final class WebPresenterImpl: WebPresenter {
    private let uiSyncQueue: DispatchQueue
    private let controllerMaker: WebControllerMaker
    private weak var currentController: WebController?
    private let maxFails: Int
    private let timeout: TimeInterval

    init(
        uiSyncQueue: DispatchQueue,
        controllerMaker: WebControllerMaker,
        maxFails: Int,
        timeout: TimeInterval
        ) {
        self.uiSyncQueue = uiSyncQueue
        self.controllerMaker = controllerMaker
        self.maxFails = maxFails
        self.timeout = timeout
    }
    
    func presentWith(urlRequest: URLRequest) throws -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var fails: Int = 0
        var finalResult: WebPresenterResult?
        
        return try uiSyncQueue.sync {
            
            guard let controller = controllerMaker.webController() else {
                throw SessionError.cantMakeWebViewController
            }
            
            let originalPath = urlRequest.url?.path ?? ""
            currentController = controller
            
            controller.load(
                urlRequest: urlRequest,
                onResult: { [weak self] result in
                    guard let `self` = self else { return }
                    
                    do {
                        let handledResult = try self.handle(result: result ,fails: fails, originalPath: originalPath)
                        
                        switch handledResult {
                        case let .response(value):
                            finalResult = .response(value)
                        case .fail:
                            fails += 1
                            self.currentController?.reload()
                        case .nothing:
                            break
                        }
                        
                    } catch let error {
                        finalResult = .error(error)
                    }
                    
                    if finalResult != nil {
                        self.currentController?.dismiss()
                    }
                },
                onDismiss: {
                    semaphore.signal()
                }
            )
            
            switch semaphore.wait(timeout: .now() + timeout) {
            case .timedOut:
                throw SessionError.webPresenterTimedOut
            case .success:
                break
            }
            
            switch finalResult {
            case .response(let response)?:
                return response
            case .error(let error)?:
                throw error
            case nil:
                throw SessionError.webPresenterResultIsNil
            }
        }
    }
    
    private func handle(result: WebControllerResult, fails: Int, originalPath: String) throws -> HandledResult {
        switch result {
        case .response(let url):
            return try handle(url: url, originalPath: originalPath)
        case .error(let error):
            return try handle(error: error, fails: fails)
        }
    }
    
    private func handle(url: URL?, originalPath: String) throws -> HandledResult {
        guard let url = url else {
            throw SessionError.wrongAuthUrl
        }
        
        let fragment = url.fragment ?? ""

        if fragment.contains("access_token=") {
            return .response(fragment)
        }
        else if fragment.contains("success=1") {
            return .response(fragment)
        }
        else if fragment.contains("access_denied") ||
            fragment.contains("cancel=1") {
            throw SessionError.deniedFromUser
        }
        else if fragment.contains("fail=1") {
            throw SessionError.failedAuthorization
        }
        else if url.path == originalPath {
            return .nothing
        }
        else {
            currentController?.goBack()
            return .nothing
        }
    }
    
    private func handle(error: Error, fails: Int) throws -> HandledResult {
        guard fails >= maxFails - 1 else {
            return .fail
        }
        
        throw error
    }
    
    func dismiss() {
        currentController?.dismiss()
    }
}
