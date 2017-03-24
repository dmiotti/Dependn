//
//  NewDateTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

private var kNewDateTableViewCellHourDateFormatter: DateFormatter!
private var kNewDateTableViewCellDayDateFormatter: DateFormatter!

protocol NewDateTableViewCellDelegate {
    func dateTableViewCell(_ cell: NewDateTableViewCell, didSelectDate date: Date)
}

final class NewDateTableViewCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "NewDateTableViewCell"

    static var hourDateFormatter: DateFormatter {
        if kNewDateTableViewCellHourDateFormatter == nil {
            kNewDateTableViewCellHourDateFormatter = DateFormatter(dateFormat: "HH:mm")
            kNewDateTableViewCellHourDateFormatter.timeStyle = .short
        }
        return kNewDateTableViewCellHourDateFormatter
    }

    static var dayDateFormatter: DateFormatter {
        if kNewDateTableViewCellDayDateFormatter == nil {
            kNewDateTableViewCellDayDateFormatter = DateFormatter(dateFormat: "EE d, yyyy")
        }
        return kNewDateTableViewCellDayDateFormatter
    }
    
    var delegate: NewDateTableViewCellDelegate?
    
    var date: Date? {
        didSet {
            if let date = date {
                let day: String
                let proximity = SHDateProximityToDate(date)
                switch proximity {
                case .today:
                    day = L("history.today")
                    break
                case .yesterday:
                    day = L("history.yesterday")
                    break
                default:
                    day = NewDateTableViewCell.dayDateFormatter.string(from: date).capitalized
                }
                let hour = NewDateTableViewCell.hourDateFormatter.string(from: date).capitalized
                chosenDateLbl.text = "\(day) | \(hour)"
                datePicker.date = date
            } else {
                chosenDateLbl.text = nil
                datePicker.date = Date()
            }
        }
    }
    
    fileprivate var chosenDateLbl: UILabel!
    
    fileprivate var dateLbl: UILabel!
    fileprivate var calImgView: UIImageView!
    
    fileprivate var hiddenDateTextField: UITextField!
    fileprivate var datePicker: UIDatePicker!
    fileprivate var toolbar: UIToolbar!

    override func commonInit() {
        super.commonInit()
        
        separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
        
        accessoryType = .disclosureIndicator
        
        calImgView = UIImageView(image: UIImage(named: "cal_icon"))
        calImgView.contentMode = .center
        contentView.addSubview(calImgView)
        
        dateLbl = UILabel()
        dateLbl.text = L("new_record.date")
        dateLbl.textColor = "A2B8CC".UIColor
        dateLbl.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        contentView.addSubview(dateLbl)
        
        chosenDateLbl = UILabel()
        chosenDateLbl.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        chosenDateLbl.textColor = UIColor.appBlackColor()
        chosenDateLbl.textAlignment = .right
        chosenDateLbl.adjustsFontSizeToFitWidth = true
        contentView.addSubview(chosenDateLbl)
        
        /// Build focused TextField
        hiddenDateTextField = UITextField()
        hiddenDateTextField.isHidden = true
        
        datePicker = UIDatePicker()
        datePicker.backgroundColor = UIColor.lightBackgroundColor()
        datePicker.datePickerMode = .dateAndTime
        hiddenDateTextField.inputView = datePicker
        contentView.addSubview(hiddenDateTextField)
        
        toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: 44))
        toolbar.isTranslucent = false
        let dateDoneItem = UIBarButtonItem(title: L("new_record.select_date"), style: .done, target: self, action: #selector(NewDateTableViewCell.datePickerDidSelectDate(_:)))
        dateDoneItem.setTitleTextAttributes(StyleSheet.doneBtnAttrs, for: .normal)
        let dateSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelItem = UIBarButtonItem(title: L("new_record.cancel"), style: .plain, target: self, action: #selector(NewDateTableViewCell.datePickerDidCancel(_:)))
        cancelItem.setTitleTextAttributes(StyleSheet.cancelBtnAttrs, for: .normal)
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [ cancelItem, flexSpace, dateSpaceItem, dateDoneItem ]
        hiddenDateTextField.inputAccessoryView = toolbar
        
        configureLayoutConstraints()
        
        layoutIfNeeded()
    }
    
    fileprivate func configureLayoutConstraints() {
        calImgView.snp.makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.left.equalTo(contentView).offset(20)
            $0.width.height.equalTo(30)
        }
        dateLbl.snp.makeConstraints {
            $0.left.equalTo(calImgView.snp.right).offset(14)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
        }
        chosenDateLbl.snp.makeConstraints {
            $0.centerY.equalTo(dateLbl)
            $0.right.equalTo(contentView)
            $0.left.equalTo(dateLbl.snp.right).offset(10)
        }
        hiddenDateTextField.snp.makeConstraints {
            $0.top.equalTo(contentView)
            $0.left.equalTo(contentView)
            $0.width.height.equalTo(1)
        }
    }
    
    func datePickerDidSelectDate(_ sender: UIBarButtonItem) {
        hiddenDateTextField.resignFirstResponder()
        delegate?.dateTableViewCell(self, didSelectDate: datePicker.date)
    }
    
    func datePickerDidCancel(_ sender: UIBarButtonItem) {
        hiddenDateTextField.resignFirstResponder()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            hiddenDateTextField.becomeFirstResponder()
        }
    }

}
