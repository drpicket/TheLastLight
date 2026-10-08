import Foundation

/// Short, playable excerpts from the existing Astral mystery. The full recovered record
/// remains available in the investigation journal after an encounter concludes.
struct StoryMoment {
    let lines: [String]
    let question: String

    static let byLoreID: [String: StoryMoment] = [
        "transmission_01": StoryMoment(
            lines: ["PROBE TRANSMISSION // ...if anyone can hear this...",
                    "The stars aren't dying. They're being collected.",
                    "Captain Voss went looking for whoever was taking them. Her trail ends here."],
            question: "Who is collecting the stars?"),
        "ship_log_01": StoryMoment(
            lines: ["RECOVERED SHIP LOG // The crew vanished without a distress call.",
                    "The ship's AI repeated one sentence: They were never stars. They were seeds."],
            question: "Seeds of what?"),
        "signal_01": StoryMoment(
            lines: ["UNIDENTIFIED SIGNAL // A pulse repeats every 47 seconds.",
                    "It points toward the Shattered Nebula. Beneath the static: thousands of heartbeats."],
            question: "What is waiting inside the nebula?"),
        "transmission_02": StoryMoment(
            lines: ["WAYFARER WARNING // The anomalies form deliberate patterns.",
                    "A probe wasn't torn apart. Its readings placed it in six locations at once."],
            question: "Who arranged the gravity field?"),
        "astral_log_01": StoryMoment(
            lines: ["ASTRAL TEXT // Each Heartstar holds a memory, preserved in light.",
                    "Their creators scattered them before leaving. Now the memories are moving."],
            question: "What is calling the memories home?"),
        "signal_02": StoryMoment(
            lines: ["UNIDENTIFIED SIGNAL // The music comes from the stars themselves.",
                    "Slowed down, it sounds like a song about leaving. A second verse is still hidden."],
            question: "Is the song a warning or an invitation?"),
        "transmission_03": StoryMoment(
            lines: ["SCIENCE DIVISION // The structure is still operating after millennia.",
                    "Fragments orbit its center in perfect spirals. At the center: a point of light."],
            question: "Is that light a doorway?"),
        "astral_log_02": StoryMoment(
            lines: ["ASTRAL TEXT // We left the Heartstars to light someone else's way.",
                    "When you hear our song, you must decide where to bring their light."],
            question: "What choice did the Astrals leave behind?"),
        "ship_log_02": StoryMoment(
            lines: ["RECOVERED SHIP LOG // The central star is brighter, but the fragments won't stay.",
                    "They drift toward the Black Expanse. Command called it an illusion."],
            question: "Where are the fragments actually going?"),
        "transmission_04": StoryMoment(
            lines: ["WAYFARER SEVEN // The darkness bends light around something enormous.",
                    "The song comes from inside it. Final words: I'm going to follow the stars."],
            question: "What is hidden in the darkness?"),
        "signal_03": StoryMoment(
            lines: ["UNIDENTIFIED VOICE // It knows every star you've gathered.",
                    "It asks you to come see where home is. It sounds almost kind."],
            question: "Who has been watching the Wayfarers?"),
        "astral_log_03": StoryMoment(
            lines: ["ASTRAL TEXT // The Heart is a moment, not a place.",
                    "Return the light to the dying star, or carry it into the unknown."],
            question: "Can either path save the galaxy?"),
        "transmission_05": StoryMoment(
            lines: ["WAYFARER COMMAND // The Astrals are real. They are waiting.",
                    "The Heartstars were never a test of strength. They were a question."],
            question: "What answer will you give them?"),
        "astral_log_04": StoryMoment(
            lines: ["ASTRAL TEXT // You followed the lights. You are no longer alone.",
                    "The Astrals offer a place among them, but the central star still fades."],
            question: "Will you stay or take the light back?"),
        "final_signal": StoryMoment(
            lines: ["UNIVERSAL SIGNAL // Choose the light that sustains, or the light that explores.",
                    "There is no wrong answer. Only your answer."],
            question: "What comes after the last light?")
    ]
}
