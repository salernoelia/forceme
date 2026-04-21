Implementing **Dynamic Island** content in iOS is handled through the **ActivityKit** and **WidgetKit** frameworks. In Apple's ecosystem, Dynamic Island views are part of a **Live Activity**.

### 1. Project Configuration
Before writing code, you must enable the capability in your project.

* **Info.plist:** Add the key `NSSupportsLiveActivities` and set it to `YES`.
* **Widget Extension:** If you don't have one, go to **File > New > Target** and select **Widget Extension**. Ensure "Include Live Activity" is checked.

---

### 2. Define Activity Attributes
You need a structure that conforms to `ActivityAttributes`. This defines what data is **static** (never changes) and what is **dynamic** (the `ContentState`).

```swift
import ActivityKit
import Foundation

struct PizzaDeliveryAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic data: changes during the activity
        var driverName: String
        var estimatedDeliveryTime: Date
    }

    // Static data: set once at the start
    var orderNumber: Int
    var pizzaType: String
}
```

---

### 3. Create the Dynamic Island UI
In your Widget Extension, you define an `ActivityConfiguration`. The Dynamic Island has four distinct presentation states you must implement:

1.  **Expanded:** Appears when the user long-presses the island.
2.  **Compact Leading:** The left side of the "pill" when one activity is active.
3.  **Compact Trailing:** The right side of the "pill".
4.  **Minimal:** A circular view used when multiple apps have active Live Activities.



```swift
import WidgetKit
import SwiftUI

struct PizzaWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PizzaDeliveryAttributes.self) { context in
            // UI for the Lock Screen (Banner)
            VStack {
                Text("Order #\(context.attributes.orderNumber)")
                Text("Driver: \(context.state.driverName)")
            }
        } dynamicIsland: { context in
            DynamicIsland {
                // 1. Expanded View
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(context.attributes.pizzaType)", systemImage: "cart")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.estimatedDeliveryTime, style: .timer)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Driver: \(context.state.driverName)")
                }
            } compactLeading: {
                // 2. Compact Leading
                Image(systemName: "bag")
            } compactTrailing: {
                // 3. Compact Trailing
                Text(context.state.estimatedDeliveryTime, style: .timer)
            } minimal: {
                // 4. Minimal (Multiple activities)
                Image(systemName: "bag")
            }
        }
    }
}
```

---

### 4. Lifecycle Management
You control the activity from your main app using the `Activity` class.

#### Start the Activity
```swift
let attributes = PizzaDeliveryAttributes(orderNumber: 123, pizzaType: "Margherita")
let initialState = PizzaDeliveryAttributes.ContentState(driverName: "Alice", estimatedDeliveryTime: Date().addingTimeInterval(1800))

do {
    let _ = try Activity.request(attributes: attributes, content: .init(state: initialState, staleDate: nil))
} catch {
    print("Error starting Live Activity: \(error.localizedDescription)")
}
```

#### Update the Activity
To change the content (e.g., a new driver or updated time), use the `update` method.
```swift
Task {
    let updatedState = PizzaDeliveryAttributes.ContentState(driverName: "Bob", estimatedDeliveryTime: Date().addingTimeInterval(900))
    for activity in Activity<PizzaDeliveryAttributes>.activities {
        await activity.update(using: updatedState)
    }
}
```

#### End the Activity
Always end the activity once the task is finished to free up the system island.
```swift
Task {
    for activity in Activity<PizzaDeliveryAttributes>.activities {
        await activity.end(dismissalPolicy: .immediate)
    }
}
```

### Technical Constraints to Remember
* **Data Size:** The `ContentState` payload must be small (under 4KB).
* **No Network/Images:** You cannot perform network requests or load `AsyncImage` directly within the widget code. Images must be in the app bundle or passed via shared **App Groups**.
* **Refresh Rate:** Updates are managed by the system; if you update too frequently, the system may throttle your activity.