import SwiftUI

struct IdentificationView: View {
    // MARK: - State Variables for User Input
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var alias: String = ""
    @State private var school: String = ""
    @State private var year: String = ""

    @State private var verificationResult: String? = nil
    @State private var isSchoolPickerActive = false

    @State private var isVerifying = false
    @State private var progress: Double = 0.0
    @State private var currentStepMessage: String = ""
    @State private var timer: Timer?

    @State private var isAlreadyIdentified = false

    var body: some View {
        NavigationView {
            Group {
                if isAlreadyIdentified {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("You’re identified ✅")
                            .font(.title3)
                            .multilineTextAlignment(.center)

                        Text("Thanks for verifying your Purdue information. You're all set!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    Form {
                        // Personal Info
                        Section(header: Text("Personal Information").font(.headline)) {
                            TextField("First Name", text: $firstName)
                            TextField("Last Name", text: $lastName)
                        }

                        // Purdue Info
                        Section(header: Text("Purdue Info").font(.headline)) {
                            TextField("Purdue Alias", text: $alias)

                            HStack {
                                Text("School")
                                Spacer()
                                Text(school.isEmpty ? "Select" : school)
                                    .foregroundColor(school.isEmpty ? .gray : .primary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isSchoolPickerActive = true
                            }
                            .background(
                                NavigationLink("", destination: SchoolSelectionView(selectedSchool: $school), isActive: $isSchoolPickerActive)
                                    .opacity(0)
                            )

                            Picker("Year", selection: $year) {
                                Text("Freshman").tag("Freshman")
                                Text("Sophomore").tag("Sophomore")
                                Text("Junior").tag("Junior")
                                Text("Senior").tag("Senior")
                            }
                        }

                        // Submit Section
                        Section {
                            Button(action: submitIdentification) {
                                Text("Submit Identification")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .disabled(isVerifying)

                            if let result = verificationResult {
                                Text(result)
                                    .foregroundColor(result.contains("✓") ? .green : .red)
                                    .font(.subheadline)
                                    .padding(.top, 4)
                            }
                        }

                        // Progress
                        if isVerifying {
                            VStack(alignment: .leading, spacing: 8) {
                                ProgressView(value: progress)
                                    .animation(.linear(duration: 0.2), value: progress)

                                Text(currentStepMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top)
                        }
                    }
                }
            }
            .navigationTitle("Identification")
            .onAppear {
                checkIdentificationStatus()
            }
        }
    }

    // MARK: - Helper: Get User ID from UserDefaults
    func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: "userId")
    }

    // MARK: - Check if User is Already Identified
    func checkIdentificationStatus() {
        guard let userId = getUserId(),
              let url = URL(string: backendURL + "api/profile/isIdentified/\(userId)") else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let isIdentified = json["isIdentified"] as? Bool {
                DispatchQueue.main.async {
                    self.isAlreadyIdentified = isIdentified
                }
            }
        }.resume()
    }

    // MARK: - Submit Verification
    func submitIdentification() {
        guard let userId = getUserId() else {
            verificationResult = "❌ Unable to find user ID."
            return
        }

        isVerifying = true
        verificationResult = nil
        progress = 0.0
        currentStepMessage = "Starting verification..."

        let steps = [
            (0.1, "Verifying name..."),
            (0.3, "Verifying alias..."),
            (0.5, "Verifying school..."),
            (0.7, "Cross-checking records..."),
            (0.9, "Finalizing...")
        ]

        var currentStepIndex = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            guard currentStepIndex < steps.count else { return }
            let (stepProgress, message) = steps[currentStepIndex]
            progress = stepProgress
            currentStepMessage = message
            currentStepIndex += 1
        }

        let inputFirst = firstName.lowercased().trimmingCharacters(in: .whitespaces)
        let inputLast = lastName.lowercased().trimmingCharacters(in: .whitespaces)
        let inputAlias = alias.lowercased()
        let inputSchool = school.lowercased()

