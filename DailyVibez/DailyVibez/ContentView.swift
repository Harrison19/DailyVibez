//
//  ContentView.swift
//  DailyVibez
//
//  Created by Harrison Kimatian on 8/11/24.
//

import SwiftUI

struct MoodEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var colorGradientStart: CodableColor
    var colorGradientEnd: CodableColor
    var rating: Int
    var notes: String
}

struct CodableColor: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    init(color: Color) {
        if let components = color.cgColor?.components, components.count >= 4 {
            self.red = Double(components[0])
            self.green = Double(components[1])
            self.blue = Double(components[2])
            self.opacity = Double(components[3])
        } else {
            self.red = 0
            self.green = 0
            self.blue = 0
            self.opacity = 1
        }
    }
    
    func toColor() -> Color {
        return Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

struct ContentView: View {
    @State private var moodEntries: [MoodEntry] = []
    @State private var showingDetail = false
    @State private var selectedEntry: MoodEntry?
    @State private var isEditing = false
    @State private var selectedEntries = Set<UUID>()
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button(action: {
                        isEditing.toggle()
                        selectedEntries.removeAll()
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                    }
                    .padding()
                    
                    Spacer()
                    
                    if isEditing {
                        Button(action: deleteSelectedEntries) {
                            Image(systemName: "trash")
                        }
                        .padding()
                    } else {
                        Button(action: addNewEntry) {
                            Image(systemName: "plus")
                        }
                        .padding()
                    }
                }
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        ForEach(moodEntries.sorted(by: { $0.date < $1.date })) { entry in
                            MoodCircleView(entry: entry, isSelected: selectedEntries.contains(entry.id))
                                .onTapGesture {
                                    if isEditing {
                                        toggleSelection(for: entry)
                                    } else {
                                        selectedEntry = entry
                                        showingDetail = true
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Text("Mood Calendar").bold(), trailing: Text("Avg: \(averageRating, specifier: "%.2f")").bold())
            .sheet(isPresented: $showingDetail) {
                if let entry = selectedEntry {
                    DetailView(entry: $moodEntries[moodEntries.firstIndex(where: { $0.id == entry.id })!])
                }
            }
            .onAppear(perform: loadData)
        }
    }
    
    func addNewEntry() {
        let newEntry = MoodEntry(date: Date(), colorGradientStart: CodableColor(color: .blue), colorGradientEnd: CodableColor(color: .purple), rating: 3, notes: "")
        moodEntries.append(newEntry)
        saveData()
    }
    
    func toggleSelection(for entry: MoodEntry) {
        if selectedEntries.contains(entry.id) {
            selectedEntries.remove(entry.id)
        } else {
            selectedEntries.insert(entry.id)
        }
    }
    
    func deleteSelectedEntries() {
        moodEntries.removeAll { selectedEntries.contains($0.id) }
        selectedEntries.removeAll()
        saveData()
    }
    
    func saveData() {
        if let encodedData = try? JSONEncoder().encode(moodEntries) {
            UserDefaults.standard.set(encodedData, forKey: "MoodEntries")
        }
    }
    
    func loadData() {
        if let savedData = UserDefaults.standard.data(forKey: "MoodEntries"),
           let decodedData = try? JSONDecoder().decode([MoodEntry].self, from: savedData) {
            moodEntries = decodedData
        }
    }
    
    var averageRating: Double {
        guard !moodEntries.isEmpty else { return 0.0 }
        let total = moodEntries.map { $0.rating }.reduce(0, +)
        return Double(total) / Double(moodEntries.count)
    }
}

struct MoodCircleView: View {
    var entry: MoodEntry
    var isSelected: Bool

    var body: some View {
        VStack {
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [entry.colorGradientStart.toColor(), entry.colorGradientEnd.toColor()]), startPoint: .top, endPoint: .bottom))
                .frame(width: 80, height: 80)
                .overlay(
                    VStack {
                        Text(dateString(entry.date))
                            .font(.caption2)
                            .foregroundColor(.white)
                        Text("\(entry.rating)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 4)
                )
        }
        .padding(4)
    }
    
    func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct DetailView: View {
    @Binding var entry: MoodEntry

    var body: some View {
        Form {
            DatePicker("Date", selection: $entry.date, displayedComponents: .date)
            ColorPicker("Gradient Start", selection: Binding(get: {
                entry.colorGradientStart.toColor()
            }, set: {
                entry.colorGradientStart = CodableColor(color: $0)
            }))
            ColorPicker("Gradient End", selection: Binding(get: {
                entry.colorGradientEnd.toColor()
            }, set: {
                entry.colorGradientEnd = CodableColor(color: $0)
            }))
            Stepper("Rating: \(entry.rating)", value: $entry.rating, in: 1...5)
            Section(header: Text("Notes")) { // Adding the Notes label back
                TextEditor(text: $entry.notes)
                    .frame(height: 100)
            }
        }
        .navigationTitle("Edit Mood Entry")
        .onDisappear(perform: saveEntry)
    }

    func saveEntry() {
        if let encodedData = try? JSONEncoder().encode(entry) {
            UserDefaults.standard.set(encodedData, forKey: entry.id.uuidString)
        }
    }
}
