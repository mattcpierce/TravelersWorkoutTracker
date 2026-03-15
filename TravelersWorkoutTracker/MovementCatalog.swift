import Foundation

enum MovementCatalog {
    static let defaultAllowedModalities: [EquipmentType] = [.dumbbells, .barbell, .kettlebell, .landmine, .bodyweight, .resistanceBand]

    static let allowedModalitiesByMovementId: [String: [EquipmentType]] = [
        "back-squat": [.barbell],
        "front-squat": [.barbell],
        "goblet-squat": [.dumbbells, .kettlebell],
        "bulgarian-split-squat": [.bodyweight, .dumbbells, .barbell, .kettlebell],
        "step-up": [.bodyweight, .dumbbells, .barbell, .kettlebell],
        "romanian-deadlift": [.barbell, .dumbbells, .kettlebell],
        "conventional-deadlift": [.barbell],
        "hip-thrust": [.bodyweight, .dumbbells, .barbell, .kettlebell],
        "single-leg-romanian-deadlift": [.bodyweight, .dumbbells, .kettlebell],
        "hamstring-slider-curl": [.bodyweight],
        "nordic-curl": [.bodyweight],
        "bench-press": [.dumbbells, .barbell],
        "incline-press": [.dumbbells, .barbell],
        "floor-press": [.dumbbells, .barbell],
        "push-up": [.bodyweight, .resistanceBand],
        "overhead-press": [.dumbbells, .barbell, .kettlebell, .landmine],
        "landmine-press": [.landmine],
        "barbell-row": [.barbell, .dumbbells],
        "chest-supported-row": [.dumbbells, .kettlebell],
        "one-arm-dumbbell-row": [.dumbbells, .kettlebell],
        "landmine-row": [.landmine],
        "pull-up": [.bodyweight, .resistanceBand],
        "chin-up": [.bodyweight, .resistanceBand],
        "lat-pulldown": [.resistanceBand],
        "lateral-raise": [.dumbbells, .resistanceBand],
        "rear-delt-fly": [.dumbbells, .resistanceBand],
        "front-raise": [.dumbbells, .resistanceBand],
        "dips": [.bodyweight],
        "overhead-triceps-extension": [.dumbbells, .barbell, .kettlebell, .resistanceBand],
        "close-grip-bench-press": [.barbell],
        "curl": [.barbell, .dumbbells, .kettlebell, .resistanceBand],
        "hammer-curl": [.dumbbells, .kettlebell],
        "standing-calf-raise": [.bodyweight, .dumbbells, .kettlebell],
        "seated-calf-raise": [.dumbbells, .kettlebell],
        "tibialis-raise": [.bodyweight, .resistanceBand],
        "hamstring-curl": [.bodyweight, .resistanceBand],
        "face-pull": [.resistanceBand],
        "band-crunch": [.resistanceBand],
        "shrug-row": [.dumbbells],
        "crunch": [.bodyweight],
        "copenhagen-plank": [.bodyweight],
        "lateral-lunge": [.bodyweight, .dumbbells, .kettlebell, .barbell],
        "cossack-squat": [.bodyweight, .dumbbells, .kettlebell],
        "lateral-band-walk": [.resistanceBand],
        "single-leg-box-squat": [.bodyweight, .dumbbells, .kettlebell],
        "lateral-step-down": [.bodyweight, .dumbbells, .kettlebell],
        "db-incline-fly": [.dumbbells],
        "reverse-hyper": [.bodyweight, .dumbbells, .kettlebell],
        "bird-dog": [.bodyweight, .dumbbells, .resistanceBand],
        "suitcase-carry": [.dumbbells, .kettlebell],
        "dead-bug": [.bodyweight],
        "pallof-press": [.resistanceBand],
        "side-plank": [.bodyweight],
        "hanging-knee-raise": [.bodyweight],
        "farmer-carry": [.dumbbells, .kettlebell],
        "landmine-squat-to-press": [.landmine]
    ]

    static let hotelAlternativeByMovementId: [String: String] = [
        "back-squat": "goblet-squat",
        "front-squat": "goblet-squat",
        "conventional-deadlift": "romanian-deadlift",
        "bench-press": "push-up",
        "incline-press": "push-up",
        "close-grip-bench-press": "push-up",
        "barbell-row": "one-arm-dumbbell-row",
        "landmine-row": "one-arm-dumbbell-row",
        "lat-pulldown": "pull-up",
        "band-crunch": "dead-bug",
        "standing-calf-raise": "seated-calf-raise"
    ]

    static func allowedModalities(for movementId: String) -> [EquipmentType] {
        allowedModalitiesByMovementId[movementId] ?? defaultAllowedModalities
    }

    static func hotelAlternative(for movementId: String) -> String? {
        hotelAlternativeByMovementId[movementId]
    }

    static func category(for movementId: String) -> String {
        switch movementId {
        case "back-squat", "front-squat", "goblet-squat", "bulgarian-split-squat", "step-up", "lateral-lunge", "cossack-squat", "single-leg-box-squat", "lateral-step-down":
            return "Lower Body"
        case "romanian-deadlift", "conventional-deadlift", "hip-thrust", "single-leg-romanian-deadlift", "hamstring-slider-curl", "nordic-curl", "hamstring-curl", "reverse-hyper":
            return "Posterior Chain"
        case "standing-calf-raise", "seated-calf-raise", "tibialis-raise":
            return "Lower Leg"
        case "bench-press", "incline-press", "floor-press", "push-up", "overhead-press", "landmine-press", "lateral-raise", "rear-delt-fly", "front-raise", "dips", "overhead-triceps-extension", "close-grip-bench-press", "db-incline-fly":
            return "Upper Push"
        case "barbell-row", "chest-supported-row", "one-arm-dumbbell-row", "landmine-row", "pull-up", "chin-up", "lat-pulldown", "face-pull", "shrug-row", "curl", "hammer-curl":
            return "Upper Pull"
        case "band-crunch", "crunch", "dead-bug", "pallof-press", "side-plank", "hanging-knee-raise", "bird-dog", "copenhagen-plank":
            return "Core"
        case "farmer-carry", "suitcase-carry", "lateral-band-walk", "landmine-squat-to-press":
            return "Accessories"
        default:
            return "General"
        }
    }

    static func tags(for movementId: String) -> [String] {
        switch movementId {
        case "back-squat", "front-squat", "goblet-squat":
            return ["squat", "compound", "legs"]
        case "romanian-deadlift", "conventional-deadlift", "hip-thrust":
            return ["hinge", "compound", "strength"]
        case "bench-press", "incline-press", "floor-press":
            return ["press", "compound", "chest"]
        case "push-up":
            return ["bodyweight", "press", "travel"]
        case "barbell-row", "one-arm-dumbbell-row", "landmine-row":
            return ["row", "back", "compound"]
        case "pull-up", "chin-up", "lat-pulldown":
            return ["vertical-pull", "back", "travel"]
        case "curl", "hammer-curl":
            return ["arms", "isolation", "biceps"]
        case "standing-calf-raise", "seated-calf-raise", "tibialis-raise":
            return ["lower-leg", "isolation", "travel"]
        case "band-crunch", "dead-bug", "pallof-press", "side-plank":
            return ["core", "travel", "control"]
        case "farmer-carry", "suitcase-carry":
            return ["carry", "grip", "conditioning"]
        default:
            let category = category(for: movementId).lowercased().replacingOccurrences(of: " ", with: "-")
            return [category]
        }
    }
}
