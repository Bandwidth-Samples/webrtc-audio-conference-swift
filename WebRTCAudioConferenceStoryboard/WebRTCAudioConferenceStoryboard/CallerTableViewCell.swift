//
//  CallerTableViewCell.swift
//  WebRTCAudioConferenceStoryboard
//
//  Created by Michael Hamer on 1/28/21.
//

import UIKit

class CallerTableViewCell: UITableViewCell {
    @IBOutlet weak var participantIdLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
