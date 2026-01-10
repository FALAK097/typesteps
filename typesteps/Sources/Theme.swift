import SwiftUI

struct AppTheme: Identifiable, Equatable {
    let id: Int
    let name: String
    let mainBg: Color
    let secondaryBg: Color
    let border: Color
    let text: Color
    let secondaryText: Color
    let accent: Color
    
    static let themes: [AppTheme] = [
        // --- LIGHT THEMES (12) ---
        AppTheme(
            id: 0,
            name: "Light",
            mainBg: .white,
            secondaryBg: Color(red: 244/255, green: 244/255, blue: 245/255),
            border: Color(red: 228/255, green: 228/255, blue: 231/255),
            text: Color(red: 9/255, green: 9/255, blue: 11/255),
            secondaryText: Color(red: 113/255, green: 113/255, blue: 122/255),
            accent: Color(red: 79/255, green: 70/255, blue: 229/255)
        ),
        AppTheme(
            id: 12,
            name: "Soft Clay",
            mainBg: Color(red: 249/255, green: 248/255, blue: 246/255),
            secondaryBg: Color(red: 238/255, green: 236/255, blue: 230/255),
            border: Color(red: 220/255, green: 216/255, blue: 206/255),
            text: Color(red: 68/255, green: 64/255, blue: 60/255),
            secondaryText: Color(red: 120/255, green: 113/255, blue: 108/255),
            accent: Color(red: 217/255, green: 119/255, blue: 87/255)
        ),
        AppTheme(
            id: 13,
            name: "Aqua Light",
            mainBg: Color(red: 240/255, green: 250/255, blue: 250/255),
            secondaryBg: Color(red: 210/255, green: 240/255, blue: 240/255),
            border: Color(red: 180/255, green: 220/255, blue: 220/255),
            text: Color(red: 20/255, green: 60/255, blue: 60/255),
            secondaryText: Color(red: 80/255, green: 120/255, blue: 120/255),
            accent: Color(red: 13/255, green: 148/255, blue: 136/255)
        ),
        AppTheme(
            id: 14,
            name: "Lavender",
            mainBg: Color(red: 250/255, green: 248/255, blue: 255/255),
            secondaryBg: Color(red: 240/255, green: 235/255, blue: 250/255),
            border: Color(red: 220/255, green: 210/255, blue: 240/255),
            text: Color(red: 40/255, green: 20/255, blue: 80/255),
            secondaryText: Color(red: 100/255, green: 80/255, blue: 140/255),
            accent: Color(red: 139/255, green: 92/255, blue: 246/255)
        ),
        AppTheme(
            id: 15,
            name: "Matcha",
            mainBg: Color(red: 248/255, green: 252/255, blue: 245/255),
            secondaryBg: Color(red: 235/255, green: 245/255, blue: 230/255),
            border: Color(red: 215/255, green: 230/255, blue: 210/255),
            text: Color(red: 40/255, green: 50/255, blue: 30/255),
            secondaryText: Color(red: 90/255, green: 110/255, blue: 80/255),
            accent: Color(red: 101/255, green: 163/255, blue: 13/255)
        ),
        AppTheme(
            id: 17,
            name: "Sakura",
            mainBg: Color(red: 255/255, green: 245/255, blue: 247/255),
            secondaryBg: Color(red: 255/255, green: 235/255, blue: 240/255),
            border: Color(red: 255/255, green: 215/255, blue: 225/255),
            text: Color(red: 90/255, green: 40/255, blue: 50/255),
            secondaryText: Color(red: 160/255, green: 80/255, blue: 95/255),
            accent: Color(red: 244/255, green: 114/255, blue: 182/255)
        ),
        AppTheme(
            id: 18,
            name: "Solarized Light",
            mainBg: Color(red: 253/255, green: 246/255, blue: 227/255),
            secondaryBg: Color(red: 238/255, green: 232/255, blue: 213/255),
            border: Color(red: 215/255, green: 204/255, blue: 172/255),
            text: Color(red: 101/255, green: 123/255, blue: 131/255),
            secondaryText: Color(red: 147/255, green: 161/255, blue: 161/255),
            accent: Color(red: 181/255, green: 137/255, blue: 0/255)
        ),
        AppTheme(
            id: 19,
            name: "Desert",
            mainBg: Color(red: 250/255, green: 247/255, blue: 240/255),
            secondaryBg: Color(red: 240/255, green: 230/255, blue: 210/255),
            border: Color(red: 220/255, green: 210/255, blue: 190/255),
            text: Color(red: 70/255, green: 60/255, blue: 50/255),
            secondaryText: Color(red: 140/255, green: 120/255, blue: 100/255),
            accent: Color(red: 200/255, green: 140/255, blue: 80/255)
        ),
        AppTheme(
            id: 20,
            name: "Glacier",
            mainBg: Color(red: 245/255, green: 247/255, blue: 250/255),
            secondaryBg: Color(red: 225/255, green: 232/255, blue: 240/255),
            border: Color(red: 200/255, green: 210/255, blue: 225/255),
            text: Color(red: 50/255, green: 65/255, blue: 85/255),
            secondaryText: Color(red: 100/255, green: 120/255, blue: 150/255),
            accent: Color(red: 14/255, green: 165/255, blue: 233/255)
        ),
        AppTheme(
            id: 21,
            name: "Ivory",
            mainBg: Color(red: 255/255, green: 255/255, blue: 248/255),
            secondaryBg: Color(red: 245/255, green: 245/255, blue: 235/255),
            border: Color(red: 230/255, green: 230/255, blue: 215/255),
            text: Color(red: 45/255, green: 45/255, blue: 40/255),
            secondaryText: Color(red: 110/255, green: 110/255, blue: 100/255),
            accent: Color(red: 161/255, green: 130/255, blue: 80/255)
        ),
        AppTheme(
            id: 22,
            name: "Rose Quartz",
            mainBg: Color(red: 253/255, green: 248/255, blue: 250/255),
            secondaryBg: Color(red: 248/255, green: 238/255, blue: 242/255),
            border: Color(red: 240/255, green: 225/255, blue: 230/255),
            text: Color(red: 80/255, green: 60/255, blue: 70/255),
            secondaryText: Color(red: 140/255, green: 110/255, blue: 120/255),
            accent: Color(red: 244/255, green: 114/255, blue: 182/255)
        ),
        AppTheme(
            id: 23,
            name: "Mint",
            mainBg: Color(red: 245/255, green: 255/255, blue: 252/255),
            secondaryBg: Color(red: 225/255, green: 245/255, blue: 240/255),
            border: Color(red: 200/255, green: 230/255, blue: 220/255),
            text: Color(red: 30/255, green: 60/255, blue: 50/255),
            secondaryText: Color(red: 80/255, green: 120/255, blue: 110/255),
            accent: Color(red: 16/255, green: 185/255, blue: 129/255)
        ),

        // --- DARK THEMES (12) ---
        AppTheme(
            id: 1,
            name: "Zinc",
            mainBg: Color(red: 9/255, green: 9/255, blue: 11/255),
            secondaryBg: Color(red: 24/255, green: 24/255, blue: 27/255),
            border: Color(red: 39/255, green: 39/255, blue: 42/255),
            text: .white,
            secondaryText: Color(red: 161/255, green: 161/255, blue: 170/255),
            accent: Color(red: 99/255, green: 102/255, blue: 241/255)
        ),
        AppTheme(
            id: 2,
            name: "Catppuccin",
            mainBg: Color(red: 30/255, green: 30/255, blue: 46/255),
            secondaryBg: Color(red: 17/255, green: 17/255, blue: 27/255),
            border: Color(red: 49/255, green: 50/255, blue: 68/255),
            text: Color(red: 205/255, green: 214/255, blue: 244/255),
            secondaryText: Color(red: 166/255, green: 173/255, blue: 200/255),
            accent: Color(red: 203/255, green: 166/255, blue: 247/255)
        ),
        AppTheme(
            id: 3,
            name: "Dracula",
            mainBg: Color(red: 40/255, green: 42/255, blue: 54/255),
            secondaryBg: Color(red: 33/255, green: 34/255, blue: 44/255),
            border: Color(red: 68/255, green: 71/255, blue: 90/255),
            text: Color(red: 248/255, green: 248/255, blue: 242/255),
            secondaryText: Color(red: 98/255, green: 114/255, blue: 164/255),
            accent: Color(red: 189/255, green: 147/255, blue: 249/255)
        ),
        AppTheme(
            id: 4,
            name: "One Dark",
            mainBg: Color(red: 40/255, green: 44/255, blue: 52/255),
            secondaryBg: Color(red: 33/255, green: 37/255, blue: 43/255),
            border: Color(red: 62/255, green: 68/255, blue: 81/255),
            text: Color(red: 171/255, green: 178/255, blue: 191/255),
            secondaryText: Color(red: 92/255, green: 99/255, blue: 112/255),
            accent: Color(red: 97/255, green: 175/255, blue: 239/255)
        ),
        AppTheme(
            id: 5,
            name: "Rose Pine",
            mainBg: Color(red: 25/255, green: 23/255, blue: 36/255),
            secondaryBg: Color(red: 31/255, green: 29/255, blue: 46/255),
            border: Color(red: 64/255, green: 61/255, blue: 82/255),
            text: Color(red: 224/255, green: 222/255, blue: 244/255),
            secondaryText: Color(red: 144/255, green: 140/255, blue: 170/255),
            accent: Color(red: 235/255, green: 188/255, blue: 186/255)
        ),
        AppTheme(
            id: 6,
            name: "Nord",
            mainBg: Color(red: 46/255, green: 52/255, blue: 64/255),
            secondaryBg: Color(red: 59/255, green: 66/255, blue: 82/255),
            border: Color(red: 76/255, green: 86/255, blue: 106/255),
            text: Color(red: 216/255, green: 222/255, blue: 233/255),
            secondaryText: Color(red: 129/255, green: 161/255, blue: 193/255),
            accent: Color(red: 136/255, green: 192/255, blue: 208/255)
        ),
        AppTheme(
            id: 7,
            name: "Tokyo Night",
            mainBg: Color(red: 26/255, green: 27/255, blue: 38/255),
            secondaryBg: Color(red: 22/255, green: 22/255, blue: 30/255),
            border: Color(red: 41/255, green: 42/255, blue: 59/255),
            text: Color(red: 169/255, green: 177/255, blue: 214/255),
            secondaryText: Color(red: 86/255, green: 95/255, blue: 137/255),
            accent: Color(red: 122/255, green: 162/255, blue: 247/255)
        ),
        AppTheme(
            id: 8,
            name: "Everforest",
            mainBg: Color(red: 45/255, green: 52/255, blue: 54/255),
            secondaryBg: Color(red: 51/255, green: 59/255, blue: 61/255),
            border: Color(red: 61/255, green: 70/255, blue: 73/255),
            text: Color(red: 211/255, green: 198/255, blue: 170/255),
            secondaryText: Color(red: 147/255, green: 153/255, blue: 138/255),
            accent: Color(red: 167/255, green: 192/255, blue: 128/255)
        ),
        AppTheme(
            id: 9,
            name: "Gruvbox",
            mainBg: Color(red: 40/255, green: 40/255, blue: 40/255),
            secondaryBg: Color(red: 50/255, green: 48/255, blue: 47/255),
            border: Color(red: 60/255, green: 56/255, blue: 54/255),
            text: Color(red: 235/255, green: 219/255, blue: 178/255),
            secondaryText: Color(red: 146/255, green: 131/255, blue: 116/255),
            accent: Color(red: 250/255, green: 189/255, blue: 47/255)
        ),
        AppTheme(
            id: 10,
            name: "Solarized",
            mainBg: Color(red: 0/255, green: 43/255, blue: 54/255),
            secondaryBg: Color(red: 7/255, green: 54/255, blue: 66/255),
            border: Color(red: 88/255, green: 110/255, blue: 117/255),
            text: Color(red: 131/255, green: 148/255, blue: 150/255),
            secondaryText: Color(red: 101/255, green: 123/255, blue: 131/255),
            accent: Color(red: 38/255, green: 139/255, blue: 210/255)
        ),
        AppTheme(
            id: 11,
            name: "Cyberpunk",
            mainBg: Color(red: 2/255, green: 2/255, blue: 5/255),
            secondaryBg: Color(red: 20/255, green: 20/255, blue: 30/255),
            border: Color(red: 255/255, green: 0/255, blue: 128/255),
            text: .white,
            secondaryText: Color(red: 0/255, green: 255/255, blue: 255/255),
            accent: Color(red: 255/255, green: 255/255, blue: 0/255)
        ),
        AppTheme(
            id: 16,
            name: "Midnight",
            mainBg: .black,
            secondaryBg: Color(red: 15/255, green: 15/255, blue: 15/255),
            border: Color(red: 30/255, green: 30/255, blue: 30/255),
            text: Color(red: 230/255, green: 230/255, blue: 230/255),
            secondaryText: Color(red: 120/255, green: 120/255, blue: 120/255),
            accent: Color(red: 0/255, green: 122/255, blue: 255/255)
        )
    ]
}
