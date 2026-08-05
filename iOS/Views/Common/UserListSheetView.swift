import SwiftUI

public struct UserListSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    public let title: String
    public let users: [User]

    public init(title: String, users: [User]) {
        self.title = title
        self.users = users
    }

    public var body: some View {
        NavigationView {
            List {
                if users.isEmpty {
                    Text("Список пока пуст.")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                } else {
                    ForEach(users) { user in
                        NavigationLink(destination: ProfileView(user: user)) {
                            HStack(spacing: 12) {
                                AvatarView(user: user, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.fullName)
                                        .font(.system(size: 15, weight: .bold))
                                    Text("@\(user.username)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(trailing: Button("Закрыть") { presentationMode.wrappedValue.dismiss() })
        }
    }
}
