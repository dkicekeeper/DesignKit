//
//  ParticleCreature.swift
//  DesignKit
//
//  A character made of light (4.6.0): a swarm of particles in the shape of a sphere, its outline
//  a thin rim of light with a glow round it (4.7.0; a dark glass sphere held it before), a soft
//  core of its colours inside that breathes with it (4.9.1), and a face in the manner of a
//  desk robot's screen: two glowing eyes drawn as solid shapes (a rounded lens
//  with a top lid and a cheek, an arc, a chevron, a heart, a spiral) and, for some moods, a small
//  mouth (ParticleCreatureFace.swift). The swarm's moods are shapes: listening, it ripples with
//  the voice; thinking, it gathers into a small core with three rings that spin in their own
//  planes while the planes turn round the centre, like a gyroscope; answering (5.3.0), a third of
//  it flows in a tilted ring round the sphere while it talks and waves of light leave its rim
//  with each phrase (a bar chart until 5.2.0); working (5.3.0), the sphere fills with light from
//  the bottom up as the work goes; `.glyph("₸")`, it draws a sign in a ring like a coin. The face carries the rest: ^ ^ for happy, > < for a celebration, hearts, slanted lids
//  for cross, worried and sad, half-closed lids for sleepy, a wink with a tongue, a tear.
//
//  Two styles: `.hero`, the full creature with its glow, the links between the nearest
//  particles and its extras (z's, hearts, sparkles, a question mark); `.compact`, a small
//  sphere for an avatar or a tab icon, with fewer particles kept inside the sphere, the coin and
//  burst moods shown as happy and an answer only talking (no ring, no waves).
//
//  Interactive (`isInteractive:`, hero): the eyes follow the finger and squint when it comes
//  close, the particles move out of its way, a tap scatters them and cheers the creature up,
//  three quick taps make it dizzy.
//
//  Light: one Canvas at 30 fps (60 while a finger is on it), positions computed from the time.
//  A change of mood carries every particle from where it was to the new shape in about 0.7 s,
//  each a little after the other, with a small overshoot. The particles are bucketed by colour
//  and depth, so a few hundred dots are a few dozen fills per frame. Under Reduce Motion,
//  `.designKitMotion(false)` or while the system saves resources it is one still frame of the
//  mood.
//
//  Light mode (4.6.1; all of it since 4.7.0, when the glass went): light added to a white page
//  is lost, so the swarm, its links, the rim, the face and the extras are drawn in ink, their
//  colours deepened with normal blending; the core is a ball of colour, the glow a faint haze,
//  and a soft shadow grounds the sphere instead of a light under it. On a dark surface in light
//  mode, give it `.environment(\.colorScheme, .dark)`.
//
//  Tenra's assistant is the first user; which mood each of its states shows stays in the app.
//

import SwiftUI
import UIKit
import DesignTokens
import DesignSupport

/// A creature made of a swarm of light in the shape of a sphere, with a glowing face and moods.
///
/// ```swift
/// ParticleCreature(mood: isThinking ? .thinking : .idle)          // hero
///     .frame(width: 260, height: 260)
/// ParticleCreature(mood: .happy, style: .compact)                 // avatar, tab icon
///     .frame(width: 40, height: 40)
/// ParticleCreature(mood: .listening, level: voice.level, isInteractive: true)
/// ParticleCreature(mood: .happy, speech: CreatureSpeech("Hi!"))      // says a line (4.10.0)
///     .creatureGesture(.wave, trigger: greetedAt)                   // and waves
///     .creatureAmbience(CreatureAmbience(dozesAfter: 40))           // a life of its own (4.11.0)
/// ```
///
/// Give it a square: the hero looks right from about 160 pt, the compact style from 24 pt.
/// The hero's sphere takes about 70% of the square; the rest is room for the burst, the answer's
/// ring and waves, and the extras. Decorative: hidden from VoiceOver, say what it is doing in
/// text. A line it says (`speech:`) is the exception: its words are read like any text.
///
/// It follows the colour scheme (4.6.1): light on a dark page, in deeper colours (ink) on a light
/// one; on a dark surface in light mode, set `.environment(\.colorScheme, .dark)` on it.
public struct ParticleCreature: View {
    /// What the creature feels or does.
    public enum Mood: Hashable, Sendable {
        /// At rest: the sphere breathes, the eyes glance around and blink.
        case idle
        /// Listening: the swarm ripples with the voice (`level:`), the eyes open wide and pulse.
        case listening
        /// Thinking: a small core inside three gyroscope rings, the eyes look up and aside.
        case thinking
        /// Answering (5.3.0): it talks, a third of the swarm flows in a tilted ring round the
        /// sphere and waves of light leave its rim with each phrase (a bar chart until 5.2.0).
        case answering
        /// A long piece of work (5.3.0): the sphere fills with light from the bottom up as
        /// `progress` (0…1) grows, the eyes on the rising light. For an import, a sync.
        case working(progress: Double)
        /// Pleased: ^ ^ eyes and a smile, the sphere bounces.
        case happy
        /// A goal reached: the swarm bursts out and gathers back, > < eyes and an open mouth.
        case celebrating
        /// Something unexpected: round eyes and an "o", the sphere swells for a moment.
        case surprised
        /// Thanked: heart eyes, the sphere beats like a heart, hearts rise.
        case love
        /// Proud of the person: smiling eyes, a smile and sparkles.
        case proud
        /// A joke or a secret: one eye winks, a tongue out, the head tilts.
        case wink
        /// Did not understand: one lid lower, the head tilts, a question mark.
        case confused
        /// Working hard: lids slanted down to the middle, the swarm turns faster.
        case determined
        /// Concerned: lids slanted up, a small frown, amber; the sphere shrinks a little.
        case worried
        /// Sad: lids slanted up, a frown and a tear.
        case sad
        /// Late in the day: half-closed lids, slow blinks, a yawn.
        case sleepy
        /// Asleep: closed eyes, dim and slow, z's rise.
        case asleep
        /// The swarm draws `text` (one character, a currency sign) inside a ring, like a coin.
        case glyph(String)
    }

    /// How much of the creature is drawn.
    public enum Style: Hashable, Sendable {
        /// The full creature: a few hundred particles, glow, links and extras.
        case hero
        /// A small sphere for an avatar or a tab icon.
        case compact
    }

    let mood: Mood
    let style: Style
    let level: Double?
    let isInteractive: Bool
    let speech: CreatureSpeech?
    let accessory: CreatureAccessory?

