import SwiftUI
import MapKit

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var auth: AuthViewModel

    @State private var selectedMapLocation: MedicalLocation? = nil
    @State private var isProfileSheetPresented: Bool = false
    @State private var isExamUploadPresented: Bool = false

    @State private var systemSearchText: String = ""

    var body: some View {
        if #available(iOS 18.0, *) {

            TabView(selection: $viewModel.selectedTab) {

                // HOME
                Tab(HomeTab.home.rawValue, systemImage: HomeTab.home.systemImage, value: HomeTab.home) {
                    NavigationStack {
                        ScrollView {
                            VStack(spacing: 20) {
                                header
                                // Keep everything visible
                                filterChips
                                mapCard
                                appointmentsSection
                                labTestRow
                                Spacer(minLength: 20)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        }
                        .sheet(item: $selectedMapLocation) { location in
                            LocationDetailSheet(location: location, userLocation: viewModel.userLocation)
                        }
                        .sheet(isPresented: $isProfileSheetPresented) {
                            NavigationStack {
                                ProfileSheetView()
                                    .environmentObject(viewModel)
                            }
                        }
                        .sheet(isPresented: $isExamUploadPresented) {
                            NavigationStack {
                                ExamUploadView()
                                    .environmentObject(viewModel)
                                    .navigationTitle("Upload Exam")
                                    .navigationBarTitleDisplayMode(.inline)
                            }
                            .presentationDetents([.fraction(0.55), .large])
                            .presentationDragIndicator(.visible)
                        }
                        .navigationBarHidden(true)
                        .onAppear {
                            viewModel.requestLocationPermission()
                            viewModel.performSearch()
                        }
                    }
                }

                // BOOK NOW
                Tab(HomeTab.bookNow.rawValue, systemImage: HomeTab.bookNow.systemImage, value: HomeTab.bookNow) {
                    NavigationStack {
                        SpecialtiesView(viewModel: viewModel)
                    }
                }

                // MESSAGES
                Tab(HomeTab.message.rawValue, systemImage: HomeTab.message.systemImage, value: HomeTab.message) {
                    NavigationStack {
                        MessagesView()
                            .environmentObject(viewModel)
                    }
                }

                // SEARCH (role: .search)
                Tab(value: HomeTab.search, role: .search) {
                    SystemSearchTab(searchText: $systemSearchText)
                        .environmentObject(viewModel)
                }
            }
            .onAppear {
                viewModel.reloadUserProfileFromStorage()
            }

        } else {
            SwiftUI.TabView(selection: $viewModel.selectedTab) {
                TabViewLegacyItem(.home) {
                    NavigationStack {
                        ScrollView {
                            VStack(spacing: 20) {
                                header
                                // Keep everything visible
                                filterChips
                                mapCard
                                appointmentsSection
                                labTestRow
                                Spacer(minLength: 20)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        }
                        .sheet(item: $selectedMapLocation) { location in
                            LocationDetailSheet(location: location, userLocation: viewModel.userLocation)
                        }
                        .sheet(isPresented: $isProfileSheetPresented) {
                            NavigationStack {
                                ProfileSheetView()
                                    .environmentObject(viewModel)
                            }
                        }
                        .sheet(isPresented: $isExamUploadPresented) {
                            NavigationStack {
                                ExamUploadView()
                                    .environmentObject(viewModel)
                                    .navigationTitle("Upload Exam")
                                    .navigationBarTitleDisplayMode(.inline)
                            }
                            .presentationDetents([.fraction(0.55), .large])
                            .presentationDragIndicator(.visible)
                        }
                        .navigationBarHidden(true)
                        .onAppear {
                            viewModel.requestLocationPermission()
                            viewModel.performSearch()
                        }
                    }
                }

                TabViewLegacyItem(.bookNow) {
                    NavigationStack {
                        SpecialtiesView(viewModel: viewModel)
                    }
                }

                TabViewLegacyItem(.message) {
                    NavigationStack {
                        MessagesView()
                            .environmentObject(viewModel)
                    }
                }

                TabViewLegacyItem(.search) {
                    NavigationStack {
                        SearchView()
                            .environmentObject(viewModel)
                    }
                }
            }
            .onAppear {
                viewModel.reloadUserProfileFromStorage()
            }
        }
    }

    private func TabViewLegacyItem(_ tab: HomeTab, @ViewBuilder content: () -> some View) -> some View {
        content()
            .tabItem {
                Image(systemName: viewModel.selectedTab == tab ? tab.selectedSystemImage : tab.systemImage)
                Text(tab.rawValue)
            }
            .tag(tab)
    }
}

