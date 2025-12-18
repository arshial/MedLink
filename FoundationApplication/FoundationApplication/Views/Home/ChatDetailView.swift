import SwiftUI

struct ChatDetailView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    let doctor: Doctor
    
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                        }
                        if isTyping {
                            typingBubble()
                                .id("typing-indicator")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: isTyping) { _, _ in
                    scrollToBottom(proxy)
                }
            }
            
            Divider()
            
            HStack(spacing: 8) {
                TextField("Message \(doctor.name)", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                
                Button {
                    send()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.all, 10)
            .background(Color(.systemBackground))
        }
        .navigationTitle(doctor.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var messages: [ChatMessage] {
        viewModel.chatThreads.first(where: { $0.doctor.id == doctor.id })?.messages ?? []
    }
    
    private var isTyping: Bool {
        viewModel.chatThreads.first(where: { $0.doctor.id == doctor.id })?.isTyping ?? false
    }
    
    private func send() {
        let text = inputText
        inputText = ""
        viewModel.sendMessage(text, to: doctor)
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            if let last = messages.last {
                withAnimation {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            } else if isTyping {
                withAnimation {
                    proxy.scrollTo("typing-indicator", anchor: .bottom)
                }
            }
        }
    }
    
    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isUser = (msg.sender == .user)
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                Text(msg.text)
                    .foregroundColor(isUser ? .white : .primary)
                    .padding(10)
                    .background(isUser ? Color.blue : Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if !isUser { Spacer(minLength: 40) }
        }
        .padding(.vertical, 2)
    }
    
    private func typingBubble() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle().fill(Color.secondary.opacity(0.5)).frame(width: 6, height: 6)
                    Circle().fill(Color.secondary.opacity(0.5)).frame(width: 6, height: 6)
                    Circle().fill(Color.secondary.opacity(0.5)).frame(width: 6, height: 6)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Spacer(minLength: 40)
        }
        .padding(.vertical, 4)
    }
}

