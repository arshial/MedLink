import SwiftUI

struct MapIntroView: View {
    @AppStorage("didShowMapIntro") private var didShowMapIntro = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.35),
                                Color.blue.opacity(0.25),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 170, height: 170)
                    .blur(radius: 16)

                Image("IMG_1088")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 8)
            }
            .padding(.top, 8)

            Text("Welcome to Medlink")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            VStack(spacing: 22) {

                introRow(
                    icon: "cross.case.fill",
                    color: .red,
                    title: "Hospitals",
                    subtitle: "Emergency & full-service care"
                )

                introRow(
                    icon: "stethoscope",
                    color: .orange,
                    title: "Private Clinics",
                    subtitle: "Specialist consultations"
                )

                introRow(
                    icon: "pill.fill",
                    color: .green,
                    title: "Pharmacies",
                    subtitle: "Medicines & essentials"
                )

                introRow(
                    icon: "location.fill",
                    color: .blue,
                    title: "Your Location",
                    subtitle: "Distance & directions"
                )
            }

            Spacer()

            Button {
                didShowMapIntro = true
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .foregroundColor(.white)
    }

    private func introRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(color)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }
}
