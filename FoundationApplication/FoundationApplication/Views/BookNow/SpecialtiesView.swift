import SwiftUI

// ===================================================
// MARK: - SPECIALTIES VIEW
// ===================================================

struct SpecialtiesView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    
    private var filteredSpecialties: [MedicalSpecialty] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return MedicalSpecialty.allCases }
        
        return MedicalSpecialty.allCases.filter { specialty in
            specialty.rawValue.localizedCaseInsensitiveContains(text)
        }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                
                // MARK: - Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search specialties", text: $searchText)
                        .focused($isSearchFocused)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground), in: Capsule())
                .padding(.horizontal, 16)
                .padding(.top, 6)
                
                // MARK: - Empty State
                if filteredSpecialties.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                        Text("No specialties found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                } else {
                    
                    // MARK: - Specialties GRID
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(filteredSpecialties) { specialty in
                            NavigationLink {
                                DoctorListView(specialty: specialty)
                            } label: {
                                SpecialtyCard(specialty: specialty)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Specialties")
        .navigationBarTitleDisplayMode(.large)
    }
}

// ===================================================
// MARK: - SPECIALTY CARD COMPONENT
// ===================================================

struct SpecialtyCard: View {
    let specialty: MedicalSpecialty
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: specialty.systemImage)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(specialty.color)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Text(specialty.rawValue)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            Text(specialty.shortDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
    }
}

// ===================================================
// MARK: - PREVIEW
// ===================================================

#Preview {
    NavigationStack {
        SpecialtiesView(viewModel: HomeViewModel())
    }
}
