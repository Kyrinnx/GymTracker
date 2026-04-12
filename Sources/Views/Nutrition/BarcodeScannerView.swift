import SwiftUI
import AVFoundation

// MARK: - OpenFoodFacts API

struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let nutriments: Nutriments?
    let quantity: String?
    let brands: String?
    let imageSmallUrl: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
        case quantity
        case brands
        case imageSmallUrl = "image_small_url"
    }
}

struct Nutriments: Codable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?
    let fiber100g: Double?
    let sugars100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case fiber100g = "fiber_100g"
        case sugars100g = "sugars_100g"
    }
}

struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

enum OpenFoodFactsAPI {
    static func fetchProduct(barcode: String) async -> ScannedProduct? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else {
            return nil
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
            guard response.status == 1, let p = response.product, let n = p.nutriments else { return nil }
            return ScannedProduct(
                barcode: barcode,
                name: p.productName ?? "Produit inconnu",
                brand: p.brands ?? "",
                quantity: p.quantity ?? "100 g",
                kcalPer100g: n.energyKcal100g ?? 0,
                proteinPer100g: n.proteins100g ?? 0,
                carbsPer100g: n.carbohydrates100g ?? 0,
                fatPer100g: n.fat100g ?? 0,
                fiberPer100g: n.fiber100g ?? 0,
                sugarPer100g: n.sugars100g ?? 0
            )
        } catch {
            return nil
        }
    }
}

struct ScannedProduct: Identifiable {
    let id = UUID()
    let barcode: String
    let name: String
    let brand: String
    let quantity: String
    let kcalPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double
    let sugarPer100g: Double

    func toFoodItem(grams: Double) -> FoodItem {
        let ratio = grams / 100.0
        return FoodItem(
            name: brand.isEmpty ? name : "\(name) (\(brand))",
            emoji: "📦",
            portion: "\(Int(grams)) g",
            grams: grams,
            kcal: Int(kcalPer100g * ratio),
            protein: proteinPer100g * ratio,
            carbs: carbsPer100g * ratio,
            fat: fatPer100g * ratio,
            fiber: fiberPer100g * ratio,
            sugar: sugarPer100g * ratio,
            category: .snacks
        )
    }
}

// MARK: - Barcode Scanner View

