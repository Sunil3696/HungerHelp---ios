import UIKit

struct DonationsResponse: Codable {
    let donations: [Donation]
}

class AllFoodViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var donations = [Donation]()
    private let refreshControl = UIRefreshControl() // Step 1: Add UIRefreshControl

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        fetchDonations()
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        // layout.minimumLineSpacing = 10
        // layout.minimumInteritemSpacing = 10
        // collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
        // collectionView.register(UINib(nibName: "AllFoodCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "RecentlyAddedCell")

        // Step 2: Initialize and configure the refresh control
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    @objc private func refreshData() {
        fetchDonations() // Fetch data again
    }

    private func fetchDonations() {
        guard let url = URL(string: "\(baseURL)food") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Retrieve token from Keychain
        if let tokenData = KeychainHelper.load(key: "userToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("Token not found")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                print("Network error: \(String(describing: error))")
                DispatchQueue.main.async {
                    self?.refreshControl.endRefreshing() // End refreshing if there's an error
                }
                return
            }

            // Print raw JSON for debugging
            if let rawJSON = String(data: data, encoding: .utf8) {
                print("Raw JSON: \(rawJSON)")
            } else {
                print("Failed to convert data to string")
            }

            do {
                // Attempt to decode the JSON response
                let response = try JSONDecoder().decode([Donation].self, from: data)
                self?.donations = response
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                    self?.refreshControl.endRefreshing() // End refreshing
                }
            } catch {
                print("Decoding error: \(error)")
                DispatchQueue.main.async {
                    self?.refreshControl.endRefreshing() // End refreshing if decoding fails
                }
            }
        }.resume()
    }

    private func loadImage(from relativePath: String, into imageView: UIImageView) {
        guard let url = URL(string: baseURL + relativePath) else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }.resume()
    }
}

extension AllFoodViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return donations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecentlyAddedCell", for: indexPath) as? AllFoodCollectionViewCell else {
            fatalError("Expected `AllFoodCollectionViewCell` type for reuseIdentifier RecentlyAddedCell. Check the configuration in storyboard.")
        }
        let donation = donations[indexPath.row]
        cell.titleLbl.text = donation.foodItem
        if let imageUrl = donation.images.first {
            loadImage(from: imageUrl, into: cell.imageView)
        } else {
            cell.imageView.image = nil
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedDonation = donations[indexPath.row]
        print("selected donation", selectedDonation)
        performSegue(withIdentifier: "showDonationDetail", sender: selectedDonation.id)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 10
        let numberOfItemsPerRow: CGFloat = 2
        let totalPadding = padding * (numberOfItemsPerRow + 1)
        let availableWidth = collectionView.frame.width - totalPadding
        let widthPerItem = availableWidth / numberOfItemsPerRow
        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDonationDetail",
           let destinationVC = segue.destination as? DonationDetailViewController,
           let donationId = sender as? String {
            destinationVC.donationId = donationId
        }
    }
}
