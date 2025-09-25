//
//  ContentView.swift
//  MindSphere
//
//  Created by IGOR on 20/09/2025.
//

import SwiftUI
import Charts

// MARK: - Data Models
struct MoodEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let mood: Mood
    let quickAnswers: [String]
    
    enum CodingKeys: String, CodingKey {
        case date, mood, quickAnswers
    }
    
    enum Mood: String, CaseIterable, Codable {
        case happy = "😊"
        case calm = "😌"
        case stressed = "😰"
        case tired = "😴"
        case excited = "🤩"
        case sad = "😢"
        case angry = "😠"
        case neutral = "😐"
        
        var name: String {
            switch self {
            case .happy: return "Happy"
            case .calm: return "Calm"
            case .stressed: return "Stressed"
            case .tired: return "Tired"
            case .excited: return "Excited"
            case .sad: return "Sad"
            case .angry: return "Angry"
            case .neutral: return "Neutral"
            }
        }
        
        var value: Double {
            switch self {
            case .happy: return 5
            case .excited: return 4.5
            case .calm: return 4
            case .neutral: return 3
            case .tired: return 2.5
            case .sad: return 2
            case .stressed: return 1.5
            case .angry: return 1
            }
        }
    }
}

struct DiaryEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case date, content
    }
    
    var preview: String {
        String(content.prefix(100)) + (content.count > 100 ? "..." : "")
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published var currentScreen: Screen = .dailyCheckIn
    @Published var moodEntries: [MoodEntry] = []
    @Published var diaryEntries: [DiaryEntry] = []
    @Published var selectedMood: MoodEntry.Mood?
    @Published var selectedQuickAnswers: Set<String> = []
    @Published var diaryText = ""
    @Published var editingEntry: DiaryEntry?
    @Published var showingEntryDetail = false
    
    enum Screen {
        case dailyCheckIn, diary, statistics, settings
    }
    
    init() {
        loadData()
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(moodEntries) {
            UserDefaults.standard.set(encoded, forKey: "moodEntries")
        }
        if let encoded = try? JSONEncoder().encode(diaryEntries) {
            UserDefaults.standard.set(encoded, forKey: "diaryEntries")
        }
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "moodEntries"),
           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            moodEntries = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "diaryEntries"),
           let decoded = try? JSONDecoder().decode([DiaryEntry].self, from: data) {
            diaryEntries = decoded
        }
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func saveMoodEntry() {
        guard let mood = selectedMood else { return }
        let entry = MoodEntry(date: Date(), mood: mood, quickAnswers: Array(selectedQuickAnswers))
        moodEntries.append(entry)
        selectedMood = nil
        selectedQuickAnswers.removeAll()
        saveData()
    }
    
    func saveDiaryEntry() {
        if let editing = editingEntry {
            if let index = diaryEntries.firstIndex(where: { $0.id == editing.id }) {
                let updatedEntry = DiaryEntry(date: editing.date, content: diaryText)
                diaryEntries[index] = updatedEntry
            }
            editingEntry = nil
        } else {
            let entry = DiaryEntry(date: Date(), content: diaryText)
            diaryEntries.append(entry)
        }
        diaryText = ""
        saveData()
    }
    
    func resetProgress() {
        moodEntries.removeAll()
        diaryEntries.removeAll()
        saveData()
    }
    
    func deleteDiaryEntry(_ entry: DiaryEntry) {
        diaryEntries.removeAll { $0.id == entry.id }
        saveData()
    }
    
    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let hasEntry = moodEntries.contains { calendar.isDate($0.date, inSameDayAs: date) }
            if hasEntry {
                streak += 1
            } else if i > 0 {
                break
            }
        }
        return streak
    }
    
    var mostCommonMood: MoodEntry.Mood? {
        let moodCounts = Dictionary(grouping: moodEntries, by: { $0.mood })
            .mapValues { $0.count }
        return moodCounts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Color Theme
extension Color {
    static let mindBackground = Color(hex: "0e0e0e")
    static let mindPrimary = Color(hex: "28a809")
    static let mindSecondary = Color(hex: "e6053a")
    static let mindAccent = Color(hex: "d17305")
    static let mindSurface = Color(hex: "1a1c1e")
    static let mindTextSecondary = Color(hex: "b3b3b3")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Animated Particle View
struct ParticleView: View {
    @State private var isAnimating = false
    let particles = Array(0..<20)
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.self) { _ in
                Circle()
                    .fill(Color.mindAccent.opacity(0.6))
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(
                        x: isAnimating ? CGFloat.random(in: 50...300) : CGFloat.random(in: 50...300),
                        y: isAnimating ? CGFloat.random(in: 100...600) : CGFloat.random(in: 100...600)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Onboarding Views
struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color.mindBackground.ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                OnboardingPage1()
                    .tag(0)
                OnboardingPage2()
                    .tag(1)
                OnboardingPage3()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
        VStack {
                Spacer()
                
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.mindTextSecondary)
                    }
                    
                    Spacer()
                    
                    Button(currentPage == 2 ? "Get Started" : "Next") {
                        if currentPage == 2 {
                            appState.hasCompletedOnboarding = true
                            appState.saveData()
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.mindPrimary)
                    .cornerRadius(25)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ParticleView()
                .frame(height: 300)
            
            Text("Track your mind daily")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct OnboardingPage2: View {
    @State private var isOpen = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.mindSurface)
                    .frame(width: 200, height: 250)
                    .rotation3DEffect(
                        .degrees(isOpen ? -15 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.mindAccent.opacity(0.3))
                    .frame(width: 180, height: 230)
                    .rotation3DEffect(
                        .degrees(isOpen ? 15 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isOpen.toggle()
                }
            }
            
            Text("Reflect on your thoughts and emotions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct OnboardingPage3: View {
    @State private var isFormed = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                ForEach(0..<8) { i in
                    Circle()
                        .fill(Color.mindAccent.opacity(0.7))
                        .frame(width: 30, height: 30)
                        .offset(
                            x: isFormed ? 0 : cos(Double(i) * .pi / 4) * 80,
                            y: isFormed ? 0 : sin(Double(i) * .pi / 4) * 80
                        )
                        .animation(
                            .easeInOut(duration: 2)
                                .delay(Double(i) * 0.1)
                                .repeatForever(autoreverses: true),
                            value: isFormed
                        )
                }
                
                Circle()
                    .fill(Color.mindPrimary.opacity(0.3))
                    .frame(width: isFormed ? 120 : 60)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isFormed
                    )
            }
            .frame(height: 200)
            .onAppear {
                isFormed = true
            }
            
            Text("Grow calm, balanced, and aware")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Daily Check-In Views
struct DailyCheckInView: View {
    @ObservedObject var appState: AppState
    
    let quickAnswers = ["Relaxed", "Focused", "Overwhelmed", "Energetic", "Peaceful", "Anxious", "Motivated", "Drained"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("How do you feel today?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                    ForEach(MoodEntry.Mood.allCases, id: \.self) { mood in
                        MoodButton(mood: mood, isSelected: appState.selectedMood == mood) {
                            withAnimation(.spring()) {
                                appState.selectedMood = mood
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                if appState.selectedMood != nil {
                    VStack(spacing: 16) {
                        Text("Quick feelings")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(quickAnswers, id: \.self) { answer in
                                QuickAnswerButton(
                                    text: answer,
                                    isSelected: appState.selectedQuickAnswers.contains(answer)
                                ) {
                                    if appState.selectedQuickAnswers.contains(answer) {
                                        appState.selectedQuickAnswers.remove(answer)
                                    } else {
                                        appState.selectedQuickAnswers.insert(answer)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                if appState.selectedMood != nil {
                    Button(action: {
                        withAnimation {
                            appState.saveMoodEntry()
                        }
                    }) {
                        Text("Save Entry")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mindPrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Recent Mood Entries
                if !appState.moodEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Mood Entries")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(appState.moodEntries.suffix(5).reversed(), id: \.id) { entry in
                            MoodEntryRow(entry: entry)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 16)
                }
                
                Spacer(minLength: 100)
            }
        }
    }
}

struct MoodEntryRow: View {
    let entry: MoodEntry
    
    var body: some View {
        HStack {
            Text(entry.mood.rawValue)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.mood.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.mindTextSecondary)
                
                if !entry.quickAnswers.isEmpty {
                    Text(entry.quickAnswers.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.mindAccent)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.mindSurface)
        )
    }
}

struct MoodButton: View {
    let mood: MoodEntry.Mood
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 8) {
                Text(mood.rawValue)
                    .font(.largeTitle)
                    .scaleEffect(isSelected ? 1.3 : (isPressed ? 1.1 : 1.0))
                
                Text(mood.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .mindTextSecondary)
            }
            .frame(width: 80, height: 80)
            .background(
                Circle()
                    .fill(isSelected ? Color.mindAccent.opacity(0.3) : Color.mindSurface)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.mindAccent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .animation(.spring(), value: isSelected)
        .animation(.spring(), value: isPressed)
    }
}

struct QuickAnswerButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .mindTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.mindPrimary.opacity(0.3) : Color.mindSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.mindPrimary : Color.clear, lineWidth: 1)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Diary Views
struct DiaryView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Diary")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.mindSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.mindAccent.opacity(0.3), lineWidth: 1)
                            )
                        
                        if appState.diaryText.isEmpty {
                            Text("Write your thoughts here...")
                                .foregroundColor(.mindTextSecondary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $appState.diaryText)
                            .foregroundColor(.white)
                            .background(Color.clear)
                            .scrollContentBackground(.hidden)
                    }
                    .frame(minHeight: 200)
                    .padding()
                    
                    if !appState.diaryText.isEmpty || appState.editingEntry != nil {
                        Button(action: {
                            appState.saveDiaryEntry()
                        }) {
                            Text(appState.editingEntry != nil ? "Update Entry" : "Save Entry")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.mindPrimary)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                if !appState.diaryEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Previous Entries")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(appState.diaryEntries.sorted(by: { $0.date > $1.date })) { entry in
                            DiaryEntryRow(entry: entry, appState: appState)
                                .padding(.horizontal)
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .onAppear {
            if let editing = appState.editingEntry {
                appState.diaryText = editing.content
            }
        }
    }
}

struct DiaryEntryRow: View {
    let entry: DiaryEntry
    @ObservedObject var appState: AppState
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.mindTextSecondary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Edit") {
                        appState.editingEntry = entry
                        appState.diaryText = entry.content
                    }
                    .font(.caption)
                    .foregroundColor(.mindAccent)
                    
                    Button("Delete") {
                        showingDeleteAlert = true
                    }
                    .font(.caption)
                    .foregroundColor(.mindSecondary)
                }
            }
            
            Text(entry.preview)
                .font(.body)
                .foregroundColor(.white)
                .lineLimit(3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.mindSurface)
        )
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation {
                    appState.deleteDiaryEntry(entry)
                }
            }
        } message: {
            Text("Are you sure you want to delete this diary entry? This action cannot be undone.")
        }
    }
}

