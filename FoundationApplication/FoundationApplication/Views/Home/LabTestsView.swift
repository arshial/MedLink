import SwiftUI

struct LabTest: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let price: String
    let imageName: String // use an asset like "lab1" or reuse an existing one
}

struct LabTestsView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    private let tests: [LabTest] = [
        LabTest(name: "Complete Blood Count (CBC)", description: "Measures red and white blood cells, hemoglobin, and platelets.", price: "€25", imageName: "lab1"),
        LabTest(name: "COVID-19 PCR", description: "Detects genetic material of the virus.", price: "€60", imageName: "lab1"),
        LabTest(name: "Lipid Profile", description: "Cholesterol and triglycerides panel.", price: "€35", imageName: "lab1"),
        LabTest(name: "Thyroid Panel (TSH, T3, T4)", description: "Evaluates thyroid function.", price: "€40", imageName: "lab1"),
        LabTest(name: "Urinalysis", description: "Checks urine composition and abnormalities.", price: "€20", imageName: "lab1")
    ]
    
    var body: some View {
        List(tests) { test in
            NavigationLink {
                LabTestBookingView(test: test)
            } label: {
                HStack(spacing: 12) {
                    Image(test.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(test.name)
                            .font(.body.weight(.semibold))
                        Text(test.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(test.price)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Lab Tests")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LabTestsView()
            .environmentObject(HomeViewModel())
    }
}
