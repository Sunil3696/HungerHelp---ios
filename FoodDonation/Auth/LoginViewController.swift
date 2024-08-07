import Foundation
import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    @IBOutlet weak var emailValue: UITextField!
    
    @IBOutlet weak var passwordValue: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autoLoginIfPossible()
    }

    func autoLoginIfPossible() {
        if let tokenData = KeychainHelper.load(key: "userToken"), !tokenData.isEmpty {
            // If a token exists, proceed to the main app screen without requiring login
            self.performSegue(withIdentifier: "showHome", sender: self)
        } else {
            // No token found, stay on the login screen
            print("No token found, user must log in")
        }
    }

    
    
    @IBAction func loginButtonTouched(_ sender: UIButton) {
        loginUser()
    }
    
    func loginUser() {
            guard let email = emailValue.text, !email.isEmpty,
                  let password = passwordValue.text, !password.isEmpty else {
                showAlert(message: "Please fill in all fields")
                return
            }

            let parameters: [String: Any] = [
                "email": email,
                "password": password
            ]

            let url = URL(string: "http://localhost:3000/auth/login")!
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
                    let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let token = responseJSON?["token"] as? String {
                        self.saveToKeychain(token: token, email: email)
                        DispatchQueue.main.async {
//                            self.showAlert(message: "Login successful!")
                            self.performSegue(withIdentifier: "showHome", sender: self)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.showAlert(message: "Failed to retrieve token")
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
    
    //Overding Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHome" {
            // Get the destination view controller
            let destinationVC = segue.destination as! FoodViewController
            // Pass any necessary data to the destination view controller
            destinationVC.userEmail = emailValue.text
        }
    }

    
    
    // MARK: Adding data to keychain
    func saveToKeychain(token: String, email: String) {
           if let tokenData = token.data(using: .utf8) {
               KeychainHelper.save(key: "userToken", data: tokenData)
           }
           if let emailData = email.data(using: .utf8) {
               KeychainHelper.save(key: "userEmail", data: emailData)
           }
       }
    
        // MARK: Showing alert
        func showAlert(message: String) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        
    
}
