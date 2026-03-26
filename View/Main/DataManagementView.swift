import SwiftUI

struct DataManagementView: View {
    @State private var showDeleteAllAlert = false

    var body: some View {
        List {
            Section(header: Text(LocalizedStringKey("settings_data_section_local"))) {
                Button(role: .destructive) {
                    showDeleteAllAlert = true
                } label: {
                    Text(LocalizedStringKey("settings_data_delete_all"))
                }
            }

            Section(footer: Text(LocalizedStringKey("settings_data_footer"))) {
                EmptyView()
            }
        }
        .navigationTitle(LocalizedStringKey("settings_data_manage"))
        .alert(LocalizedStringKey("settings_data_delete_all_title"), isPresented: $showDeleteAllAlert) {
            Button(LocalizedStringKey("settings_data_delete_all_confirm"), role: .destructive) {
                
            }
            Button(LocalizedStringKey("common_cancel"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey("settings_data_delete_all_message"))
        }
    }
}
