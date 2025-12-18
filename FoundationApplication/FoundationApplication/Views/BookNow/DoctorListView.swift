import SwiftUI

struct DoctorListView: View {
    let specialty: MedicalSpecialty
    
    private var doctors: [DoctorProfile] {
        doctorProfiles(for: specialty)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(doctors) { doctor in
                    DoctorCardView(doctor: doctor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(specialty.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
