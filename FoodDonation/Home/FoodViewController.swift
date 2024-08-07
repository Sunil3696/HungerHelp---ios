import UIKit

let baseURL = "http://localhost:3000/"

struct Category: Codable {
    let id: String?
    let title: String
    let icon: String
}

struct User: Codable {
    let fullName: String
    let phoneNumber: String
    let profile: String?
}

struct Request: Codable {
    let userId: String
    let id: String
    let requestDate: String

    enum CodingKeys: String, CodingKey {
        case userId
        case id = "_id"
        case requestDate
    }
}

struct Donation: Codable {
    let id: String?
    let foodItem: String
    let description: String
    let quantity: String
    let location: String
    let availableTill: String
    let notes: String?
    let images: [String]
    let status: String
    let user: User
    let requests: [Request]
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case foodItem
        case description
        case quantity
        case location
        case availableTill
        case notes
        case images
        case status
        case user
        case requests
        case createdAt
        case updatedAt
    }
}

class FoodViewController: UIViewController {
    var userEmail: String?
    
    @IBOutlet weak var categoriesCollectionView: UICollectionView!
    @IBOutlet weak var recentlyAddedCollectionView: UICollectionView!
    
    var categories = [Category]()
    var donations = [Donation]()
    
    private let refreshControl = UIRefreshControl() // Add the refresh control

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViews()
        fetchCategories()
        fetchDonations()
    }

    private func setupCollectionViews() {
        let categoriesLayout = UICollectionViewFlowLayout()
            categoriesLayout.scrollDirection = .horizontal
            categoriesLayout.itemSize = CGSize(width: 100, height: 100)
            categoriesLayout.minimumLineSpacing = 10
            categoriesLayout.minimumInteritemSpacing = 10
            categoriesLayout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

            categoriesCollectionView.setCollectionViewLayout(categoriesLayout, animated: true)
            categoriesCollectionView.showsHorizontalScrollIndicator = false
            categoriesCollectionView.delegate = self
            categoriesCollectionView.dataSource = self

            let recentlyAddedLayout = UICollectionViewFlowLayout()
            recentlyAddedLayout.scrollDirection = .vertical
            recentlyAddedLayout.minimumLineSpacing = 0 // Set to 0 to remove space between rows
            recentlyAddedLayout.minimumInteritemSpacing = 0 // Set to 0 to remove space between items
            recentlyAddedLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

            recentlyAddedCollectionView.setCollectionViewLayout(recentlyAddedLayout, animated: true)
            recentlyAddedCollectionView.delegate = self
            recentlyAddedCollectionView.dataSource = self

            // Add refresh control to recently added collection view
            recentlyAddedCollectionView.refreshControl = refreshControl
            refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }

    @objc private func refreshData(_ sender: Any) {
        // Fetch new data and reload collections
        fetchCategories()
        fetchDonations()
    }

    private func fetchCategories() {
        guard let url = URL(string: "http://localhost:3000/category") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                print("Network error: \(String(describing: error))")
                return
            }
            do {
                self?.categories = try JSONDecoder().decode([Category].self, from: data)
                DispatchQueue.main.async {
                    self?.categoriesCollectionView.reloadData()
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }.resume()
    }

    private func fetchDonations() {
        guard let url = URL(string: "\(baseURL)food") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

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
                return
            }
            
            let rawJSON = String(data: data, encoding: .utf8) ?? "Invalid JSON"
            print("Raw JSON: \(rawJSON)")
            
            do {
                let donations = try JSONDecoder().decode([Donation].self, from: data)
                self?.donations = donations
                DispatchQueue.main.async {
                    self?.recentlyAddedCollectionView.reloadData()
                    self?.refreshControl.endRefreshing() // End the refresh control
                }
                print("Fetched Donations: \(self?.donations.map { $0.foodItem } ?? [])")
            } catch {
                print("Decoding error: \(error)")
                DispatchQueue.main.async {
                    self?.refreshControl.endRefreshing() // End the refresh control
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

extension FoodViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoriesCollectionView {
            return categories.count
        } else {
            return donations.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoriesCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCollectionViewCell
            let category = categories[indexPath.row]
            cell.titleLbl.text = category.title
            loadImage(from: category.icon, into: cell.imageView)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecentlyAddedCell", for: indexPath) as! RecentlyAddedCollectionViewCell
            let donation = donations[indexPath.row]
            cell.titleLbl.text = donation.foodItem
            print(donation.foodItem)
            
            if let imageUrl = donation.images.first {
                loadImage(from: imageUrl, into: cell.imageView)
            } else {
                cell.imageView.image = nil
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedDonation = donations[indexPath.row]
        print("selected donation", selectedDonation)
        performSegue(withIdentifier: "showDonationDetail", sender: selectedDonation.id)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 10
        let numberOfItemsPerRow: CGFloat
        
        if collectionView == categoriesCollectionView {
            numberOfItemsPerRow = 4
        } else {
            numberOfItemsPerRow = 2
        }
        
        let totalPadding = padding * (numberOfItemsPerRow + 1)
        let individualPadding = totalPadding / numberOfItemsPerRow
        let size = (collectionView.frame.size.width / numberOfItemsPerRow) - individualPadding
        return CGSize(width: size, height: size)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDonationDetail",
           let destinationVC = segue.destination as? DonationDetailViewController,
           let donationId = sender as? String {
            destinationVC.donationId = donationId
        }
    }
}
