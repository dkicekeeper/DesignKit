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
    @State private var frequency = "monthly"
    @State private var showsEditSheet = false
    @State private var accountName = "Kaspi Gold"

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

            ShowcaseSection(title: "UniversalRow · InfoRowLayout", subtitle: "The base row: icon, content, trailing, hint") {
                VStack(spacing: 0) {
                    UniversalRow(config: .standard, leadingIcon: .sfSymbol("creditcard", color: AppColors.accent)) {
                        Text("Kaspi Gold").font(AppTypography.body)
                    } trailing: {
                        FormattedAmountText(amount: 152_340.5, currency: "KZT")
                    }
                    Divider()
                    UniversalRow(config: .settings, leadingIcon: .sfSymbol("bell", color: AppColors.accent),
                                 hint: "A day before the payment") {
                        Text("Reminders").font(AppTypography.body)
                    } trailing: {
                        DisclosureChevron()
                    }
                }
                .cardStyle()
                InfoRowLayout(label: "Status") {
                    Text("Active")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.success)
                }
                .cardContentPadding()
                .cardStyle()
            }

            ShowcaseSection(title: "EditSheetContainer", subtitle: "Edit sheet: title, Cancel, Save, Form") {
                Button {
                    showsEditSheet = true
                } label: {
                    Text("Edit account").frame(maxWidth: .infinity)
                }
                .secondaryButton()
            }
            .sheet(isPresented: $showsEditSheet) {
                EditSheetContainer(
                    title: "Edit account",
                    isSaveDisabled: accountName.isEmpty,
                    onSave: { showsEditSheet = false },
                    onCancel: { showsEditSheet = false }
                ) {
                    Section("Name") {
                        TextField("Account name", text: $accountName)
                    }
                }
            }

            ShowcaseSection(title: "Settings rows") {
                FormSection {
                    NavigationSettingsRow(icon: "paintbrush.fill", title: "Theme",
                                          iconColor: AppColors.accent) {
                        Text("Theme settings").navigationTitle("Theme")
                    }
                    DatePickerRow(icon: "calendar", title: "Start date", selection: $date)
                    MenuPickerRow(icon: "arrow.triangle.2.circlepath", title: "Frequency",
                                  selection: $frequency,
                                  options: [("Weekly", "weekly"), ("Monthly", "monthly"), ("Yearly", "yearly")])
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
                HStack(spacing: AppSpacing.sm) {
                    EntityActionButton(title: "Edit", systemImage: "pencil") {}
                    EntityActionButton(title: "Delete", systemImage: "trash", role: .destructive) {}
                }
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