// MARK: - Statistics Views
struct StatisticsView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Your Progress")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Streak Section
                VStack(spacing: 16) {
                    HStack {
                        ForEach(0..<min(appState.currentStreak, 7), id: \.self) { _ in
                            Circle()
                                .fill(Color.mindAccent)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .fill(Color.mindAccent.opacity(0.3))
                                        .scaleEffect(1.5)
                                        .animation(.easeInOut(duration: 1).repeatForever(), value: true)
                                )
                        }
                        if appState.currentStreak > 7 {
                            Text("+\(appState.currentStreak - 7)")
                                .foregroundColor(.mindAccent)
                                .font(.headline)
                        }
                    }
                    
                    Text("\(appState.currentStreak) day streak")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.mindSurface)
                )
                .padding(.horizontal)
                
                // Mood Chart
                if !appState.moodEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Mood Trends")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Chart(appState.moodEntries.suffix(14)) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Mood", entry.mood.value)
                            )
                            .foregroundStyle(Color.mindAccent)
                        }
                        .frame(height: 200)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.mindSurface)
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Summary Stats
                VStack(spacing: 16) {
                    StatCard(
                        title: "Total Entries",
                        value: "\(appState.moodEntries.count)",
                        icon: "chart.bar.fill"
                    )
                    
                    if let mostCommon = appState.mostCommonMood {
                        StatCard(
                            title: "Most Common Mood",
                            value: "\(mostCommon.rawValue) \(mostCommon.name)",
                            icon: "heart.fill"
                        )
                    }
                    
                    StatCard(
                        title: "Diary Entries",
                        value: "\(appState.diaryEntries.count)",
                        icon: "book.fill"
                    )
                }
                .padding(.horizontal)
                
                Spacer(minLength: 100)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.mindAccent)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.mindTextSecondary)
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.mindSurface)
        )
    }
}

