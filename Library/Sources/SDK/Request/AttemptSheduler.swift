import Foundation

protocol AttemptSheduler: class {
    func setLimit(to: AttemptLimit)
    func shedule(attempt: Attempt, concurrent: Bool)
}

final class AttemptShedulerImpl: AttemptSheduler {
    
    private lazy var concurrentQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = .max
        return queue
    }()
    private let serialQueue: AttemptApiQueue
    
    private var limit: AttemptLimit {
        get { return serialQueue.limit }
        set { serialQueue.limit = newValue }
    }
    
    init(limit: AttemptLimit) {
        serialQueue = AttemptApiQueue(limit: limit)
    }
    
    func setLimit(to newLimit: AttemptLimit) {
        limit = newLimit
    }
    
    func shedule(attempt: Attempt, concurrent: Bool) {
        let operation = attempt.toOperation()
        
        if concurrent {
            concurrentQueue.addOperation(operation)
        }
        else {
            serialQueue.addOperation(operation)
        }
    }
}

private class AttemptApiQueue: OperationQueue {
    
    private let counterQueue = DispatchQueue(label: "SwiftyVK.couterQueue")
    private let attemptsQueue = DispatchQueue(
        label: "SwiftyVK.serialAttemptQueue",
        qos: .userInitiated
    )
    
    private var sended = 0
    private var waited = [Operation]()
    var limit: AttemptLimit
    
    init(limit: AttemptLimit) {
        self.limit = limit
        
        super.init()
        underlyingQueue = attemptsQueue
        
        counterQueue.async {
            let timer = Timer(
                timeInterval: 1,
                target: self,
                selector: #selector(self.dropCounter),
                userInfo: nil,
                repeats: true
            )
            timer.tolerance = 0.01
            RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
            RunLoop.current.run()
        }
    }
    
    override func addOperation(_ operation: Operation) {
        attemptsQueue.async {
            self.addOperationSync(operation)
        }
    }
    
    private func addOperationSync(_ operation: Operation) {
        if limit.count < 1 || sended < limit.count {
            sended += 1
            super.addOperation(operation)
        }
        else {
            waited.append(operation)
        }
    }

    @objc
    private func dropCounter() {
        attemptsQueue.async(execute: dropCounterSync)
    }
    
    private func dropCounterSync() {
        guard !waited.isEmpty || sended > 0 else { return }
        
        self.sended = 0
        
        while !waited.isEmpty && sended < limit.count {
            sended += 1
            let op = waited.removeFirst()
            super.addOperation(op)
        }
    }
}
