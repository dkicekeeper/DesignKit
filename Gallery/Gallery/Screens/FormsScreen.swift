//
//  FormsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct FormsScreen: View {
    @State private var name = "Groceries"
    @State private var empty = ""
    @State private var date = Date()
    @State private var frequency = "monthly"
    @State private var showsEditSheet = false
    @State private var pickedAccount: String? = "gold"
    @State private var heroIcon: IconSource? = .sfSymbol("creditcard.fill")
    @State private var heroTitle = "Kaspi Gold"
    @State private var heroAmount = "125000"
    @State private var heroCurrency = "KZT"
    @State private var accountName = "Kaspi Gold"

    var body: some View {
        ShowcasePage(title: "Forms & Settings") {
            ShowcaseSection(title: "SectionHeaderView", subtitle: "A section title over content") {
                SectionHeaderView("Accounts", systemImage: "creditcard.fill")
            }

            ShowcaseSection(title: "SettingsSectionHeaderView", subtitle: "A settings group title") {
                SettingsSectionHeaderView(title: "Appearance")
            }

            ShowcaseSection(title: "FormSection", subtitle: "A titled group of fields") {
                FormSection(header: "Transaction") {
                    FormTextField(text: $name, placeholder: "Title")
                    FormTextField(text: $empty, placeholder: "Note (optional)")
                }
            }

            ShowcaseSection(title: "FormTextField", subtitle: "Plain · help text · error") {
                FormSection {
                    FormTextField(text: $name, placeholder: "Title")
                    FormTextField(text: $empty, placeholder: "Note (optional)",
                                  helpText: "Shown on the transaction detail")
                    FormTextField(text: $empty, placeholder: "Amount",
                                  keyboardType: .decimalPad,
                                  errorMessage: "Enter a value greater than 0")
                }
            }

            ShowcaseSection(title: "UniversalRow", subtitle: "The base row: icon, content, trailing, hint") {
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
            }

            ShowcaseSection(title: "InfoRowLayout", subtitle: "A label over any trailing content") {
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

            ShowcaseSection(title: "EditableHero", subtitle: "Icon (opens IconPicker), name, amount, currency") {
                EditableHero(icon: $heroIcon, title: $heroTitle, titlePlaceholder: "Account name",
                             amount: $heroAmount, currency: $heroCurrency, options: .amountAndCurrency)
            }

            ShowcaseSection(title: "CheckmarkRow", subtitle: "A choice list: all · with an icon and a value") {
                FormSection {
                    CheckmarkRow("All accounts", isSelected: pickedAccount == nil) { pickedAccount = nil }
                    CheckmarkRow("Kaspi Gold",
                                 icon: .custom(source: .sfSymbol("creditcard.fill"),
                                               style: .roundedSquare(size: AppIconSize.xl, tint: .accentMonochrome)),
                                 value: "120 000 ₸",
                                 isSelected: pickedAccount == "gold") { pickedAccount = "gold" }
                    CheckmarkRow("Halyk Savings",
                                 icon: .custom(source: .sfSymbol("banknote.fill"),
                                               style: .roundedSquare(size: AppIconSize.xl, tint: .accentMonochrome)),
                                 value: "1 250 000 ₸",
                                 isSelected: pickedAccount == "savings") { pickedAccount = "savings" }
                }
            }

            ShowcaseSection(title: "NavigationSettingsRow", subtitle: "Opens a settings screen") {
                FormSection {
                    NavigationSettingsRow(icon: "paintbrush.fill", title: "Theme",
                                          iconColor: AppColors.accent) {
                        Text("Theme settings").navigationTitle("Theme")
                    }
                }
            }

            ShowcaseSection(title: "DatePickerRow", subtitle: "Inline DatePicker in a row") {
                FormSection {
                    DatePickerRow(icon: "calendar", title: "Start date", selection: $date)
                }
            }

            ShowcaseSection(title: "MenuPickerRow", subtitle: "A menu of options in a row") {
                FormSection {
                    MenuPickerRow(icon: "arrow.triangle.2.circlepath", title: "Frequency",
                                  selection: $frequency,
                                  options: [("Weekly", "weekly"), ("Monthly", "monthly"), ("Yearly", "yearly")])
                }
            }

            ShowcaseSection(title: "ActionSettingsRow", subtitle: "A row that runs an action · destructive") {
                FormSection {
                    ActionSettingsRow(icon: "trash.fill", title: "Delete all data",
                                      isDestructive: true) {}
                }
            }

            ShowcaseSection(title: "PlusTabLabel", subtitle: "The tab bar's add button · expanded") {
                HStack(spacing: AppSpacing.xl) {
                    PlusTabLabel(isExpanded: false)
                    PlusTabLabel(isExpanded: true)
                }
                .font(AppTypography.bodyEmphasis)
            }

            ShowcaseSection(title: "BulkDeleteButton", subtitle: "Deletes the selected items") {
                BulkDeleteButton(count: 3) {}
            }

            ShowcaseSection(title: "EntityActionButton", subtitle: "Edit · delete on a detail screen") {
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
