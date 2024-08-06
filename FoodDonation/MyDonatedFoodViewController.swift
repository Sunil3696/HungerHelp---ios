//
//  MyDonatedFoodViewController.swift
//  FoodDonation
//
//  Created by Sunil Balami on 2024-08-06.
//

import UIKit

class MyDonatedFoodViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!

    var donatedFoodItems: [DonatedFoodItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        fetchDonatedFoodItems()
    }

    func fetchDonatedFoodItems() {
        guard let url = URL(string: "\(baseURL)food/mydonatedfood") else { return }
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
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "No data received from server")
                }
                return
            }

            // Print raw JSON data for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(jsonString)")
            }

            do {
                // Decode the JSON response directly into an array of DonatedFoodItem
                let decoder = JSONDecoder()
                let fetchedItems = try decoder.decode([DonatedFoodItem].self, from: data)
                DispatchQueue.main.async {
                    self?.donatedFoodItems = fetchedItems
                    self?.tableView.reloadData()
                }
            } catch {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Failed to parse response: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    // MARK: - UITableViewDataSource Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return donatedFoodItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DonatedFoodCell", for: indexPath) as? MyDonatedFoodTableViewCell else {
            return UITableViewCell()
        }

        let donatedFoodItem = donatedFoodItems[indexPath.row]
        cell.titleLabel.text = donatedFoodItem.foodItem
        cell.descriptionLabel.text = donatedFoodItem.description
        cell.statusLabel.text = donatedFoodItem.status

        // Set image if available
        if let imageUrlString = donatedFoodItem.images.first, let imageUrl = URL(string: "\(baseURL)\(imageUrlString)") {
            loadImage(from: imageUrl, into: cell.posterImageView)
        } else {
            cell.posterImageView.image = nil
        }

        return cell
    }

    // Load image from URL asynchronously
    private func loadImage(from url: URL, into imageView: UIImageView) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    imageView.image = UIImage(data: data)
                }
            } else {
                DispatchQueue.main.async {
                    imageView.image = nil
                }
            }
        }
    }

    // MARK: - UITableViewDelegate Methods

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, handler) in
            self?.deleteFoodItem(at: indexPath)
            handler(true)
        }
        deleteAction.backgroundColor = .red

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let updateStatusAction = UIContextualAction(style: .normal, title: "Update Status") { [weak self] (action, view, handler) in
            self?.showStatusAlert(for: indexPath)
            handler(true)
        }
        updateStatusAction.backgroundColor = .blue

        let configuration = UISwipeActionsConfiguration(actions: [updateStatusAction])
        return configuration
    }

    // MARK: - Update Request Status

    func showStatusAlert(for indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Update Status", message: "Choose an option", preferredStyle: .actionSheet)
        
        let approveAction = UIAlertAction(title: "Approve", style: .default) { [weak self] _ in
            self?.updateRequestStatus(at: indexPath, status: "Approved")
        }
        
        let rejectAction = UIAlertAction(title: "Reject", style: .destructive) { [weak self] _ in
            self?.updateRequestStatus(at: indexPath, status: "Rejected")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(approveAction)
        alertController.addAction(rejectAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    func updateRequestStatus(at indexPath: IndexPath, status: String) {
        let foodItem = donatedFoodItems[indexPath.row]
        guard let url = URL(string: "\(baseURL)food/update-requests/\(foodItem._id)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["requestStatus": status]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        // Retrieve token from Keychain
        if let tokenData = KeychainHelper.load(key: "userToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            showAlert(title: "Error", message: "Authorization token not found")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
                return
            }

            // Check the response status code
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self?.fetchDonatedFoodItems() // Refresh the list after updating
                }
            } else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Failed to update request status.")
                }
            }
        }.resume()
    }

    // MARK: - Delete Item

    func deleteFoodItem(at indexPath: IndexPath) {
        let foodItem = donatedFoodItems[indexPath.row]
        guard let url = URL(string: "\(baseURL)food/\(foodItem._id)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        // Retrieve token from Keychain
        if let tokenData = KeychainHelper.load(key: "userToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            showAlert(title: "Error", message: "Authorization token not found")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
                return
            }

            // Check the response status code
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self?.donatedFoodItems.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            } else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Failed to delete item.")
                }
            }
        }.resume()
    }

    // MARK: - Helper Methods

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Models

struct DonatedFoodItem: Codable {
    let user: Donor
    let _id: String
    let foodItem: String
    let description: String
    let quantity: String
    let location: String
    let availableTill: String
    let notes: String
    let images: [String]
    let status: String
    let requests: [FoodRequest]
    let createdAt: String
    let updatedAt: String
}

struct Donor: Codable {
    let fullName: String
    let phoneNumber: String
    let profile: String
}

struct FoodRequest: Codable {
    let userId: String
    let _id: String
    let requestDate: String
    let requestStatus: String?
}
