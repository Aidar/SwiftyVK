public extension VK.Api {
    public enum Storage: APIMethod {
        case get(Parameters)
        case set(Parameters)
        case getKeys(Parameters)
    }
}
