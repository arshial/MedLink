import SwiftUI
import CoreLocation
import MapKit


// -------------------------------------------------------
// MARK: - VIEW: LocationDetailSheet
// -------------------------------------------------------

struct LocationDetailSheet: View {
    let location: MedicalLocation
    let userLocation: CLLocation?
    
    @Environment(\.dismiss) var dismiss
    
    private var distanceString: String {
        guard let userLoc = userLocation else { return "Distance unavailable" }
        
        let dest = CLLocation(latitude: location.coordinate.latitude,
                              longitude: location.coordinate.longitude)
        let meters = userLoc.distance(from: dest)
        
        if meters < 1000 {
            return "\(Int(meters)) m away"
        } else {
            return String(format: "%.1f km away", meters / 1000)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // DRAG INDICATOR
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .alignHorizontallyCenter()
            
            // HEADER
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: location.type.systemImage)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 58, height: 58)
                    .background(markerColor(for: location.type))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.title3.bold())
                        .lineLimit(2)
                    
                    Text(location.type.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text(distanceString)
                            .font(.caption.bold())
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                }
                Spacer()
            }
            
            Divider()
            
            // ADDRESS
            VStack(alignment: .leading, spacing: 8) {
                Text("Address")
                    .font(.headline)
                
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                    Text(location.addressPlaceholder)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            
            Spacer()
            
            // GET DIRECTIONS BUTTON
            Button {
                openAppleMaps()
                dismiss()
            } label: {
                Text("Get Directions")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.fraction(0.42), .medium])
        .presentationDragIndicator(.visible)
    }
    
    // -------------------------------------------------------
    // MARK: - HELPERS
    // -------------------------------------------------------
    
    private func openAppleMaps() {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        let url = URL(string: "maps://?daddr=\(lat),\(lon)")!
        UIApplication.shared.open(url)
    }
    
    private func markerColor(for type: FacilityFilter) -> Color {
        switch type {
        case .hospital: return .red
        case .pharmacy: return .green
        case .clinic: return .orange
        case .all: return .blue
        }
    }
}

// -------------------------------------------------------
// MARK: - ALIGNMENT EXTENSION
// -------------------------------------------------------

extension View {
    func alignHorizontallyCenter() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }
}
