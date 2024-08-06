//
//  AddFoodViewController.swift
//  FoodDonation
//
//  Created by Sunil Balami on 2024-08-06.
//
import UIKit

class AddFoodViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var foodItemTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var availableTillDatePicker: UIDatePicker!
    @IBOutlet weak var notesTextField: UITextField!
    @IBOutlet weak var selectedImageView: UIImageView!
    
    var selectedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func selectImageTapped(_ sender: UIButton) {
        openPhotoLibrary()
    }
    
    func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .photoLibrary
            present(imagePickerController, animated: true, completion: nil)
        } else {
            showAlert(title: "Photo Library Unavailable", message: "The photo library is not accessible.")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            selectedImageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitTapped(_ sender: UIButton) {
        addFoodItem()
    }
    
    private func addFoodItem() {
        guard let foodItem = foodItemTextField.text, !foodItem.isEmpty,
              let description = descriptionTextField.text, !description.isEmpty,
              let quantity = quantityTextField.text, !quantity.isEmpty,
              let location = locationTextField.text, !location.isEmpty,
              let image = selectedImage else {
            showAlert(title: "Error", message: "Please fill in all fields and select an image")
            return
        }
        
        let availableTill = availableTillDatePicker.date
        let notes = notesTextField.text ?? ""
        
        uploadFoodItem(foodItem: foodItem, description: description, quantity: quantity, location: location, availableTill: availableTill, notes: notes, image: image)
    }
    
    private func uploadFoodItem(foodItem: String, description: String, quantity: String, location: String, availableTill: Date, notes: String, image: UIImage) {
        
        guard let url = URL(string: "\(baseURL)food/add-food") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Retrieve token from Keychain
        if let tokenData = KeychainHelper.load(key: "userToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            showAlert(title: "Error", message: "Authorization token not found")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let availableTillString = dateFormatter.string(from: availableTill)
        
        let parameters: [String: Any] = [
            "foodItem": foodItem,
            "description": description,
            "quantity": quantity,
            "location": location,
            "availableTill": availableTillString,
            "notes": notes
        ]
        
        // Create HTTP body
        request.httpBody = createBody(parameters: parameters, image: image, boundary: boundary)
        
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
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let success = jsonResponse["success"] as? Bool, success {
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Success", message: "Food item added successfully")
                        }
                    } else {
                        let message = (jsonResponse["message"] as? String) ?? "Unknown error"
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Error", message: message)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Failed to parse response")
                }
            }
        }.resume()
    }
    
    private func createBody(parameters: [String: Any], image: UIImage, boundary: String) -> Data {
        var body = Data()
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
