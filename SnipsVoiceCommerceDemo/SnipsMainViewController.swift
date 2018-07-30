//
//  ViewController.swift
//  SnipsVoiceCommerceDemo
//
//  Created by Fabrice Dewasmes on 12/07/2018.
//  Copyright © 2018 Fabrice Dewasmes. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import SnipsPlatform
import DrawerKit
import AZTabBar

let INTENT_LIST_CART_ITEMS = "alrouen:listCartItems"
let INTENT_PURGE_CART = "alrouen:purgeCart"
let INTENT_ADD_ITEM = "alrouen:addItem"
let INTENT_ORDER_STATUS = "alrouen:orderStatus"
let INTENT_SMALL_TALK = "alrouen:smallTalk"
let INTENT_YES = "alrouen:sayYes"
let INTENT_NO = "alrouen:sayNo"

let ALL_INTENTS = [INTENT_LIST_CART_ITEMS, INTENT_PURGE_CART, INTENT_ADD_ITEM, INTENT_ORDER_STATUS, INTENT_SMALL_TALK]
let YES_NO = [INTENT_YES , INTENT_NO]

let SKILL_MESSAGES : Dictionary<String,Dictionary<String,Any>> = [
    "fr": [
        "hello": [
        "Bonjour, que puis-je faire pour vous aider ?",
        "Bonjour, comment puis-je vous aider ?"
        ],
        "youAreWelcome": [
        "Mais de rien.",
        "Je vous en pris."
        ],
        "newQuestion": [
        "Que puis-je faire d'autre pour vous aider ?",
        "Puis-je vous aider pour autre chose ?"
        ],
        "bye": [
        "à bientôt"
        ],
        "unknownSmallTalk": [
        "Je ne suis pas sur de vous avoir compris... "
        ],
        "and": " et ",
        "lookingForPastOrder": [
        "Bien sur, je recherche dans votre historique d'achat",
        "Pas de problème, je regarde dans vos derniers achats"
        ],
        "purgeCartConfirmation": "Voulez-vous supprimer cet article ?",
        "purgeCartPluralConfirmation": "Voulez-vous supprimer ces articles ?",
        "purgeDone": "Voilà votre panier est vide",
        "purgeCancel": "Pas de problème, je n'ai rien supprimé",
        "addItemConfirmation": "Je vous propose d'ajouter %@. C'est bien ça ?",
        "itemAdded": "Voilà l'article est enregistré",
        "itemsAdded": "Voilà les %d articles sont enregistrés",
        "itemNotAdded": "Pas de problème, je n'ai rien ajouté",
        "noEnoughItem": "Désolé mais pour l'article {}, le stock n'est pas suffisant pour la quantité que vous demandez",
        "inYourCart": "J'ai trouvé %d articles dans votre panier: %@",
        "inYourCartShort" : "J'ai trouvé %d articles dans votre panier",
        "emptyCart": "Je ne vois rien dans votre panier pour le moment",
        "tooBigCart" : "Il y a plus de 10 articles dans votre paniers",
        "cahier": "cahier de 96 pages",
        "protegecahier": "Protège-cahier transparent vert",
        "encre": "étui de 24 cartouches d'encre noire",
        "stylo": "Stylo bille noire",
        "unknown_product": "produit que je ne connais pas",
        "order_status": "Le status de votre dernière commande est celui-ci : %@",
        "unknown_status": "inconnus"
    ]
]

let PRODUCTS = [
    "3329680637410": "cahier",
    "3086126732343": "encre",
    "0073228109695": "stylo",
    "3210330734057": "protegecahier"
]

let ORDER_STATUS = [
    "canceled":"annulée",
    "closed":"fermée",
    "complete":"terminée",
    "holded":"en suspend",
    "payment_review":"en cours de validation paiement",
    "paypal_reversed":"annulation paypal",
    "pending": "en cours de préparation",
    "pending_payment":"en attente de paiement",
    "pending_paypal":"en attente de confirmation paypal",
    "processing":"en cours de traitement"
]

let ACTION_ADD_ITEMS = "add_items"
let ACTION_PURGE_CART = "purgeCart"

class SnipsMainViewController: UIViewController{
    private var cartViewController: CartViewController? = nil
    private var orderViewController: OrderViewController? = nil
    private var magentoClient : MagentoClient? = nil
    
    //The icons that will be displayed on the tabs that are not currently selected
    var icons = [String]()
    
    //The icons that will be displayed for each tab once they are selected.
    var selectedIcons = [String]()
    
    var tabController: AZTabBarController?
    
    private var messages : Message = Message(lang:"fr",messages : SKILL_MESSAGES["fr"]!)
    
    private var snips: SnipsPlatform? = nil
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    
    private var currentAddItem : [Item] = []
    var currentSayMessage: SayMessage?
    