    @Environment(\.designKitMotion) private var designKitMotion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.creatureGestureRequest) private var gestureRequest
    @Environment(\.creatureGestureFrame) private var gestureFrame
    @Environment(\.creatureAmbience) private var ambience
    @Environment(\.creatureFollowsTilt) private var followsTilt
    @State private var engine = ParticleCreatureEngine()
    /// Whether this creature holds the shared tilt sensor (5.3.0).
    @State private var holdsTilt = false
    @State private var isTouching = false
    @State private var shownSpeech: CreatureSpeech?
    @State private var shownEmotion: CreatureSpeech.Emotion = .calm
    @State private var speechStart = Date.distantPast

    /// - Parameters:
    ///   - mood: What the creature shows. A change moves the swarm into the new shape.
    ///   - style: `.hero` or `.compact`.
    ///   - level: The voice level, 0…1, for `.listening`; `nil` ripples on its own.
    ///   - isInteractive: Follows and reacts to touches (hero only).
    ///   - speech: A line it says (4.10.0, hero only): the letters fly out of its mouth while
    ///     it talks, in its mood's colour, and move the way it feels. A new line replaces the
    ///     one on screen; `nil` takes it away.
    ///   - accessory: What it wears (4.12.0), drawn in its own light: a change puts the new one
    ///     on (its dots gather from the sphere) and takes the old one off (they scatter). The
    ///     compact style wears hats only.
    public init(
        mood: Mood = .idle,
        style: Style = .hero,
        level: Double? = nil,
        isInteractive: Bool = false,
        speech: CreatureSpeech? = nil,
        accessory: CreatureAccessory? = nil
    ) {
        self.mood = mood
        self.style = style
        self.level = level.map { min(max($0, 0), 1) }
        self.isInteractive = isInteractive
        self.speech = speech
        self.accessory = accessory
    }

    /// The creature as a still picture (5.3.0), for where a view cannot move or live: a
    /// widget, a notification's attachment, a share image, an app's launch screen. The still
    /// frame of `mood`, as Reduce Motion shows it, `side` points square.
    ///
    /// ```swift
    /// let picture = ParticleCreature.image(mood: .happy, side: 120, colorScheme: .dark)
    /// ```
    ///
    /// In a widget the view itself draws the same frame: `ParticleCreature(mood:)` with
    /// `.designKitMotion(false)`.
    @MainActor
    public static func image(
        mood: Mood = .idle,
        style: Style = .hero,
        accessory: CreatureAccessory? = nil,
        side: CGFloat,
        colorScheme: ColorScheme = .light,
        scale: CGFloat = 3
    ) -> UIImage? {
        let renderer = ImageRenderer(content:
            ParticleCreature(mood: mood, style: style, accessory: accessory)
                .frame(width: side, height: side)
                .designKitMotion(false)
                .environment(\.colorScheme, colorScheme)
        )
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.uiImage
    }

    /// Motion of its own: off under Reduce Motion and `.designKitMotion(false)`.
    private var moves: Bool { designKitMotion && !reduceMotion }

    public var body: some View {
        AmbientMotionGate { allowsAmbientMotion in
            if allowsAmbientMotion && designKitMotion {
                TimelineView(.animation(minimumInterval: isTouching
                    ? ParticleCreatureMetrics.touchFrameInterval
                    : ParticleCreatureMetrics.frameInterval)) { timeline in
                    canvas(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                canvas(time: nil)
            }
        }
        .contentShape(Rectangle())
        .gesture(touchGesture, including: isInteractive && style == .hero ? .all : .none)
        .accessibilityHidden(true)
        .overlay {
            if style == .hero {
                GeometryReader { proxy in
                    if let shownSpeech {
                        speechWords(shownSpeech, in: proxy.size)
                    }
                }
                // The words are placed by the creature's own sides; their text keeps the app's
                // direction.
                .environment(\.layoutDirection, .leftToRight)
            }
        }
        .onChange(of: speech, initial: true) { _, line in say(line) }
        .onChange(of: wantsTilt) { _, wants in holdTilt(wants) }
        .onAppear { holdTilt(wantsTilt) }
        .onDisappear { holdTilt(false) }
        .onChange(of: gestureRequest) { _, request in
            guard let request else { return }
            if moves { engine.perform(request.gesture, date: Date()) }
            // Not motion: it plays under Reduce Motion too (5.3.0).
            if request.haptic { HapticManager.play(request.gesture.hapticCue) }
        }
        .task(id: shownSpeech?.id) { await dismissSpeechWhenDone() }
        .task(id: daydreams) { await daydream() }
    }

    // MARK: Tilt

    /// The eyes follow the phone's tilt (5.3.0): while it moves, in the hero style.
    private var wantsTilt: Bool { followsTilt && moves && style == .hero }

    private func holdTilt(_ holds: Bool) {
        guard holds != holdsTilt else { return }
        holdsTilt = holds
        if holds { CreatureTilt.shared.start() } else { CreatureTilt.shared.stop() }
    }

    // MARK: Speech

    /// A new line, or `nil`. `stirs`: it ends the quiet (a daydream does not).
    private func say(_ line: CreatureSpeech?, stirs: Bool = true) {
        guard style == .hero else { return }
        let now = Date()
        let emotion = line.map { Self.emotion(of: $0, mood: mood) } ?? .calm
        speechStart = now
        engine.speak(moves ? line : nil, emotion: emotion, date: now, look: line.map { lookAtWords($0) }, stirs: stirs)
        shownEmotion = emotion
        withAnimation(AppAnimation.motion(AppAnimation.smooth, reduceMotion: reduceMotion, isEnabled: designKitMotion)) {
            shownSpeech = line
        }
    }

    /// The line's emotion, `.automatic` taken from the mood.
    static func emotion(of line: CreatureSpeech, mood: Mood) -> CreatureSpeech.Emotion {
        guard line.emotion == .automatic else { return line.emotion }
        switch mood {
        case .happy, .celebrating, .proud, .love: return .joy
        case .thinking: return .thought
        case .worried: return .worry
        case .sad: return .sad
        case .sleepy, .asleep: return .whisper
        default: return .calm
        }
    }

    /// Where the eyes go while the creature thinks a line or a picture: at it.
    private func lookAtWords(_ line: CreatureSpeech) -> (x: Double, y: Double) {
        switch line.placement {
        case .above: return (0.2, -0.85)
        case .trailing, .leading:
            let onRight = (line.placement == .trailing) != (layoutDirection == .rightToLeft)
            return (onRight ? 0.7 : -0.7, -0.5)
        }
    }

    /// The pictures it may daydream of now (4.11.0): while it moves, idle, in the hero style.
    private var daydreams: [String] {
        moves && style == .hero && mood == .idle ? ambience.daydreams : []
    }

    /// Now and then a picture it daydreams of, when nothing is said and it is awake.
    private func daydream() async {
        let symbols = daydreams
        guard !symbols.isEmpty else { return }
        var turn = 0
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(CreatureAmbienceMetrics.daydreamWait(turn)))
            guard !Task.isCancelled else { return }
            if shownSpeech == nil, !engine.isDozing(at: Date()) {
                say(CreatureSpeech(symbol: symbols[turn % symbols.count], label: "", emotion: .thought,
                                   duration: .seconds(CreatureAmbienceMetrics.daydreamLength), id: "daydream-\(turn)"),
                    stirs: false)
            }
            turn += 1
        }
    }

    private func dismissSpeechWhenDone() async {
        guard let line = shownSpeech, var duration = line.visibleDuration else { return }
        if !moves, line.duration == .automatic, line.symbol == nil {
            duration -= CreatureSpeechTiming.typingDuration(of: line.text)
        }
        try? await Task.sleep(for: .seconds(duration))
        guard !Task.isCancelled, shownSpeech?.id == line.id else { return }
        engine.speak(nil, date: Date())
        withAnimation(AppAnimation.motion(AppAnimation.smooth, reduceMotion: reduceMotion, isEnabled: designKitMotion)) {
            shownSpeech = nil
        }
    }

    /// The words just off the sphere's rim, the letters flying to them from the mouth: over
    /// the creature, or beside it on the upper side.
    private func speechWords(_ line: CreatureSpeech, in size: CGSize) -> some View {
        let geo = Geometry(size: size, style: .hero)
        let rim = geo.radius * CreatureSpeechMetrics.rim + CreatureSpeechMetrics.gap
        let width = line.maxWidth
        let room = CreatureSpeechMetrics.room
        let alignment: Alignment
        let anchor: UnitPoint
        let tip: CGPoint
        let center: CGPoint
        // Words come out of the mouth; a thought out of the upper side of the head (4.11.0).
        let headward: Double
        switch line.placement {
        case .above:
            alignment = .bottom
            anchor = .bottom
            tip = CGPoint(x: geo.cx, y: geo.restY - rim)
            center = CGPoint(x: tip.x, y: tip.y - room / 2)
            headward = layoutDirection == .rightToLeft ? -1 : 1
        case .trailing, .leading:
            let onRight = (line.placement == .trailing) != (layoutDirection == .rightToLeft)
            let side: Double = onRight ? 1 : -1
            headward = side
            let angle = CreatureSpeechMetrics.sideAngle
            alignment = onRight ? .leading : .trailing
            anchor = onRight ? .leading : .trailing
            tip = CGPoint(x: geo.cx + side * rim * cos(angle), y: geo.restY + rim * sin(angle))
            center = CGPoint(x: tip.x + side * width / 2, y: tip.y)
        }
        let source: CGPoint
        if line.isThought(shownEmotion) {
            let angle = line.placement == .above
                ? -Double.pi / 2 + CreatureSpeechMetrics.headTurn
                : CreatureSpeechMetrics.sideAngle + CreatureSpeechMetrics.headDrop
            let reach = geo.radius * CreatureSpeechMetrics.head
            source = CGPoint(x: geo.cx + headward * reach * cos(angle), y: geo.restY + reach * sin(angle))
        } else {
            source = CGPoint(x: geo.cx, y: geo.restY + geo.radius * CreatureSpeechMetrics.mouth)
        }
        let onLight = colorScheme == .light
        return CreatureSpeechWords(
            speech: line,
            emotion: shownEmotion,
            start: speechStart,
            moves: moves,
            color: Self.wordColor(mood, onLight: onLight),
            glows: !onLight,
            anchor: anchor,
            mouth: CGSize(width: source.x - tip.x, height: source.y - tip.y),
            textDirection: layoutDirection
        )
        .frame(width: width, height: line.placement == .above ? room : room * 2, alignment: alignment)
        .transition(.opacity)
        .position(center)
        .id(line.id)
    }

    /// The mood's colour for its words: its main hue in ink on a light page, lighter in the dark.
    static func wordColor(_ mood: Mood, onLight: Bool) -> Color {
        let hue = CreaturePalette.of(CreaturePose(mood))[0]
        let rgb = onLight
            ? hue * (1 - CreatureInk.faceDepth)
            : hue + (SIMD3<Double>(repeating: 255) - hue) * CreatureSpeechMetrics.lightWords
        return Color(.sRGB, red: rgb.x / 255, green: rgb.y / 255, blue: rgb.z / 255)
    }

    private func canvas(time: Double?) -> some View {
        let engine = engine
        let mood = mood
        let style = style
        let level = level
        let onLight = colorScheme == .light
        let still = time == nil ? gestureFrame : nil
        let isRTL = layoutDirection == .rightToLeft
        let ambience = moves ? ambience : .still
        let accessory = accessory
        let tilt = holdsTilt && time != nil ? CreatureTilt.shared.gaze : nil
        return Canvas { context, size in
            engine.tilt = tilt
            engine.render(in: &context, size: size, mood: mood, style: style, level: level, time: time,
                          onLight: onLight, still: still, isRTL: isRTL, ambience: ambience, accessory: accessory)
        }
    }

    private var touchGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                engine.pointer = value.location
                if !isTouching { isTouching = true }
            }
            .onEnded { value in
                engine.pointer = nil
                isTouching = false
                let moved = hypot(value.translation.width, value.translation.height)
                if moved < ParticleCreatureMetrics.tapSlop {
                    engine.poke(at: value.location, date: Date())
                    HapticManager.play(.tap)
                }
            }
    }
}

enum ParticleCreatureMetrics {
    /// Ambient motion: 30 fps (docs/motion.md §9).
    static let frameInterval: Double = 1.0 / 30
    /// While a finger is on it the creature follows the finger: display rate.
    static let touchFrameInterval: Double = 1.0 / 60
    /// A touch that moved less than this is a tap.
    static let tapSlop: Double = 10
    /// How long a change of mood carries the particles, and how much later the last one starts.
    static let transition: Double = 0.5
    static let stagger: Double = 0.2
    /// How long a change of face takes: lids slide, an eye closes and opens in a new form.
    static let faceTransition: Double = 0.32
}

// MARK: - Engine

/// Builds the swarm and draws one frame of it. Positions come from the time; the only state is
/// what a change needs: the mood, when it began, where the particles were then, the last touch.
final class ParticleCreatureEngine {
    typealias RGB = SIMD3<Double>

    private struct Particle {
        let index: Int
        let tone: Int
        let ux: Double, uy: Double, uz: Double
        let theta: Double
        let phase: Double
        /// 0…1: when the particle starts moving in a change of mood.
        let delay: Double
    }

    /// The finger, in the view's coordinates; set by the gesture.
    var pointer: CGPoint?
    /// The phone's tilt for the eyes (5.3.0, `.creatureFollowsTilt()`), -1…1; set each frame.
    var tilt: (x: Double, y: Double)?

    private var particles: [Particle] = []
    private var builtStyle: ParticleCreature.Style?
    private var builtCount = 0

    private var origin: Double?
    private var requested: ParticleCreature.Mood = .idle
    private var pose: CreaturePose = .idle
    private var poseAt: Double = 0
    private var started = false
    private var blending = false
    private var glyphText = ""
    private var glyphPoints: [CGPoint] = [.zero]
    /// Working (5.3.0): the work done that was asked for, and the light shown, which follows it.
    private var workTarget: Double = 0
    private var workShown: Double = 0
    private var workClock: Double = 0

    private var fromParts: [CGPoint] = []
    private var fromDepth: [Double] = []
    private var fromFace: CreatureFace?
    private var fromPalette: [RGB] = CreaturePalette.idle
    private var fromShell: Double = 1
    private var fromCore: Double = 1
    private var lastParts: [CGPoint] = []
    private var lastDepth: [Double] = []
    private var lastFace: CreatureFace?
    private var lastPalette: [RGB] = CreaturePalette.idle
    private var lastShell: Double = 1
    private var lastCore: Double = 1

    private var pokeAt: Double = -100
    private var pokePoint: CGPoint = .zero
    private var pokes: [Double] = []
    private var dizzyUntil: Double = -1

    /// A gesture playing (4.10.0) and a line being said, from their start (absolute time).
    private var gesture: CreatureGesture?
    private var gestureStart: Double = 0
    private var speechLetters: [Character] = []
    private var speechSchedule: [Double] = []
    private var speechStart: Double = 0
    private var speechEmotion: CreatureSpeech.Emotion = .calm
    private var speechLook: (x: Double, y: Double)?
    /// Its life of its own (4.11.0), and when the quiet began (the creature's time): a touch, a
    /// line, a gesture or a new mood ends it.
    private var ambience = CreatureAmbience.still
    private var quietSince: Double = 0

    // MARK: Events

    func poke(at point: CGPoint, date: Date) {
        guard let origin else { return }
        let t = date.timeIntervalSinceReferenceDate - origin
        pokeAt = t
        pokePoint = point
        quietSince = t
        pokes = pokes.filter { t - $0 < 2 } + [t]
        if pokes.count >= 3 {
            dizzyUntil = t + 2.4
            pokes = []
        }
    }

    /// Plays `gesture` from `date` (4.10.0).
    func perform(_ gesture: CreatureGesture, date: Date) {
        self.gesture = gesture
        gestureStart = date.timeIntervalSinceReferenceDate
        stir(date)
    }

    /// Whether it has dozed off by `date` (4.11.0).
    func isDozing(at date: Date) -> Bool {
        guard let origin, let doze = ambience.dozesAfter else { return false }
        return date.timeIntervalSinceReferenceDate - origin - quietSince > doze
    }

    /// Something happened: the quiet starts again, and a dozing creature wakes.
    private func stir(_ date: Date) {
        if let origin { quietSince = date.timeIntervalSinceReferenceDate - origin }
    }

