import UIKit

class CategoryCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }

    private func setupUI() {
        // Ensure the title is displayed in one line and truncates if it's too long
        titleLbl.numberOfLines = 1
        titleLbl.lineBreakMode = .byTruncatingTail

        // Adjust the imageView content mode
        imageView.contentMode = .scaleAspectFit
    }
}
