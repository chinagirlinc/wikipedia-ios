import UIKit

@objc public protocol WMFReadingThemesControlsViewControllerDelegate {
    
    func fontSizeSliderValueChangedInController(_ controller: ReadingThemesControlsViewController, value: Int)
}

@objc(WMFReadingThemesControlsViewController)
open class ReadingThemesControlsViewController: UIViewController {
    
    static let WMFUserDidSelectThemeNotification = "WMFUserDidSelectThemeNotification"
    static let WMFUserDidSelectThemeNotificationThemeKey = "theme"
    
    var theme = Theme.standard
    
    @IBOutlet weak var imageDimmingLabel: UILabel!
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    @IBOutlet weak var brightnessSlider: UISlider!
    
    @IBOutlet weak var lightThemeButton: UIButton!
    @IBOutlet weak var sepiaThemeButton: UIButton!
    @IBOutlet weak var darkThemeButton: UIButton!
    
    @IBOutlet weak var imageDimmingSwitch: UISwitch!
    
    @IBOutlet var separatorViews: [UIView]!
    
    @IBOutlet var textSizeSliderViews: [UIView]!
    
    @IBOutlet weak var minBrightnessImageView: UIImageView!
    @IBOutlet weak var maxBrightnessImageView: UIImageView!
    
    @IBOutlet weak var tSmallImageView: UIImageView!
    @IBOutlet weak var tLargeImageView: UIImageView!
    
    @IBOutlet var textLabels: [UILabel]!
    @IBOutlet var stackView: UIStackView!
    
    var visible = false
    
    open weak var delegate: WMFReadingThemesControlsViewControllerDelegate?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        if let max = self.maximumValue {
            if let current = self.currentValue {
                self.setValues(0, maximum: max, current: current)
                self.maximumValue = nil
                self.currentValue = nil
            }
        }
        brightnessSlider.value = Float(UIScreen.main.brightness)
        
        imageDimmingLabel.text = CommonStrings.dimImagesTitle
    
        NotificationCenter.default.addObserver(self, selector: #selector(self.screenBrightnessChangedInApp(notification:)), name: NSNotification.Name.UIScreenBrightnessDidChange, object: nil)
        
        preferredContentSize = stackView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func applyBorder(to button: UIButton) {
        button.borderWidth = 2
        button.isEnabled = false
        button.borderColor = theme.colors.link

    }
    
    func removeBorderFrom(_ button: UIButton) {
        button.borderWidth = traitCollection.displayScale > 0.0 ? 1.0/traitCollection.displayScale : 0.5
        button.isEnabled = true
        button.borderColor = UIColor.wmf_lighterGray //intentionally unthemed
    }
    
    var isTextSizeSliderHidden: Bool {
        set {
            let _ = self.view //ensure view is loaded
            for slideView in textSizeSliderViews {
                slideView.isHidden = newValue
            }
            preferredContentSize = stackView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        }
        get {
            return textSizeSliderViews.first?.isHidden ?? false
        }
    }
    
    open func setValuesWithSteps(_ steps: Int, current: Int) {
        if self.isViewLoaded {
            self.setValues(0, maximum: steps-1, current: current)
        }else{
            maximumValue = steps-1
            currentValue = current
        }
    }
    
    func setValues(_ minimum: Int, maximum: Int, current: Int){
        self.slider.minimumValue = minimum
        self.slider.maximumValue = maximum
        self.slider.value = current
    }
    
    @IBAction func dimmingSwitchValueChanged(_ sender: Any) {
        let currentTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
        UserDefaults.wmf_userDefaults().wmf_isImageDimmingEnabled = imageDimmingSwitch.isOn
        userDidSelect(theme: currentTheme.withDimmingEnabled(imageDimmingSwitch.isOn))
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visible = true
        let currentTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
        updateThemeButtons(with: currentTheme)
    }
    
    func updateThemeButtons(with theme: Theme) {
        removeBorderFrom(lightThemeButton)
        removeBorderFrom(darkThemeButton)
        removeBorderFrom(sepiaThemeButton)
        imageDimmingSwitch.isEnabled = false
        imageDimmingSwitch.isOn = UserDefaults.wmf_userDefaults().wmf_isImageDimmingEnabled
        switch theme.name {
        case Theme.sepia.name:
            applyBorder(to: sepiaThemeButton)
        case Theme.light.name:
            applyBorder(to: lightThemeButton)
        case Theme.darkDimmed.name:
            fallthrough
        case Theme.dark.name:
            imageDimmingSwitch.isEnabled = true
            applyBorder(to: darkThemeButton)
        default:
            break
        }
    }
    
    func screenBrightnessChangedInApp(notification: Notification){
        brightnessSlider.value = Float(UIScreen.main.brightness)
    }
    
    @IBAction func brightnessSliderValueChanged(_ sender: UISlider) {
        UIScreen.main.brightness = CGFloat(sender.value)
    }
    
    @IBAction func fontSliderValueChanged(_ slider: SWStepSlider) {
        if let delegate = self.delegate, visible {
            delegate.fontSizeSliderValueChangedInController(self, value: self.slider.value)
        }
    }
    
    func userDidSelect(theme: Theme) {
        let userInfo = ["theme": theme]
        updateThemeButtons(with: theme)
        NotificationCenter.default.post(name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: userInfo)
    }
    
    @IBAction func sepiaThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme:  Theme.sepia)
    }
    
    @IBAction func lightThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme: Theme.light)
    }
    
    @IBAction func darkThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme: Theme.dark.withDimmingEnabled(UserDefaults.wmf_userDefaults().wmf_isImageDimmingEnabled))
    }
}

// MARK: - Themeable

extension ReadingThemesControlsViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.colors.popoverBackground
        
        for separator in separatorViews {
            separator.backgroundColor = theme.colors.border
        }
        
        slider.backgroundColor = view.backgroundColor
        
        for label in textLabels {
            label.textColor = theme.colors.primaryText
        }
        
        let buttons = [lightThemeButton, darkThemeButton, sepiaThemeButton]
        for button in buttons {
            guard let button = button else {
                continue
            }
            button.borderColor = button.isEnabled ? theme.colors.border : theme.colors.link
        }


        minBrightnessImageView.tintColor = theme.colors.secondaryText
        maxBrightnessImageView.tintColor = theme.colors.secondaryText
        tSmallImageView.tintColor = theme.colors.secondaryText
        tLargeImageView.tintColor = theme.colors.secondaryText
        
        view.tintColor = theme.colors.link
    }
    
}
