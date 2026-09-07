import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = DesklyViewModel()
    @State private var phaseToEdit: WorkPhase?
    @State private var showingAddPhase = false
    @State private var showingResetConfirmation = false
    @State private var showingStandardConfirmation = false

    private let ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    planSection
                    timerCard
                }
                .frame(maxWidth: 920)
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
            .background(Color.desklyBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(.desklyOrange)
        .onAppear { model.requestNotificationPermission() }
        .onReceive(ticker) { model.tick(at: $0) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.sceneBecameActive() }
            if phase == .background { model.sceneMovedToBackground() }
        }
        .sheet(isPresented: $showingAddPhase) {
            AddPhaseSheet { kind in model.add(kind: kind) }
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $phaseToEdit) { phase in
            EditPhaseSheet(phase: phase) { model.update($0) }
                .presentationDetents([.medium])
        }
        .confirmationDialog("Tag neu starten?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Tag neu starten", role: .destructive) { model.resetDay() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Deskly springt zur ersten Phase zurück und setzt den Countdown zurück.")
        }
        .confirmationDialog("Standardplan wiederherstellen?", isPresented: $showingStandardConfirmation, titleVisibility: .visible) {
            Button("Standardplan verwenden", role: .destructive) { model.restoreStandardPlan() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Dein aktueller Tagesplan wird ersetzt.")
        }
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image("DesklyLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 31, height: 31)
            Text("Deskly")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
            Spacer()
            Toggle(isOn: $model.soundEnabled) {
                Label(model.soundEnabled ? "Ton an" : "Ton aus", systemImage: model.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.subheadline.weight(.medium))
            }
            .toggleStyle(.button)
            .buttonStyle(.borderless)
        }
        .padding(.top, 10)
    }

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("DEIN TAGESPLAN")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("\(model.phases.count) Phasen · \(totalDurationText)")
                        .font(.subheadline.weight(.semibold))
                }
                Spacer()
                Menu {
                    Button("Neue Phase", systemImage: "plus") { showingAddPhase = true }
                    Button("Standardplan", systemImage: "arrow.counterclockwise") { showingStandardConfirmation = true }
                } label: {
                    Label("Phase", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(model.phases) { phase in
                        if model.dropTargetID == phase.id, model.draggedPhaseID != phase.id,
                           let dragged = model.phases.first(where: { $0.id == model.draggedPhaseID }) {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(Color.desklyOrange.opacity(0.10))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .strokeBorder(Color.desklyOrange.opacity(0.34), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                                }
                                .frame(width: model.cardWidth(for: dragged), height: 94)
                                .transition(.scale(scale: 0.96).combined(with: .opacity))
                        }

                        PhaseCardView(
                            phase: phase,
                            width: model.cardWidth(for: phase),
                            isCurrent: model.currentPhase?.id == phase.id,
                            isDragging: model.draggedPhaseID == phase.id,
                            onEdit: { phaseToEdit = phase },
                            onDelete: { model.remove(phase) }
                        )
                        .onDrag {
                            model.beginDragging(phase)
                            return NSItemProvider(object: phase.id.uuidString as NSString)
                        } preview: {
                            PhaseCardView(
                                phase: phase,
                                width: model.cardWidth(for: phase),
                                isCurrent: model.currentPhase?.id == phase.id,
                                isDragging: false,
                                onEdit: {},
                                onDelete: {}
                            )
                            .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
                        }
                        .onDrop(
                            of: [UTType.plainText],
                            delegate: PhaseDropDelegate(target: phase, model: model)
                        )
                    }
                }
                .animation(.snappy(duration: 0.22), value: model.dropTargetID)
                .padding(.vertical, 2)
            }
        }
        .padding(17)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.black.opacity(0.07))
        }
    }

    private var timerCard: some View {
        VStack(spacing: 20) {
            if let phase = model.currentPhase {
                HStack(spacing: 13) {
                    Image(systemName: phase.kind.systemImage)
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(Color.desklyOrange)
                        .frame(width: 52, height: 52)
                        .background(Color.desklyOrange.opacity(0.11), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.isCompleted ? "GESCHAFFT" : "AKTUELLE PHASE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text(model.isCompleted ? "Tagesplan abgeschlossen" : phase.name)
                            .font(.title3.weight(.semibold))
                    }
                    Spacer(minLength: 0)
                }
            }

            Text(model.formattedTime)
                .font(.system(size: 70, weight: .ultraLight, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            ProgressView(value: model.progress)
                .tint(.desklyOrange)

            HStack {
                Text("Danach")
                    .foregroundStyle(.secondary)
                Spacer()
                if let next = model.nextPhase {
                    Label("\(next.name) · \(next.minutes) Min.", systemImage: next.kind.systemImage)
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text("Tagesplan beendet")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(13)
            .background(Color.desklySoft, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            if model.alarmActive {
                Button("Alarm stoppen", systemImage: "stop.fill") { model.stopAlarm() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { controls }
                VStack(spacing: 10) { controls }
            }
        }
        .padding(22)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.black.opacity(0.07))
        }
    }

    @ViewBuilder private var controls: some View {
        Button(model.isRunning ? "Pause" : (model.isCompleted ? "Neu starten" : "Start"), systemImage: model.isRunning ? "pause.fill" : "play.fill") {
            model.toggleRunning()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)

        Button("Vorherige", systemImage: "backward.end.fill") { model.previous() }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(model.currentIndex == 0)

        Button("Überspringen", systemImage: "forward.end.fill") { model.skip() }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(model.currentIndex >= model.phases.count - 1)

        Button("Tag neu", systemImage: "arrow.counterclockwise") { showingResetConfirmation = true }
            .buttonStyle(.bordered)
            .controlSize(.large)
    }

    private var totalDurationText: String {
        let minutes = model.phases.reduce(0) { $0 + $1.minutes }
        return "\(minutes / 60) Std. \(minutes % 60) Min."
    }
}

private struct PhaseCardView: View {
    let phase: WorkPhase
    let width: CGFloat
    let isCurrent: Bool
    let isDragging: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.caption.weight(.bold))
                .foregroundStyle(isCurrent ? Color.white.opacity(0.7) : Color.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: phase.kind.systemImage)
                    .font(.body.weight(.medium))
                Text(phase.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text("\(phase.minutes) Min.")
                    .font(.caption2)
                    .opacity(0.72)
            }
            Spacer(minLength: 0)
            Menu {
                Button("Zeit bearbeiten", systemImage: "pencil") { onEdit() }
                Button("Phase löschen", systemImage: "trash", role: .destructive) { onDelete() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .frame(width: 30, height: 36)
                    .contentShape(Rectangle())
            }
            .tint(isCurrent ? Color.white : Color.primary)
        }
        .padding(.horizontal, 12)
        .frame(width: width, height: 94)
        .foregroundStyle(isCurrent ? Color.white : Color.primary)
        .background(isCurrent ? Color.desklyOrange : Color.desklySoft, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .opacity(isDragging ? 0.18 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .contextMenu {
            Button("Zeit bearbeiten", systemImage: "pencil") { onEdit() }
            Button("Phase löschen", systemImage: "trash", role: .destructive) { onDelete() }
        }
    }
}

private struct PhaseDropDelegate: DropDelegate {
    let target: WorkPhase
    let model: DesklyViewModel

    func dropEntered(info: DropInfo) {
        model.targetDrop(on: target)
    }

    func performDrop(info: DropInfo) -> Bool {
        model.completeDrop(before: target)
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

private extension Color {
    static let desklyOrange = Color(red: 0.96, green: 0.35, blue: 0.09)
    static let desklyBackground = Color(red: 0.985, green: 0.977, blue: 0.968)
    static let desklySoft = Color(red: 1.0, green: 0.956, blue: 0.925)
}