    /// Talks while the letters of `line` leave from `date` (4.10.0): wide for joy, barely for a
    /// whisper, not at all for a thought, when the eyes go to `look` instead. `nil` stops.
    func speak(_ line: CreatureSpeech?, emotion: CreatureSpeech.Emotion = .calm, date: Date,
               look: (x: Double, y: Double)? = nil, stirs: Bool = true) {
        let thinks = line?.isThought(emotion) ?? false
        let talks = line != nil && !thinks
        speechLetters = talks ? Array(line?.text ?? "") : []
        speechSchedule = talks ? CreatureSpeechTiming.schedule(line?.text ?? "") : []
        speechEmotion = emotion
        speechLook = thinks ? look : nil
        speechStart = date.timeIntervalSinceReferenceDate
        if line != nil, stirs { stir(date) }
    }

    // MARK: Frame

    func render(
        in context: inout GraphicsContext,
        size: CGSize,
        mood: ParticleCreature.Mood,
        style: ParticleCreature.Style,
        level: Double?,
        time: Double?,
        onLight: Bool = false,
        still: CreatureGestureFrame? = nil,
        isRTL: Bool = false,
        ambience: CreatureAmbience = .still,
        accessory: CreatureAccessory? = nil
    ) {
        let geo = Geometry(size: size, style: style)
        guard geo.radius > 1 else { return }
        let animated = time != nil
        if let time, origin == nil { origin = time }
        let t = time.map { $0 - (origin ?? $0) } ?? 0
        build(style: style, radius: geo.radius)
        self.ambience = style == .hero ? ambience : .still
        dress(accessory, t: t, animated: animated)
        if pointer != nil { quietSince = t }

        let mapped = Self.map(mood, style: style)
        if case .working(let progress) = mapped { workTarget = clampValue(progress, 0, 1) }
        // The light rises to the work done in about a fifth of a second; a still frame shows it.
        let step = animated ? clampValue((t - workClock) * CreatureWork.follow, 0, 1) : 1
        workShown += (workTarget - workShown) * step
        workClock = t
        var forced = false
        if mapped != requested {
            requested = mapped
            quietSince = t
            if case .glyph(let text) = mapped, text != glyphText {
                glyphText = text
                glyphPoints = GlyphSampler.points(for: text)
                forced = true
            }
        }
        let shown = animated ? effectivePose(at: t) : CreaturePose(mapped)
        if shown != pose || forced || !started {
            begin(shown, at: t, animated: animated && started)
        }
        started = true
        // A still frame shows the mood settled: bursts over, swells gone.
        let mt = animated ? t - poseAt : 10
        let cy = centerY(geo, t: t, mt: mt)
        let paletteMix = blending ? smoothStep(mt / 0.9) : 1
        let palette = (0..<4).map { fromPalette[$0] + (CreaturePalette.of(pose)[$0] - fromPalette[$0]) * paletteMix }
        let shellTarget: Double = 1
        let shell = blending ? fromShell + (shellTarget - fromShell) * smoothStep(mt / 0.6) : shellTarget
        let coreTarget = coreStrength(pose)
        let core = blending ? fromCore + (coreTarget - fromCore) * paletteMix : coreTarget
        let gaze = animated ? gazeDirection(geo, t: t) : (x: 0, y: 0)

        // A gesture (4.10.0): its moment while it plays, or the frame a still asks for.
        var motion = CreatureMotion.none
        if let time, let gesture {
            let shown = gesture.shown(in: style)
            let progress = (time - gestureStart) / shown.duration
            if progress >= 1 {
                self.gesture = nil
            } else if progress >= 0 {
                motion = .of(shown, progress: progress, isRTL: isRTL)
            }
        } else if time == nil, let still {
            motion = .of(still.gesture.shown(in: style), progress: still.progress, isRTL: isRTL)
        }
        // Its own life (4.11.0): now and then a fidget while it is idle and quiet.
        if animated, self.ambience.fidgets, self.gesture == nil, pose == .idle, pointer == nil,
           let fidget = CreatureFidget.at(quiet: t - quietSince) {
            motion = .fidget(fidget.fidget, progress: fidget.progress, side: isRTL ? -fidget.side : fidget.side)
        }
        // About thirty particles leave the sphere for the hand and come back after.
        let handStride = max(2, particles.count / CreatureHandMetrics.particles)
        var handPoints: [CGPoint] = []
        if style == .hero, let hand = motion.hand, hand.reach > 0.001 {
            handPoints = hand.points(count: (particles.count + handStride - 1) / handStride,
                                     center: CGPoint(x: geo.cx, y: cy), radius: geo.radius)
        }

        var parts = [CGPoint](repeating: .zero, count: particles.count)
        var depth = [Double](repeating: 0.5, count: particles.count)
        for n in particles.indices {
            var (point, z) = target(particles[n], geo, t: t, mt: mt, cy: cy, level: level)
            if blending, n < fromParts.count {
                let e = Self.carry(mt - particles[n].delay * ParticleCreatureMetrics.stagger)
                point = blend(fromParts[n], point, e)
                z = fromDepth[n] + (z - fromDepth[n]) * e
            }
            if style == .hero && animated { point = displaced(point, geo, t: t) }
            if !handPoints.isEmpty, particles[n].index % handStride == 0, let reach = motion.hand?.reach {
                let k = particles[n].index / handStride
                if k < handPoints.count {
                    let e = smoothStep((reach - particles[n].delay * 0.35) / 0.65)
                    point = blend(point, handPoints[k], e)
                    z += (0.95 - z) * e
                }
            }
            parts[n] = point
            depth[n] = z
        }

        var faceTarget = CreatureFace.of(pose)
        faceTarget.anchor = faceAnchor(geo, cy: cy)
        var face = faceTarget
        if let fromFace, animated {
            face = CreatureFace.blend(fromFace, faceTarget, Self.carryFace(mt))
            if mt > ParticleCreatureMetrics.faceTransition + 0.2 { self.fromFace = nil }
        }
        lastFace = face
        var shownFace = animated ? living(face, geo, t: t, gaze: gaze, level: level) : face
        shownFace = Self.apply(motion, to: shownFace)
        // Answering (5.3.0): it talks on its own, in phrases; a line being said takes over.
        if pose == .answering {
            shownFace.mouth = CreatureMouth(form: .open, y: shownFace.mouth.y, width: CreatureFace.talkWidth,
                                            open: animated ? CreatureAnswer.mouth(at: t) : CreatureAnswer.stillMouth)
        }
        // Talking (4.10.0): the mouth opens and shuts while the letters leave; a thought holds
        // the eyes on the words instead.
        if let time, style == .hero {
            if let open = CreatureSpeechTiming.mouth(speechSchedule, letters: speechLetters, at: time - speechStart) {
                var width = CreatureFace.talkWidth
                var opening = open
                switch speechEmotion {
                case .joy:
                    width *= 1.3
                    opening = 0.35 + 0.65 * open
                case .whisper:
                    width *= 0.7
                    opening = 0.55 * open
                case .worry, .sad:
                    width *= 0.85
                    opening = 0.7 * open
                case .automatic, .calm, .thought, .dizzy:
                    break
                }
                shownFace.mouth = CreatureMouth(form: .open, y: shownFace.mouth.y, width: width, open: opening)
            }
            if let look = speechLook {
                var glance = CreatureMotion()
                glance.gazeX = look.x
                glance.gazeY = look.y
                glance.gazeWeight = smoothStep((time - speechStart) / 0.35)
                shownFace = Self.apply(glance, to: shownFace)
            }
        }
        var tear: CGPoint?
        if pose == .sad && animated && style == .hero {
            let progress = (t * 0.55).truncatingRemainder(dividingBy: 1)
            let eye = shownFace.left
            let r = geo.radius * CreatureFace.scale
            tear = CGPoint(
                x: shownFace.anchor.x + eye.x * r,
                y: shownFace.anchor.y + (eye.y + eye.height / 2) * r + progress * r * 0.45
            )
        }

        if blending && mt > ParticleCreatureMetrics.transition + ParticleCreatureMetrics.stagger + 0.3 { blending = false }
        lastParts = parts
        lastDepth = depth
        lastPalette = palette
        lastShell = shell
        lastCore = core

        draw(in: &context, geo: geo, style: style, t: t, cy: cy, palette: palette, shell: shell,
             core: core, parts: parts, depth: depth, face: shownFace, tear: tear, motion: motion, onLight: onLight)
    }

    // MARK: Accessories

    /// What it wears (4.12.0): the accessory on it and when it was put on, and the one being
    /// taken off; the first frame dresses it without a change.
    private var worn: CreatureAccessory?
    private var wornAt: Double = -100
    private var shed: CreatureAccessory?
    private var shedAt: Double = -100
    private var dressed = false

    private func dress(_ accessory: CreatureAccessory?, t: Double, animated: Bool) {
        guard accessory != worn || !dressed else { return }
        if dressed && animated {
            shed = worn
            shedAt = t
            worn = accessory
            wornAt = t
        } else {
            shed = nil
            worn = accessory
            wornAt = -100
        }
        dressed = true
    }

    /// The pieces to draw now: the one worn (with how far it is on, `nil` all the way) and the one
    /// leaving (with how far it has gone).
    private func wardrobe(at t: Double) -> [(accessory: CreatureAccessory, on: Double?, off: Double?)] {
        var pieces: [(accessory: CreatureAccessory, on: Double?, off: Double?)] = []
        if let shed {
            let off = (t - shedAt) / CreatureAccessoryMetrics.shed
            if off < 1 { pieces.append((shed, nil, max(off, 0))) } else { self.shed = nil }
        }
        if let worn {
            let on = (t - wornAt) / CreatureAccessoryMetrics.wear
            pieces.append((worn, on < 1 ? max(on, 0) : nil, nil))
        }
        return pieces
    }

