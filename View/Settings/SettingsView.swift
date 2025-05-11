import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                // Уведомления
                Section(header: Text("Уведомления")) {
                    Toggle("Разрешить уведомления", isOn: .constant(true))
                    // Здесь позже можно добавить настройки звука, времени и т.д.
                }

                // Язык интерфейса
                Section(header: Text("Язык интерфейса")) {
                    Picker("Мова", selection: .constant("Українська")) {
                        Text("Українська").tag("Українська")
                        Text("Русский").tag("Русский")
                        Text("English").tag("English")
                    }
                }

                // Конфиденциальность
                Section(header: Text("Данные и конфиденциальность")) {
                    NavigationLink("Управление данными") {
                        Text("Здесь будут опции для экспорта, очистки данных и политики конфиденциальности")
                            .padding()
                    }
                }

                // О приложении
                Section(header: Text("О приложении")) {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    NavigationLink("О разработке") {
                        Text("TaskFlow — приложение для управления задачами с таймером и проектами.")
                            .padding()
                    }
                }
            }
            .navigationTitle("Настройки")
            .scrollContentBackground(.hidden)
            .background(AppColorPalette.background)
        }
    }
}

#Preview {
    SettingsView()
}
