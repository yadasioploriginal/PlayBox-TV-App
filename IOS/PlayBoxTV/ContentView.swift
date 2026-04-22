import SwiftUI
import AVKit

// MARK: - Models
struct Channel: Identifiable {
    let id = UUID()
    let name: String
    let desc: String
    let icon: String
    let urlString: String
}

let mockChannels = [
    Channel(name: "PlayboxTV", desc: "Oficjalny kanał na żywo", icon: "📺", urlString: "https://ogladaj.playboxtv.pl.eu.org/hls/playboxtv.m3u8")
]

// MARK: - Main View
struct ContentView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.selected.iconColor = UIColor(red: 229/255, green: 62/255, blue: 62/255, alpha: 1.0)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 229/255, green: 62/255, blue: 62/255, alpha: 1.0)]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Główna", systemImage: "tv")
                }
            
            AboutView()
                .tabItem {
                    Label("O aplikacji", systemImage: "info.circle")
                }
        }
        .accentColor(Color(red: 229/255, green: 62/255, blue: 62/255))
        .preferredColorScheme(.dark)
    }
}

// MARK: - Home View
struct HomeView: View {
    @State private var selectedChannel: Channel?
    @State private var isPlayerPresented = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.03).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Oglądaj\nna żywo 📺")
                                .font(.system(size: 32, weight: .heavy, design: .default))
                                .lineSpacing(4)
                            Text("Wybierz kanał i ciesz się streamem")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        ForEach(mockChannels) { channel in
                            ChannelCard(channel: channel)
                                .onTapGesture {
                                    selectedChannel = channel
                                    isPlayerPresented = true
                                }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 0) {
                        Text("Playbox")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                        Text("TV")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(Color(red: 229/255, green: 62/255, blue: 62/255))
                    }
                }
            }
            .fullScreenCover(isPresented: $isPlayerPresented) {
                if let channel = selectedChannel {
                    PlayerContainerView(channel: channel)
                }
            }
        }
    }
}

// MARK: - Channel Card
struct ChannelCard: View {
    let channel: Channel
    @State private var isBlinking = false
    
    var body: some View {
        HStack(spacing: 14) {
            Text(channel.icon)
                .font(.system(size: 24))
                .frame(width: 50, height: 50)
                .background(Color(white: 0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(channel.desc)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(red: 229/255, green: 62/255, blue: 62/255))
                    .frame(width: 6, height: 6)
                    .opacity(isBlinking ? 0.2 : 1.0)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 0.7).repeatForever()) {
                            isBlinking.toggle()
                        }
                    }
                
                Text("LIVE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 229/255, green: 62/255, blue: 62/255))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(red: 229/255, green: 62/255, blue: 62/255).opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 229/255, green: 62/255, blue: 62/255).opacity(0.4), lineWidth: 1)
            )
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.white.opacity(0.3))
                .font(.system(size: 14, weight: .bold))
        }
        .padding(16)
        .background(Color(white: 0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Player Container View
struct PlayerContainerView: View {
    let channel: Channel
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            if let url = URL(string: channel.urlString) {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        let audioSession = AVAudioSession.sharedInstance()
                        try? audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
                        try? audioSession.setActive(true)
                        
                        let newPlayer = AVPlayer(url: url)
                        self.player = newPlayer
                        newPlayer.play()
                    }
                    .onDisappear {
                        player?.pause()
                        player = nil
                    }
            } else {
                Text("Błędny adres URL")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                
                Text(channel.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                
                Spacer()
            }
            .padding()
            .padding(.top, 40) // safe area approx
        }
        .statusBar(hidden: true)
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.03).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 12) {
                            Text("📺")
                                .font(.system(size: 40))
                                .frame(width: 80, height: 80)
                                .background(
                                    LinearGradient(colors: [Color(red: 60/255, green: 0, blue: 0), Color(red: 30/255, green: 0, blue: 0)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(red: 229/255, green: 62/255, blue: 62/255).opacity(0.3), lineWidth: 1)
                                )
                            
                            HStack(spacing: 0) {
                                Text("Playbox")
                                    .font(.system(size: 24, weight: .heavy))
                                Text("TV")
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(Color(red: 229/255, green: 62/255, blue: 62/255))
                            }
                            
                            Text("Wersja 1.0.0")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 30)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Author
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TWÓRCA")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                                .tracking(1.5)
                            
                            HStack(spacing: 14) {
                                Text("Y")
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        LinearGradient(colors: [Color(red: 60/255, green: 0, blue: 0), Color(red: 229/255, green: 62/255, blue: 62/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("yadasiopl")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text("Twórca & Deweloper")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text("AUTOR")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(red: 229/255, green: 62/255, blue: 62/255))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 229/255, green: 62/255, blue: 62/255).opacity(0.15))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(red: 229/255, green: 62/255, blue: 62/255).opacity(0.4), lineWidth: 1)
                                    )
                            }
                            .padding(16)
                            .background(Color(white: 0.08))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Info Grid
                        VStack(alignment: .leading, spacing: 10) {
                            Text("INFORMACJE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                                .tracking(1.5)
                            
                            VStack(spacing: 1) {
                                InfoRow(label: "Platforma", value: "📱 iOS")
                                InfoRow(label: "Protokół", value: "HLS")
                                InfoRow(label: "Tryb", value: "Live Stream")
                                InfoRow(label: "Rok", value: "2025")
                            }
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        
                        Text("Stworzone z ❤️ przez yadasiopl\nPlayboxTV — streaming na wyciągnięcie ręki")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 0) {
                        Text("Playbox")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                        Text("TV")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(Color(red: 229/255, green: 62/255, blue: 62/255))
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(white: 0.08))
    }
}
