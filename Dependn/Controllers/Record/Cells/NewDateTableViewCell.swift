//
//  NewDateTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

protocol NewDateTableViewCellDelegate {
    func dateTableViewCell(cell: NewDateTableViewCell, didSelectDate date: NSDate)
}

final class NewDateTableViewCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "NewDateTableViewCell"
    
    var delegate: NewDateTableViewCellDelegate?
    
    private(set) var chosenDateLbl: UILabel!
    
    private var dateLbl: UILabel!
    private var calImgView: UIImageView!
    
    private var hiddenDateTextField: UITextField!
    private var datePicker: UIDatePicker!
    private var toolbar: UIToolbar!

    override func commonInit() {
        super.commonInit()
        
        separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
        
        accessoryType = .DisclosureIndicator
        
        calImgView = UIImageView(image: UIImage(named: "cal_icon"))
        calImgView.contentMode = .Center
        contentView.addSubview(calImgView)
        
        dateLbl = UILabel()
        dateLbl.text = L("new_record.date")
        dateLbl.textColor = "A2B8CC".UIColor
        dateLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        contentView.addSubview(dateLbl)
        
        chosenDateLbl = UILabel()
        chosenDateLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        chosenDateLbl.textColor = UIColor.appBlackColor()
        chosenDateLbl.textAlignment = .Right
        chosenDateLbl.adjustsFontSizeToFitWidth = true
        contentView.addSubview(chosenDateLbl)
        
        /// Build focused TextField
        hiddenDateTextField = UITextField()
        hiddenDateTextField.hidden = true
        
        datePicker = UIDatePicker()
        datePicker.backgroundColor = UIColor.lightBackgroundColor()
        datePicker.datePickerMode = .DateAndTime
        hiddenDateTextField.inputView = datePicker
        contentView.addSubview(hiddenDateTextField)
        
        toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: 44))
        toolbar.translucent = false
        let dateDoneItem = UIBarButtonItem(title: L("new_record.select_date"), style: .Done, target: self, action: "datePickerDidSelectDate:")
        dateDoneItem.setTitleTextAttributes(StyleSheet.doneBtnAttrs, forState: .Normal)
        let dateSpaceItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let cancelItem = UIBarButtonItem(title: L("new_record.cancel"), style: .Plain, target: self, action: "datePickerDidCancel:")
        cancelItem.setTitleTextAttributes(StyleSheet.cancelBtnAttrs, forState: .Normal)
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        toolbar.items = [ cancelItem, flexSpace, dateSpaceItem, dateDoneItem ]
        hiddenDateTextField.inputAccessoryView = toolbar
        
        configureLayoutConstraints()
        
        layoutIfNeeded()
    }
    
    private func configureLayoutConstraints() {
        calImgView.snp_makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.left.equalTo(contentView).offset(20)
            $0.width.height.equalTo(30)
        }
        dateLbl.snp_makeConstraints {
            $0.left.equalTo(calImgView.snp_right).offset(14)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
        }
        chosenDateLbl.snp_makeConstraints {
            $0.centerY.equalTo(dateLbl)
            $0.right.equalTo(contentView)
            $0.left.equalTo(dateLbl.snp_right).offset(10)
        }
        hiddenDateTextField.snp_makeConstraints {
            $0.top.equalTo(contentView)
            $0.left.equalTo(contentView)
            $0.width.height.equalTo(1)
        }
    }
    
    func datePickerDidSelectDate(sender: UIBarButtonItem) {
        hiddenDateTextField.resignFirstResponder()
        delegate?.dateTableViewCell(self, didSelectDate: datePicker.date)
    }
    
    func datePickerDidCancel(sender: UIBarButtonItem) {
        hiddenDateTextField.resignFirstResponder()
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            hiddenDateTextField.becomeFirstResponder()
        }
    }

}
