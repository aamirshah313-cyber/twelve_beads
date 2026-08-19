/// Machine opponent difficulty, per 05-ai-and-gameplay-systems.md:
/// - [easy]: weighted/random legal choice (mandatory capture is already
///   enforced by `legalActions` itself, so "always takes obvious captures"
///   falls out for free).
/// - [medium]: shallow negamax with alpha-beta, fixed depth.
/// - [difficult]: iterative deepening negamax with alpha-beta, move
///   ordering, a transposition cache, and a device-safe time budget.
enum Difficulty { easy, medium, difficult }
