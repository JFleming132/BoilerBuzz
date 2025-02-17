import SwiftUI

struct SpendingView: View {
    @State private var spendLimit: Double = 200.0
    @State private var currentSpent: Double = 0.0
    @State private var expenses: [(name: String, amount: Double)] = []
    
    // Modal states
    @State private var showAddExpenseSheet = false
    @State private var showChangeLimitSheet = false
    
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
                        .scaleEffect(y: 2) // Thicker bar
                        .accentColor(.gold)
                    
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
                            .foregroundColor(.black)
                    }
                    
                    Button(action: { showChangeLimitSheet = true }) {
                        Label("Edit Limit", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .foregroundColor(.black)
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
                        ForEach(expenses, id: \.name) { expense in
                            HStack {
                                Text(expense.name)
                                Spacer()
                                Text("$\(expense.amount, specifier: "%.2f")")
                                    .foregroundColor(.gold)
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
        }
    }
}

// Add Expense View (iOS Modal)
struct AddExpenseView: View {
    @Binding var currentSpent: Double
    @Binding var expenses: [(name: String, amount: Double)]
    @Environment(\.dismiss) var dismiss
    
    @State private var expenseName: String = ""
    @State private var expenseAmount: String = ""
    
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
                            expenses.append((name: expenseName, amount: amount))
                            currentSpent += amount
                        }
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// Change Limit View (iOS Modal)
struct ChangeLimitView: View {
    @Binding var spendLimit: Double
    @Environment(\.dismiss) var dismiss
    
    @State private var newLimit: String = ""
    
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
                            spendLimit = amount
                        }
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// Custom Color Extension
extension Color {
    static let gold = Color(red: 0.85, green: 0.65, blue: 0.13)
}

#Preview {
    SpendingView()
}

