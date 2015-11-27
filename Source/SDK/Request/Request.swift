import Foundation



internal var sharedCaptchaIsRun = false
internal var sharedCatchaAnswer : [String : String]?



///Request to VK API
public class Request : CustomStringConvertible {
  public var timeout = VK.defaults.timeOut
  public var isAsynchronous = VK.defaults.sendAsynchronous
  public var errorBlock = VK.defaults.errorBlock
  public var progressBlock = VK.defaults.progressBlock
  ///Maximum number of attempts to send, after which execution priryvaetsya and an error is returned
  public var maxAttempts = VK.defaults.maxAttempts
  ///Whether to allow automatic processing of some API error
  public var catchErrors = VK.defaults.catchErrors
  internal var method = ""
  internal private(set) var isAPI = false
  internal var attempts = 0
  internal var isCanSend : Bool {return attempts < maxAttempts || maxAttempts == 0}
  internal var swappedRequest : Request?
  internal var customURL : String?
  internal private(set) var isCancelled = false
  private var _successBlock = VK.defaults.successBlock
  private var privateLanguage = VK.defaults.language
  private var useSystemLanguage = VK.defaults.useSystemLanguage
  private var HTTPMethod = "GET"
  private var media : [Media]?
  private var parameters = [String : String]()
  public var successBlock : VK.SuccessBlock {
    get{return _successBlock}
    set{
      if swappedRequest != nil {swappedRequest?.successBlock = newValue}
      else {_successBlock = newValue}
    }
  }
  public var language : String? {
    get {
      if useSystemLanguage {
        let syslemLang = NSLocale.preferredLanguages()[0] as String
        
        if VK.defaults.supportedLanguages.contains(syslemLang) {
          return syslemLang
        }
        else if syslemLang == "uk" {
          return "ua"
        }
      }
      return self.privateLanguage
    }
    set {
      self.privateLanguage = newValue
      useSystemLanguage = false
    }
  }
  internal var URLRequest : NSURLRequest {
    let req = NSURLFabric.get(url: customURL, HTTPMethod: HTTPMethod, method: method, params: allParameters, media: media)
    req.timeoutInterval = NSTimeInterval(self.timeout)
    return req
  }
  internal lazy var response : Response = {
    let result = Response()
    result.request = self
    return result
  }()
  private var allParameters : [String : String] {
    var params = parameters
    
    if let token = Token.get() {
      params["access_token"] = token
    }
    
    if sharedCatchaAnswer != nil {
      params["captcha_sid"] = sharedCatchaAnswer!["captcha_sid"]
      params["captcha_key"] = sharedCatchaAnswer!["captcha_key"]
      sharedCatchaAnswer = nil
    }
    
    params["v"] = VK.defaults.apiVersion
    params["https"] = "1";
    
    if let lang = language {
      params["lang"] = lang
    }
    
    return params
  }
  public var description : String {
    get {return "Request: \(method) parameters: \(parameters), attempts: \(maxAttempts)"}
  }
  
  
  
  internal init(url: String) {
    self.customURL = url
    Log([.life], "\(self) INIT")
  }
  
  
  
  internal init(method: String, parameters: [VK.Arg : String]?) {
    self.isAPI               = true
    self.method              = method
    self.parameters          = argToString(parameters)
    Log([.life], "\(self) INIT")
  }
  
  
  
  internal init(url: String, media: [Media]) {
    self.maxAttempts         = 10
    self.HTTPMethod          = "POST"
    self.customURL           = url
    self.media               = media
    Log([.life], "\(self) INIT")
  }
  
  
  
  ///Add new parameters to request
  public func addParameters(agrDict: [VK.Arg : String]?) {
    for (argName, argValue) in agrDict! {
      Log([.request, .reqParameters], "Add parameter \(argName.rawValue)=\(argValue) to request \(self)")
      self.parameters[argName.rawValue] = argValue
    }
  }
  
  
  
  ///Send with blocks
  public func send(_successBlock: VK.SuccessBlock,_ _errorBlock:  VK.ErrorBlock) {
    self.successBlock = _successBlock
    self.errorBlock = _errorBlock
    self.send()
  }
  
  
  
  ///Just send
  public func send() {
    attempts = 0
    isCancelled = false
    reSend()
  }
  
  
  
  internal func reSend() -> Bool {
    if isCanSend {
      attempts++
      let type = (self.isAsynchronous ? "asynchronous" : "synchronous")
      Log([.request], "Sending \(type) request \(self)")
      response.error = nil
      _ = Connection(request: self)
      return true
    }
    else {
      return false
    }
  }
  
  
  
  internal func sendInCurrentThread() -> Bool {
    if isCanSend {
      Connection.sendInCurrentThread(self)
      return true
    }
    else {
      return false
    }
  }
  
  
  
  public func cancel() {
    isCancelled = true
  }
  
  
  
  private func argToString(agrDict: [VK.Arg : String]?) -> [String : String] {
    var strDict = [String : String]()
    
    guard agrDict != nil else {return [:]}
    
    for (argName, argValue) in agrDict! {
      strDict[argName.rawValue] = argValue
      Log([.request, .reqParameters], "Parse parameter \(argName.rawValue)=\(argValue) in \(self) to string")
    }
    return strDict
  }
  
  
  
  init() {
    Log([LogOption.life], "\(self) INIT")
  }
  
  
  
  deinit {
    Log([LogOption.life], "\(self) DEINIT")
  }
}

