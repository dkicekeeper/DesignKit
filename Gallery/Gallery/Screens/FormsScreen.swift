//
//  FormsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens
import DesignComponents

struct FormsScreen: View {
    @State private var name = "Groceries"
    @State private var empty = ""
    @State private var date = Date()

    var body: some View {
        ShowcasePage(title: "Forms & Settings") {
            ShowcaseSection(title: "Section headers") {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView("Accounts", systemImage: "creditcard.fill")
                    SettingsSectionHeaderView(title: "Appearance")
                }
            }

            ShowcaseSection(title: "FormSection + FormTextField") {
                FormSection(header: "Transaction") {
                    FormTextField(text: $name, placeholder: "Title")
                    FormTextField(text: $empty, placeholder: "Note (optional)",
                                  helpText: "Shown on the transaction detail")
                    FormTextField(text: $empty, placeholder: "Amount",
                                  keyboardType: .decimalPad,
                                  errorMessage: "Enter a value greater than 0")
                }
            }

            ShowcaseSection(title: "Settings rows") {
                FormSection {
                    NavigationSettingsRow(icon: "paintbrush.fill", title: "Theme",
                                          iconColor: AppColors.accent) {
                        Text("Theme settings").navigationTitle("Theme")
                    }
                    DatePickerRow(icon: "calendar", title: "Start date", selection: $date)
                    ActionSettingsRow(icon: "trash.fill", title: "Delete all data",
                                      isDestructive: true) {}
                }
            }

            ShowcaseSection(title: "Buttons & labels") {
                HStack(spacing: AppSpacing.xl) {
                    PlusTabLabel(isExpanded: false)
                    PlusTabLabel(isExpanded: true)
                }
                .font(AppTypography.bodyEmphasis)
                BulkDeleteButton(count: 3) {}
            }

            ShowcaseSection(title: "SiriGlowView", subtitle: "Apple-Intelligence edge glow") {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.xl)
                        .fill(AppColors.bgCard)
                    SiriGlowView()
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                    Text("Listening…")
                        .font(AppTypography.h4)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .frame(height: 200)
            }
        }
    }
}

#Preview { NavigationStack { FormsScreen() } }
