//
//  ProfileViewController.swift
//  FoodDonation
//
//  Created by Sunil Balami on 2024-08-06.
//

import UIKit

// Model representing the user's profile data
struct UserProfile: Codable {
    let id: String
    let fullName: String
    let email: String
    let profile: String?
    let phoneNumber: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fullName
        case email
        case profile
        case phoneNumber
    }
}

class ProfileViewController: UIViewController {

    // Outlets for UI elements
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchProfileData()
    }
    
    // Fetch the user's profile data from the server
    private func fetchProfileData() {
        guard let url = URL(string: "\(baseURL)food/myaccount") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Retrieve token from Keychain
        if let tokenData = KeychainHelper.load(key: "userToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            showAlert(title: "Error", message: "Authorization token not found")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Network error: \(error?.localizedDescription ?? "Unknown error")")
                }
                return
            }
            
            do {
                let userProfile = try JSONDecoder().decode(UserProfile.self, from: data)
                DispatchQueue.main.async {
                    self?.updateUI(with: userProfile)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Failed to parse user data")
                }
            }
        }.resume()
    }
    
    // Update the UI with the user's profile data
    private func updateUI(with userProfile: UserProfile) {
        fullNameLabel.text = userProfile.fullName
        emailLabel.text = userProfile.email
        phoneNumberLabel.text = userProfile.phoneNumber
        
        if let profilePath = userProfile.profile, !profilePath.isEmpty {
            loadImage(from: profilePath, into: profileImageView)
        } else {
            // Set a default image if profile image is not available
            profileImageView.image = UIImage(named: "2")
        }
    }
    
    // Load an image from a given URL path
    private func loadImage(from relativePath: String, into imageView: UIImageView) {
        guard let url = URL(string: baseURL + relativePath) else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    // Show an alert with the specified title and message
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    // IBAction for logout button
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        // Display an alert to confirm logout
        let alertController = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        
        // OK action to confirm logout
        let okAction = UIAlertAction(title: "OK", style: .destructive) { [weak self] _ in
            self?.performLogout()
        }
        
        // Cancel action to dismiss the alert
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Perform the logout process
    private func performLogout() {
        // Clear the token from Keychain
        KeychainHelper.delete(key: "userToken")
        
        // Navigate back to the login screen
        if let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
            loginVC.modalPresentationStyle = .fullScreen
            present(loginVC, animated: true, completion: nil)
        }
    }
}
