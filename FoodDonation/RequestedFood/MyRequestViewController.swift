import UIKit

class MyRequestViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var foodItems: [CustomFood] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register the custom cell NIB
        tableView.dataSource = self
        tableView.delegate = self
        
        // Fetch the requested food items
        fetchRequestedFoodItems()
    }

    func fetchRequestedFoodItems() {
        guard let url = URL(string: "\(baseURL)food/requests") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Retrieve token from Keychain
        if let tokenData = KeychainHelper.load(key: "userToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            print(token)
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
                // Decode the JSON response directly into an array of CustomFood
                let decoder = JSONDecoder()
                let fetchedItems = try decoder.decode([CustomFood].self, from: data)
                DispatchQueue.main.async {
                    self?.foodItems = fetchedItems
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
        return foodItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RequestedCell", for: indexPath) as? RequestedCell else {
            return UITableViewCell()
        }

        let foodItem = foodItems[indexPath.row]
        cell.titleLabel.text = foodItem.foodItem
        cell.decLabel.text = foodItem.description
        cell.status.text = foodItem.status

        // Set image if available
        if let imageUrlString = foodItem.images.first, let imageUrl = URL(string: "\(baseURL)\(imageUrlString)") {
            print("Loading image from URL: \(imageUrl.absoluteString)")
            
            // Load image asynchronously
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: imageUrl) {
                    print("Image data loaded successfully for URL: \(imageUrl.absoluteString)")
                    DispatchQueue.main.async {
                        if let image = UIImage(data: data) {
                            cell.posterImageView.image = image
                            cell.setNeedsLayout()  // Force the cell to layout so the image gets displayed
                        } else {
                            print("Failed to create image from data")
                            cell.posterImageView.image = nil
                        }
                    }
                } else {
                    print("Failed to load image data from URL: \(imageUrl.absoluteString)")
                    DispatchQueue.main.async {
                        cell.posterImageView.image = nil
                    }
                }
            }
        } else {
            print("No valid image URL found for item: \(foodItem.foodItem)")
            cell.posterImageView.image = nil
        }

        return cell
    }

    // MARK: - Swipe Actions

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, handler) in
            self?.deleteFoodItem(at: indexPath)
            handler(true)
        }

        deleteAction.backgroundColor = .red

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }

    // MARK: - Delete Item

    func deleteFoodItem(at indexPath: IndexPath) {
        let foodItem = foodItems[indexPath.row]
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
                    self?.foodItems.remove(at: indexPath.row)
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

// MARK: - Custom Models for MyRequestViewController

struct CustomFood: Codable {
    let user: CustomUser
    let _id: String
    let foodItem: String
    let description: String
    let quantity: String
    let location: String
    let availableTill: String
    let notes: String
    let images: [String]
    let status: String
    let requests: [CustomRequest]
    let createdAt: String
    let updatedAt: String
}

struct CustomUser: Codable {
    let fullName: String
    let phoneNumber: String
    let profile: String
}

struct CustomRequest: Codable {
    let userId: String
    let _id: String
    let requestDate: String
}
