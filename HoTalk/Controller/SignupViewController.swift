//
//  SignupViewController.swift
//  HowlTalk
//
//  Created by 김호중 on 2019/05/09.
//  Copyright © 2019 hojung. All rights reserved.
//

import UIKit
import Firebase

class SignupViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    let remoteconfig = RemoteConfig.remoteConfig()
    var color: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statusBar = UIView()
        
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { (m) in
            m.right.top.left.equalTo(self.view)
            m.height.equalTo(self.view.safeAreaInsets.top)
        }
        
        color = remoteconfig["splash_background"].stringValue
        statusBar.backgroundColor = UIColor(hex: color!)
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imagePicker)))
        
        signupButton.backgroundColor = UIColor(hex: color!)
        cancelButton.backgroundColor = UIColor(hex: color!)

        signupButton.addTarget(self, action: #selector(signupEvent), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelEvent), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    @objc func imagePicker() {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.modalPresentationStyle = .fullScreen
        
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.imageView.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelEvent() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func signupEvent() {
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (authResult, error) in
            guard let uid = authResult?.user.uid, error == nil else {
                
                return
            }
            let image = self.imageView.image
            let imageCopressed =  image?.jpegData(compressionQuality: 0.1)
            let storageRef = Storage.storage().reference().child("userImages").child(uid)
            
            storageRef.putData(imageCopressed!, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print("Occur the error : \(error!))")
                    return
                }
                
                storageRef.downloadURL(completion: { (url, error) in
                    
                    let values = ["name" : self.nameTextField.text, "profileImageurl" : url?.absoluteString, "uid" : Auth.auth().currentUser?.uid]
                    
                    Database.database().reference().child("users").child(uid).setValue(values, withCompletionBlock: { (error, reference) in
                        if (error == nil) {
                            self.cancelEvent()
                        }
                    })
                    
                })
            })
            
            
            
            
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
