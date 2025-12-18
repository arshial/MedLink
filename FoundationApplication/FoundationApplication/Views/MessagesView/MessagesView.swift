import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        List {
            if viewModel.chatThreads.isEmpty {
                Section {
                    VStack(spacing: 10) {
                        Spacer(minLength: 16)
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("No messages yet")
                            .font(.headline)
                        Text("Book a doctor to start a conversation.")
                            .foregroundColor(.secondary)
                        Spacer(minLength: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                }
            } else {
                Section {
                    ForEach(viewModel.chatThreads) { thread in
                        NavigationLink {
                            ChatDetailView(doctor: thread.doctor)
                                .environmentObject(viewModel)
                        } label: {
                            threadRow(thread)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func threadRow(_ thread: ChatThread) -> some View {
        let last = thread.messages.last
        return HStack(spacing: 12) {
            Image(thread.doctor.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(thread.doctor.name)
                    .font(.body.weight(.semibold))
                if let last {
                    Text(last.text)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No messages yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
