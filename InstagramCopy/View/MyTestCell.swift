//
//  MyTestCell.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/07/16.
//

import UIKit

class MyTestCell: UICollectionViewCell {
    
    static let identifier = "HomeYourRecommandViewCell"

    private let menuImageViewSize: CGFloat = 100

    private let menuImageView: UIImageView = {
        var imageView = UIImageView()
        imageView.backgroundColor = .cyan
        imageView.layer.cornerRadius = 50
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
        setConstraint()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUI()
        setConstraint()
    }

    private func setUI() {
        self.addSubview(menuImageView)
    }

    private func setConstraint() {
        configureMenuImageViewConstraint()
    }

    private func configureMenuImageViewConstraint() {
        menuImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            menuImageView.topAnchor.constraint(equalTo: self.topAnchor),
            menuImageView.widthAnchor.constraint(equalToConstant: menuImageViewSize),
            menuImageView.heightAnchor.constraint(equalToConstant: menuImageViewSize),
            menuImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }
}
