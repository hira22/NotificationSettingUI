//
//  ContentView.swift
//  Setting
//
//  Created by hiraoka on 2020/12/09.
//

import SwiftUI

struct ContentView: View {
    @State private var notifications: [RowViewModel] = []
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("アプリ通知設定")) {
                    ForEach(notifications.filter {$0.methodType == .push}, id: \.category) { notification in
                        ListRowView(notification: notification)
                    }
                }
                Section(header: Text("メール配信設定")) {
                    ForEach(notifications.filter {$0.methodType == .mail}, id: \.category) { notification in
                        VStack(alignment: .leading) {
                            ListRowView(notification: notification)
                            
                            if [Category.automaticMessage, Category.manualMessage].contains(notification.category) {
                                PullDownView(notification: notification)
                            }
                        }
                    }
                }
            }
            .onAppear {
                let response = try? JSONDecoder().decode(UserNotificationResponse.self, from: json.data(using: .utf8)!)
                self.notifications = (response?.notifications ?? []).map(RowViewModel.init)
            }
            .navigationTitle("通知設定")
            .listStyle(InsetGroupedListStyle())
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
#endif

//class ListViewModel: ObservableObject {
//    var notifications: [RowViewModel]
//    init () {
//        notifications = [
//            RowViewModel(
//        ]
//    }
//
//    func fetch() {
//
//    }
//}

class RowViewModel: ObservableObject {
    
    static let  selectableRows = [
        (method: MethodType.mail, category: Category.automaticMessage),
        (method: MethodType.mail, category: Category.manualMessage)
    ]
    
    internal init(category: Category, methodType: MethodType) {
        self.category = category
        self.methodType = methodType
        self.enable = true
        self.minutes = .fiveMinutely
    }
    
    internal init(notification: Notification) {
        self.category = notification.category
        self.methodType = notification.methodType
        self.enable = notification.enable
        
        if Self.selectableRows
            .contains(where: { $0.method == notification.methodType && $0.category == notification.category }) {
            self.minutes = notification.minutes == .zero ? .fiveMinutely : notification.minutes
        } else {
            self.minutes = notification.minutes
        }

    }
    
    let category: Category
    let methodType: MethodType
    @Published var  enable: Bool
    @Published var  minutes: MinuteType
}


// MARK: - Question
struct UserNotificationResponse: Codable {
    let notifications: [Notification]?
}

// MARK: - Notification
struct Notification: Codable {
    let category: Category
    let methodType: MethodType
    let enable: Bool
    let minutes: MinuteType
}

enum Category: String, Codable {
    case automaticMessage = "automatic_message"
    case manualMessage = "manual_message"
    case newArrivalProposal = "new_arrival_proposal"
    case proposal = "proposal"
    case dailyMail = "daily_mail"
    case infoMail = "info_mail"
    
    var label: String {
        return ""
    }
}

enum MethodType: String, Codable {
    case mail = "mail"
    case push = "push"
}

enum MinuteType: Int, Codable, CaseIterable {
    case zero = 0
    case fiveMinutely = 5
    case daily = 1440
    
    var label: String {
        switch self {
        case .fiveMinutely:
            return "すぐにお知らせ"
        case .daily:
            return "1日1回まとめてお知らせ"
        case .zero:
            return "すぐにお知らせ"
        }
    }
    
    static let selections: [Self] = [.fiveMinutely, daily]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let x = try? container.decode(Int.self) else {
            self = .zero
           return
        }
        
        if x < MinuteType.fiveMinutely.rawValue {
            self = .zero
            return
        }
        
        if x < MinuteType.daily.rawValue {
            self = .fiveMinutely
            return
        }
        
        self = .daily
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fiveMinutely:
            try container.encode(5)
        case .daily:
            try container.encode(1440)
        case .zero:
            try container.encode(0)
        }
    }
}

let json = """
{
  "notifications": [
    {
      "category": "automatic_message",
      "methodType": "push",
      "enable": false,
      "minutes": 5
    },
    {
      "category": "manual_message",
      "methodType": "push",
      "enable": true,
      "minutes": 0
    },
    {
      "category": "new_arrival_proposal",
      "methodType": "push",
      "enable": true,
      "minutes": 0
    },
    {
      "category": "proposal",
      "methodType": "push",
      "enable": true,
      "minutes": 0
    },
    {
      "category": "automatic_message",
      "methodType": "mail",
      "enable": true,
      "minutes": 0
    },
    {
      "category": "manual_message",
      "methodType": "mail",
      "enable": true,
      "minutes": 0
    },
    {
      "category": "new_arrival_proposal",
      "methodType": "mail",
      "enable": true,
      "minutes": 0
    },
    {
      "category": "proposal",
      "methodType": "mail",
      "enable": true,
      "minutes": 0
    },
    {
      "category": "daily_mail",
      "methodType": "mail",
      "enable": true,
      "minutes": 0
    },
    {
      "category": "info_mail",
      "methodType": "mail",
      "enable": true,
      "minutes": 0
    }
  ]
}
"""

struct ListRowView: View {
    @StateObject var notification: RowViewModel
    
    var body: some View {
        Button(action: {
            notification.enable.toggle()
        }) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: notification.enable ? "checkmark.square.fill" : "square")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(notification.enable ? .blue : .gray)
                    .frame(width: 20.0, height: 20.0)
                
                Text(notification.category.rawValue)
            }
        }
    }
}

struct PullDownView: View {
    @StateObject var notification: RowViewModel
    
    var body: some View {
        HStack {
            Spacer()
            Picker(
                selection: $notification.minutes,
                label:
                    ZStack {
                        Capsule()
                            .foregroundColor(notification.enable ? .white : Color.gray.opacity(0.5))
                            .shadow(color: Color.black.opacity(0.16), radius: 1, x: 0.0, y: 1.0)
                        
                        HStack {
                            Text(notification.minutes.label)
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .padding(.horizontal, 12)
                    }
                    .foregroundColor(.gray)
                    .frame(width: 180),
                content: {
                    ForEach(MinuteType.selections, id: \.self) { minute in
                        Text(minute.label).tag(minute)
                    }
                }
            )
            .font(.caption)
            .pickerStyle(MenuPickerStyle())
            .disabled(!notification.enable)
        }
        .frame(minHeight: 24)
    }
}
