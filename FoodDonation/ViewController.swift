import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var emailfield: UITextField!
    
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var Signinbutton: UIButton!
     
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        emailfield.layer.cornerRadius = 22
        passwordField.layer.cornerRadius = 22
        Signinbutton.layer.cornerRadius = 22
     
    }


}