// MARK: - Settings Views
struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var showingResetAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Button(action: {
                        appState.currentScreen = .statistics
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.mindAccent)
                            Text("View Statistics")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.mindTextSecondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mindSurface)
                        )
                    }
                    
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.mindSecondary)
                            Text("Reset Progress")
                                .foregroundColor(.mindSecondary)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mindSurface)
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 100)
            }
        }
        .alert("Reset Progress", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                appState.resetProgress()
            }
        } message: {
            Text("This will permanently delete all your mood entries and diary entries. This action cannot be undone.")
        }
    }
}

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        ZStack {
            Color.mindBackground.ignoresSafeArea()
            
            if !appState.hasCompletedOnboarding {
                OnboardingView(appState: appState)
            } else {
                VStack {
                    // Main Content
                    switch appState.currentScreen {
                    case .dailyCheckIn:
                        DailyCheckInView(appState: appState)
                    case .diary:
                        DiaryView(appState: appState)
                    case .statistics:
                        StatisticsView(appState: appState)
                    case .settings:
                        SettingsView(appState: appState)
                    }
                    
                    // Bottom Navigation
                    HStack(spacing: 0) {
                        TabButton(
                            icon: "brain.head.profile",
                            title: "Check-In",
                            isSelected: appState.currentScreen == .dailyCheckIn
                        ) {
                            appState.currentScreen = .dailyCheckIn
                        }
                        
                        TabButton(
                            icon: "book.fill",
                            title: "Diary",
                            isSelected: appState.currentScreen == .diary
                        ) {
                            appState.currentScreen = .diary
                        }
                        
                        TabButton(
                            icon: "chart.bar.fill",
                            title: "Stats",
                            isSelected: appState.currentScreen == .statistics
                        ) {
                            appState.currentScreen = .statistics
                        }
                        
                        TabButton(
                            icon: "gearshape.fill",
                            title: "Settings",
                            isSelected: appState.currentScreen == .settings
                        ) {
                            appState.currentScreen = .settings
                        }
                    }
                    .padding(.top, 8)
                    .background(
                        Rectangle()
                            .fill(Color.mindSurface)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
        }
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .mindAccent : .mindTextSecondary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .mindAccent : .mindTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ContentView()
}
