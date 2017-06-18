#if os(OSX)
    import Cocoa
    typealias VKStoryboard = NSStoryboard
#elseif os(iOS)
    import UIKit
    typealias VKStoryboard = UIStoryboard
#endif

protocol DependencyFactory:
    DependencyHolder,
    SessionMaker,
    TaskMaker,
    AttemptMaker,
    TokenMaker,
    WebControllerMaker,
    CaptchaControllerMaker
{}

protocol DependencyHolder: SessionStorageHolder, AuthorizatorHolder {
    init(appId: String, delegate: SwiftyVKDelegate?)
}

protocol SessionStorageHolder: class {
    var sessionStorage: SessionStorage { get }
}

protocol AuthorizatorHolder: class {
    var authorizator: Authorizator { get }
}

protocol SessionMaker: class {
    func session() -> Session
}

protocol TaskMaker: class {
    func task(request: Request, callbacks: Callbacks, session: TaskSession & ApiErrorExecutor) -> Task
}

protocol AttemptMaker: class {
    func attempt(request: URLRequest, timeout: TimeInterval, callbacks: AttemptCallbacks) -> Attempt
}

protocol TokenMaker: class {
    func token(token: String, expires: TimeInterval, info: [String : String]) -> Token
}

protocol WebControllerMaker: class {
    func webController() -> WebController?
}

protocol CaptchaControllerMaker {
    func captchaController() -> CaptchaController?
}

final class DependencyFactoryImpl: DependencyFactory {
    
    private let appId: String
    private weak var delegate: SwiftyVKDelegate?
    private let uiSyncQueue = DispatchQueue(label: "SwiftyVK.uiSyncQueue")
    
    init(appId: String, delegate: SwiftyVKDelegate?) {
        self.appId = appId
        self.delegate = delegate
    }
    
    lazy public var sessionStorage: SessionStorage = {
        return SessionStorageImpl(sessionMaker: self)
    }()
    
    func session() -> Session {
        
        let captchaPresenter = CaptchaPresenterImpl(
            uiSyncQueue: uiSyncQueue,
            controllerMaker: self,
            timeout: 600
        )
        
        return SessionImpl(
            taskSheduler: TaskShedulerImpl(),
            attemptSheduler: AttemptShedulerImpl(limit: .limited(3)),
            authorizator: sharedAuthorizator,
            taskMaker: self,
            captchaPresenter: captchaPresenter
        )
    }
    
    var authorizator: Authorizator {
        return sharedAuthorizator
    }
    
    private lazy var sharedAuthorizator: Authorizator = {
        
        let urlOpener: UrlOpener
        
        #if os(iOS)
            urlOpener = UIApplication.shared
        #elseif os(macOS)
            urlOpener = UrlOpener_macOS()
        #endif
        
        let vkAppProxy = VkAppProxyImpl(
            appId: self.appId,
            urlOpener: urlOpener
        )
        
        let webPresenter = WebPresenterImpl(
            uiSyncQueue: self.uiSyncQueue,
            controllerMaker: self,
            maxFails: 3,
            timeout: 600
        )
        
        return AuthorizatorImpl(
            appId: self.appId,
            delegate: self.delegate,
            tokenStorage: TokenStorageImpl(),
            tokenMaker: self,
            tokenParser: TokenParserImpl(),
            vkAppProxy: vkAppProxy,
            webPresenter: webPresenter
        )
    }()
    
    func webController() -> WebController? {
        var webController: WebController?
        
        #if os(iOS)
            webController = storyboard().instantiateViewController(withIdentifier: "Web") as? WebController_iOS
        #elseif os(macOS)
            webController = storyboard().instantiateController(withIdentifier: "Web") as? WebController_macOS
        #endif
        
        guard let controller = webController as? VkViewController else {
            return nil
        }
        
        DispatchQueue.main.sync {
            self.delegate?.vkNeedToPresent(viewController: controller)
        }
        
        return webController
    }
    
    func captchaController() -> CaptchaController? {
        var captchaController: CaptchaController?
        
        #if os(iOS)
            captchaController = storyboard().instantiateViewController(withIdentifier: "Captcha") as? CaptchaController_iOS
        #elseif os(macOS)
            captchaController = storyboard().instantiateController(withIdentifier: "Captcha") as? CaptchaController_macOS
        #endif
        
        guard let controller = captchaController as? VkViewController else {
            return nil
        }
        
        DispatchQueue.main.sync {
            self.delegate?.vkNeedToPresent(viewController: controller)
        }
        
        return captchaController
    }
    
    func storyboard() -> VKStoryboard {
        return VKStoryboard(
            name: Resources.withSuffix("Storyboard"),
            bundle: Resources.bundle
        )
    }
    
    func task(request: Request, callbacks: Callbacks, session: TaskSession & ApiErrorExecutor) -> Task {
        return TaskImpl(
            request: request,
            callbacks: callbacks,
            session: session,
            urlRequestBuilder: urlRequestBuilder(),
            attemptMaker: self,
            apiErrorHandler: ApiErrorHandlerImpl(session: session)
        )
    }
    
    func attempt(request: URLRequest, timeout: TimeInterval, callbacks: AttemptCallbacks) -> Attempt {
        return AttemptImpl(request: request, timeout: timeout, callbacks: callbacks)
    }
    
    func token(token: String, expires: TimeInterval, info: [String : String]) -> Token {
        return TokenImpl(
            token: token,
            expires: expires,
            info: info
        )
    }
    
    private func urlRequestBuilder() -> UrlRequestBuilder {
        return UrlRequestBuilderImpl(
            queryBuilder: QueryBuilderImpl(),
            bodyBuilder: MultipartBodyBuilderImpl()
        )
    }
}
