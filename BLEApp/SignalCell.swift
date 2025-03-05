//
//  SignalCell.swift
//  BLEApp
//
//  Created by Allegro on 3/3/25.
//

import UIKit

class SignalCell: UITableViewCell {
    
    // MARK: - UI Elements
    let commandIDLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let functionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.textColor = .white
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor(white: 0.1, alpha: 1)
        layer.cornerRadius = 10
        clipsToBounds = true
        
        // Add subviews
        contentView.addSubview(commandIDLabel)
        contentView.addSubview(functionLabel)
        contentView.addSubview(descriptionTextView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Command ID Label
            commandIDLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            commandIDLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            commandIDLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -15),
            
            // Function Label
            functionLabel.topAnchor.constraint(equalTo: commandIDLabel.bottomAnchor, constant: 5),
            functionLabel.leadingAnchor.constraint(equalTo: commandIDLabel.leadingAnchor),
            functionLabel.trailingAnchor.constraint(equalTo: commandIDLabel.trailingAnchor),
            
            // Description TextView
            descriptionTextView.topAnchor.constraint(equalTo: functionLabel.bottomAnchor, constant: 5),
            descriptionTextView.leadingAnchor.constraint(equalTo: commandIDLabel.leadingAnchor),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            descriptionTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configure Cell Data
    func configure(with command: [String: String]) {
        commandIDLabel.text = command["Command ID"]
        functionLabel.text = command["Function"]
        descriptionTextView.text = command["Description"]
    }
}

