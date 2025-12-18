import SwiftUI

private enum SearchScope: String, CaseIterable, Identifiable {
    case all = "All"
    case doctors = "Doctors"
    case specialties = "Specialties"

    var id: String { rawValue }
}

struct SearchView: View {
    @EnvironmentObject var viewModel: HomeViewModel

    @State private var searchText: String = ""
    @FocusState private var searchFocused: Bool
    @Environment(\.isSearching) private var isSearching

    @State private var scope: SearchScope = .all

    @State private var recentSearches: [String] = []
    private let recentsKey = "search_recents_v1"

    private var allDoctors: [DoctorProfile] {
        MedicalSpecialty.allCases.flatMap { doctorProfiles(for: $0) }
    }

    private var suggestedDoctors: [DoctorProfile] {
        allDoctors.sorted(by: { $0.rating > $1.rating }).prefix(6).map { $0 }
    }

    private var filteredDoctors: [DoctorProfile] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        let matchesName = allDoctors.filter { $0.name.localizedCaseInsensitiveContains(q) }
        let matchesSpecialty = allDoctors.filter { $0.specialty.rawValue.localizedCaseInsensitiveContains(q) }
        switch scope {
        case .all:
            var seen = Set<UUID>()
            return (matchesName + matchesSpecialty).filter { seen.insert($0.id).inserted }
        case .doctors:
            return matchesName
        case .specialties:
            return []
        }
    }

    private var filteredSpecialties: [MedicalSpecialty] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return MedicalSpecialty.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        List {
            if searchText.isEmpty {
                discoverySections
            } else {
                resultsSections
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Doctors, specialties")
        .searchFocused($searchFocused)
        .searchScopes($scope) {
            ForEach(SearchScope.allCases) { s in
                Text(s.rawValue).tag(s)
            }
        }
        .searchSuggestions { suggestionsContent }
        .onAppear {
            loadRecents()
            DispatchQueue.main.async { searchFocused = true }
        }
        .onSubmit(of: .search) { addRecent(searchText) }
        .onChange(of: isSearching) { _, nowSearching in
            if !nowSearching { searchFocused = false }
        }
    }

    private var discoverySections: some View {
        Group {
            Section("Top Categories") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                    ForEach(MedicalSpecialty.allCases) { spec in
                        NavigationLink {
                            DoctorListView(specialty: spec)
                        } label: {
                            specialtyCard(spec)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 4)
            }

            Section("Suggested Doctors") {
                ForEach(suggestedDoctors) { doctor in
                    NavigationLink {
                        DoctorProfileBookingView(doctor: doctor)
                            .environmentObject(viewModel)
                    } label: {
                        suggestedDoctorRow(doctor)
                    }
                }
            }

            if !recentSearches.isEmpty {
                Section {
                    HStack {
                        Text("Recent")
                        Spacer()
                        Button("Clear All") {
                            recentSearches = []
                            saveRecents()
                        }
                        .font(.footnote)
                    }
                    .foregroundStyle(.secondary)

                    wrapChips(recentSearches) { q in
                        searchText = q
                        searchFocused = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var resultsSections: some View {
        if scope == .specialties {
            Section("Specialties") {
                if filteredSpecialties.isEmpty {
                    noResultsRow
                } else {
                    ForEach(filteredSpecialties) { spec in
                        NavigationLink {
                            DoctorListView(specialty: spec)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: spec.systemImage)
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(width: 22, height: 22)
                                    .background(spec.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Text(spec.rawValue)
                            }
                        }
                    }
                }
            }
        } else {
            Section("Doctors") {
                if filteredDoctors.isEmpty {
                    noResultsRow
                } else {
                    ForEach(filteredDoctors) { doctor in
                        NavigationLink {
                            DoctorProfileBookingView(doctor: doctor)
                                .environmentObject(viewModel)
                        } label: {
                            doctorRow(doctor)
                        }
                    }
                }
            }

            if scope == .all {
                Section("Specialties") {
                    if filteredSpecialties.isEmpty {
                        EmptyView()
                    } else {
                        ForEach(filteredSpecialties) { spec in
                            NavigationLink {
                                DoctorListView(specialty: spec)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: spec.systemImage)
                                        .foregroundColor(.white)
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(width: 22, height: 22)
                                        .background(spec.color)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    Text(spec.rawValue)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var suggestionsContent: some View {
        if searchText.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if !recentSearches.isEmpty {
                    Text("Recent").font(.caption).foregroundStyle(.secondary)
                    ForEach(recentSearches.prefix(6), id: \.self) { q in
                        Button {
                            searchText = q
                            searchFocused = true
                        } label: {
                            Label(q, systemImage: "clock")
                        }
                    }
                }

                Divider().padding(.vertical, 4)

                Text("Specialties").font(.caption).foregroundStyle(.secondary)
                ForEach(MedicalSpecialty.allCases.prefix(6)) { spec in
                    Button {
                        searchText = spec.rawValue
                        searchFocused = true
                    } label: {
                        Label(spec.rawValue, systemImage: spec.systemImage)
                    }
                }
            }
        } else {
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let docNames = allDoctors.map { $0.name }.filter { $0.localizedCaseInsensitiveContains(q) }.prefix(5)
            let specNames = MedicalSpecialty.allCases.map { $0.rawValue }.filter { $0.localizedCaseInsensitiveContains(q) }.prefix(5)

            ForEach(specNames, id: \.self) { name in
                Button { searchText = name } label: {
                    Label(name, systemImage: "square.grid.2x2")
                }
            }
            ForEach(docNames, id: \.self) { name in
                Button { searchText = name } label: {
                    Label(name, systemImage: "person.fill.viewfinder")
                }
            }
        }
    }

    private func specialtyCard(_ spec: MedicalSpecialty) -> some View {
        VStack(spacing: 10) {
            Image(systemName: spec.systemImage)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(spec.color)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(spec.rawValue)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }

    private func doctorRow(_ doctor: DoctorProfile) -> some View {
        HStack(spacing: 12) {
            Image(doctor.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(doctor.name).font(.body)
                HStack(spacing: 8) {
                    Image(systemName: doctor.specialty.systemImage)
                        .foregroundColor(.white)
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 20, height: 20)
                        .background(doctor.specialty.color)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    Text(doctor.specialty.rawValue)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption2)
                    Text(String(format: "%.1f", doctor.rating)).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Missing helpers implemented

    private func loadRecents() {
        if let saved = UserDefaults.standard.array(forKey: recentsKey) as? [String] {
            recentSearches = saved
        } else {
            recentSearches = []
        }
    }

    private func saveRecents() {
        UserDefaults.standard.set(recentSearches, forKey: recentsKey)
    }

    private func addRecent(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        // Deduplicate (case-insensitive), keep most recent first, cap to 20
        var new: [String] = [q]
        for item in recentSearches where !item.caseInsensitiveCompare(q).isSame {
            new.append(item)
        }
        if new.count > 20 { new = Array(new.prefix(20)) }
        recentSearches = new
        saveRecents()
    }

    private func wrapChips(_ items: [String], action: @escaping (String) -> Void) -> some View {
        FlowLayout(items: items) { item in
            Button {
                action(item)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                    Text(item)
                        .font(.subheadline.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var noResultsRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .foregroundColor(.secondary)
            Text("No results")
                .foregroundColor(.secondary)
        }
    }

    private func suggestedDoctorRow(_ doctor: DoctorProfile) -> some View {
        HStack(spacing: 12) {
            Image(doctor.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(doctor.name)
                    .font(.body.weight(.semibold))
                HStack(spacing: 8) {
                    Image(systemName: doctor.specialty.systemImage)
                        .foregroundColor(.white)
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 20, height: 20)
                        .background(doctor.specialty.color)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    Text(doctor.specialty.rawValue)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    Text(String(format: "%.1f", doctor.rating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

private extension ComparisonResult {
    var isSame: Bool { self == .orderedSame }
}

private struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
                    .alignmentGuide(.leading) { d in
                        if width + d.width > g.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        width += d.width
                        return result
                    }
                    .alignmentGuide(.top) { _ in height }
            }
        }
        .background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async { self.totalHeight = geo.size.height }
                return .clear
            }
        )
    }
}

#Preview {
    NavigationStack {
        SearchView()
            .environmentObject(HomeViewModel())
    }
}
