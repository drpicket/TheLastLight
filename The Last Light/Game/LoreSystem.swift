import Foundation

struct LoreEntry: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let region: Region
    let category: LoreCategory
    let discoveryHint: String
    
    func isDiscovered(gameState: GameState = GameState.shared) -> Bool {
        return gameState.discoveredLore.contains(id)
    }
}

enum LoreCategory: String, Codable, CaseIterable {
    case transmission = "Transmission"
    case astralLog = "Astral Log"
    case shipRecord = "Ship Record"
    case signal = "Strange Signal"
    case environmental = "Environmental Clue"
    
    var icon: String {
        switch self {
        case .transmission: return "antenna.radiowaves.left.and.right"
        case .astralLog: return "scroll"
        case .shipRecord: return "doc.text"
        case .signal: return "waveform"
        case .environmental: return "eye"
        }
    }
}

enum LoreSystem {
    static let allEntries: [LoreEntry] = [
        LoreEntry(
            id: "transmission_01",
            title: "First Contact",
            content: """
            [SIGNAL DECRYPTED]
            
            "...if anyone receives this, the Heartstars are falling. We tried to stabilize them, but the pull is too strong. Something is calling them home.
            
            I don't know who built them. I don't know where they're going. But the stars... they're not dying. They're being collected.
            
            If you're hearing this, you're one of the last Wayfarers. Collect the fragments. Bring them back to the central star. It's all we can do.
            
            — Captain Elara Voss, Wayfarer Corps"
            """,
            region: .silentBelt,
            category: .transmission,
            discoveryHint: "Collect your first stars in the Silent Belt"
        ),
        LoreEntry(
            id: "ship_log_01",
            title: "Abandoned Vessel",
            content: """
            [RECOVERED SHIP LOG]
            
            Day 247 since the fall.
            
            We found another Wayfarer drifting near the belt. No crew. The ship's AI was still running, repeating the same message: "They're not stars. They were never stars. They're seeds."
            
            Seeds of what?
            
            The crew's personal logs mention hearing music in the static. Beautiful, impossible music. Three crew members left the ship to follow it. We never saw them again.
            
            I'm not going to follow the music.
            """,
            region: .silentBelt,
            category: .shipRecord,
            discoveryHint: "Explore the Silent Belt thoroughly"
        ),
        LoreEntry(
            id: "signal_01",
            title: "The Whisper",
            content: """
            [UNIDENTIFIED SIGNAL]
            
            The signal repeats every 47 seconds. It's not random noise—it has structure. Layers upon layers of information compressed into a single tone.
            
            When I slow it down, I hear what sounds like... breathing? No. Heartbeats. Thousands of heartbeats, all slightly out of sync.
            
            The signal is coming from the direction of the Shattered Nebula. But that's impossible. Nothing lives in the nebula. The gravitational shear would tear any ship apart.
            
            Unless the ship was built to withstand it.
            """,
            region: .silentBelt,
            category: .signal,
            discoveryHint: "Collect 20 stars in the Silent Belt"
        ),
        LoreEntry(
            id: "transmission_02",
            title: "Gravitational Warning",
            content: """
            [SIGNAL DECRYPTED]
            
            "To all Wayfarers: avoid the Shattered Nebula. The gravitational anomalies are not natural. They form patterns—spirals, lattices, geometries that shouldn't exist in nature.
            
            We sent a probe into the nebula. The last transmission showed the probe being pulled in six directions at once. The readings were impossible. The probe was in six places simultaneously.
            
            The nebula isn't destroying matter. It's sorting it. Arranging it. Like someone organizing their tools.
            
            — Wayfarer Command"
            """,
            region: .shatteredNebula,
            category: .transmission,
            discoveryHint: "Enter the Shattered Nebula"
        ),
        LoreEntry(
            id: "astral_log_01",
            title: "The Architect's Note",
            content: """
            [ASTRAL TEXT - TRANSLATED]
            
            "We built the Heartstars to be eternal. Not because we feared death, but because we feared forgetting.
            
            Each Heartstar contains a memory. A moment from our civilization, preserved in light. When they shine, we exist. When they fade, we are forgotten.
            
            We are leaving this galaxy, but we cannot take the Heartstars with us. They are too heavy with memory. So we will scatter them, and let them find their way home.
            
            If you are reading this, you are helping us remember. Thank you."
            """,
            region: .shatteredNebula,
            category: .astralLog,
            discoveryHint: "Collect blue stars in the Shattered Nebula"
        ),
        LoreEntry(
            id: "signal_02",
            title: "The Song",
            content: """
            [UNIDENTIFIED SIGNAL]
            
            The music is louder here. It's not coming from outside—it's coming from the stars themselves. When I hold a blue star near the ship's sensors, the music becomes clear.
            
            It's a song about leaving. About a civilization that grew so advanced they became lonely. They filled the galaxy with artificial stars so they'd never be alone, but even that wasn't enough.
            
            The song has a second verse. I can barely hear it. It sounds like... an invitation?
            
            The stars aren't falling. They're answering a call.
            """,
            region: .shatteredNebula,
            category: .signal,
            discoveryHint: "Collect 30 stars in the Shattered Nebula"
        ),
        LoreEntry(
            id: "transmission_03",
            title: "The Astral Structure",
            content: """
            [SIGNAL DECRYPTED]
            
            "We've found it. The structure in the Forgotten Orbit. It's not a ruin—it's a machine. Still active after thousands of years.
            
            The structure is a collector. It's been gathering star fragments, pulling them in with a gravitational field we can't explain. The fragments orbit it in perfect spirals, like water draining.
            
            At the center of the structure is a single point of light. It's not a star. It's a... doorway? A seed?
            
            The Astrals didn't just leave. They left something behind. Something that's still working.
            
            — Dr. Kael Ren, Wayfarer Science Division"
            """,
            region: .forgottenOrbit,
            category: .transmission,
            discoveryHint: "Enter the Forgotten Orbit"
        ),
        LoreEntry(
            id: "astral_log_02",
            title: "The Farewell",
            content: """
            [ASTRAL TEXT - TRANSLATED]
            
            "Today we leave. Not because we must, but because we choose to.
            
            We have seen what becomes of civilizations that stay too long. They grow afraid. They build walls around their stars. They forget that the universe is vast and beautiful and meant to be explored.
            
            We are not dying. We are graduating.
            
            To whoever finds this: the Heartstars are our gift. They will light your way. But know that they are also a question. When you gather enough of them, you will hear our song. And then you must decide: will you return the light to what is dying, or will you follow it to what is waiting?
            
            Both choices are correct. Both choices are wrong. That is the nature of choice."
            """,
            region: .forgottenOrbit,
            category: .astralLog,
            discoveryHint: "Collect golden stars in the Forgotten Orbit"
        ),
        LoreEntry(
            id: "ship_log_02",
            title: "The Collector's Dilemma",
            content: """
            [RECOVERED SHIP LOG]
            
            Day 891 since the fall.
            
            I've been collecting stars for months now. The central star is brighter—everyone says so. The galaxy is healing.
            
            But I can't shake the feeling that I'm not saving the stars. I'm delivering them.
            
            The stars I collect... they don't stay at the central star. They drift. Slowly, imperceptibly, they drift toward the Black Expanse. Toward the Heart.
            
            I reported this to Command. They said it was gravitational lensing. An optical illusion.
            
            But I've been a pilot for twenty years. I know when something is moving.
            
            The stars are going somewhere. And I think the Astrals want them to.
            """,
            region: .forgottenOrbit,
            category: .shipRecord,
            discoveryHint: "Collect 40 stars in the Forgotten Orbit"
        ),
        LoreEntry(
            id: "transmission_04",
            title: "Into Darkness",
            content: """
            [SIGNAL DECRYPTED]
            
            "This is Wayfarer Seven. I'm entering the Black Expanse.
            
            There are almost no stars here. The few that remain are dim, flickering, like candles in a storm. They're being pulled away even as I watch.
            
            The darkness isn't empty. It's full. Full of something I can't see. Something that bends light around it.
            
            I can hear the song clearly now. It's not coming from ahead. It's coming from below. From within. From inside the darkness itself.
            
            The Astrals didn't leave the galaxy. They went inside it.
            
            I'm going to follow the stars. If anyone finds this log, tell my daughter—"
            
            [SIGNAL LOST]
            """,
            region: .blackExpanse,
            category: .transmission,
            discoveryHint: "Enter the Black Expanse"
        ),
        LoreEntry(
            id: "signal_03",
            title: "The Pull",
            content: """
            [UNIDENTIFIED SIGNAL]
            
            The signal here is different. It's not a song anymore. It's a voice.
            
            It says my name.
            
            It knows how many stars I've collected. It knows where I'm from. It knows about the Wayfarer Corps, about the central star, about everything.
            
            And it says: "You've brought so many home. Won't you come see where home is?"
            
            The voice is warm. Kind. Like a parent calling a child to dinner.
            
            I should be terrified. But I'm not. I'm curious.
            
            What if the Astrals aren't gone? What if they're just... somewhere else? And the stars are the path to finding them?
            
            What if saving the galaxy and finding the Astrals are the same thing?
            """,
            region: .blackExpanse,
            category: .signal,
            discoveryHint: "Collect 25 stars in the Black Expanse"
        ),
        LoreEntry(
            id: "astral_log_03",
            title: "The Invitation",
            content: """
            [ASTRAL TEXT - TRANSLATED]
            
            "We know you're close. We've been watching you collect our stars, one by one, with such care and determination.
            
            You remind us of ourselves, long ago. Before we learned to build Heartstars. Before we learned to leave.
            
            The Heart is not a place. It's a moment. The moment when a civilization decides what it wants to be.
            
            We chose to explore. To leave. To scatter our memories across the galaxy so that someone, someday, would follow.
            
            You've followed. You've gathered. Now comes the choice.
            
            The central star is dying. You can save it with the stars you've collected. The galaxy will live. But the path will close.
            
            Or you can bring the stars to the Heart. The Astrals will return. The galaxy will change. But nothing will ever be the same.
            
            There is no wrong choice. Only your choice."
            """,
            region: .blackExpanse,
            category: .astralLog,
            discoveryHint: "Collect ancient stars in the Black Expanse"
        ),
        LoreEntry(
            id: "transmission_05",
            title: "The Last Light",
            content: """
            [SIGNAL DECRYPTED]
            
            "This is the final transmission from Wayfarer Command.
            
            If you're hearing this, you've reached the Heart. You've seen what we only dreamed of.
            
            The Astrals are real. They're waiting. And they're not what we expected.
            
            They're not gods. They're not monsters. They're just... people. People who made a choice a long time ago, and who have been waiting for someone to make the same choice.
            
            The Heartstars were never meant to be collected. They were meant to be a test. A question. A way to find someone brave enough to follow the light into the unknown.
            
            You are that someone.
            
            Whatever you decide, know this: the galaxy is proud of you. We are proud of you.
            
            The last light is not the end. It's the beginning.
            
            — Wayfarer Command, signing off"
            """,
            region: .heart,
            category: .transmission,
            discoveryHint: "Enter the Heart"
        ),
        LoreEntry(
            id: "astral_log_04",
            title: "Welcome Home",
            content: """
            [ASTRAL TEXT - TRANSLATED]
            
            "You came.
            
            We weren't sure anyone would. It's been so long. Thousands of your years. We've watched your species grow, watched you look up at the stars and wonder.
            
            You wondered about us. And in wondering, you became like us.
            
            The Heartstars were our gift to you. Not because we wanted you to save us, but because we wanted you to have a choice. A real choice. The kind of choice that defines a civilization.
            
            You can return the stars to your central star. Your galaxy will live. And we will remain here, in the Heart, waiting for the next species to follow the light.
            
            Or you can stay. Join us. Help us build new Heartstars for new galaxies. Become what we became.
            
            Either way, you are no longer alone. You never were. The stars were always watching. We were always watching.
            
            Welcome home, Wayfarer."
            """,
            region: .heart,
            category: .astralLog,
            discoveryHint: "Collect ancient stars in the Heart"
        ),
        LoreEntry(
            id: "final_signal",
            title: "The Choice",
            content: """
            [UNIVERSAL SIGNAL]
            
            The signal is coming from everywhere and nowhere. It's not sound. It's not light. It's something deeper. Something that resonates in the space between atoms.
            
            It says:
            
            "You have gathered the fragments. You have heard our story. You have seen the Heart.
            
            Now, Wayfarer, you must choose.
            
            Will you be the light that sustains? Or the light that explores?
            
            Will you return the stars to the dying, or will you carry them to the unknown?
            
            There is no wrong answer. There is only your answer.
            
            Choose."
            
            [AWAITING INPUT]
            """,
            region: .heart,
            category: .signal,
            discoveryHint: "Reach the center of the Heart"
        )
    ]
    
    static func entries(for region: Region) -> [LoreEntry] {
        return allEntries.filter { $0.region == region }
    }
    
    static func discoveredEntries(gameState: GameState = GameState.shared) -> [LoreEntry] {
        return allEntries.filter { gameState.discoveredLore.contains($0.id) }
    }
    
    static func undiscoveredEntries(gameState: GameState = GameState.shared) -> [LoreEntry] {
        return allEntries.filter { !gameState.discoveredLore.contains($0.id) }
    }
    
    static func entry(withId id: String) -> LoreEntry? {
        return allEntries.first { $0.id == id }
    }
}
