//
//  MagentoClient.swift
//  SnipsVoiceCommerceDemo
//
//  Created by Fabrice Dewasmes on 12/07/2018.
//  Copyright © 2018 Fabrice Dewasmes. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


let CLIENT_TOKEN_URI = "rest/V1/integration/customer/token"
let GET_CART_URI = "rest/default/V1/carts/mine"
let GET_CART_ITEM_URI = "rest/default/V1/carts/mine/items"
let ADD_TO_CART_URI = "rest/default/V1/carts/mine/items"
let DELETE_ITEM_URI = "rest/default/V1/carts/mine/items/%d"
let ME_URI = "rest/default/V1/customers/me"

let MAGENTO_URL = "https://smileshop.hubinnov.org/"

struct User {
    var login: String
    var password: String
}

class MagentoClient {
    let host: String
    var user: User{
        didSet{
            self.updateCredentials()
        }
    }
    var current_token: String
    let sessionManager: SessionManager
    
    private static var sharedMagentoClient: MagentoClient = {
        let magentoClient = MagentoClient(host: MAGENTO_URL)
        return magentoClient
    }()
    
    init(host:String) {
        self.host = host
        self.user = User(login:"",password:"")
        self.current_token = ""
        self.sessionManager = SessionManager()
        self.updateCredentials()
    }
    
    private func updateCredentials()->() {
            let authHandler = AuthHandler(
                baseURLString: self.host,
                username: self.user.login,
                password: self.user.password
            )
            
            sessionManager.adapter = authHandler
            sessionManager.retrier = authHandler
    }
    
    private func buildUrl(uri:String) -> (String){
        return "\(self.host)\(uri)"
    }
   
    func getCartItems(completionHandler: @escaping([Item]) -> ())  {
        var items = [Item]()
        sessionManager.request(self.buildUrl(uri:GET_CART_ITEM_URI)).validate().responseJSON{ response in
            guard response.result.isSuccess,
                let value = response.result.value else {
                    print("Error while fetching cart: \(String(describing: response.result.error))")
                    return
            }
            let json = JSON(value)
            items = json.arrayValue.map({Item.build(json: $0)})
            completionHandler(items)
            
        }
    }
    
    func getCartID(completionHandler: @escaping(Int) -> ()){
        sessionManager.request(self.buildUrl(uri:GET_CART_URI)).validate().responseJSON{ response in
            guard response.result.isSuccess,
                let value = response.result.value else {
                    print("Error while fetching cart ID: \(String(describing: response.result.error))")
                    return
            }
            let json = JSON(value)
            if let cartID = json["id"].int {
                completionHandler(cartID)
            }
        }
    }
    
    func addItems(cartID:Int, items:[Item], completionHandler: @escaping(Int) -> ()) {
        print("addItem")
        print(items)
        let cartItems = items.map{["sku":$0.sku,"qty":$0.quantity,"quote_id":cartID]}
        let group = DispatchGroup()
        var addedItemsCount : Int = 0
        for cartItem in cartItems {
            group.enter()
            print("adding \(cartItem)")
            sessionManager.request(self.buildUrl(uri:GET_CART_ITEM_URI), method: .post, parameters: ["cartItem":cartItem], encoding: JSONEncoding.default).validate().responseJSON{response in
                    switch response.result {
                    case .success:
                        print("add of \(cartItem) Successful")
                        addedItemsCount += 1
                    case .failure(let error):
                        print(error)
                    }
                    group.leave()
                }
            }
            group.notify(queue: DispatchQueue.main) {
                print("add completed, calling completion")
                completionHandler(addedItemsCount)
            }
        }
    
    func purgeCart(completionHandler: @escaping(Int) -> ()){
        getCartItems(completionHandler: {items in
            var deletedItemsCount :Int = 0
            let group = DispatchGroup()
            
            for cartItem in items {
                group.enter()
                self.sessionManager.request(self.buildUrl(uri:String(format:DELETE_ITEM_URI, cartItem.id)), method: .delete).validate().responseJSON{ response in
                    switch response.result {
                    case .success:
                        print("deletion of \(cartItem.id) Successful")
                        deletedItemsCount += 1
                    case .failure(let error):
                        print(error)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: DispatchQueue.main) {
                completionHandler(deletedItemsCount)
            }
        })
    }
    
    func getCustomerLastname(completionHandler : @escaping(String) -> ()) {
        self.sessionManager.request(self.buildUrl(uri:ME_URI), method: .get).validate().responseJSON{ response in
            guard response.result.isSuccess,
                let value = response.result.value else {
                    print("Error while fetching customer name: \(String(describing: response.result.error))")
                    return
            }
            let json = JSON(value)
            if let name :String = json["lastname"].string {
                completionHandler(name)
            }
        }
    }
}

class AuthHandler: RequestAdapter, RequestRetrier {
    private typealias RefreshCompletion = (_ succeeded: Bool, _ token: String?) -> Void
    
    private let sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        
        return SessionManager(configuration: configuration)
    }()
    
    private let lock = NSLock()
    
    private var baseURLString: String
    private var username: String
    private var password: String
    private var token: String
    
    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []
    
    // MARK: - Initialization
    
    public init(baseURLString: String, username: String, password: String) {
        self.baseURLString = baseURLString
        self.username = username
        self.password = password
        self.token=""
    }
    
    // MARK: - RequestAdapter
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        if let urlString = urlRequest.url?.absoluteString, urlString.hasPrefix(baseURLString) {
            var urlRequest = urlRequest
            urlRequest.setValue("Bearer \(token)" , forHTTPHeaderField: "Authorization")
            return urlRequest
        }
        
        return urlRequest
    }
    
    // MARK: - RequestRetrier
    
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        lock.lock() ; defer { lock.unlock() }
        
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            requestsToRetry.append(completion)
            
            if !isRefreshing {
                refreshTokens { [weak self] succeeded, token in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                    
                    if let token = token {
                        strongSelf.token = token
                    }
                    
                    strongSelf.requestsToRetry.forEach { $0(succeeded, 0.0) }
                    strongSelf.requestsToRetry.removeAll()
                }
            }
        } else {
            completion(false, 0.0)
        }
    }
    
    // MARK: - Private - Refresh Tokens
    
    private func refreshTokens(completion: @escaping RefreshCompletion) {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        let urlString = "\(baseURLString)\(CLIENT_TOKEN_URI)"
        
        let parameters: [String: Any] = [
            "username": self.username,
            "password": self.password
        ]
        
        sessionManager.request(urlString, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }
                guard response.result.isSuccess,
                    let value = response.result.value else {
                        print("Error while fetching token: \(String(describing: response.result.error))")
                        completion(false,nil)
                        return
                }
                
                let token = String(describing: value)
                print(token)
                completion(true, token)
                
                strongSelf.isRefreshing = false
        }
    }
}
