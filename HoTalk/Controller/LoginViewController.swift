//
//  LoginViewController.swift
//  HowlTalk
//
//  Created by 김호중 on 2019/05/07.
//  Copyright © 2019 hojung. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signup: UIButton!
    @IBOutlet weak var emailLoginTextView: UITextField!
    @IBOutlet weak var passwordLoginTextField: UITextView!
    
    let remoteconfig = RemoteConfig.remoteConfig()
    var color : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try Auth.auth().signOut()
        } catch {
            print("can't be to signOut")
        }
//        let statusBar = UIView()
//
//        self.view.addSubview(statusBar)
//        statusBar.snp.makeConstraints { (m) in
//            m.right.top.left.equalTo(self.view)
//        }
        print("view's safeAreaInsetTop is \(self.view.safeAreaInsets.top)")
        
        color = remoteconfig["splash_background"].stringValue
        
//        statusBar.backgroundColor = UIColor(hex: color)
        loginButton.backgroundColor = UIColor(hex: color)
        loginButton.layer.cornerRadius = loginButton.frame.width * 0.05
        signup.backgroundColor = UIColor(hex: color)
        signup.layer.cornerRadius = signup.frame.width * 0.05
        loginButton.addTarget(self, action: #selector(loginEvent), for: UIControl.Event.touchUpInside)
        
        signup.addTarget(self, action: #selector(presentSignup), for: .touchUpInside)
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                let mainView = self.storyboard?.instantiateViewController(withIdentifier: "MainViewTabBarController") as! UITabBarController
                mainView.modalPresentationStyle = .fullScreen
                self.present(mainView, animated: true, completion: nil)
            }
        }
        // Do any additional setup after loading the view.
    }
    
    @objc func presentSignup() {
        let view = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        view.modalPresentationStyle = .fullScreen
        self.present(view, animated: true, completion: nil)
    }
    
    @objc func loginEvent() {
        Auth.auth().signIn(withEmail: emailLoginTextView.text!, password: passwordLoginTextField.text!) { (user, error) in
            if error != nil {
                print(error!._code)
                self.handleError(error!)      // use the handleError method
                return
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AuthErrorCode {
    var errorMessage: String {
        switch self {
        case .emailAlreadyInUse:
            return "The email is already in use with another account"
        case .userNotFound:
            return "Account not found for the specified user. Please check and try again"
        case .userDisabled:
            return "Your account has been disabled. Please contact support."
        case .invalidEmail, .invalidSender, .invalidRecipientEmail:
            return "Please enter a valid email"
        case .networkError:
            return "Network error. Please try again."
        case .weakPassword:
            return "Your password is too weak. The password must be 6 characters long or more."
        case .wrongPassword:
            return "Your password is incorrect. Please try again or use 'Forgot password' to reset your password"
        default:
            return "Unknown error occurred"
        }
    }
}


extension LoginViewController {
    func handleError(_ error: Error) {
        if let errorCode = AuthErrorCode(rawValue: error._code) {
            print(errorCode.errorMessage)
            let alert = UIAlertController(title: "Error", message: errorCode.errorMessage, preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
}