struct BarcodeScannerView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let mealType: MealType

    @State private var scannedBarcode: String?
    @State private var product: ScannedProduct?
    @State private var isLoading = false
    @State private var notFound = false
    @State private var grams: Double = 100
    @State private var editKcal: String = ""
    @State private var editProt: String = ""
    @State private var editCarbs: String = ""
    @State private var editFat: String = ""
    @State private var saveAsFavorite = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if product == nil {
                    scannerArea
                } else {
                    productResult
                }
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    // MARK: - Scanner area

    private var scannerArea: some View {
        ZStack {
            CameraPreview(onBarcodeScanned: handleBarcode)
                .ignoresSafeArea()

            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.color.accent, lineWidth: 3)
                    .frame(width: 260, height: 160)
                    .shadow(color: theme.color.accent.opacity(0.5), radius: 12)
                Spacer()

                VStack(spacing: 12) {
                    if isLoading {
                        ProgressView("Recherche en cours...")
                            .tint(.white)
                    } else if notFound {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title)
                                .foregroundStyle(.yellow)
                            Text("Produit non trouvé")
                                .font(.headline)
                            Text("Réessaie ou ajoute-le manuellement")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Réessayer") {
                                notFound = false
                                scannedBarcode = nil
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Text("Scanne un code-barres")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("EAN-8, EAN-13, UPC")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Product result

    private var productResult: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product header
                VStack(spacing: 8) {
                    Text("📦")
                        .font(.system(size: 50))
                    Text(product?.name ?? "")
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                    if let brand = product?.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("pour 100 g : \(Int(product?.kcalPer100g ?? 0)) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Grams input
                VStack(spacing: 12) {
                    HStack {
                        Text("Quantité")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(grams)) g")
                            .font(.title3.bold())
                            .foregroundStyle(theme.color.accent)
                    }
                    HStack(spacing: 16) {
                        Button { grams = max(10, grams - 10) } label: {
                            Image(systemName: "minus")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(theme.color.accent.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        Slider(value: $grams, in: 10...500, step: 10)
                            .tint(theme.color.accent)
                            .onChange(of: grams) { _, _ in updateFields() }
                        Button { grams = min(500, grams + 10) } label: {
                            Image(systemName: "plus")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(theme.color.accent)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // Editable macros
                VStack(spacing: 10) {
                    Text("VALEURS NUTRITIONNELLES")
                        .font(.caption2.bold())
                        .tracking(1)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 10) {
                        editableField("kcal", text: $editKcal)
                        editableField("P (g)", text: $editProt)
                        editableField("G (g)", text: $editCarbs)
                        editableField("L (g)", text: $editFat)
                    }
                }
                .padding(18)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // Save as favorite
                Toggle(isOn: $saveAsFavorite) {
                    Label("Sauvegarder en favori", systemImage: "star.fill")
                        .foregroundStyle(.primary)
                }
                .tint(.yellow)
                .padding(.horizontal, 18)

                // Buttons
                VStack(spacing: 10) {
                    Button { addProduct() } label: {
                        Text("Ajouter")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.color.gradient)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        product = nil
                        scannedBarcode = nil
                        notFound = false
                    } label: {
                        Text("Scanner un autre produit")
                            .font(.subheadline)
                            .foregroundStyle(theme.color.accent)
                    }
                }
            }
            .padding()
        }
    }

    private func editableField(_ label: String, text: Binding<String>) -> some View {
        VStack(spacing: 4) {
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.callout.bold())
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Logic

    private func handleBarcode(_ barcode: String) {
        guard scannedBarcode == nil, !isLoading else { return }
        scannedBarcode = barcode
        isLoading = true
        notFound = false
        Task {
            if let result = await OpenFoodFactsAPI.fetchProduct(barcode: barcode) {
                product = result
                grams = 100
                updateFields()
            } else {
                notFound = true
            }
            isLoading = false
        }
    }

    private func updateFields() {
        guard let p = product else { return }
        let ratio = grams / 100.0
        editKcal = "\(Int(p.kcalPer100g * ratio))"
        editProt = "\(Int(p.proteinPer100g * ratio))"
        editCarbs = "\(Int(p.carbsPer100g * ratio))"
        editFat = "\(Int(p.fatPer100g * ratio))"
    }

    private func addProduct() {
        let kcal = Int(editKcal) ?? 0
        let prot = Double(editProt) ?? 0
        let carbs = Double(editCarbs) ?? 0
        let fat = Double(editFat) ?? 0
        let name = product?.name ?? "Produit scanné"
        let brand = product?.brand ?? ""
        let displayName = brand.isEmpty ? name : "\(name) (\(brand))"

        let meal = MealEntry(
            name: displayName,
            type: mealType,
            calories: kcal,
            protein: prot,
            carbs: carbs,
            fat: fat,
            fiber: 0,
            sugar: 0
        )
        context.insert(meal)

        if saveAsFavorite {
            let item = FoodItem(
                name: displayName,
                emoji: "📦",
                portion: "\(Int(grams)) g",
                grams: grams,
                kcal: kcal,
                protein: prot,
                carbs: carbs,
                fat: fat,
                fiber: 0,
                sugar: 0,
                category: .snacks
            )
            context.insert(FavoriteFood(item: item))
        }

        dismiss()
    }
}

// MARK: - Camera Preview (UIKit wrapper)

struct CameraPreview: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onBarcodeScanned: onBarcodeScanned) }

    func makeUIViewController(context: Context) -> CameraVC {
        let vc = CameraVC()
        vc.coordinator = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: CameraVC, context: Context) {}

    class CameraVC: UIViewController {
        var coordinator: Coordinator?
        private var session: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            setupCamera()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            previewLayer?.frame = view.bounds
        }

        private func setupCamera() {
            let session = AVCaptureSession()
            self.session = session
            coordinator?.session = session

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }

            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(coordinator, queue: .main)
                output.metadataObjectTypes = [.ean8, .ean13, .upce]
            }

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = view.bounds
            view.layer.addSublayer(layer)
            self.previewLayer = layer

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var session: AVCaptureSession?
        let onBarcodeScanned: (String) -> Void
        private var hasScanned = false

        init(onBarcodeScanned: @escaping (String) -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !hasScanned,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue else { return }
            hasScanned = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            session?.stopRunning()
            onBarcodeScanned(value)
        }
    }
}
