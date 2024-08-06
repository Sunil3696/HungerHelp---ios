//
//  RegisterViewController.swift
//  FoodDonation
//
//  Created by Sunil Balami on 2024-08-05.
//

import Foundation
import UIKit

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var addressTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var phoneTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
            super.viewDidLoad()
        }
    
    
    
    @IBAction func registerButtonTapped(_ sender: UIButton) {
        registerUser()
    }
    
    func registerUser() {
        guard let name = nameTextField.text, !name.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let phone = phoneTextField.text, !phone.isEmpty,
              let address = addressTextField.text, !address.isEmpty else {
            // Show alert if any field is empty
            showAlert(message: "Please fill in all fields")
            return
        }
        
        let parameters: [String: Any] = [
            "name": name,
            "email": email,
            "password": password,
            "phone": phone,
            "address": address
        ]
        
        print(parameters)
        
        let url = URL(string: "http://localhost:3000/api/users/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
            showAlert(message: "Failed to encode request")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                DispatchQueue.main.async {
                    self.showAlert(message: "Request failed")
                }
                return
            }
            
            do {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                    let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
                    print(responseJSON)
                    DispatchQueue.main.async {
                        self.showAlert(message: "Registration successful!")
                    }
                } else {
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400 {
                        let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        let errorMessage = responseJSON?["error"] as? String ?? "Unknown error"
                        DispatchQueue.main.async {
                            self.showAlert(message: "Registration failed: \(errorMessage)")
                        }
                    }
                }
            } catch let error {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    self.showAlert(message: "Failed to parse response")
                }
            }
        }
        
        task.resume()
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
    
}
