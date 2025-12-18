import SwiftUI

struct DoctorCardView: View {
    let doctor: DoctorProfile
    
    @State private var goToBooking = false
    @State private var showLoginPrompt = false
    @State private var presentLoginSheet = false
    
    @EnvironmentObject private var auth: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // HEADER
            HStack(alignment: .center, spacing: 16) {
                Image(doctor.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 66, height: 66)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(doctor.name)
                        .font(.system(size: 18, weight: .semibold))
                    
                    // Specialty with icon
                    HStack(spacing: 8) {
                        Image(systemName: doctor.specialty.systemImage)
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 22, height: 22)
                            .background(doctor.specialty.color)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        Text(doctor.specialty.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // ⭐ Rating
                    HStack(spacing: 4) {
                        starRow(rating: doctor.rating)
                        Text(String(format: "%.1f", doctor.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Languages: \(doctor.languages.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            
            // ADDRESS
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.red)
                    .font(.caption)
                
                Text(doctor.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            
            // BOOK BUTTON
            Button {
                if auth.isAuthenticated {
                    goToBooking = true
                } else {
                    showLoginPrompt = true
                }
            } label: {
                Text("Book")
                    .font(.callout.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 22)
                    .background(Color.blue, in: Capsule())
            }
            .alert("Sign in required",
                   isPresented: $showLoginPrompt) {
                Button("Cancel", role: .cancel) { }
                Button("Open Login") {
                    presentLoginSheet = true
                }
            } message: {
                Text("Please sign in to book an appointment.")
            }
            .sheet(isPresented: $presentLoginSheet) {
                // Modal login; when user signs in, the sheet will dismiss on success
                NavigationStack {
                    LoginView()
                        .environmentObject(auth)
                }
            }
            
            // Hidden NavigationLink that triggers on tap
            NavigationLink(
                destination: BookingView(doctor: doctor),
                isActive: $goToBooking
            ) {
                EmptyView()
            }
            .hidden()
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(radius: 6)
        )
    }
    
    private func starRow(rating: Double) -> some View {
        let full = Int(rating)
        let half = (rating - Double(full)) >= 0.5
        
        return HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                if i < full {
                    Image(systemName: "star.fill")
                } else if i == full && half {
                    Image(systemName: "star.leadinghalf.filled")
                } else {
                    Image(systemName: "star")
                }
            }
            .foregroundColor(.yellow)
            .font(.caption)
        }
    }
}
