import UIKit

final class SharePreviewControllerIOS: UIViewController, UITextViewDelegate, ShareController {

    @IBOutlet weak var messageTextView: UITextView?
    @IBOutlet weak var linkTitle: UILabel?
    @IBOutlet weak var linkUrl: UILabel?
    @IBOutlet weak var imageCollection: ShareImageCollectionViewIOS?
    @IBOutlet weak var sendButton: UIBarButtonItem?
    @IBOutlet weak var placeholderView: UIView?
    @IBOutlet weak var placeholderIndicator: UIActivityIndicatorView?
    
    @IBOutlet weak var separatorHeight: NSLayoutConstraint?
    @IBOutlet weak var linkViewHeight: NSLayoutConstraint?
    @IBOutlet weak var imageCollectionHeight: NSLayoutConstraint?
    
    private var context = ShareContext()
    private var onPost: ((ShareContext) -> ())?
    private var rightButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageTextView?.delegate = self
        separatorHeight?.constant = 1 / UIScreen.main.nativeScale
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        imageCollectionHeight?.constant = context.images.isEmpty ? 0 : 135
        linkViewHeight?.constant = context.link != nil ? 51 : 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let preferencesController = segue.destination as? SharePreferencesControllerIOS {
            preferencesController.set(preferences: context.preferences)
        }
    }
    
    func share(_ context: ShareContext, onPost: @escaping (ShareContext) -> (), onDismiss: @escaping () -> ()) {
        self.context = context
        self.onPost = onPost
        
        DispatchQueue.safelyOnMain {
            updateView()
        }
    }
    
    private func updateView() {
        imageCollection?.set(images: context.images)
        
        messageTextView?.text = context.message
        
        linkTitle?.text = context.link?.title
        linkUrl?.text = context.link?.url.absoluteString
        
        updateSendButton()
    }
    
    func showPlaceholder(_ enable: Bool) {
        enablePostButton(!enable)
        
        DispatchQueue.safelyOnMain {
            UIView.animate(withDuration: 0.3) {
                self.placeholderView?.alpha = enable ? 1 : 0
            }
            
        }
    }
    
    func enablePostButton(_ enable: Bool) {
        DispatchQueue.safelyOnMain {
            if enable {
                navigationItem.setRightBarButton(rightButton, animated: true)
                rightButton = nil
            }
            else {
                rightButton = navigationItem.rightBarButtonItem
                let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                let barButton = UIBarButtonItem(customView: activityIndicator)
                navigationItem.setRightBarButton(barButton, animated: true)
                activityIndicator.startAnimating()
            }
        }
    }
    
    func close() {
        DispatchQueue.safelyOnMain {
            messageTextView?.endEditing(true)
            navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func showError(title: String, message: String, buttontext: String) {
        DispatchQueue.safelyOnMain {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: buttontext, style: .default, handler: nil))
            present(alert, animated: true, completion: nil) 
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        context.message = textView.text
        updateSendButton()
    }
    
    private func updateSendButton() {
        sendButton?.isEnabled = messageTextView?.text.isEmpty == false || context.hasAttachments
    }
    
    @IBAction func donePressed(_ sender: Any) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let strongSelf = self else { return }
            self?.onPost?(strongSelf.context)
        }
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.endEditing(true)
        }
        
        return true
    }
    
    deinit {
        print("DEINIT", type(of: self))
    }
}
