import UIKit

class ApprovedRequestsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var approvedRequests: [ApprovedRequest] = []
    let refreshControl = UIRefreshControl() // Add a refresh control

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self

        // Setup the refresh control
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        fetchApprovedRequests()
    }

    @objc func refreshData() {
        fetchApprovedRequests() // Fetch data again
    }

    func fetchApprovedRequests() {
        guard let url = URL(string: "\(baseURL)food/approved-requests") else { return }
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
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing() // End refreshing
            }

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
                // Decode the JSON response directly into an array of ApprovedRequest
                let decoder = JSONDecoder()
                let fetchedItems = try decoder.decode([ApprovedRequest].self, from: data)
                DispatchQueue.main.async {
                    self?.approvedRequests = fetchedItems
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
        return approvedRequests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ApprovedRequestCell", for: indexPath) as? ApprovedRequestTableViewCell else {
            return UITableViewCell()
        }

        let approvedRequest = approvedRequests[indexPath.row]
        cell.foodItemLabel.text = approvedRequest.foodItem
        cell.locationLabel.text = approvedRequest.location

        // Set image if available
        if let imageUrlString = approvedRequest.images.first, let imageUrl = URL(string: "\(baseURL)\(imageUrlString)") {
            loadImage(from: imageUrl, into: cell.foodImageView)
        } else {
            cell.foodImageView.image = nil
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

    // MARK: - Helper Methods

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Models

struct ApprovedRequest: Codable {
    let user: ApprovingUser
    let _id: String
    let foodItem: String
    let description: String
    let quantity: String
    let location: String
    let availableTill: String
    let notes: String
    let images: [String]
    let status: String
    let requests: [ApprovedRequestDetail]
    let createdAt: String
    let updatedAt: String
}

struct ApprovingUser: Codable {
    let fullName: String
    let phoneNumber: String
    let profile: String
}

struct ApprovedRequestDetail: Codable {
    let userId: String
    let requestStatus: String?
    let _id: String
    let requestDate: String
}
