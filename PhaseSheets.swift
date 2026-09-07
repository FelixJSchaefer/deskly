import SwiftUI

struct AddPhaseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (PhaseKind) -> Void

    var body: some View {
        NavigationStack {
            List(PhaseKind.allCases) { kind in
                Button {
                    onSelect(kind)
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: kind.systemImage)
                            .foregroundStyle(Color(red: 0.96, green: 0.35, blue: 0.09))
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(kind.defaultName)
                                .foregroundStyle(.primary)
                            Text("\(kind.defaultMinutes) Minuten")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Phase hinzufügen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

struct EditPhaseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: WorkPhase
    let onSave: (WorkPhase) -> Void

    init(phase: WorkPhase, onSave: @escaping (WorkPhase) -> Void) {
        _draft = State(initialValue: phase)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Phase") {
                    TextField("Name", text: $draft.name)
                    Stepper(value: $draft.minutes, in: 1...480) {
                        HStack {
                            Text("Dauer")
                            Spacer()
                            Text("\(draft.minutes) Min.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Phase bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if draft.name.isEmpty { draft.name = draft.kind.defaultName }
                        onSave(draft)
                        dismiss()
                    }
                }
            }
        }
    }
}
