import Foundation
import HealthKit

@Observable
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    private(set) var isAuthorized = false

    /// All the types GymTracker can write to HealthKit
    private let writeTypes: Set<HKSampleType> = [
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryFatTotal),
        HKQuantityType(.dietaryFiber),
        HKQuantityType(.dietarySugar),
        HKQuantityType(.dietaryWater),
        HKQuantityType(.bodyMass),
        HKQuantityType(.bodyFatPercentage),
        HKQuantityType(.leanBodyMass),
    ]

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorization

    /// Requests HealthKit authorization and checks that at least one write type was granted.
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: [])
            // requestAuthorization doesn't throw when the user denies — check actual status
            let authorized = checkWriteAuthorization()
            isAuthorized = authorized
            return authorized
        } catch {
            print("[HealthKit] Authorization failed: \(error)")
            isAuthorized = false
            return false
        }
    }

    /// Checks if at least one write type is currently authorized. Call on app launch to sync state.
    func refreshAuthorization() {
        guard isAvailable else {
            isAuthorized = false
            return
        }
        isAuthorized = checkWriteAuthorization()
    }

    private func checkWriteAuthorization() -> Bool {
        guard isAvailable else { return false }
        // Check if at least one write type is authorized
        for type in writeTypes {
            if store.authorizationStatus(for: type) == .sharingAuthorized {
                return true
            }
        }
        return false
    }

    // MARK: - Nutrition

    func saveMeal(calories: Int, protein: Double, carbs: Double, fat: Double,
                  fiber: Double, sugar: Double, date: Date) {
        guard isAuthorized else { return }

        let samples: [(HKQuantityTypeIdentifier, Double, HKUnit)] = [
            (.dietaryEnergyConsumed, Double(calories), .kilocalorie()),
            (.dietaryProtein, protein, .gram()),
            (.dietaryCarbohydrates, carbs, .gram()),
            (.dietaryFatTotal, fat, .gram()),
            (.dietaryFiber, fiber, .gram()),
            (.dietarySugar, sugar, .gram()),
        ]

        for (id, value, unit) in samples where value > 0 {
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            let sample = HKQuantitySample(type: HKQuantityType(id), quantity: quantity, start: date, end: date)
            store.save(sample) { _, error in
                if let error { print("[HealthKit] Save \(id) error: \(error)") }
            }
        }
    }

    func deleteMeal(calories: Int, protein: Double, carbs: Double, fat: Double,
                    fiber: Double, sugar: Double, date: Date) {
        guard isAuthorized else { return }

        let types: [(HKQuantityTypeIdentifier, Double)] = [
            (.dietaryEnergyConsumed, Double(calories)),
            (.dietaryProtein, protein),
            (.dietaryCarbohydrates, carbs),
            (.dietaryFatTotal, fat),
            (.dietaryFiber, fiber),
            (.dietarySugar, sugar),
        ]

        for (id, value) in types where value > 0 {
            let type = HKQuantityType(id)
            let predicate = HKQuery.predicateForSamples(
                withStart: date.addingTimeInterval(-1),
                end: date.addingTimeInterval(1),
                options: .strictStartDate
            )
            let sourcePredicate = HKQuery.predicateForObjects(from: HKSource.default())
            let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, sourcePredicate])

            let query = HKSampleQuery(sampleType: type, predicate: compound, limit: 1, sortDescriptors: nil) { [weak self] _, samples, _ in
                guard let sample = samples?.first else { return }
                self?.store.delete(sample) { _, error in
                    if let error { print("[HealthKit] Delete \(id) error: \(error)") }
                }
            }
            store.execute(query)
        }
    }

    // MARK: - Water

    func saveWater(milliliters: Int, date: Date) {
        guard isAuthorized, milliliters > 0 else { return }
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(milliliters))
        let sample = HKQuantitySample(
            type: HKQuantityType(.dietaryWater),
            quantity: quantity,
            start: date,
            end: date
        )
        store.save(sample) { _, error in
            if let error { print("[HealthKit] Save water error: \(error)") }
        }
    }

    // MARK: - Body Composition

    func saveWeight(kg: Double, bodyFat: Double?, date: Date) {
        guard isAuthorized, kg > 0 else { return }

        // Body mass
        let massQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let massSample = HKQuantitySample(
            type: HKQuantityType(.bodyMass),
            quantity: massQuantity,
            start: date,
            end: date
        )
        store.save(massSample) { _, error in
            if let error { print("[HealthKit] Save bodyMass error: \(error)") }
        }

        // Body fat percentage
        if let bf = bodyFat, bf > 0 {
            let bfQuantity = HKQuantity(unit: .percent(), doubleValue: bf / 100.0)
            let bfSample = HKQuantitySample(
                type: HKQuantityType(.bodyFatPercentage),
                quantity: bfQuantity,
                start: date,
                end: date
            )
            store.save(bfSample) { _, error in
                if let error { print("[HealthKit] Save bodyFat error: \(error)") }
            }

            // Lean body mass
            let leanMass = kg * (1 - bf / 100.0)
            let leanQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: leanMass)
            let leanSample = HKQuantitySample(
                type: HKQuantityType(.leanBodyMass),
                quantity: leanQuantity,
                start: date,
                end: date
            )
            store.save(leanSample) { _, error in
                if let error { print("[HealthKit] Save leanBodyMass error: \(error)") }
            }
        }
    }
}
