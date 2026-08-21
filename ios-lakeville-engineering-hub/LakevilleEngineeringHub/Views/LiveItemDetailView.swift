import MapKit
import SwiftUI

/// Detail for a single live condition, with a map of the affected segment and
/// a shortcut to open it in Maps for a field visit.
struct LiveItemDetailView: View {
    let item: LiveItem

    @Environment(\.openURL) private var openURL
    @Environment(LocationProvider.self) private var location

    /// Limits of the municipality the work sits in, drawn for context.
    private var jurisdictionBoundary: MunicipalBoundary? {
        BoundaryStore.shared.boundary(cityID: item.jurisdictionID)
    }

    /// How far the crew currently is from the affected segment.
    private var distanceFromMe: Double? {
        guard let here = location.currentPoint else { return nil }
        return item.distanceInMiles(from: here)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                VStack(spacing: 20) {
                    if !item.path.isEmpty { map }
                    detailsCard
                    actions
                }
                .padding(.horizontal, Theme.pageMargin)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Theme.canvas)
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .civicNavigationBar()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(item.category.singular, systemImage: item.category.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.amber)

            Text(item.title)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                if let impact = item.impact {
                    StatusChip(text: impact, tone: item.isFullClosure ? .amber : .steel)
                }
                if let jurisdiction = item.jurisdiction {
                    Label(jurisdiction, systemImage: "building.2.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                if let distanceFromMe {
                    Label(
                        distanceFromMe < 0.1
                            ? "You're here"
                            : "\(distanceFromMe.formatted(.number.precision(.fractionLength(1)))) mi away",
                        systemImage: "location.fill"
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.pageMargin)
        .padding(.top, 16)
        .padding(.bottom, 22)
        .background(Theme.navy)
    }

    private var map: some View {
        Map(initialPosition: .region(region)) {
            if let boundary = jurisdictionBoundary {
                ForEach(Array(boundary.rings.enumerated()), id: \.offset) { _, ring in
                    MapPolygon(coordinates: ring.map(\.coordinate))
                        .foregroundStyle(Theme.navy.opacity(0.06))
                        .stroke(Theme.navy.opacity(0.7), lineWidth: 2)
                }
            }
            ForEach(Array(item.displaySegments.enumerated()), id: \.offset) { _, run in
                if run.count > 1 {
                    MapPolyline(coordinates: run.map(\.coordinate))
                        .stroke(Theme.amber, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                }
            }
            if let anchor = item.anchor {
                Marker(item.title, systemImage: item.category.systemImage, coordinate: anchor.coordinate)
                    .tint(Theme.navy)
            }
            if location.access.isAuthorized {
                UserAnnotation()
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .frame(height: 220)
        .clipShape(.rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        .accessibilityLabel("Map of the affected segment")
        .task { location.start() }
    }

    private var region: MKCoordinateRegion {
        guard let anchor = item.anchor else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 44.67, longitude: -93.05),
                span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
            )
        }

        let points = item.allPoints
        let latitudes = points.map(\.latitude)
        let longitudes = points.map(\.longitude)
        let latSpan = max((latitudes.max() ?? 0) - (latitudes.min() ?? 0), 0.01) * 1.6
        let lonSpan = max((longitudes.max() ?? 0) - (longitudes.min() ?? 0), 0.01) * 1.6

        return MKCoordinateRegion(
            center: anchor.coordinate,
            span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lonSpan)
        )
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            if let detail = item.detail {
                row(label: "Work", value: detail)
                Divider().padding(.leading, 16)
            }
            if let schedule = item.schedule {
                row(label: "Schedule", value: schedule)
                Divider().padding(.leading, 16)
            }
            if let owner = item.owner {
                row(label: "Lead agency", value: owner)
                Divider().padding(.leading, 16)
            }
            if let jurisdiction = item.jurisdiction {
                row(label: "Jurisdiction", value: jurisdiction)
                Divider().padding(.leading, 16)
            }
            if let segmentSummary = item.segmentSummary {
                row(label: "Mapped as", value: segmentSummary)
                Divider().padding(.leading, 16)
            }
            row(label: "Source", value: item.sourceTitle)
            if let updatedAt = item.updatedAt {
                Divider().padding(.leading, 16)
                row(label: "Data updated", value: updatedAt.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .civicCard()
    }

    private func row(label: String, value: String) -> some View {
        LabeledContent {
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        } label: {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if let link = item.link, let url = URL(string: link) {
                Button {
                    openURL(url)
                } label: {
                    Label("Open project page", systemImage: "arrow.up.right.square")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.navy, in: .rect(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            if let anchor = item.anchor {
                Button {
                    openInMaps(anchor)
                } label: {
                    Label("Directions", systemImage: "car.fill")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.surface, in: .rect(cornerRadius: 12))
                        .foregroundStyle(Theme.navy)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Theme.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func openInMaps(_ point: GeoPoint) {
        let placemark = MKPlacemark(coordinate: point.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = item.title
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
