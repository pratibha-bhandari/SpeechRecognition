//
//  FormFieldTableViewCell.swift
//  SpeechRecognition
//
//  Created by Admin on 14/06/18.
//  Copyright © 2018 DB. All rights reserved.
//

import UIKit

class FormFieldTableViewCell: UITableViewCell {
    @IBOutlet weak var quesLabel: UILabel!
    @IBOutlet weak var answerTxtFld: UITextField!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
