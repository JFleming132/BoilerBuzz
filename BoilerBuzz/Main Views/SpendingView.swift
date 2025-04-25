import SwiftUI

import SwiftUI

struct SpendingView: View {
    @State private var spendLimit: Double = 200.0
    @State private var currentSpent: Double = 0.0
    @State private var expenses: [(name: String, amount: Double)] = []

    // Modal states
    @State private var showAddExpenseSheet = false
    @State private var showChangeLimitSheet = false

    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Progress Bar Card
                VStack(spacing: 12) {
                    Text("Monthly Spending")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    ProgressView(value: currentSpent, total: spendLimit)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(y: 2)
                        .accentColor(currentSpent > spendLimit ? .red : tertiaryColor)

                    
                    HStack {
                        Text("$\(currentSpent, specifier: "%.2f") spent")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Limit: $\(spendLimit, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // Buttons
                HStack(spacing: 20) {
                    Button(action: { showAddExpenseSheet = true }) {
                        Label("Expense", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .foregroundColor(secondaryColor)
                    }
                    
                    Button(action: { showChangeLimitSheet = true }) {
                        Label("Edit Limit", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .foregroundColor(secondaryColor)
                    }
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                
                // Expense History List
                VStack(alignment: .leading) {
                    Text("Spending History")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    List {
                        ForEach(expenses.reversed(), id: \.name) { expense in
                            HStack {
                                Text(expense.name)
                                Spacer()
                                Text("$\(expense.amount, specifier: "%.2f")")
                                    .foregroundColor(tertiaryColor)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .frame(height: 300)
                    .listStyle(.plain)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Spending Tracker")
            .sheet(isPresented: $showAddExpenseSheet) {
                AddExpenseView(currentSpent: $currentSpent, expenses: $expenses)
            }
            .sheet(isPresented: $showChangeLimitSheet) {
                ChangeLimitView(spendLimit: $spendLimit)
            }
            .onAppear {
                fetchUserDetails()
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
    }

    func fetchUserDetails() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            errorMessage = "User not found."
            showError = true
            return
        }

        let url = URL(string: backendURL + "api/spending/getUserDetails/\(userId)")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Failed to fetch user details: \(error.localizedDescription)"
                    showError = true
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    errorMessage = "Invalid server response."
                    showError = true
                }
                return
            }

            if httpResponse.statusCode != 200 {
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let message = json["message"] as? String {
                            DispatchQueue.main.async {
                                errorMessage = "Failed to fetch details: \(message)"
                                showError = true
                            }
                        } else {
                            DispatchQueue.main.async {
                                errorMessage = "Server error."
                                showError = true
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            errorMessage = "Error parsing response."
                            showError = true
                        }
                    }
                }
                return
            }

            // Parse response data
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let limit = json["limit"] as? Double,
                           let currentSpent = json["currentSpent"] as? Double,
                           let expenses = json["expenses"] as? [[String: Any]] {
                            // Update the UI with fetched data
                            DispatchQueue.main.async {
                                self.spendLimit = limit
                                self.currentSpent = currentSpent
                                self.expenses = expenses.map { expense in
                                    (name: expense["name"] as? String ?? "", amount: expense["amount"] as? Double ?? 0.0)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                errorMessage = "Invalid data format."
                                showError = true
                            }
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        errorMessage = "Failed to parse response."
                        showError = true
                    }
                }
            }
        }.resume()
    }
}


// Add Expense View (iOS Modal)
struct AddExpenseView: View {
    @Binding var currentSpent: Double
    @Binding var expenses: [(name: String, amount: Double)]
    @Environment(\.dismiss) var dismiss

    @State private var expenseName: String = ""
    @State private var expenseAmount: String = ""
    @State private var errorMessage: String?
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Expense Name", text: $expenseName)
                TextField("Amount", text: $expenseAmount)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let amount = Double(expenseAmount), amount > 0 {
                            let newExpense = (name: expenseName, amount: amount)
                            addExpenseAPI(expense: newExpense)
                        } else {
                            errorMessage = "Please enter a valid amount."
                            showError = true
                        }
                    }
                    .bold()
                }
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
    }

    func addExpenseAPI(expense: (name: String, amount: Double)) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            errorMessage = "User not found."
            showError = true
            return
        }

        let url = URL(string: backendURL + "api/spending/addExpense/\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": expense.name,
            "amount": expense.amount
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Failed to add expense: \(error.localizedDescription)"
                    showError = true
                }
                return
            }

            // Check if response is valid and has a non-200 status code
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    errorMessage = "Invalid server response."
                    showError = true
                }
                return
            }

            // If status code is not 200, try to parse the error message from the API
            if httpResponse.statusCode != 200 {
                if let data = data {
                    do {
                        // Try to decode the response data for an error message
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let message = json["message"] as? String {
                            DispatchQueue.main.async {
                                errorMessage = "Failed to add expense: \(message)"
                                showError = true
                            }
                        } else {
                            DispatchQueue.main.async {
                                errorMessage = "Failed to add expense: Server error."
                                showError = true
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            errorMessage = "Failed to add expense: Parsing error."
                            showError = true
                        }
                    }
                }
                return
            }

            // If the response is successful, update UI
            DispatchQueue.main.async {
                expenses.append(expense)
                currentSpent += expense.amount
                dismiss()
            }
        }.resume()
    }
}



// Change Limit View (iOS Modal)
struct ChangeLimitView: View {
    @Binding var spendLimit: Double
    @Environment(\.dismiss) var dismiss

    @State private var newLimit: String = ""
    @State private var errorMessage: String?
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("New Monthly Limit", text: $newLimit)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Change Limit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let amount = Double(newLimit), amount > 0 {
                            updateLimitAPI(newLimit: amount)
                        } else {
                            errorMessage = "Please enter a valid limit."
                            showError = true
                        }
                    }
                    .bold()
                }
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
    }

    func updateLimitAPI(newLimit: Double) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            errorMessage = "User not found."
            showError = true
            return
        }

        let url = URL(string: backendURL + "api/spending/editLimit/\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "newLimit": newLimit
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Failed to update limit: \(error.localizedDescription)"
                    showError = true
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    errorMessage = "Invalid server response."
                    showError = true
                }
                return
            }

            if httpResponse.statusCode != 200 {
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let message = json["message"] as? String {
                            DispatchQueue.main.async {
                                errorMessage = "Failed to update limit: \(message)"
                                showError = true
                            }
                        } else {
                            DispatchQueue.main.async {
                                errorMessage = "Server error."
                                showError = true
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            errorMessage = "Error parsing response."
                            showError = true
                        }
                    }
                }
                return
            }

            // If the response is successful, update UI
            DispatchQueue.main.async {
                self.spendLimit = newLimit
                dismiss()
            }
        }.resume()
    }
}