        let fullNameRaw = "\(firstName) \(lastName)"
        guard let encodedName = fullNameRaw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: backendURL + "/api/profile/aliasLookup/\(encodedName)?userId=\(userId)") else {
            verificationResult = "❌ Invalid URL."
            isVerifying = false
            timer?.invalidate()
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    verificationResult = "❌ Request failed: \(error.localizedDescription)"
                    isVerifying = false
                    timer?.invalidate()
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    verificationResult = "❌ Invalid response from server."
                    isVerifying = false
                    timer?.invalidate()
                }
                return
            }

            let aliasMatch = (json["aliasMatch"] as? Bool) ?? false
            let fetchedAlias = (json["alias"] as? String ?? "").lowercased()
            let fetchedName = (json["name"] as? String ?? "").lowercased()
            let fetchedSchool = (json["school"] as? String ?? "").lowercased()

            let nameParts = fetchedName.split(separator: " ").map { $0.lowercased() }
            let fetchedFirst = nameParts.first ?? ""
            let fetchedLast = nameParts.last ?? ""

            let aliasExactMatch = inputAlias == fetchedAlias
            let nameExactMatch = inputFirst == fetchedFirst && inputLast == fetchedLast
            let schoolExactMatch = inputSchool == fetchedSchool

            DispatchQueue.main.async {
                progress = 1.0
                currentStepMessage = "Complete!"
                timer?.invalidate()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isVerifying = false

                    if aliasMatch && aliasExactMatch && nameExactMatch && schoolExactMatch {
                        verificationResult = "✅ Identity verified!"
                        isAlreadyIdentified = true // ✅ optional local update
                    } else {
                        var message = "❌ We couldn't verify your identity.\n\nPlease check the following:"
                        
                        if !aliasMatch {
                            message += "\n• The alias you entered does not match the email from your BoilerBuzz registration."
                        }
                        if !aliasExactMatch {
                            message += "\n• The alias you entered doesn't match the Purdue database for the name you entered."
                        }
                        if !nameExactMatch {
                            message += "\n• Your first or last name doesn't match a student in the Purdue database."
                        }
                        if !schoolExactMatch {
                            message += "\n• The school you selected doesn't match the Purdue database for the name you entered."
                        }

                        verificationResult = message
                    }
                }
            }
        }.resume()
    }
}

// MARK: - School Picker View
struct SchoolSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedSchool: String
    @State private var searchText = ""

    var filteredSchools: [String] {
        if searchText.isEmpty {
            return purdueSchools
        } else {
            return purdueSchools.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        List {
            Section {
                TextField("Search Schools", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }

            ForEach(filteredSchools, id: \.self) { school in
                Button(action: {
                    selectedSchool = school
                    dismiss()
                }) {
                    Text(school)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Select School")
    }
}

// MARK: - Purdue School List
let purdueSchools = [
    "Aeronautics and Astro", "Agricultural and Biological Engineering", "Agricultural Engr", "Agriculture",
    "Allied Health", "Architecture Tech", "Arts and Letters", "Arts and Sciences", "Aviation Technology",
    "Biomedical Engineering", "Bldg Constr and Contract", "Bus and Mgmt Sciences", "Business",
    "Chemical Engineering", "Civil Engineering", "Civil Engr Tech", "Community College", "Comp Manuf Technology",
    "Computer Graphics Technology", "Computer Technology", "Construction Engr", "Construction Tech",
    "Consumer and Family Sci", "Continuing Studies", "Dental Auxillary Educ", "Developmental Studies",
    "Distance Learning", "Education", "Electrical and Computer Engineering", "Electrical Engineering",
    "Electrical Engr Tech", "Engineering", "Engineering and Technology", "Engr and Technology IPLS",
    "Faculties Prof Studies", "Fine and Performing Arts", "First-Year Engineering", "Forestry", "General Studies",
    "Graduate School", "Health Sciences", "Indiana UN PGM IPLS", "Industrial Engineering", "Industrial Technology",
    "Interdisciplinary Engr", "Labor Studies", "Land Surveying", "Liberal Arts", "Liberal Arts and Science",
    "Liberal Arts and Social Sciences", "Management", "Materials Engineering", "Mechanical Engineering",
    "Mechanical Engr Tech", "Music", "NC Community College", "Nuclear Engineering", "Nursing",
    "Organizational Leadership and Supervision", "P E Hlth and Rec Studies", "Pharmacy and Pharm Sci",
    "Physical Education", "Polytechnic Institute", "Pre-Major", "Pre-Pharmacy", "Pre-Technology",
    "Professional Studies", "Public", "Science", "Science IPLS", "Supervision", "Technical Graphics", "Technology",
    "Temporary", "Undergraduate Studies Program", "Univ Affiliated Prgms", "University Division",
    "Veterinary Medicine", "Visual and Performing Arts"
]

struct IdentificationView_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationView()
    }
}
