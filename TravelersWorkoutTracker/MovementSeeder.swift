import Foundation
import SwiftData

enum MovementSeeder {
    static let seedVersion = 4

    private static let seedVersionKey = "movementSeedVersion"

    struct SeedMovement {
        let id: String
        let name: String
        let movementDescription: String
        let category: String
        let tags: [String]
        let hotelAlternativeMovementId: String?
        let allowedModalities: [EquipmentType]
        let isCustom: Bool
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        let storedSeedVersion = defaults.integer(forKey: seedVersionKey)

        do {
            let existingMovements = try context.fetch(FetchDescriptor<Movement>())
            let hasBuiltIns = existingMovements.contains { !$0.isCustom }

            guard storedSeedVersion < seedVersion || !hasBuiltIns else { return }

            let movementById = Dictionary(uniqueKeysWithValues: existingMovements.map { ($0.id, $0) })

            for seed in builtInMovements {
                if let movement = movementById[seed.id] {
                    guard !movement.isCustom else { continue }
                    movement.name = seed.name
                    movement.description = seed.movementDescription
                    movement.category = seed.category
                    movement.tags = seed.tags
                    movement.hotelAlternativeMovementId = seed.hotelAlternativeMovementId
                    movement.allowedModalities = seed.allowedModalities
                    movement.isCustom = false
                } else {
                    context.insert(
                        Movement(
                            id: seed.id,
                            name: seed.name,
                            description: seed.movementDescription,
                            category: seed.category,
                            tags: seed.tags,
                            hotelAlternativeMovementId: seed.hotelAlternativeMovementId,
                            allowedModalities: seed.allowedModalities,
                            isCustom: false
                        )
                    )
                }
            }

            try context.save()
            defaults.set(seedVersion, forKey: seedVersionKey)
        } catch {
            print("MovementSeeder failed: \(error.localizedDescription)")
        }
    }

