import UIKit

class ChangePasswordViewController: UIViewController {

    // Outlets for text fields
    @IBOutlet weak var currentPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Action for the submit button
    @IBAction func changePasswordTapped(_ sender: UIButton) {
        guard let currentPassword = currentPasswordTextField.text,
              let newPassword = newPasswordTextField.text,
              let confirmPassword = confirmPasswordTextField.text else {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }
        
        // Validate new password and confirm password match
        if newPassword != confirmPassword {
            showAlert(title: "Error", message: "New passwords do not match.")
            return
        }
        
        // Proceed with changing the password
        changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }
    
    // Function to change the password
    private func changePassword(currentPassword: String, newPassword: String) {
        guard let url = URL(string: "http://localhost:3000/user/change-password") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Retrieve token from Keychain
        if let tokenData = KeychainHelper.load(key: "userToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            showAlert(title: "Error", message: "Authorization token not found")
            return
        }
        
        // Prepare request body
        let parameters: [String: Any] = [
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            showAlert(title: "Error", message: "Failed to encode request")
            return
        }
        
        // Make the API request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Network error: \(error?.localizedDescription ?? "Unknown error")")
                }
                return
            }
            
            // Debugging: Print raw response data
            if let rawJSON = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(rawJSON)")
            }
            
            // Check response status code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            do {
                // Decode response
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let message = jsonResponse["message"] as? String {
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Success", message: "Password has been changed. Please logout and relogin for the proper flow")
                            // Optionally navigate back to the profile or another screen
                            self?.navigationController?.popViewController(animated: true)
                        }
                    } else if let error = jsonResponse["error"] as? String {
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Error", message: error)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Error", message: "Unexpected response format")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Error", message: "Failed to parse response")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Failed to parse response: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    // Helper function to show alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}
