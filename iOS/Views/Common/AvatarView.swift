import SwiftUI

public struct AvatarView: View {
    public let urlString: String?
    public let size: CGFloat
    public let isOnline: Bool
    
    public init(urlString: String?, size: CGFloat = 44, isOnline: Bool = false) {
        self.urlString = urlString
        self.size = size
        self.isOnline = isOnline
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let urlString = urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.gray.opacity(0.4))
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: size, height: size)
                    .foregroundColor(.blue.opacity(0.6))
                    .clipShape(Circle())
            }
            
            if isOnline {
                Circle()
                    .fill(Color.green)
                    .frame(width: max(10, size * 0.28), height: max(10, size * 0.28))
                    .overlay(
                        Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2)
                    )
            }
        }
    }
}