    private static let builtInMovements: [SeedMovement] = [
        .init(
            id: "back-squat",
            name: "Back Squat",
            movementDescription: "Set the bar across your upper back, brace hard, and sit down between your hips with control. Keep your knees tracking over your toes and drive through mid-foot to stand tall.",
            category: "Squat",
            tags: ["quads", "glutes", "compound"],
            hotelAlternativeMovementId: "goblet-squat",
            allowedModalities: [.barbell],
            isCustom: false
        ),
        .init(
            id: "front-squat",
            name: "Front Squat",
            movementDescription: "Rack the load on your front shoulders and keep elbows high as you descend. Stay upright, hit controlled depth, then push the floor away to stand.",
            category: "Squat",
            tags: ["quads", "core", "compound"],
            hotelAlternativeMovementId: "goblet-squat",
            allowedModalities: [.barbell, .kettlebell],
            isCustom: false
        ),
        .init(
            id: "goblet-squat",
            name: "Goblet Squat",
            movementDescription: "Hold the load tight to your chest and keep your ribs stacked over your hips. Lower with control, keep your heels grounded, and stand by driving evenly through both feet.",
            category: "Squat",
            tags: ["quads", "glutes", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.dumbbells, .kettlebell],
            isCustom: false
        ),
        .init(
            id: "bulgarian-split-squat",
            name: "Bulgarian Split Squat",
            movementDescription: "Set your rear foot on a bench and keep most of your weight on the front leg. Drop straight down with control, then push through the front heel to return.",
            category: "Squat",
            tags: ["quads", "glutes", "unilateral"],
            hotelAlternativeMovementId: "step-up",
            allowedModalities: [.dumbbells, .kettlebell, .bodyweight],
            isCustom: false
        ),
        .init(
            id: "step-up",
            name: "Step-Up",
            movementDescription: "Place your whole lead foot on the step and stay tall through your torso. Drive through that leg to stand up and lower slowly without bouncing off the back foot.",
            category: "Squat",
            tags: ["quads", "glutes", "unilateral", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.dumbbells, .kettlebell, .bodyweight],
            isCustom: false
        ),
        .init(
            id: "landmine-squat",
            name: "Landmine Squat",
            movementDescription: "Hold the bar close to your chest, brace your trunk, and sit down with your elbows tucked. Drive evenly through the floor and keep the bar path smooth on the way up.",
            category: "Squat",
            tags: ["quads", "glutes", "compound"],
            hotelAlternativeMovementId: "goblet-squat",
            allowedModalities: [.landmine],
            isCustom: false
        ),

        .init(
            id: "deadlift",
            name: "Deadlift",
            movementDescription: "Set your feet, brace your trunk, and pull slack out of the bar before lifting. Push through the floor, keep the load close, and lock out with hips and knees together.",
            category: "Hinge",
            tags: ["posterior-chain", "glutes", "compound"],
            hotelAlternativeMovementId: "romanian-deadlift",
            allowedModalities: [.barbell],
            isCustom: false
        ),
        .init(
            id: "romanian-deadlift",
            name: "Romanian Deadlift",
            movementDescription: "Unlock your knees and hinge your hips back while keeping the load close to your legs. Stop when your hamstrings are loaded, then squeeze your glutes to return to full hip extension.",
            category: "Hinge",
            tags: ["hamstrings", "glutes", "compound"],
            hotelAlternativeMovementId: "single-leg-romanian-deadlift",
            allowedModalities: [.barbell, .dumbbells, .kettlebell],
            isCustom: false
        ),
        .init(
            id: "hip-thrust",
            name: "Hip Thrust",
            movementDescription: "Set your upper back on the bench and keep your chin tucked with ribs down. Drive your hips up to full extension, pause with glutes tight, and lower slowly.",
            category: "Hinge",
            tags: ["glutes", "posterior-chain"],
            hotelAlternativeMovementId: "single-leg-romanian-deadlift",
            allowedModalities: [.barbell, .dumbbells, .kettlebell, .bodyweight],
            isCustom: false
        ),
        .init(
            id: "single-leg-romanian-deadlift",
            name: "Single-Leg Romanian Deadlift",
            movementDescription: "Balance on one leg and hinge at the hips while the free leg reaches back. Keep your hips square, control the bottom position, and drive through the planted foot to stand.",
            category: "Hinge",
            tags: ["hamstrings", "glutes", "unilateral", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.dumbbells, .kettlebell, .bodyweight],
            isCustom: false
        ),
        .init(
            id: "hamstring-slider-curl",
            name: "Hamstring Slider Curl",
            movementDescription: "Lift your hips into a bridge and keep them high as your heels slide away. Pull your heels back in under control without letting your hips drop.",
            category: "Hinge",
            tags: ["hamstrings", "bodyweight", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.bodyweight],
            isCustom: false
        ),
        .init(
            id: "nordic-curl",
            name: "Nordic Curl",
            movementDescription: "Anchor your ankles and keep your body in a straight line from knees to shoulders. Lower as slowly as possible, catch lightly with your hands, and assist yourself back up.",
            category: "Hinge",
            tags: ["hamstrings", "bodyweight"],
            hotelAlternativeMovementId: "hamstring-slider-curl",
            allowedModalities: [.bodyweight],
            isCustom: false
        ),
        .init(
            id: "hamstring-curl",
            name: "Hamstring Curl",
            movementDescription: "Set up so your knee lines up with the machine or cable pivot, brace your trunk, and keep your hips from lifting or arching. Pull your heels toward your glutes under control, pause at the top, and lower slowly to a full stretch.",
            category: "Hinge",
            tags: ["hamstrings", "isolation"],
            hotelAlternativeMovementId: "hamstring-slider-curl",
            allowedModalities: [.machine, .cable, .resistanceBand],
            isCustom: false
        ),
        .init(
            id: "reverse-hyper",
            name: "Reverse Hyper",
            movementDescription: "Lie face down on the pad with your hips just past the edge and hold the handles firmly. Let your legs hang under control, then drive them back and up by squeezing your glutes while keeping your lower back neutral. Raise your legs until your body forms a straight line, pause briefly, and lower slowly without letting the weight swing.",
            category: "Hinge",
            tags: ["glutes", "posterior-chain", "lower-back"],
            hotelAlternativeMovementId: "single-leg-romanian-deadlift",
            allowedModalities: [.machine],
            isCustom: false
        ),

        .init(
            id: "bench-press",
            name: "Bench Press",
            movementDescription: "Set your upper back tight, plant your feet, and lower the bar to your mid chest with control. Press up on a smooth path while keeping your shoulders packed.",
            category: "Horizontal Push",
            tags: ["chest", "triceps", "compound"],
            hotelAlternativeMovementId: "push-up",
            allowedModalities: [.barbell, .dumbbells],
            isCustom: false
        ),
        .init(
            id: "incline-press",
            name: "Incline Press",
            movementDescription: "Set the bench at a low incline and pin your shoulder blades to the pad. Lower to your upper chest under control and press up without losing back tension.",
            category: "Horizontal Push",
            tags: ["upper-chest", "shoulders", "compound"],
            hotelAlternativeMovementId: "push-up",
            allowedModalities: [.barbell, .dumbbells],
            isCustom: false
        ),
        .init(
            id: "floor-press",
            name: "Floor Press",
            movementDescription: "Set your upper arms on a stable path and lower until your triceps touch the floor lightly. Pause briefly, then press to lockout while keeping your shoulders down.",
            category: "Horizontal Push",
            tags: ["chest", "triceps"],
            hotelAlternativeMovementId: "push-up",
            allowedModalities: [.barbell, .dumbbells, .kettlebell],
            isCustom: false
        ),
        .init(
            id: "push-up",
            name: "Push-Up",
            movementDescription: "Create a straight line from head to heel and brace your core before each rep. Lower your chest under control and push the floor away to full arm extension.",
            category: "Horizontal Push",
            tags: ["chest", "triceps", "bodyweight", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.bodyweight],
            isCustom: false
        ),

        .init(
            id: "overhead-press",
            name: "Overhead Press",
            movementDescription: "Start with the load at shoulder height and squeeze your glutes to keep your torso stacked. Press straight overhead, move your head through, and lower with control.",
            category: "Vertical Push",
            tags: ["shoulders", "triceps", "compound"],
            hotelAlternativeMovementId: "pike-push-up",
            allowedModalities: [.barbell, .dumbbells, .kettlebell],
            isCustom: false
        ),
        .init(
            id: "landmine-press",
            name: "Landmine Press",
            movementDescription: "Hold the bar end at shoulder level and keep your ribs down as you press along the arc. Reach at the top, then return slowly without rotating your torso.",
            category: "Vertical Push",
            tags: ["shoulders", "upper-chest", "compound"],
            hotelAlternativeMovementId: "pike-push-up",
            allowedModalities: [.landmine],
            isCustom: false
        ),
        .init(
            id: "pike-push-up",
            name: "Pike Push-Up",
            movementDescription: "Set your hips high and stack your shoulders over your hands as much as you can. Lower the crown of your head toward the floor with control and press back up without collapsing.",
            category: "Vertical Push",
            tags: ["shoulders", "bodyweight", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.bodyweight],
            isCustom: false
        ),

        .init(
            id: "barbell-row",
            name: "Barbell Row",
            movementDescription: "Hinge to a fixed torso angle and brace your trunk before each pull. Row toward your lower ribs, squeeze your back, and lower the load under control.",
            category: "Horizontal Pull",
            tags: ["back", "lats", "compound"],
            hotelAlternativeMovementId: "one-arm-dumbbell-row",
            allowedModalities: [.barbell],
            isCustom: false
        ),
        .init(
            id: "chest-supported-row",
            name: "Chest-Supported Row",
            movementDescription: "Press your chest firmly into the pad and let your shoulders stretch at the bottom. Pull your elbows back toward your hips, pause, and lower with control.",
            category: "Horizontal Pull",
            tags: ["back", "upper-back"],
            hotelAlternativeMovementId: "one-arm-dumbbell-row",
            allowedModalities: [.dumbbells, .machine],
            isCustom: false
        ),
        .init(
            id: "one-arm-dumbbell-row",
            name: "One-Arm Dumbbell Row",
            movementDescription: "Brace your support hand and keep your torso still as the weight hangs. Pull your elbow toward your hip, squeeze at the top, and lower slowly.",
            category: "Horizontal Pull",
            tags: ["back", "lats", "unilateral", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.dumbbells, .kettlebell],
            isCustom: false
        ),
        .init(
            id: "landmine-row",
            name: "Landmine Row",
            movementDescription: "Set a stable hinge and keep your spine neutral throughout the set. Pull the handle into your midsection and lower under control without jerking.",
            category: "Horizontal Pull",
            tags: ["back", "compound"],
            hotelAlternativeMovementId: "one-arm-dumbbell-row",
            allowedModalities: [.landmine],
            isCustom: false
        ),
        .init(
            id: "meadows-row",
            name: "Meadows Row",
            movementDescription: "Stand perpendicular to the bar with one end anchored in a landmine. Brace your free hand on your knee or a bench, grab the bar sleeve with the outside hand, and hinge slightly at the hips. Pull your elbow up and back toward your hip while keeping your torso stable, pause briefly at the top, and lower the weight under control.",
            category: "Horizontal Pull",
            tags: ["back", "lats", "upper-back", "unilateral"],
            hotelAlternativeMovementId: "one-arm-dumbbell-row",
            allowedModalities: [.landmine],
            isCustom: false
        ),

        .init(
            id: "pull-up",
            name: "Pull-Up",
            movementDescription: "Start from a dead hang, set your shoulders down, and pull your elbows toward your ribs. Bring your chest toward the bar, then lower slowly to full extension.",
            category: "Vertical Pull",
            tags: ["lats", "bodyweight", "compound"],
            hotelAlternativeMovementId: "band-lat-pulldown",
            allowedModalities: [.bodyweight],
            isCustom: false
        ),
        .init(
            id: "chin-up",
            name: "Chin-Up",
            movementDescription: "Use an underhand grip and begin each rep from a controlled dead hang. Pull until your chin clears the bar, then lower with control.",
            category: "Vertical Pull",
            tags: ["lats", "biceps", "bodyweight"],
            hotelAlternativeMovementId: "band-lat-pulldown",
            allowedModalities: [.bodyweight],
            isCustom: false
        ),
        .init(
            id: "band-lat-pulldown",
            name: "Band Lat Pulldown",
            movementDescription: "Anchor the band overhead and sit or kneel tall with your core braced. Pull your elbows down toward your sides, pause, and return to a full stretch slowly.",
            category: "Vertical Pull",
            tags: ["lats", "bands", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.resistanceBand],
            isCustom: false
        ),

        .init(
            id: "lateral-raise",
            name: "Lateral Raise",
            movementDescription: "Raise your arms out to shoulder height with a soft bend in the elbows. Control the lowering phase and keep your shoulders relaxed instead of shrugged.",
            category: "Shoulders",
            tags: ["delts", "isolation"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.dumbbells, .kettlebell, .cable, .resistanceBand],
            isCustom: false
        ),
        .init(
            id: "rear-delt-fly",
            name: "Rear Delt Fly",
            movementDescription: "Set a slight hinge and keep your chest stable while your arms open wide. Lead with your elbows, pause briefly, and lower slowly back to the start.",
            category: "Shoulders",
            tags: ["rear-delts", "upper-back", "isolation"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.dumbbells, .cable, .resistanceBand],
            isCustom: false
        ),
        .init(
            id: "front-raise",
            name: "Front Raise",
            movementDescription: "Stand tall with your ribs down and lift the load to shoulder level without swinging. Lower under control and reset before the next rep.",
            category: "Shoulders",
            tags: ["front-delts", "isolation"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.dumbbells, .kettlebell, .cable, .resistanceBand],
            isCustom: false
        ),
        .init(
            id: "face-pull",
            name: "Face Pull",
            movementDescription: "Set the anchor at face height and pull the handle toward the bridge of your nose with elbows high and shoulders down. Finish by rotating your hands back and squeezing your upper back, then return slowly without letting the load yank you forward.",
            category: "Shoulders",
            tags: ["rear-delts", "upper-back", "bands"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.resistanceBand, .cable],
            isCustom: false
        ),

        .init(
            id: "dips",
            name: "Dips",
            movementDescription: "Support your body with locked elbows and shoulders set down. Lower to a controlled stretch, then press back up without losing position.",
            category: "Arms",
            tags: ["triceps", "chest", "bodyweight"],
            hotelAlternativeMovementId: "close-grip-bench-press",
            allowedModalities: [.bodyweight],
            isCustom: false
        ),
        .init(
            id: "overhead-triceps-extension",
            name: "Overhead Triceps Extension",
            movementDescription: "Keep your elbows pointed up and close as you lower the load behind your head. Extend fully at the top and return slowly to maintain tension.",
            category: "Arms",
            tags: ["triceps", "isolation"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.dumbbells, .kettlebell, .cable, .resistanceBand],
            isCustom: false
        ),
        .init(
            id: "close-grip-bench-press",
            name: "Close-Grip Bench Press",
            movementDescription: "Use a shoulder-width or slightly narrower grip and keep your forearms vertical. Lower with elbows tucked, then press to lockout under control.",
            category: "Arms",
            tags: ["triceps", "compound"],
            hotelAlternativeMovementId: "push-up",
            allowedModalities: [.barbell, .dumbbells],
            isCustom: false
        ),
        .init(
            id: "barbell-curl",
            name: "Barbell Curl",
            movementDescription: "Keep your elbows pinned near your sides and curl without leaning your torso back. Squeeze at the top, then lower fully and slowly.",
            category: "Arms",
            tags: ["biceps", "isolation"],
            hotelAlternativeMovementId: "dumbbell-curl",
            allowedModalities: [.barbell],
            isCustom: false
        ),
        .init(
            id: "dumbbell-curl",
            name: "Dumbbell Curl",
            movementDescription: "Keep your elbows near your sides and curl the weights without swinging. Squeeze at the top, then lower fully and slowly.",
            category: "Arms",
            tags: ["biceps", "isolation", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.dumbbells, .kettlebell],
            isCustom: false
        ),
        .init(
            id: "hammer-curl",
            name: "Hammer Curl",
            movementDescription: "Use a neutral grip and keep your wrists stacked as you curl upward. Control the lowering phase to full extension on every rep.",
            category: "Arms",
            tags: ["biceps", "brachialis", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.dumbbells, .kettlebell, .resistanceBand],
            isCustom: false
        ),

        .init(
            id: "dead-bug",
            name: "Dead Bug",
            movementDescription: "Press your low back into the floor and brace before moving your limbs. Extend the opposite arm and leg slowly, then return without losing contact.",
            category: "Core",
            tags: ["core", "stability", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.bodyweight],
            isCustom: false
        ),
        .init(
            id: "pallof-press",
            name: "Pallof Press",
            movementDescription: "Stand side-on to the anchor at chest height, brace your abs and glutes, and keep your ribs stacked over your hips. Press your hands straight out without letting your torso rotate, pause briefly, then return slowly to your chest.",
            category: "Core",
            tags: ["core", "anti-rotation"],
            hotelAlternativeMovementId: "dead-bug",
            allowedModalities: [.resistanceBand, .cable],
            isCustom: false
        ),
        .init(
            id: "calf-raise",
            name: "Calf Raise",
            movementDescription: "Place the ball of your foot on a step or stable edge with your heel hanging free and keep your knees mostly straight. Drive up as high as you can through the forefoot, pause at the top, and lower slowly into a full stretch.",
            category: "Carry / Conditioning",
            tags: ["calves", "isolation", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.bodyweight, .dumbbells, .barbell, .machine],
            isCustom: false
        ),
        .init(
            id: "side-plank",
            name: "Side Plank",
            movementDescription: "Stack your shoulder over your elbow and align your hips with your torso. Lift into a straight line, brace hard, and hold steady breathing.",
            category: "Core",
            tags: ["core", "obliques", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.bodyweight],
            isCustom: false
        ),
        .init(
            id: "hanging-knee-raise",
            name: "Hanging Knee Raise",
            movementDescription: "Start from a dead hang and set your shoulders down before each rep. Curl your pelvis up and bring your knees toward your chest, then lower slowly without swinging.",
            category: "Core",
            tags: ["abs", "hip-flexors"],
            hotelAlternativeMovementId: "crunch",
            allowedModalities: [.bodyweight],
            isCustom: false
        ),
        .init(
            id: "crunch",
            name: "Crunch",
            movementDescription: "Flatten your low back and keep your chin neutral as you curl your upper spine. Lift with control, pause briefly, and lower without relaxing completely.",
            category: "Core",
            tags: ["abs", "bodyweight", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.bodyweight],
            isCustom: false
        ),

        .init(
            id: "farmer-carry",
            name: "Farmer Carry",
            movementDescription: "Pick up the loads, stand tall, and keep your ribs stacked over your hips. Walk with short controlled steps while keeping your shoulders packed.",
            category: "Carry / Conditioning",
            tags: ["grip", "conditioning", "hotel-friendly"],
            hotelAlternativeMovementId: nil,
            allowedModalities: [.dumbbells, .kettlebell],
            isCustom: false
        ),
        .init(
            id: "landmine-squat-to-press",
            name: "Landmine Squat to Press",
            movementDescription: "Lower into a squat with the bar close to your chest and stay braced. Drive up through your legs and press in one smooth motion, then return under control.",
            category: "Carry / Conditioning",
            tags: ["conditioning", "full-body", "compound"],
            hotelAlternativeMovementId: "push-up",
            allowedModalities: [.landmine],
            isCustom: false
        )
    ]
}