@available(iOS 18.0, *)
private struct SystemSearchTab: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Binding var searchText: String
    @FocusState private var fieldFocused: Bool

    private var allDoctors: [DoctorProfile] {
        MedicalSpecialty.allCases.flatMap { doctorProfiles(for: $0) }
    }

    private var filteredDoctors: [DoctorProfile] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        let matchesName = allDoctors.filter { $0.name.localizedCaseInsensitiveContains(q) }
        let matchesSpecialty = allDoctors.filter { $0.specialty.rawValue.localizedCaseInsensitiveContains(q) }
        var seen = Set<UUID>()
        return (matchesName + matchesSpecialty).filter { seen.insert($0.id).inserted }
    }

    private var filteredSpecialties: [MedicalSpecialty] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return MedicalSpecialty.allCases.filter {
            $0.rawValue.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    discoverySection
                } else {
                    resultsSections
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
        .searchable(text: $searchText, prompt: "Doctors, specialties")
        .searchFocused($fieldFocused)
    }

    private var discoverySection: some View {
        Section("Discovery") {
            Label("Trending", systemImage: "flame")
            Label("Recently viewed", systemImage: "clock")
            Label("Categories", systemImage: "square.grid.2x2")
        }
    }

    @ViewBuilder
    private var resultsSections: some View {
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

        Section("Specialties") {
            if filteredSpecialties.isEmpty {
                EmptyView()
            } else {
                ForEach(filteredSpecialties) { spec in
                    NavigationLink {
                        DoctorListView(specialty: spec)
                    } label: {
                        specialtyRow(spec)
                    }
                }
            }
        }
    }

    private func doctorRow(_ doctor: DoctorProfile) -> some View {
        HStack(spacing: 12) {
            Image(doctor.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(doctor.name)
                    .font(.body)
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
        }
        .contentShape(Rectangle())
    }

    private func specialtyRow(_ spec: MedicalSpecialty) -> some View {
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

    private var noResultsRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .foregroundColor(.secondary)
            Text("No results")
                .foregroundColor(.secondary)
        }
    }
}

extension HomeView {

    private var header: some View {
        HStack(spacing: 14) {

            Group {
                if auth.isAuthenticated {
                    if let ui = auth.decodedProfileImage() {
                        Image(uiImage: ui)
                            .resizable()
                    } else if UIImage(named: "ProfilePic") != nil {
                        Image("ProfilePic")
                            .resizable()
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                } else {
                    // Signed out: always show a neutral placeholder (do not load stored image)
                    Image(systemName: "person.circle")
                        .resizable()
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .contentShape(Rectangle())
            .onTapGesture {
                // Always open the profile sheet when tapping the avatar
                isProfileSheetPresented = true
            }
            .accessibilityLabel("Open profile")

            VStack(alignment: .leading, spacing: 2) {
                let name = UserDefaults.standard.string(forKey: "user_fullName") ?? "Guest"
                Text(auth.isAuthenticated ? "Hello \(name)" : "Welcome")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text("Find nearby health services")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private func signedOutPrompt(_ title: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text("Please sign in to continue.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FacilityFilter.allCases) { filter in
                    Button {
                        viewModel.selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                filter == viewModel.selectedFilter ?
                                Color.blue : Color(.systemGray5)
                            )
                            .foregroundColor(
                                filter == viewModel.selectedFilter ? .white : .primary
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private var mapCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemGray4))

            Map(
                coordinateRegion: $viewModel.region,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: viewModel.locations
            ) { location in
                MapAnnotation(
                    coordinate: location.coordinate,
                    anchorPoint: CGPoint(x: 0.5, y: 1)
                ) {
                    VStack(spacing: 0) {
                        // Smaller circular icon
                        Image(systemName: location.type.systemImage)
                            .font(.system(size: 11)) // was 14
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18) // was 24x24
                            .background(markerColor(for: location.type))
                            .clipShape(Circle())
                            .shadow(radius: 2) // was 3

                        // Smaller pointer triangle
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 6)) // was 8
                            .foregroundColor(markerColor(for: location.type))
                            .rotationEffect(.degrees(180))
                            .offset(y: -1.5) // was -2
                    }
                    .onTapGesture {
                        selectedMapLocation = location
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))

            if viewModel.locations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                    Text("No places found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .frame(height: 260)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
    }

    private func markerColor(for type: FacilityFilter) -> Color {
        switch type {
        case .hospital: return .red
        case .pharmacy: return .green
        case .clinic: return .orange
        case .all: return .blue
        }
    }

    private var appointmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Appointments")
                .font(.headline)

            if viewModel.appointments.isEmpty {
                noAppointmentsCard
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.appointments) { appt in
                        appointmentCard(for: appt)
                    }
                }
            }
        }
    }

    private func appointmentCard(for appt: Appointment) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 12) {

                Group {
                    if UIImage(named: appt.image) != nil {
                        Image(appt.image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.crop.square")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.secondary)
                            .padding(10)
                            .background(Color(.systemGray6))
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text(appt.doctor.name)
                        .font(.system(size: 18, weight: .semibold))

                    HStack(spacing: 8) {
                        Image(systemName: appt.doctor.specialty.systemImage)
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 22, height: 22)
                            .background(appt.doctor.specialty.color)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text(appt.doctor.specialty.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)

                        Text(dateFormatter.string(from: appt.date))
                            .font(.footnote)

                        Circle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 3, height: 3)

                        Text(timeFormatter.string(from: appt.date))
                            .font(.footnote)
                    }

                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(appt.locationAddress)
                            Text(appt.city)
                            Text(appt.country)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button {
                    viewModel.deleteAppointment(appt.id)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
    }

    private var noAppointmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No appointments yet")
                .font(.headline)

            Text("Tap below to book your first appointment.")
                .foregroundColor(.secondary)

            Button {
                viewModel.selectedTab = .bookNow
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Book an appointment")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
    }

    private var labTestRow: some View {
        Button {
            isExamUploadPresented = true
        } label: {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "doc.viewfinder")
                    Text("Upload exam to find doctors")
                }
                Spacer()
                Image(systemName: "chevron.up")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
            )
        }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }
}

#Preview {
    HomeView()
        .environmentObject(HomeViewModel())
        .environmentObject(AuthViewModel())
}
