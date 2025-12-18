import Foundation

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let sender: Sender
    let text: String
    let date: Date
    
    enum Sender: String, Hashable {
        case user
        case doctor
    }
}

struct ChatThread: Identifiable, Hashable {
    let id = UUID()
    let doctor: Doctor
    var messages: [ChatMessage]
    var isTyping: Bool = false
}

