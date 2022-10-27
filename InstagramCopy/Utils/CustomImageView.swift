//
//  CustomImageView.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/07/08.
//

import UIKit

var imageCache = [String: UIImage]()

class CustomImageView: UIImageView {
    
    var lastImageUrlUsedToLoadImage: String?
    
    func loadImage(with urlString: String) {
        
        self.image = nil
        
        lastImageUrlUsedToLoadImage = urlString
        
        if let cachedImage = imageCache[urlString] {
            self.image = cachedImage
            return
        }
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { (data, respone, error) in
            
            if let error = error {
                print("failed load image", error.localizedDescription)
            }
            
            if self.lastImageUrlUsedToLoadImage != url.absoluteString {
                return
            }
            
            guard let imageData = data else { return }
            
            let photoImage = UIImage(data: imageData)
            imageCache[url.absoluteString] = photoImage
            
            DispatchQueue.main.async {
                self.image = photoImage
            }
        }.resume()
    }
}
