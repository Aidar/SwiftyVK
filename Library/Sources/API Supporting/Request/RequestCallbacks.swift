public struct RequestCallbacks {
    public typealias Success = (Data) throws -> ()
    public typealias Error = (VKError) -> ()
    public typealias Progress = (_ type: ProgressType, _ current: Int64, _ of: Int64) -> ()

    public static let empty = RequestCallbacks()
    
    var onSuccess: Success?
    var onError: Error?
    var onProgress: Progress?
    
    public init(
        onSuccess: Success? = nil,
        onError: Error? = nil,
        onProgress: Progress? = nil
        ) {
        self.onSuccess = onSuccess
        self.onError = onError
        self.onProgress = onProgress
    }
}

public enum ProgressType {
    case sended
    case recieved
}
