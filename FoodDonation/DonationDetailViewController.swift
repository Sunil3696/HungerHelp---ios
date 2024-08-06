//
//  DonationDetailViewController.swift
//  FoodDonation
//
//  Created by Sunil Balami on 2024-08-05.
//

import Foundation
import UIKit
import MapKit

class DonationDetailViewController: UIViewController {
    var donationId: String?
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var foodItemLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var availableTillLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let id = donationId {
            fetchDonationDetail(for: id)
        } else {
            print("No donation ID available")
        }
    }
    
    private func fetchDonationDetail(for id: String) {
        guard let url = URL(string: "\(baseURL)food/\(id)") else { return }
        
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
                DispatchQueue.main.async {
                    self?.showAlert(title: "Network Error", message: "Failed to load donation details.")
                }
                return
            }
            
            do {
                let donation = try JSONDecoder().decode(Donation.self, from: data)
                DispatchQueue.main.async {
                    self?.updateUI(with: donation)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Decoding Error", message: "Failed to decode donation details.")
                }
            }
        }.resume()
    }
    
    private func updateUI(with donation: Donation) {
        foodItemLabel.text = donation.foodItem
        descriptionLabel.text = donation.description
        quantityLabel.text = donation.quantity
        locationLabel.text = donation.location
        availableTillLabel.text = donation.availableTill
        
        
        // Load the first image if available
        if let imageUrl = donation.images.first {
            loadImage(from: imageUrl, into: imageView)
        } else {
            imageView.image = UIImage(named: "placeholder") // Optionally set a placeholder image
        }
        
        // Geocode the location and update the map
        geocodeAddress(donation.location)
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
    
    private func geocodeAddress(_ address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Geocoding Error", message: "Failed to find location.")
                }
                return
            }
            DispatchQueue.main.async {
                self?.updateMapView(with: location.coordinate)
            }
        }
    }
    
    private func updateMapView(with coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Donation Location"
        
        mapView.addAnnotation(annotation)
        
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }
    
    
    
    
    @IBAction func buttonTouched(_ sender: UIButton) {
        guard let donationId = donationId else {
            showAlert(title: "Error", message: "Donation ID is missing.")
            return
        }
        
        sendRequestForDonation(withId: donationId)
    }
    
    private func sendRequestForDonation(withId id: String) {
        guard let url = URL(string: "\(baseURL)food/request/\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Retrieve token from Keychain
        if let tokenData = KeychainHelper.load(key: "userToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            showAlert(title: "Error", message: "Token not found.")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Request Failed", message: error.localizedDescription)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Request Failed", message: "No data received from server.")
                }
                return
            }
            
            // Print the raw JSON for debugging
            if let rawJSON = String(data: data, encoding: .utf8) {
                print("Raw JSON: \(rawJSON)")
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let success = jsonResponse["success"] as? Bool, success {
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Request Successful", message: "Your request has been submitted.")
                        }
                    } else {
                        let message = (jsonResponse["message"] as? String) ?? "Unknown error"
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Request Failed", message: message)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Request Failed", message: "Could not process server response.")
                }
            }
        }.resume()
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}
