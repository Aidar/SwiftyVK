import UIKit

final class CaptchaController_iOS: UIViewController, UITextFieldDelegate, CaptchaController {
    
    @IBOutlet private weak var imageView: UIImageView?
    @IBOutlet private weak var textField: UITextField?
    @IBOutlet weak var preloader: UIActivityIndicatorView?
    @IBOutlet weak var closeButton: UIButton?
    private var onResult: ((String) -> ())?
    private var onDismiss: (() -> ())?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        closeButton?.setImage(
            UIImage(named: "CloseButton", in: Resources.bundle, compatibleWith: nil),
            for: .normal
        )
        
        closeButton?.setImage(
            UIImage(named: "CloseButtonPressed", in: Resources.bundle, compatibleWith: nil),
            for: .highlighted
        )
        
        imageView?.backgroundColor = .white
        imageView?.layer.cornerRadius = 15
        imageView?.layer.masksToBounds = true
        imageView?.layer.borderColor = UIColor.lightGray.cgColor
        imageView?.layer.borderWidth = 1 / UIScreen.main.nativeScale
        textField?.delegate = self
        preloader?.color = .lightGray
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismiss?()
    }
    
    func prepareForPresent() {
        DispatchQueue.main.async {
            self.imageView?.image = nil
            self.imageView?.alpha = 0.75
            
            self.textField?.isEnabled = false
            self.textField?.text = nil
            self.textField?.alpha = 0.75
            
            self.preloader?.startAnimating()
        }
    }
    
    func present(imageData: Data, onResult: @escaping (String) -> (), onDismiss: @escaping () -> ()) {
        DispatchQueue.main.sync {
            imageView?.image = UIImage(data: imageData)
            imageView?.alpha = 1
            
            textField?.isEnabled = true
            textField?.alpha = 1
            textField?.becomeFirstResponder()
            
            preloader?.stopAnimating()
        }
        
        self.onResult = onResult
        self.onDismiss = onDismiss
    }
    
    @IBAction func dismissByButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func dismiss() {
        DispatchQueue.main.sync {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let result = textField.text, !result.isEmpty else {
            return false
        }
        
        onResult?(result)
        textField.resignFirstResponder()
        return true
    }
}