    var drawerDisplayController:DrawerDisplayController? = nil
    
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var recordButton: RecordButton!
    
    @IBAction func startDialogTapped(_ sender: Any) {
        try! snips?.startSession(text: nil, intentFilter: [], canBeEnqueued: true, customData: nil)
    }
    
    @IBAction func expandDrawerButtonTapped(_ sender: Any) {
        doModalPresentation()
    }
    @IBAction func recordTapped(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            snips = nil
            startButton.isEnabled = false
            recordButton.change(state: .stalled)
        } else {
            let assistantURL = Bundle.main.url(forResource: "my_assistant", withExtension: nil)!
            let assistantIsEmpty = try! FileManager.default.contentsOfDirectory(at: assistantURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                .isEmpty
            
            if !assistantIsEmpty {
                startSnips(assistantURL: assistantURL)
            } else {
                fatalError("Unzip an assistant downloaded on https://console.snips.ai in the folder `my_assistant`")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        icons.append("cart-blue")
        icons.append("truck-blue")
        selectedIcons.append("cart-white")
        selectedIcons.append("truck-white")
        
        self.magentoClient = MagentoClient(host:"Some_server")
        self.magentoClient?.user = User(login:"some_user", password: "some_password")
        
        self.synthesizer.delegate = self
        
        self.cartViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CartViewController") as? CartViewController
        self.orderViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OrderViewController") as? OrderViewController
        self.cartViewController?.magentoClient = self.magentoClient
        
        tabController = AZTabBarController.insert(into: self, withTabIconNames: icons)
        tabController?.setViewController(self.cartViewController!, atIndex: 0)
        tabController?.setViewController(self.orderViewController!, atIndex: 1)
        tabController?.highlightedBackgroundColor = UIColor(rgb:0x4A90E2)
        tabController?.selectionIndicatorColor = .white
        tabController?.buttonsBackgroundColor = .gray
        tabController?.defaultColor = .white
        tabController?.highlightColor = .white
        tabController?.tabBarHeight = 60.0
        tabController?.highlightButton(atIndex: 0)
        tabController?.animateTabChange = true
        
        // reposition record button on top
        view.bringSubview(toFront: recordButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: utility methods
extension SnipsMainViewController{
    private func productSkuBy(name:String) -> String{
        let keys = PRODUCTS.keysForValue(value: name)
        if (keys.count > 0){
            return keys[0]
        } else {
            return ""
        }
    }
    
    private func productNameBy(sku:String) -> String?{
        let names = PRODUCTS.filter { (key,value) -> Bool in
            key == sku
            }.values.map{$0}
        let name = names.count > 0 ? names[0] : nil
        return name
    }
    
    private func statusNameFor(status:String) -> String {
        if let name = ORDER_STATUS[status] {
            return name
        } else {
            return ""
        }
    }
    
    private func messageFrom(sku : String) -> String {
        if let productName = productNameBy(sku : sku){
            return self.messages.getMessage(name:productName)
        } else {
            return self.messages.getMessage(name:"unknown_product")
        }
    }
    
    func buildItemsArray(items:[String], quantities:[Double]) -> [Item]{
        var itemsWithQuantitiesAndSku : [Item] = []
        for i in 0...items.count-1 {
            let q = (i < quantities.count ? quantities[i] : 1.0)
            itemsWithQuantitiesAndSku.append(Item(name:items[i], quantity: Int(q), sku:productSkuBy(name: items[i])))
        }
        
        return itemsWithQuantitiesAndSku
    }
    
    func buildItemSequence(itemsWithQuantities: [Item], rename:(String)->(String)) -> String{
        var itemList = itemsWithQuantities.map{"\($0.quantity) \(rename($0.name))"}
        let and = self.messages.getMessage(name:"and")
        
        var itemsStr : String
        
        if itemList.count > 1{
            itemsStr = itemList.joined(separator: and)
        } else {
            itemsStr = itemList[0]
        }
        
        return itemsStr
    }
    
    func buildAddItemSentence(itemsWithQuantities: [Item]) -> String{
        let itemsString = self.buildItemSequence(itemsWithQuantities:itemsWithQuantities, rename:{ (itemName) in
            self.messages.getMessage(name: itemName)
        })
        
        return String(format: self.messages.getMessage(name: "addItemConfirmation"), itemsString)
    }
}

// MARK: drawer management
extension SnipsMainViewController {
    func doModalPresentation() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "presented")
            as? DrawerNavigationController else { return }
        
        var configuration = DrawerConfiguration()
        
        configuration.durationIsProportionalToDistanceTraveled = false
        // default is UISpringTimingParameters()
        configuration.timingCurveProvider = UISpringTimingParameters(dampingRatio: 0.8)
        configuration.fullExpansionBehaviour = .leavesCustomGap(gap: 100) // default is .coversFullScreen
        configuration.supportsPartialExpansion = true
        configuration.dismissesInStages = true
        configuration.isDrawerDraggable = true
        configuration.isFullyPresentableByDrawerTaps = true
        configuration.numberOfTapsForFullDrawerPresentation = 1
        configuration.isDismissableByOutsideDrawerTaps = true
        configuration.numberOfTapsForOutsideDrawerDismissal = 1
        configuration.flickSpeedThreshold = 3
        configuration.upperMarkGap = 100 // default is 40
        configuration.lowerMarkGap =  80 // default is 40
        configuration.maximumCornerRadius = 15
        
        var handleViewConfiguration = HandleViewConfiguration()
        handleViewConfiguration.autoAnimatesDimming = true
        handleViewConfiguration.backgroundColor = .gray
        handleViewConfiguration.size = CGSize(width: 40, height: 6)
        handleViewConfiguration.top = 8
        handleViewConfiguration.cornerRadius = .automatic
        configuration.handleViewConfiguration = handleViewConfiguration
        
        let borderColor = UIColor(red: 205.0/255.0, green: 206.0/255.0, blue: 210.0/255.0, alpha: 1)
        let drawerBorderConfiguration = DrawerBorderConfiguration(borderThickness: 0.5,
                                                                  borderColor: borderColor)
        configuration.drawerBorderConfiguration = drawerBorderConfiguration
        
        let drawerShadowConfiguration = DrawerShadowConfiguration(shadowOpacity: 0.25,
                                                                  shadowRadius: 4,
                                                                  shadowOffset: .zero,
                                                                  shadowColor: .black)
        configuration.drawerShadowConfiguration = drawerShadowConfiguration
        
        drawerDisplayController = DrawerDisplayController(presentingViewController: self,
                                                          presentedViewController: vc,
                                                          configuration: configuration,
                                                          inDebugMode: true)
        
        present(vc, animated: true)
    }
}

// MARK: - Skill management

extension SnipsMainViewController {
    
    func yes(intent:IntentMessage){
        if intent.customData == ACTION_ADD_ITEMS{
            self.magentoClient?.getCartID(completionHandler: {cartID in
                self.magentoClient?.addItems(cartID: cartID, items: self.currentAddItem, completionHandler: {addedItemsCount in
                    if addedItemsCount > 1 {
                        try! self.snips?.endSession(sessionId: intent.sessionId, text:String(format:self.messages.getMessage(name:"itemsAdded"), addedItemsCount))
                    } else if addedItemsCount > 0 {
                        try! self.snips?.endSession(sessionId: intent.sessionId, text:self.messages.getMessage(name:"itemAdded"))
                    }
                    self.currentAddItem.removeAll()
                    self.cartViewController?.refreshCart()
                })
            })
        } else if intent.customData == ACTION_PURGE_CART{
            self.magentoClient?.purgeCart(completionHandler: {removedItems in
                try! self.snips?.endSession(sessionId: intent.sessionId, text:self.messages.getMessage(name:"purgeDone"))
                self.cartViewController?.emptyCart()
            })
        }
        
    }
    
    func no(intent: IntentMessage){
        if intent.customData == ACTION_ADD_ITEMS{
            self.currentAddItem.removeAll()
            try! self.snips?.endSession(sessionId: intent.sessionId, text:self.messages.getMessage(name:"itemNotAdded"))
        } else if intent.customData == ACTION_PURGE_CART{
            try! self.snips?.endSession(sessionId: intent.sessionId, text:self.messages.getMessage(name:"purgeCancel"))
        }
    }
    
    func purgeCart(intent: IntentMessage){
        self.magentoClient?.getCartItems(completionHandler: {items in
            if items.count > 0{
                try! self.snips?.endSession(sessionId: intent.sessionId, text:String(format:self.messages.getMessage(name:"inYourCartShort"), items.count))
                var confirmation : String = ""
                if items.count > 1 {
                    confirmation = self.messages.getMessage(name:"purgeCartPluralConfirmation")
                } else {
                    confirmation = self.messages.getMessage(name:"purgeCartConfirmation")
                }
                try! self.snips?.startSession(text: confirmation, intentFilter: YES_NO, canBeEnqueued: true, customData: ACTION_PURGE_CART)
            } else{
                try! self.snips?.endSession(sessionId: intent.sessionId, text:self.messages.getMessage(name:"emptyCart"))
            }
        })
    }
    
    private func addItem(intent:IntentMessage) {
        var items : [String] = []
        var quantities : [Double] = []
        for slot in intent.slots {
            switch slot.slotName{
            case "quantity" :
                switch slot.value{
                case let .number(val):
                    quantities.append(val)
                default:
                    quantities.append(0.0)
                }
            case "item":
                switch slot.value{
                case let .custom(val):
                    items.append(val)
                default:
                    items.append("")
                }
            default:
                print("unrecognized slot for intent")
            }
        }
        
        self.currentAddItem = buildItemsArray(items: items, quantities: quantities)
        let confirmation = self.buildAddItemSentence(itemsWithQuantities: self.currentAddItem)

        try! self.snips?.endSession(sessionId: intent.sessionId, text: self.messages.getMessage(name: "lookingForPastOrder"))

        try! snips?.startSession(text: confirmation, intentFilter: YES_NO, canBeEnqueued: true, customData: ACTION_ADD_ITEMS)
    }
    
    func startSnips(assistantURL url: URL) {
        // Start microphone
        try! startRecording()
        
        // Start snips
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.snips = try! SnipsPlatform(assistantURL: url, enableHtml: true, enableLogs: true)
            self?.snips?.onIntentDetected = { intent in
                switch intent.intent?.intentName{
                case INTENT_ADD_ITEM:
                    self?.addItem(intent: intent)
                case INTENT_YES:
                    self?.yes(intent: intent)
                case INTENT_NO:
                    self?.no(intent: intent)
                case INTENT_PURGE_CART:
                    self?.purgeCart(intent: intent)
                default:
                    print("other")
                }
                
            }
            self?.snips?.onHotwordDetected = {
                print("hotword detected")
            }
            
            self?.snips?.speechHandler = { [weak self] sayMessage in
                let utterance = AVSpeechUtterance(string: sayMessage.text)
                utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
                self?.currentSayMessage = sayMessage
                self?.synthesizer.speak(utterance)
            }
            self?.snips?.snipsWatchHandler = { log in
                guard let htmlAttributedString = "\(log)<br />".htmlAttributedString else { return }
                
                DispatchQueue.main.async {
                    guard let actualHtmlAttributedString = self?.textView.attributedText else { return }
                    
                    let newAttributedString = NSMutableAttributedString(attributedString: actualHtmlAttributedString)
                    newAttributedString.append(htmlAttributedString)
                    self?.textView.attributedText = newAttributedString
                    
                    self?.textView.scrollRangeToVisible(NSMakeRange(newAttributedString.length, 0)) // scroll to bottom
                }
            }
            try! self?.snips?.start()
            
            DispatchQueue.main.async {
                self?.recordButton.change(state: .recording)
                self?.startButton.isEnabled = true
            }
        }
    }
}

// MARK: - Microphone management

private extension SnipsMainViewController {
    func requestRecordPermission() throws  {
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.requestRecordPermission { _ in
            // The callback may not be called on the main thread. Add an
            // operation to the main queue to update the record button"s state.
            let recordPermission = audioSession.recordPermission()
            OperationQueue.main.addOperation {
                switch recordPermission {
                case .undetermined:
                    self.startButton.isEnabled = false
                    self.recordButton.isEnabled = false
                    self.recordButton.change(state: .disabled)
                    self.recordButton.setTitle("Record not yet authorized", for: .disabled)
                    
                case .denied:
                    self.startButton.isEnabled = false
                    self.recordButton.isEnabled = false
                    self.recordButton.change(state: .disabled)
                    self.recordButton.setTitle("User denied access to recording", for: .disabled)
                    
                case .granted:
                    self.recordButton.isEnabled = true
                    self.recordButton.change(state: .stalled)
                }
            }
        }
    }
    
    func startRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .mixWithOthers)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setPreferredSampleRate(16_000)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                            sampleRate: 16_000,
                                            channels: 1,
                                            interleaved: true)
        
        let downMixer = AVAudioMixerNode()
        audioEngine.attach(downMixer)
        audioEngine.connect(inputNode, to: downMixer, format: nil)
        
        downMixer.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, when) in
            self?.snips?.appendBuffer(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
}

private extension String {
    var htmlAttributedString: NSAttributedString? {
        guard let data = self.data(using: .utf16) else { return nil }
        guard let html = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil) else { return nil }
        return html
    }
}

extension Dictionary where Value: Equatable {
    /// Returns all keys mapped to the specified value.
    /// ```
    /// let dict = ["A": 1, "B": 2, "C": 3]
    /// let keys = dict.keysForValue(2)
    /// assert(keys == ["B"])
    /// assert(dict["B"] == 2)
    /// ```
    func keysForValue(value: Value) -> [Key] {
        return compactMap { (key: Key, val: Value) -> Key? in
            value == val ? key : nil
        }
    }
}

extension SnipsMainViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        try! snips?.notifySpeechEnded(messageId: currentSayMessage?.messageId, sessionId: currentSayMessage?.sessionId)
        currentSayMessage = nil
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension UIView {
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