    /// One accessory: a soft fill and an outline in the mood's colours (light in the dark, ink on
    /// a light page), its solid parts stronger, dots of light along the outline. `on`: its dots
    /// gather from the sphere, then the outline and the fill come; `off`: they fade and the dots
    /// scatter.
    private func drawAccessory(
        _ accessory: CreatureAccessory,
        on: Double?,
        off: Double?,
        in context: GraphicsContext,
        origin: CGPoint,
        unit: Double,
        sphere: CGPoint,
        geo: Geometry,
        face: CreatureFace,
        palette: [RGB],
        hero: Bool,
        strength: Double,
        t: Double,
        onLight: Bool
    ) {
        let drawing = CreatureAccessoryDrawing.of(accessory, face: face)
        let place: ([CGPoint]) -> [CGPoint] = { points in
            points.map { CGPoint(x: origin.x + $0.x * unit, y: origin.y + $0.y * unit) }
        }
        func path(_ points: [CGPoint], closed: Bool) -> Path {
            var path = Path()
            path.addLines(place(points))
            if closed { path.closeSubpath() }
            return path
        }
        let lineTone = onLight ? deepen(palette[0], CreatureInk.depth) : whiten(palette[1], 0.35)
        let fillTone = onLight ? deepen(palette[0], CreatureCore.depth) : palette[0]
        let solidTone = onLight ? deepen(palette[2], 0.3) : whiten(palette[2], 0.15)
        let formed = (on.map { smoothStep(($0 - 0.45) / 0.35) } ?? 1) * (off.map { 1 - smoothStep($0 / 0.35) } ?? 1) * strength
        let filled = (on.map { smoothStep(($0 - 0.6) / 0.4) } ?? 1) * (off.map { 1 - smoothStep($0 / 0.3) } ?? 1) * strength
        let lineWidth = hero ? max(1, 1.5 * geo.scale) : max(0.7, geo.radius / 22)

        var light = context
        if !onLight { light.blendMode = .plusLighter }
        if filled > 0.01 {
            var fill = light
            fill.opacity = (onLight ? CreatureAccessoryMetrics.inkFill : CreatureAccessoryMetrics.lightFill) * filled
            for shape in drawing.shapes { fill.fill(path(shape, closed: true), with: .color(color(fillTone, 1))) }
        }
        if formed > 0.01 {
            var line = light
            line.opacity = (onLight ? CreatureGlow.inkRimPeak : CreatureGlow.rimPeak) * formed
            for shape in drawing.shapes {
                line.stroke(path(shape, closed: true), with: .color(color(lineTone, 1)), lineWidth: lineWidth)
            }
            for stroke in drawing.lines {
                line.stroke(path(stroke, closed: false), with: .color(color(lineTone, 1)),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
        // The dark lenses and the mask cover the eyes: drawn as they are, not added as light.
        let covers = accessory == .sunglasses || accessory == .sleepMask
        if filled > 0.01 && !drawing.solids.isEmpty {
            var solid = covers ? context : light
            if covers {
                solid.opacity = 0.92 * filled
                let tone = accessory == .sunglasses ? RGB(26, 24, 38) : deepen(palette[2], onLight ? 0.2 : 0.5)
                for piece in drawing.solids { solid.fill(path(piece, closed: true), with: .color(color(tone, 1))) }
                solid.opacity = (onLight ? 0.9 : 0.75) * filled
                for piece in drawing.solids {
                    solid.stroke(path(piece, closed: true), with: .color(color(lineTone, 1)), lineWidth: lineWidth)
                }
            } else {
                solid.opacity = (onLight ? CreatureAccessoryMetrics.inkSolid : CreatureAccessoryMetrics.lightSolid) * filled
                for piece in drawing.solids { solid.fill(path(piece, closed: true), with: .color(color(solidTone, 1))) }
            }
            var mark = context
            mark.opacity = 0.85 * filled
            let markTone = accessory == .sunglasses ? RGB(255, 255, 255) : whiten(palette[1], 0.6)
            for stroke in drawing.marks {
                mark.stroke(path(stroke, closed: false), with: .color(color(markTone, 1)),
                            style: StrokeStyle(lineWidth: lineWidth * 0.9, lineCap: .round, lineJoin: .round))
            }
        }
        // The dots of light along the outline: they gather from the sphere, twinkle, scatter.
        guard hero else { return }
        let spots = place(drawing.dots(spacing: CreatureAccessoryMetrics.dotSpacing * geo.radius / unit))
        guard !spots.isEmpty else { return }
        var dots = light
        let size = 1.3 * geo.unit
        let dotTone = onLight ? lineTone : whiten(lineTone, 0.4)
        for (index, spot) in spots.enumerated() {
            let i = Double(index)
            let seed = fraction(sin(i * 12.9898 + 3.3) * 43758.5453)
            var point = spot
            var alpha = 0.55 + 0.45 * (0.5 + 0.5 * sin(t * 2.4 + i * 1.7))
            if let on {
                // Out of the sphere, staggered, on a little arc.
                let local = min(max((on * CreatureAccessoryMetrics.wear - seed * CreatureAccessoryMetrics.spread)
                    / CreatureAccessoryMetrics.flight, 0), 1)
                guard local > 0 else { continue }
                let angle = seed * 2 * .pi
                let from = CGPoint(x: sphere.x + cos(angle) * geo.radius * 0.6, y: sphere.y + sin(angle) * geo.radius * 0.6)
                let e = 1 - pow(1 - local, 3)
                point = CGPoint(x: from.x + (spot.x - from.x) * e,
                                y: from.y + (spot.y - from.y) * e - sin(.pi * local) * geo.radius * 0.15)
                alpha *= min(1, local * 2)
            }
            if let off {
                let dx = spot.x - sphere.x
                let dy = spot.y - sphere.y
                let d = max(hypot(dx, dy), 1)
                let push = off * geo.radius * (0.3 + 0.3 * seed)
                point = CGPoint(x: spot.x + dx / d * push, y: spot.y + dy / d * push + off * off * geo.radius * 0.2)
                alpha *= 1 - off
            }
            dots.opacity = alpha * strength
            dots.fill(Path(ellipseIn: CGRect(x: point.x - size, y: point.y - size, width: size * 2, height: size * 2)),
                      with: .color(color(dotTone, 1)))
        }
    }

    /// What a gesture does to the face: where the eyes look, how wide they are, a blink.
    private static func apply(_ motion: CreatureMotion, to face: CreatureFace) -> CreatureFace {
        guard motion.gazeWeight > 0 || motion.eyeScale != 1 || motion.blink > 0 else { return face }
        var face = face
        let shiftX = motion.gazeX * 0.1 * motion.gazeWeight
        let shiftY = motion.gazeY * 0.07 * motion.gazeWeight
        for side in [\CreatureFace.left, \CreatureFace.right] {
            face[keyPath: side].x += shiftX
            face[keyPath: side].y += shiftY
            face[keyPath: side].width *= motion.eyeScale
            face[keyPath: side].height *= motion.eyeScale
            if motion.blink > 0, face[keyPath: side].form == .lens {
                face[keyPath: side].height *= 1 - 0.92 * motion.blink
            }
        }
        return face
    }

    // MARK: Building

    private func build(style: ParticleCreature.Style, radius: Double) {
        let count: Int = switch style {
        case .hero: min(max(Int(radius * 3.4), 150), 400)
        case .compact: 90
        }
        guard style != builtStyle || count != builtCount else { return }
        builtStyle = style
        builtCount = count

        let golden = Double.pi * (3 - 5.0.squareRoot())
        particles = (0..<count).map { i in
            let y = 1 - Double(i) / Double(count - 1) * 2
            let r = max(0, 1 - y * y).squareRoot()
            let theta = Double(i) * golden
            return Particle(
                index: i,
                tone: i % 4,
                ux: cos(theta) * r, uy: y, uz: sin(theta) * r,
                theta: theta,
                phase: Double((i * 9301 + 49297) % 233280) / 233280,
                delay: Double((i * 37) % 50) / 50
            )
        }
        lastParts = []
        lastDepth = []
        blending = false
    }

    private func begin(_ next: CreaturePose, at t: Double, animated: Bool) {
        fromFace = animated ? lastFace : nil
        if animated && lastParts.count == particles.count {
            fromParts = lastParts
            fromDepth = lastDepth
            fromPalette = lastPalette
            fromShell = lastShell
            fromCore = lastCore
            blending = true
        } else {
            fromPalette = CreaturePalette.of(next)
            fromShell = 1
            fromCore = coreStrength(next)
            blending = false
        }
        pose = next
        poseAt = t
    }

    /// How strongly the core burns in a mood (4.9.1): brighter while thinking, dim asleep; while
    /// working (5.3.0), from dim to bright with the work done.
    private func coreStrength(_ pose: CreaturePose) -> Double {
        switch pose {
        case .thinking: CreatureCore.thinking
        case .working: CreatureWork.coreFloor + (CreatureCore.thinking - CreatureWork.coreFloor) * workTarget
        case .asleep: 0.45
        case .sleepy: 0.7
        default: 1
        }
    }

    /// The compact sphere has no room for the coin or the burst; an answer only talks there.
    private static func map(_ mood: ParticleCreature.Mood, style: ParticleCreature.Style) -> ParticleCreature.Mood {
        guard style == .compact else { return mood }
        switch mood {
        case .celebrating, .glyph: return .happy
        default: return mood
        }
    }

    private func effectivePose(at t: Double) -> CreaturePose {
        let base = CreaturePose(requested)
        if t < dizzyUntil { return .dizzy }
        let cheerable: [CreaturePose] = [.idle, .listening, .asleep, .sleepy, .sad, .worried]
        if t - pokeAt < 1.3 && cheerable.contains(base) { return .happy }
        // Dozing off after a quiet spell (4.11.0): sleepy, then asleep.
        if base == .idle, let doze = ambience.dozesAfter, t - quietSince > doze {
            return t - quietSince > doze + CreatureAmbienceMetrics.drowse ? .asleep : .sleepy
        }
        return base
    }

    // MARK: Motion

    /// A change of mood: 0 → 1 over `transition`, with a small overshoot.
    private static func carry(_ elapsed: Double) -> Double {
        let x = min(max(elapsed / ParticleCreatureMetrics.transition, 0), 1)
        let s = 1.2
        let m = x - 1
        return 1 + (s + 1) * m * m * m + s * m * m
    }

    private func tilt(_ t: Double) -> Double {
        switch pose {
        case .confused: 0.13 * sin(t * 1.8)
        case .wink: 0.09
        case .dizzy: 0.15 * sin(t * 5)
        default: 0
        }
    }

    private func centerY(_ geo: Geometry, t: Double, mt: Double) -> Double {
        let r = geo.radius
        var cy = geo.restY
        switch pose {
        case .happy: cy -= abs(sin(t * 4.2)) * r * 0.14
        case .celebrating where mt >= 0.5: cy -= abs(sin(t * 4.2)) * r * 0.14
        case .proud: cy -= abs(sin(t * 2.4)) * r * 0.05
        case .worried: cy += r * 0.08 + sin(t * 1.2) * r * 0.03
        case .sad: cy += r * 0.08
        case .sleepy: cy += r * 0.03
        case .surprised: cy -= r * 0.06 * exp(-mt * 3)
        default: break
        }
        return cy
    }

    /// Saccades: quick jumps between resting points, sometimes back to the centre. The finger
    /// wins when there is one.
    private func gazeDirection(_ geo: Geometry, t: Double) -> (x: Double, y: Double) {
        if let pointer {
            return (clampValue((pointer.x - geo.cx) / (geo.radius * 1.4), -1, 1),
                    clampValue((pointer.y - geo.restY) / (geo.radius * 1.4), -1, 1))
        }
        let period = 1.7
        let k = (t / period).rounded(.down)
        let now = Self.saccade(k)
        let before = Self.saccade(k - 1)
        let s = smoothStep((t - k * period) / 0.14)
        let glance = (x: before.x + (now.x - before.x) * s, y: before.y + (now.y - before.y) * s)
        // The phone's tilt (5.3.0), the glances going on on top of it.
        if let tilt {
            return (clampValue(tilt.x + glance.x * CreatureTiltMetrics.glance, -1, 1),
                    clampValue(tilt.y + glance.y * CreatureTiltMetrics.glance, -1, 1))
        }
        return glance
    }

    private static func saccade(_ k: Double) -> (x: Double, y: Double) {
        let a = fraction(sin(k * 91.7 + 3.1) * 43758.5453)
        let b = fraction(sin(k * 57.3 + 1.7) * 24634.6345)
        return a < 0.25 ? (0, 0) : ((a - 0.5) * 1.5, (b - 0.5) * 0.9)
    }

    private static let ringRadius: [Double] = [0.66, 0.88, 1.06]
    private static let ringTilt: [Double] = [1.05, 0.55, 1.35]
    private static let ringSpin: [Double] = [1.6, -1.25, 1.0]
    private static let ringPrecession: [Double] = [0.55, 0.8, -0.45]

    private func target(_ p: Particle, _ geo: Geometry, t: Double, mt: Double, cy: Double, level: Double?) -> (CGPoint, Double) {
        let r0 = geo.radius
        let cx = geo.cx
        switch pose {
        case .thinking:
            if p.index % 5 == 0 {
                // The core turns as one ball (5.2.0): an angle per particle (its own longitude
                // added) set every one of them on the same meridian, a spinning half circle.
                let a = t * 2.2
                let x = p.ux * cos(a) + p.uz * sin(a)
                let z = -p.ux * sin(a) + p.uz * cos(a)
                return (CGPoint(x: cx + x * r0 * 0.28, y: cy + p.uy * r0 * 0.28), (z + 1) / 2)
            }
            // Gyroscope: each ring spins in its own plane and the plane turns round the centre.
            let ring = p.index % 3
            let rr = r0 * Self.ringRadius[ring] * (1 + (p.phase - 0.5) * 0.06)
            let tiltAngle = Self.ringTilt[ring]
            let spin = p.theta * 3 + t * Self.ringSpin[ring]
            let precession = t * Self.ringPrecession[ring] + Double(ring) * 2.1
            let x = cos(spin) * rr
            let z = sin(spin) * rr
            let y1 = -z * sin(tiltAngle)
            let z1 = z * cos(tiltAngle)
            let x2 = x * cos(precession) + z1 * sin(precession)
            let z2 = -x * sin(precession) + z1 * cos(precession)
            let view = 0.32
            let y3 = y1 * cos(view) - z2 * sin(view)
            let z3 = y1 * sin(view) + z2 * cos(view)
            return (CGPoint(x: cx + x2, y: cy + y3), clampValue(0.5 + 0.5 * z3 / (r0 * 1.1), 0, 1))

        case .answering where builtStyle == .hero && p.index % CreatureAnswer.ringShare == 0:
            // A third of the swarm flows in a tilted ring round the sphere (5.3.0), its front
            // passing under the face, its back behind the sphere.
            let count = (particles.count + CreatureAnswer.ringShare - 1) / CreatureAnswer.ringShare
            let k = p.index / CreatureAnswer.ringShare
            let a = Double(k) / Double(count) * 2 * .pi + t * CreatureAnswer.ringSpeed
            let rr = r0 * CreatureAnswer.ringRadius * (1 + (p.phase - 0.5) * 0.05)
            let x = cos(a) * rr
            let z = sin(a) * rr
            let y = z * sin(CreatureAnswer.ringTilt) + sin(t * 2 + p.phase * 6) * r0 * 0.012
            let depth = z * cos(CreatureAnswer.ringTilt) / (rr * 1.1)
            return (CGPoint(x: cx + x, y: cy + y + r0 * CreatureAnswer.ringDrop), clampValue(0.5 + 0.5 * depth, 0, 1))

        case .working:
            // The sphere fills with light from the bottom up (5.3.0): below the line the swarm
            // burns bright and large, above it dim; the line itself shines and ripples.
            let (point, z) = sphere(p, geo, t: t, mt: mt, cy: cy, level: level)
            let line = cy + r0 * (1 - 2 * workShown) + sin((point.x - cx) / r0 * 4 + t * 3) * r0 * CreatureWork.ripple
            let below = smoothStep((point.y - line) / (r0 * CreatureWork.edge) + 0.5)
            let crest = max(0, 1 - abs(point.y - line) / (r0 * CreatureWork.crest))
            let lit = CreatureWork.dim + (1 - CreatureWork.dim) * below
            return (point, clampValue(max(z * lit + CreatureWork.lift * below, crest), 0, 1))

        case .glyph:
            let wobble = cos(0.5 * sin(t * 2.2))
            let ringCount = Int(Double(particles.count) * 0.38)
            let x: Double
            let y: Double
            if p.index < ringCount {
                let a = Double(p.index) / Double(ringCount) * 2 * .pi + t * 0.3
                let rr = r0 * (p.index % 2 == 1 ? 0.96 : 0.86)
                x = cos(a) * rr
                y = sin(a) * rr
            } else {
                // The golden-ratio sequence spreads the particles evenly over the sign's points
                // (a stride through the scan order lined them up in stripes).
                let step = fraction(Double(p.index - ringCount) * 0.618_033_988_749_895)
                let q = glyphPoints[min(glyphPoints.count - 1, Int(step * Double(glyphPoints.count)))]
                x = q.x * r0 * 1.2
                y = q.y * r0 * 1.2 + r0 * 0.1
            }
            return (CGPoint(x: cx + x * wobble, y: cy + y), 0.75 + 0.25 * sin(p.phase * 2 * .pi + t))

        case .celebrating where mt < 0.5:
            let e = 1 - pow(1 - mt / 0.5, 3)
            let length = max(hypot(p.ux, p.uy), 0.0001)
            let d = r0 * (1 + 1.5 * e) * (0.8 + 0.4 * p.phase)
            return (CGPoint(x: cx + p.ux / length * d, y: cy + p.uy / length * d), (p.uz + 1) / 2)

        default:
            return sphere(p, geo, t: t, mt: mt, cy: cy, level: level)
        }
    }

    private func sphere(_ p: Particle, _ geo: Geometry, t: Double, mt: Double, cy: Double, level: Double?) -> (CGPoint, Double) {
        let r0 = geo.radius
        let spin: Double = switch pose {
        case .listening: 0.6
        case .asleep: 0.12
        case .sleepy, .sad: 0.15
        case .determined: 0.8
        case .working: 0.5
        case .confused: 0.25
        case .dizzy: 1.2
        default: 0.35
        }
        let a = t * spin
        let lean = 0.25 * sin(t * 0.3)
        let x = p.ux * cos(a) + p.uz * sin(a)
        let z0 = -p.ux * sin(a) + p.uz * cos(a)
        let y = p.uy * cos(lean) - z0 * sin(lean)
        let z = p.uy * sin(lean) + z0 * cos(lean)
        var r = r0 * (0.93 + 0.07 * sin(t * 1.3 + p.phase * 2 * .pi))
        switch pose {
        case .listening:
            let voice = level.map { 0.2 + 0.8 * $0 } ?? (0.45 + 0.55 * abs(sin(t * 2.7) * sin(t * 1.3 + 1)))
            r = r0 * (1 + 0.16 * voice * sin(p.uy * 10 - t * 8))
        case .worried:
            r = r * 0.84 + (fraction(sin(t * 37 + p.phase * 113) * 4375.85) - 0.5) * r0 * 0.02
        case .asleep:
            r *= 0.9
        case .surprised:
            r *= 1 + 0.14 * exp(-mt * 4)
        case .love:
            let beat = pow(max(0, sin(t * 7)), 8) + 0.6 * pow(max(0, sin(t * 7 - 0.9)), 8)
            r *= 1 + 0.06 * beat
        case .proud:
            r *= 1.04
        case .sad, .determined:
            r *= 0.92
        default:
            break
        }
        var sx = 1.0
        var sy = 1.0
        switch pose {
        case .happy, .celebrating:
            sx = 1 + 0.06 * cos(t * 8.4)
            sy = 1 / sx
        case .sad:
            sy = 0.9
        case .sleepy:
            let yawn = pow(max(0, sin(t * 1.05)), 12)
            sy = 1 + 0.09 * yawn
            sx = 1 - 0.03 * yawn
        default:
            break
        }
        var px = x * r * sx
        var py = y * r * sy
        let angle = tilt(t)
        if angle != 0 {
            (px, py) = (px * cos(angle) - py * sin(angle), px * sin(angle) + py * cos(angle))
        }
        let wobble = pose == .dizzy ? (sin(t * 6) * r0 * 0.05, cos(t * 6) * r0 * 0.03) : (0.0, 0.0)
        return (CGPoint(x: geo.cx + px + wobble.0, y: cy + py + wobble.1), (z + 1) / 2)
    }

    /// The finger pushes particles aside; a tap scatters them and they spring back.
    private func displaced(_ point: CGPoint, _ geo: Geometry, t: Double) -> CGPoint {
        var x = point.x
        var y = point.y
        if let pointer {
            let dx = x - pointer.x
            let dy = y - pointer.y
            let d = hypot(dx, dy)
            let reach = geo.radius * 0.5
            if d < reach && d > 0.01 {
                let push = (1 - d / reach) * geo.radius * 0.12
                x += dx / d * push
                y += dy / d * push
            }
        }
        let since = t - pokeAt
        if since >= 0 && since < 1.2 {
            let dx = point.x - pokePoint.x
            let dy = point.y - pokePoint.y
            let d = hypot(dx, dy) + 1
            let strength = geo.radius * 0.4 * exp(-d / (geo.radius * 0.6))
            let tau = 0.12
            let kick = (since / tau) * exp(1 - since / tau)
            x += dx / d * strength * kick
            y += dy / d * strength * kick
        }
        return CGPoint(x: x, y: y)
    }

    // MARK: Face

    /// A change of face: quicker than the swarm, with a small overshoot.
    private static func carryFace(_ elapsed: Double) -> Double {
        let x = min(max(elapsed / ParticleCreatureMetrics.faceTransition, 0), 1)
        let s = 1.4
        let m = x - 1
        return 1 + (s + 1) * m * m * m + s * m * m
    }

    /// Where the face sits: on the sphere, or over the coin.
    private func faceAnchor(_ geo: Geometry, cy: Double) -> CGPoint {
        let r0 = geo.radius
        switch pose {
        case .glyph:
            return CGPoint(x: geo.cx, y: cy - r0 * 0.55)
        default:
            return CGPoint(x: geo.cx, y: cy - r0 * 0.04)
        }
    }

    /// What time adds to a face: the gaze, blinks, a squint at the finger, the voice, the
    /// heartbeat, a little breathing.
    private func living(_ face: CreatureFace, _ geo: Geometry, t: Double, gaze: (x: Double, y: Double), level: Double?) -> CreatureFace {
        var face = face
        var lx = gaze.x
        var ly = gaze.y
        switch pose {
        case .thinking:
            lx = 0.45 + 0.15 * sin(t * 0.9)
            ly = -0.6
        case .working:
            // On the light as it rises.
            lx = 0.12 * sin(t * 0.8)
            ly = 0.55 - 0.9 * workShown
        case .asleep, .dizzy, .answering, .glyph:
            lx = 0
            ly = 0
        default:
            break
        }
        // Looking aside turns the head: both eyes slide, the far one a little smaller.
        face.left.x += lx * 0.1
        face.right.x += lx * 0.1
        face.left.y += ly * 0.07
        face.right.y += ly * 0.07
        face.left.width *= 1 + 0.08 * lx
        face.left.height *= 1 + 0.05 * lx
        face.right.width *= 1 - 0.08 * lx
        face.right.height *= 1 - 0.05 * lx
        face.anchor.y += sin(t * 1.3) * geo.radius * 0.012

        let blink = blinkAmount(t)
        if blink > 0 {
            if face.left.form == .lens { face.left.height *= 1 - 0.92 * blink }
            if face.right.form == .lens { face.right.height *= 1 - 0.92 * blink }
        }
        if pose == .idle, let pointer, hypot(pointer.x - face.anchor.x, pointer.y - face.anchor.y) < geo.radius * 0.5 {
            face.left.lid = min(face.left.lid + 0.3, 0.9)
            face.right.lid = min(face.right.lid + 0.3, 0.9)
        }
        if pose == .listening {
            let voice = level ?? (0.4 + 0.4 * abs(sin(t * 2.7) * sin(t * 1.3 + 1)))
            face.left.height *= 1 + 0.1 * voice
            face.right.height *= 1 + 0.1 * voice
        }
        if pose == .love {
            let beat = 1 + 0.1 * (pow(max(0, sin(t * 7)), 8) + 0.6 * pow(max(0, sin(t * 7 - 0.9)), 8))
            face.left.width *= beat
            face.left.height *= beat
            face.right.width *= beat
            face.right.height *= beat
        }
        return face
    }

    /// 0 open … 1 closed. A blink every 4.3 s, a double one every third time; slow and long
    /// when sleepy; shut for a moment after a tap.
    private func blinkAmount(_ t: Double) -> Double {
        if t - pokeAt < 0.3 { return 1 }
        if pose == .sleepy {
            let c = t.truncatingRemainder(dividingBy: 3)
            return c < 0.5 ? sin(c / 0.5 * .pi) : 0
        }
        let c = t.truncatingRemainder(dividingBy: 4.3)
        let pulse: (Double, Double) -> Double = { start, length in
            c >= start && c < start + length ? sin((c - start) / length * .pi) : 0
        }
        let second = Int((t / 4.3).rounded(.down)) % 3 == 2 ? pulse(0.22, 0.14) : 0
        return max(pulse(0, 0.14), second)
    }

    // MARK: Drawing

    private func draw(
        in context: inout GraphicsContext,
        geo: Geometry,
        style: ParticleCreature.Style,
        t: Double,
        cy: Double,
        palette: [RGB],
        shell: Double,
        core: Double,
        parts: [CGPoint],
        depth: [Double],
        face: CreatureFace,
        tear: CGPoint?,
        motion: CreatureMotion,
        onLight: Bool
    ) {
        let r0 = geo.radius
        let cx = geo.cx
        let shellRadius = r0 * 1.2
        let center = CGPoint(x: cx, y: cy)
        let sphereRect = CGRect(x: cx - shellRadius, y: cy - shellRadius, width: shellRadius * 2, height: shellRadius * 2)
        let globe = Path(ellipseIn: sphereRect)
        let hero = style == .hero

        // The shadow on the ground: soft all round, an ellipse of a round gradient. Light of the
        // swarm's colour in the dark, a shadow on a light page.
        if hero {
            let groundY = geo.restY + r0 * 1.34
            let lift = max(pose == .happy || pose == .celebrating ? abs(sin(t * 4.2)) : 0, motion.lift)
            let rx = r0 * 1.3 * (1 - lift * 0.2)
            let ry = r0 * 0.2
            let strength = (onLight ? CreatureInk.shadow : CreatureGlow.ground) * shell * (1 - lift * 0.4)
            let tone = onLight ? RGB(0, 0, 0) : palette[0]
            var ground = context
            ground.translateBy(x: cx, y: groundY)
            ground.scaleBy(x: 1, y: ry / rx)
            ground.fill(
                Path(ellipseIn: CGRect(x: -rx, y: -rx, width: rx * 2, height: rx * 2)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: color(tone, strength), location: 0),
                        .init(color: color(tone, strength * 0.45), location: 0.45),
                        .init(color: color(tone, 0), location: 1),
                    ]),
                    center: .zero, startRadius: 0, endRadius: rx
                )
            )
        }

        // A gesture moves the sphere and all on it, turning and squashing it round its bottom
        // (4.10.0); the shadow stays on the ground.
        var body = context
        if motion.movesSphere {
            let pivot = CGPoint(x: cx, y: cy + r0)
            body.translateBy(x: pivot.x + motion.dx * r0, y: pivot.y + motion.dy * r0)
            body.rotate(by: .radians(motion.tilt))
            body.scaleBy(x: motion.sx, y: motion.sy)
            body.translateBy(x: -pivot.x, y: -pivot.y)
        }

        // The glow round the sphere (4.7.0, where the glass was): light of its colour in the
        // dark, a faint haze on a light page; and the sweep of light while thinking.
        if shell > 0.02 {
            var glow = body
            glow.opacity = shell
            if !onLight { glow.blendMode = .plusLighter }
            let pulse = 0.8 + 0.2 * sin(t * 2)
            let alpha = (onLight ? CreatureGlow.haze : CreatureGlow.halo) * pulse
            let reach = hero
                ? min(shellRadius * CreatureGlow.reach, min(geo.width, geo.height) / 2)
                : shellRadius
            glow.fill(
                Path(ellipseIn: CGRect(x: cx - reach, y: cy - reach, width: reach * 2, height: reach * 2)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: color(palette[0], alpha), location: 0),
                        .init(color: color(palette[0], alpha * 0.6), location: min(0.95, shellRadius / reach * 0.8)),
                        .init(color: color(palette[0], 0), location: 1),
                    ]),
                    center: center, startRadius: 0, endRadius: reach
                )
            )
            if pose == .thinking && !onLight {
                glow.fill(globe, with: .conicGradient(
                    Gradient(stops: [
                        .init(color: color(CreaturePalette.sweep, 0), location: 0),
                        .init(color: color(CreaturePalette.sweepPeak, 0.12), location: 0.08),
                        .init(color: color(CreaturePalette.sweep, 0), location: 0.18),
                        .init(color: color(CreaturePalette.sweep, 0), location: 1),
                    ]),
                    center: center, angle: .radians(t * 2.5)
                ))
            }
        }

        // The swarm, bucketed by colour and depth: light added in the dark; in ink on a light
        // page (4.6.1), where light added to white is lost. The far half, the core, the near half.
        let dim: Double = pose == .asleep ? 0.45 : pose == .sleepy ? 0.7 : 1
        var swarm = body
        if !onLight { swarm.blendMode = .plusLighter }
        if !hero { swarm.clip(to: globe) }
        let levels = 6
        var dots = [[Path]](repeating: [Path](repeating: Path(), count: levels), count: 4)
        var halos = [Path](repeating: Path(), count: 4)
        let sizeFactor = hero ? 1.0 : 1.3
        for n in parts.indices {
            let z = depth[n]
            let level = min(levels - 1, max(0, Int(z * Double(levels))))
            let zl = (Double(level) + 0.5) / Double(levels)
            let radius = (0.7 + 1.8 * zl) * geo.unit * sizeFactor
            let p = parts[n]
            let tone = particles[n].tone
            dots[tone][level].addEllipse(in: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
            if hero && !onLight && z > 0.86 {
                let halo = radius * 2.6
                halos[tone].addEllipse(in: CGRect(x: p.x - halo, y: p.y - halo, width: halo * 2, height: halo * 2))
            }
        }
        func fillDots(_ range: Range<Int>) {
            for tone in 0..<4 {
                let ink = deepen(palette[tone], CreatureInk.depth)
                for level in range where !dots[tone][level].isEmpty {
                    let zl = (Double(level) + 0.5) / Double(levels)
                    let shade = onLight
                        ? color(ink, (CreatureInk.nearAlpha + CreatureInk.depthAlpha * zl) * dim)
                        : color(whiten(palette[tone], 0.15 * zl), (0.16 + 0.6 * zl) * dim)
                    swarm.fill(dots[tone][level], with: .color(shade))
                }
            }
        }
        fillDots(0..<levels / 2)
        drawCore(in: body, center: center, radius: r0, hero: hero, globe: globe, t: t,
                 palette: palette, strength: core * shell, onLight: onLight)
        fillDots(levels / 2..<levels)
        for tone in 0..<4 where !halos[tone].isEmpty {
            swarm.fill(halos[tone], with: .color(color(whiten(palette[tone], 0.14), 0.035 * dim)))
        }

        // Faint links between the nearest particles on the front.
        if hero && (pose == .idle || pose == .listening || pose == .happy) {
            let front = Array(parts.indices.filter { depth[$0] > 0.82 }.prefix(90))
            let reach = r0 * 0.17
            var links = [Path](repeating: Path(), count: 3)
            for a in front.indices {
                let pa = parts[front[a]]
                for b in (a + 1)..<front.count {
                    let pb = parts[front[b]]
                    let dx = pa.x - pb.x
                    let dy = pa.y - pb.y
                    let d2 = dx * dx + dy * dy
                    guard d2 < reach * reach else { continue }
                    let strength = 1 - d2.squareRoot() / reach
                    let bucket = min(2, Int(strength * 3))
                    links[bucket].move(to: pa)
                    links[bucket].addLine(to: pb)
                }
            }
            let linkTone = onLight ? deepen(palette[1], CreatureInk.depth) : palette[1]
            for bucket in 0..<3 where !links[bucket].isEmpty {
                let alpha = (Double(bucket) + 0.5) / 3 * (onLight ? CreatureInk.links : 0.11) * dim
                swarm.stroke(links[bucket], with: .color(color(linkTone, alpha)), lineWidth: 0.6 * max(geo.unit, 0.6))
            }
        }

        // The sphere's outline in light (4.7.0): a thin rim, brightest on the side the light
        // falls on, which drifts round slowly; with a glow in the dark, in ink on a light page.
        if shell > 0.02 {
            let rimTone = onLight ? deepen(palette[0], CreatureInk.depth) : whiten(palette[1], 0.35)
            let peak = onLight ? CreatureGlow.inkRimPeak : CreatureGlow.rimPeak
            let floor = onLight ? CreatureGlow.inkRimFloor : CreatureGlow.rimFloor
            let crest = onLight ? rimTone : whiten(rimTone, 0.55)
            let light = GraphicsContext.Shading.conicGradient(
                Gradient(stops: [
                    .init(color: color(rimTone, floor), location: 0),
                    .init(color: color(rimTone, peak * 0.7), location: 0.22),
                    .init(color: color(crest, peak), location: 0.32),
                    .init(color: color(rimTone, peak * 0.55), location: 0.45),
                    .init(color: color(rimTone, floor), location: 0.7),
                    .init(color: color(rimTone, floor), location: 1),
                ]),
                center: center,
                angle: .radians(CreatureGlow.lightAngle + t * CreatureGlow.drift)
            )
            let lineWidth = hero ? max(1, 1.5 * geo.scale) : max(0.7, r0 / 22)
            var rim = body
            rim.opacity = shell
            if !onLight {
                rim.blendMode = .plusLighter
                rim.drawLayer { halo in
                    halo.addFilter(.blur(radius: lineWidth * 2.5))
                    halo.stroke(globe, with: light, lineWidth: lineWidth * 3)
                }
            }
            rim.stroke(globe, with: light, lineWidth: lineWidth)
        }

        if hero, let hand = motion.hand, hand.reach > 0.02 {
            drawHand(hand, in: body, center: center, radius: r0, palette: palette,
                     lineWidth: max(1, 1.5 * geo.scale), onLight: onLight)
        }

        // A hat (4.12.0) on the top of the sphere, moving with it.
        let pieces = wardrobe(at: t)
        // The avatar's hat is a little smaller, its brim still on the top of the sphere.
        let hatScale = hero ? 1 : CreatureAccessoryMetrics.compactHat
        let hatOrigin = CGPoint(x: center.x, y: center.y - shellRadius * CreatureAccessoryMetrics.brim * (1 - hatScale))
        for piece in pieces where piece.accessory.isOnHead {
            drawAccessory(piece.accessory, on: piece.on, off: piece.off, in: body, origin: hatOrigin,
                          unit: shellRadius * hatScale, sphere: center, geo: geo, face: face, palette: palette,
                          hero: hero, strength: shell, t: t, onLight: onLight)
        }

        // The face, turned with the head; in ink on a light page.
        var faceLayer = body
        if !hero { faceLayer.clip(to: globe) }
        let lean = tilt(t)
        if lean != 0 {
            faceLayer.translateBy(x: cx, y: geo.restY)
            faceLayer.rotate(by: .radians(lean))
            faceLayer.translateBy(x: -cx, y: -geo.restY)
        }
        let faceInk: Double = onLight ? 1 : 0
        CreatureFaceRenderer.draw(face, in: &faceLayer, radius: r0, hero: hero, time: t, ink: faceInk)
        if let tear { CreatureFaceRenderer.tear(at: tear, radius: r0, in: &faceLayer, ink: faceInk) }

        // Glasses and masks (4.12.0) on the eyes, following the gaze; the hero only.
        if hero {
            for piece in pieces where !piece.accessory.isOnHead {
                drawAccessory(piece.accessory, on: piece.on, off: piece.off, in: faceLayer, origin: face.anchor,
                              unit: r0 * CreatureFace.scale, sphere: center, geo: geo, face: face, palette: palette,
                              hero: hero, strength: 1, t: t, onLight: onLight)
            }
        }

        if hero { drawExtras(in: &body, geo: geo, t: t, cy: cy, onLight: onLight) }
    }

    /// The hand of a wave or a point (4.10.0) once its particles have gathered: a soft fill and
    /// an outline of the mood's colours, light in the dark, ink on a light page. The particles
    /// themselves are drawn with the swarm, along the outline.
    private func drawHand(
        _ hand: CreatureHand,
        in context: GraphicsContext,
        center: CGPoint,
        radius r0: Double,
        palette: [RGB],
        lineWidth: Double,
        onLight: Bool
    ) {
        let formed = smoothStep((hand.reach - 0.35) / 0.65)
        guard formed > 0.01 else { return }
        let pieces = hand.paths(center: center, radius: r0)
        let fillTone = onLight ? deepen(palette[0], CreatureCore.depth) : palette[0]
        let lineTone = onLight ? deepen(palette[0], CreatureInk.depth) : whiten(palette[1], 0.35)
        var layer = context
        if !onLight { layer.blendMode = .plusLighter }
        // Each in a layer of its own at full strength, faded as a whole: where the pieces
        // overlap the fill is no denser, and the outline runs round the outside only.
        var fill = layer
        fill.opacity = (onLight ? CreatureHandMetrics.inkFill : CreatureHandMetrics.lightFill) * formed
        fill.drawLayer { shape in
            for piece in pieces { shape.fill(piece, with: .color(color(fillTone, 1))) }
        }
        var outline = layer
        outline.opacity = (onLight ? CreatureGlow.inkRimPeak : CreatureGlow.rimPeak) * formed
        outline.drawLayer { line in
            for piece in pieces { line.stroke(piece, with: .color(color(lineTone, 1)), lineWidth: lineWidth * 2) }
            line.blendMode = .destinationOut
            for piece in pieces { line.fill(piece, with: .color(.black)) }
        }
    }

    /// The core (4.9.1): a soft ball of the mood's colours inside the swarm, so the creature has
    /// a body on a white page. It breathes with the sphere and flares at a tap; colour on a
    /// light page, light in the dark, fainter in the avatar.
    private func drawCore(
        in context: GraphicsContext,
        center: CGPoint,
        radius r0: Double,
        hero: Bool,
        globe: Path,
        t: Double,
        palette: [RGB],
        strength: Double,
        onLight: Bool
    ) {
        let breath = sin(t * CreatureCore.breathRate)
        let since = t - pokeAt
        let flare = since >= 0 && since < 1.2 ? exp(-since / 0.25) : 0
        let alpha = min(1, (onLight ? CreatureCore.ink : CreatureCore.light) * (hero ? 1 : CreatureCore.compact)
            * strength * (1 + CreatureCore.breath * breath + CreatureCore.flare * flare))
        guard alpha > 0.005 else { return }
        let reach = r0 * CreatureCore.reach * (1 + CreatureCore.swell * breath + 0.12 * flare)
        let inner = onLight ? deepen(palette[0], CreatureCore.depth) : whiten(palette[0], 0.3)
        let outer = onLight ? deepen(palette[2], CreatureCore.depth) : palette[2]
        let middle = inner + (outer - inner) * 0.5
        var layer = context
        if !onLight { layer.blendMode = .plusLighter }
        if !hero { layer.clip(to: globe) }
        // It fills the sphere almost to the rim and has no edge: its colour holds well out from
        // the centre, then fades to nothing just inside the rim.
        layer.fill(
            Path(ellipseIn: CGRect(x: center.x - reach, y: center.y - reach, width: reach * 2, height: reach * 2)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: color(inner, alpha), location: 0),
                    .init(color: color(inner, alpha * 0.9), location: 0.3),
                    .init(color: color(middle, alpha * 0.65), location: 0.55),
                    .init(color: color(outer, alpha * 0.3), location: 0.8),
                    .init(color: color(outer, 0), location: 1),
                ]),
                center: center, startRadius: 0, endRadius: reach
            )
        )
    }

    /// The z's, hearts, sparkles and question mark beside the sphere: in ink on a light page.
    private func drawExtras(in context: inout GraphicsContext, geo: Geometry, t: Double, cy: Double, onLight: Bool) {
        let s = geo.scale
        let shellRadius = geo.radius * 1.2
        let cx = geo.cx
        var extras = context
        switch pose {
        case .asleep:
            let letter = extras.resolve(Text(verbatim: "z")
                .font(.system(size: 22 * s, weight: .heavy, design: .rounded))
                .foregroundStyle(color(onLight ? CreatureInk.sleepLetter : CreaturePalette.sleepLetter, 1)))
            for k in 0..<3 {
                let ph = (t * 0.4 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                extras.opacity = sin(ph * .pi)
                extras.draw(letter, at: CGPoint(x: cx + shellRadius * 0.72 + ph * 30 * s, y: cy - shellRadius * 0.72 - ph * 60 * s), anchor: .bottomLeading)
            }
        case .love:
            for k in 0..<3 {
                let ph = (t * 0.35 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                extras.opacity = sin(ph * .pi) * 0.85
                let heart = Self.heart(
                    at: CGPoint(x: cx + shellRadius * (0.7 + 0.15 * sin(ph * 6 + Double(k))), y: cy - shellRadius * 0.5 - ph * 90 * s),
                    scale: (0.45 + 0.15 * Double(k)) * s
                )
                extras.fill(heart, with: .color(color(onLight ? CreatureInk.heart : CreaturePalette.heart, 1)))
            }
        case .proud:
            for (k, spot) in CreaturePalette.sparkleSpots.enumerated() {
                extras.opacity = 0.25 + 0.75 * pow(abs(sin(t * 2.2 + Double(k) * 1.7)), 3)
                let spark = Self.sparkle(at: CGPoint(x: cx + spot.x * shellRadius, y: cy + spot.y * shellRadius), radius: (7 + Double(k)) * s)
                extras.fill(spark, with: .color(color(onLight ? CreatureInk.sparkle : CreaturePalette.sparkle, 1)))
            }
        case .answering:
            // Waves of light leave the rim as it talks (5.3.0), fading as they spread.
            if !onLight { extras.blendMode = .plusLighter }
            let tone = onLight ? deepen(CreaturePalette.answering[0], CreatureInk.depth) : whiten(CreaturePalette.answering[3], 0.2)
            let dot = max(0.8, 1.6 * geo.unit)
            for k in 0..<CreatureAnswer.waves {
                let progress = (t / CreatureAnswer.wavePeriod + Double(k) / Double(CreatureAnswer.waves))
                    .truncatingRemainder(dividingBy: 1)
                let radius = shellRadius * (1.02 + CreatureAnswer.waveReach * progress)
                var ring = Path()
                for n in 0..<CreatureAnswer.waveDots {
                    let a = Double(n) / Double(CreatureAnswer.waveDots) * 2 * .pi + Double(k) * 0.4
                    let point = CGPoint(x: cx + cos(a) * radius, y: cy + sin(a) * radius)
                    ring.addEllipse(in: CGRect(x: point.x - dot, y: point.y - dot, width: dot * 2, height: dot * 2))
                }
                extras.opacity = CreatureAnswer.waveAlpha * pow(1 - progress, 1.6) * min(1, progress * 6)
                extras.fill(ring, with: .color(color(tone, 1)))
            }
        case .confused:
            extras.opacity = 0.9
            let mark = extras.resolve(Text(verbatim: "?")
                .font(.system(size: 34 * s, weight: .heavy, design: .rounded))
                .foregroundStyle(color(onLight ? CreatureInk.question : CreaturePalette.question, 1)))
            extras.draw(mark, at: CGPoint(x: cx + shellRadius * 0.68, y: cy - shellRadius * 0.72 + sin(t * 2.4) * 6 * s), anchor: .bottomLeading)
        default:
            break
        }
    }

    private static func heart(at point: CGPoint, scale: Double) -> Path {
        var path = Path()
        for k in 0...24 {
            let a = Double(k) / 24 * 2 * .pi
            let sa = sin(a)
            let p = CGPoint(
                x: point.x + 16 * sa * sa * sa * scale,
                y: point.y - (13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a)) * scale
            )
            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    private static func sparkle(at point: CGPoint, radius: Double) -> Path {
        var path = Path()
        for k in 0...32 {
            let a = Double(k) / 32 * 2 * .pi
            let r = radius * (0.25 + 0.75 * pow(abs(cos(2 * a)), 5))
            let p = CGPoint(x: point.x + cos(a) * r, y: point.y + sin(a) * r)
            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    private func color(_ rgb: RGB, _ alpha: Double) -> Color {
        Color(.sRGB, red: rgb.x / 255, green: rgb.y / 255, blue: rgb.z / 255, opacity: alpha)
    }

    private func whiten(_ rgb: RGB, _ amount: Double) -> RGB {
        rgb + (RGB(repeating: 255) - rgb) * amount
    }

    private func deepen(_ rgb: RGB, _ amount: Double) -> RGB {
        rgb * (1 - amount)
    }
}

/// Light mode (4.6.1): the creature on a light page. Light added to white is lost, so it is
/// drawn with normal blending in deeper colours.
enum CreatureInk {
    /// How far a particle's colour is taken towards black.
    static let depth: Double = 0.3
    /// A particle's opacity, the far ones fainter: `nearAlpha + depthAlpha × depth`.
    static let nearAlpha: Double = 0.4
    static let depthAlpha: Double = 0.55
    /// The links' strongest opacity (0.11 in the dark, where they add light).
    static let links: Double = 0.22
    /// The shadow under the sphere, where the dark draws a light on the ground.
    static let shadow: Double = 0.18
    /// The face: its colours this much deeper, its glow this much fainter, so cyan eyes read on
    /// white.
    static let faceDepth: Double = 0.45
    static let faceGlowCut: Double = 0.7
    /// The extras: a lavender z, a pink heart, an amber sparkle, a violet question mark.
    static let sleepLetter: SIMD3<Double> = [104, 98, 170]
    static let heart: SIMD3<Double> = [228, 70, 138]
    static let sparkle: SIMD3<Double> = [222, 156, 20]
    static let question: SIMD3<Double> = [112, 92, 226]
}

/// What holds the swarm together since the glass went (4.7.0): a glow round it and a rim of
/// light along its outline, as in the owner's references of a sphere made of light.
enum CreatureGlow {
    /// The glow's opacity at the centre: light in the dark, a haze on a light page.
    static let halo: Double = 0.2
    static let haze: Double = 0.08
    /// How far the hero's glow reaches, in sphere radii (the square's edge at most).
    static let reach: Double = 1.9
    /// The light on the ground under the sphere in the dark.
    static let ground: Double = 0.2
    /// The rim's opacity where the light falls and on the far side; in the dark and in ink.
    static let rimPeak: Double = 0.85
    static let rimFloor: Double = 0.12
    static let inkRimPeak: Double = 0.6
    static let inkRimFloor: Double = 0.1
    /// Where the light falls on the rim (radians, from the right, clockwise: the lower right)
    /// and how fast it drifts round (radians a second).
    static let lightAngle: Double = 0.2
    static let drift: Double = 0.25
}

/// The core (4.9.1, the owner's idea once the glass went): a soft ball of the mood's colours
/// at the centre of the swarm, its heart. Without it the swarm had no body on a white page.
enum CreatureCore {
    /// How far it reaches, in particle-sphere radii (it fades out there): almost the whole
    /// sphere, whose rim is at 1.2 (the owner's review: the first core, 0.72, was a cloud round
    /// the eyes).
    static let reach: Double = 1.12
    /// Its opacity at the centre: colour on a light page, light in the dark (fainter there, so
    /// the glowing eyes over it keep their contrast).
    static let ink: Double = 0.55
    static let light: Double = 0.3
    /// On a light page its colours this much deeper, so the pale moods (the coin's yellow) show.
    static let depth: Double = 0.1
    /// The avatar's core, as a share of the hero's.
    static let compact: Double = 0.7
    /// The breath, in step with the sphere's (radians a second): how much it swells and
    /// brightens.
    static let breathRate: Double = 1.3
    static let swell: Double = 0.06
    static let breath: Double = 0.15
    /// Brighter while thinking; how much a tap makes it flare.
    static let thinking: Double = 1.3
    static let flare: Double = 0.6
}

/// Answering (5.3.0): the ring round the sphere, the waves from its rim, the talking mouth.
enum CreatureAnswer {
    /// Every third particle flows in the ring.
    static let ringShare = 3
    /// The ring's radius (the rim is at 1.2), its tilt (its front under the face), how far below
    /// the centre it sits, and its speed (radians a second).
    static let ringRadius: Double = 1.42
    static let ringTilt: Double = 0.42
    static let ringDrop: Double = 0.06
    static let ringSpeed: Double = 0.9
    /// A wave leaves the rim this often (seconds), three on their way at once, and goes this far
    /// (rim radii) as it fades; the dots of one.
    static let wavePeriod: Double = 1.2
    static let waves = 3
    static let waveReach: Double = 0.42
    static let waveDots = 44
    static let waveAlpha: Double = 0.55
    /// Phrases of this length (seconds) with a pause at their end; the syllables' rate.
    static let phrase: Double = 1.6
    static let pause: Double = 0.35
    static let syllables: Double = 11
    /// The mouth in a still frame.
    static let stillMouth: Double = 0.5

    /// How far the mouth is open at `t`: syllables in phrases, nearly shut in the pauses.
    static func mouth(at t: Double) -> Double {
        let inPhrase = t.truncatingRemainder(dividingBy: phrase) < phrase - pause
        guard inPhrase else { return 0.15 }
        return 0.25 + 0.75 * max(0, sin(t * syllables)) * (0.6 + 0.4 * sin(t * 2.3))
    }
}

/// Working (5.3.0): the light that fills the sphere with the work done.
enum CreatureWork {
    /// How quickly the light follows the progress (a share of the gap a second, times 5).
    static let follow: Double = 5
    /// Above the line the swarm keeps this much of its light; below it every particle comes this
    /// much nearer (brighter and larger).
    static let dim: Double = 0.45
    static let lift: Double = 0.35
    /// The line's soft edge and its shining crest (sphere radii), and its ripple.
    static let edge: Double = 0.18
    static let crest: Double = 0.07
    static let ripple: Double = 0.03
    /// The core at no work done (it reaches the thinking glow when the work is done).
    static let coreFloor: Double = 0.75
}

// MARK: - Geometry

private struct Geometry {
    let width: Double
    let height: Double
    let radius: Double
    let cx: Double
    /// The sphere's centre at rest; some moods bounce or sink from it.
    let restY: Double
    /// Particle and eye sizes.
    let unit: Double

    init(size: CGSize, style: ParticleCreature.Style) {
        width = size.width
        height = size.height
        let side = min(width, height)
        cx = width / 2
        switch style {
        case .hero:
            radius = side * 0.28
            restY = height * 0.47
            unit = radius / 105
        case .compact:
            radius = side * 0.337
            restY = height / 2
            unit = radius / 40
        }
    }

    /// The board's offsets and sizes were drawn for a radius of 150.
    var scale: Double { radius / 150 }
}

// MARK: - Poses, eyes, colours

/// The mood on screen: a requested mood, or a short reaction to a touch.
enum CreaturePose: Equatable {
    case idle, listening, thinking, answering, working, glyph, celebrating, happy, surprised, love, proud
    case wink, confused, determined, worried, sad, sleepy, asleep, dizzy

    init(_ mood: ParticleCreature.Mood) {
        switch mood {
        case .idle: self = .idle
        case .listening: self = .listening
        case .thinking: self = .thinking
        case .answering: self = .answering
        case .working: self = .working
        case .happy: self = .happy
        case .celebrating: self = .celebrating
        case .surprised: self = .surprised
        case .love: self = .love
        case .proud: self = .proud
        case .wink: self = .wink
        case .confused: self = .confused
        case .determined: self = .determined
        case .worried: self = .worried
        case .sad: self = .sad
        case .sleepy: self = .sleepy
        case .asleep: self = .asleep
        case .glyph: self = .glyph
        }
    }
}

/// The creature's own colours: four tones per pose for the swarm, and its extras. Its look is
/// its identity, so these are fixed rather than taken from the accent.
private enum CreaturePalette {
    typealias RGB = SIMD3<Double>

    static let idle: [RGB] = [[124, 108, 255], [64, 214, 255], [255, 112, 190], [176, 160, 255]]
    static let listening: [RGB] = [[96, 150, 255], [64, 228, 255], [150, 124, 255], [205, 196, 255]]
    static let thinking: [RGB] = [[124, 108, 255], [70, 200, 255], [230, 110, 220], [176, 160, 255]]
    static let answering: [RGB] = [[124, 108, 255], [150, 140, 255], [106, 92, 255], [176, 170, 255]]
    static let working: [RGB] = [[96, 130, 255], [70, 210, 255], [130, 120, 255], [150, 230, 255]]
    static let happy: [RGB] = [[46, 214, 150], [255, 214, 90], [90, 236, 180], [60, 200, 230]]
    static let coin: [RGB] = [[255, 212, 94], [255, 188, 58], [255, 236, 160], [240, 168, 40]]
    static let worried: [RGB] = [[245, 158, 40], [255, 186, 80], [255, 138, 70], [255, 214, 130]]
    static let asleep: [RGB] = [[120, 116, 190], [100, 130, 200], [150, 140, 210], [90, 100, 170]]
    static let surprised: [RGB] = [[90, 200, 255], [200, 230, 255], [130, 160, 255], [170, 240, 255]]
    static let love: [RGB] = [[255, 110, 170], [255, 160, 200], [230, 90, 150], [255, 190, 215]]
    static let proud: [RGB] = [[255, 200, 90], [176, 140, 255], [255, 226, 150], [140, 120, 255]]
    static let sad: [RGB] = [[110, 140, 210], [90, 120, 190], [140, 160, 220], [80, 110, 170]]
    static let determined: [RGB] = [[110, 90, 255], [80, 70, 220], [150, 120, 255], [60, 90, 230]]
    static let confused: [RGB] = [[150, 130, 255], [90, 200, 230], [200, 150, 255], [120, 170, 240]]
    static let sleepy: [RGB] = [[140, 130, 210], [110, 140, 210], [170, 160, 225], [100, 115, 190]]

    static func of(_ pose: CreaturePose) -> [RGB] {
        switch pose {
        case .idle, .wink, .dizzy: idle
        case .listening: listening
        case .thinking: thinking
        case .answering: answering
        case .working: working
        case .happy, .celebrating: happy
        case .glyph: coin
        case .worried: worried
        case .asleep: asleep
        case .surprised: surprised
        case .love: love
        case .proud: proud
        case .sad: sad
        case .determined: determined
        case .confused: confused
        case .sleepy: sleepy
        }
    }

    static let sweep: RGB = [120, 150, 255]
    static let sweepPeak: RGB = [130, 190, 255]
    static let sleepLetter: RGB = [186, 182, 232]
    static let heart: RGB = [255, 140, 190]
    static let sparkle: RGB = [255, 224, 140]
    static let question: RGB = [206, 198, 255]
    static let sparkleSpots: [CGPoint] = [
        CGPoint(x: -0.95, y: -0.7), CGPoint(x: 0.92, y: -0.55), CGPoint(x: -0.8, y: 0.75), CGPoint(x: 1.0, y: 0.6),
    ]
}

// MARK: - Glyph

/// The points of a character for `.glyph`, sampled once from a 160 pt rendering, as offsets
/// from the centre in units of its size.
private enum GlyphSampler {
    static func points(for text: String) -> [CGPoint] {
        let side = 160
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            let font = UIFont.systemFont(ofSize: 128, weight: .heavy)
            let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: UIColor.white])
            let bounds = string.size()
            string.draw(at: CGPoint(x: (Double(side) - bounds.width) / 2, y: (Double(side) - bounds.height) / 2 + 6))
        }
        guard let cgImage = image.cgImage else { return [.zero] }
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let base = buffer.baseAddress,
                  let bitmap = CGContext(
                    data: base, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else { return false }
            bitmap.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return [.zero] }
        var points: [CGPoint] = []
        for y in stride(from: 0, to: height, by: 3) {
            for x in stride(from: 0, to: width, by: 3) where pixels[(y * width + x) * 4 + 3] > 128 {
                points.append(CGPoint(
                    x: (Double(x) - Double(width) / 2) / Double(width),
                    y: (Double(y) - Double(height) / 2) / Double(height)
                ))
            }
        }
        return points.isEmpty ? [.zero] : points
    }
}

// MARK: - Helpers

private func clampValue(_ value: Double, _ low: Double, _ high: Double) -> Double {
    min(max(value, low), high)
}

private func fraction(_ value: Double) -> Double {
    value - value.rounded(.down)
}

private func smoothStep(_ x: Double) -> Double {
    let c = clampValue(x, 0, 1)
    return c * c * (3 - 2 * c)
}

private func blend(_ a: CGPoint, _ b: CGPoint, _ e: Double) -> CGPoint {
    CGPoint(x: a.x + (b.x - a.x) * e, y: a.y + (b.y - a.y) * e)
}

// MARK: - Skeleton

/// The creature's place while it loads: a grey sphere where the swarm will be.
public struct ParticleCreatureSkeleton: View {
    let style: ParticleCreature.Style

    public init(style: ParticleCreature.Style = .hero) {
        self.style = style
    }

    public var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let diameter = side * (style == .hero ? 0.28 : 0.337) * 2.4
            Skeleton.circle(diameter)
                .position(x: proxy.size.width / 2, y: proxy.size.height * (style == .hero ? 0.47 : 0.5))
        }
        .skeletonLoadingLabel()
    }
}
