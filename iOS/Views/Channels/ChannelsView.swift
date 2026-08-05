import SwiftUI

public struct ChannelsView: View {
    @StateObject private var viewModel = ChannelsViewModel()

    public init() {}

    public var body: some View {
        NavigationView {
            List {
                Section(header: Text("Рекомендуемые каналы & Паблики")) {
                    ForEach(viewModel.channels) { channel in
                        HStack(spacing: 12) {
                            AvatarView(urlString: channel.avatarUrl, size: 52)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Text(channel.name)
                                        .font(.system(size: 15, weight: .bold))
                                    if channel.isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Text(channel.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                Text("\(channel.subscribersCount) подписчиков")
                                    .font(.system(size: 11))
                                    .foregroundColor(.blue)
                            }

                            Spacer()

                            Button(action: {
                                viewModel.toggleSubscribe(channel: channel)
                            }) {
                                Text(channel.isSubscribed ? "Вы подписаны" : "Подписаться")
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(channel.isSubscribed ? Color(UIColor.systemGroupedBackground) : Color.blue)
                                    .foregroundColor(channel.isSubscribed ? .primary : .white)
                                    .cornerRadius(14)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Каналы")
        }
    }
}
