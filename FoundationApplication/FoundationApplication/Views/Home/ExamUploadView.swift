import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ExamUploadView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    @State private var selectedDocURL: URL?
    @State private var selectedDocName: String?
    @State private var showDocPicker = false
    
    @State private var selectedSpecialty: MedicalSpecialty = .primaryCare
    @State private var canContinue = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Header
                VStack(spacing: 6) {
                    Text("Upload your exam")
                        .font(.title3.bold())
                    Text("Add a photo or PDF of your exam, then pick a specialty to see recommended doctors.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 12)
                
                // Image picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Image")
                        .font(.headline)
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                                .padding(10)
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                        }
                        if selectedImage != nil {
                            Button(role: .destructive) {
                                selectedImage = nil
                                selectedPhotoItem = nil
                                updateContinueState()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding(10)
                                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    
                    if let img = selectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("No image selected")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                // PDF picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("PDF")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Button {
                            showDocPicker = true
                        } label: {
                            Label("Choose PDF", systemImage: "doc.richtext")
                                .padding(10)
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                        }
                        if selectedDocURL != nil {
                            Button(role: .destructive) {
                                selectedDocURL = nil
                                selectedDocName = nil
                                updateContinueState()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding(10)
                                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    
                    if let name = selectedDocName {
                        HStack {
                            Image(systemName: "doc.text")
                            Text(name)
                                .lineLimit(1)
                            Spacer()
                        }
                        .foregroundColor(.secondary)
                    } else {
                        Text("No PDF selected")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                // Specialty selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose specialty")
                        .font(.headline)
                    Picker("Specialty", selection: $selectedSpecialty) {
                        ForEach(MedicalSpecialty.allCases) { spec in
                            Text(spec.rawValue).tag(spec)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Continue button
                NavigationLink {
                    DoctorListView(specialty: selectedSpecialty)
                } label: {
                    Text("Show Doctors")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canContinue ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!canContinue)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Upload Exam")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: .constant(false), selection: $selectedPhotoItem) // managed by PhotosPicker button
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    selectedImage = img
                } else {
                    selectedImage = nil
                }
                updateContinueState()
            }
        }
        .sheet(isPresented: $showDocPicker) {
            DocumentPickerView(allowedContentTypes: [UTType.pdf]) { url in
                selectedDocURL = url
                selectedDocName = url?.lastPathComponent
                updateContinueState()
            }
        }
    }
    
    private func updateContinueState() {
        // Enable continue if either an image or a PDF is provided
        canContinue = (selectedImage != nil) || (selectedDocURL != nil)
    }
}

// UIKit document picker wrapped for SwiftUI
struct DocumentPickerView: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let onPick: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL?) -> Void
        init(onPick: @escaping (URL?) -> Void) { self.onPick = onPick }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls.first)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(nil)
        }
    }
}

#Preview {
    NavigationStack {
        ExamUploadView()
            .environmentObject(HomeViewModel())
    }
}
