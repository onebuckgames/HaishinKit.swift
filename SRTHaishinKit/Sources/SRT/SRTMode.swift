import Foundation
import libsrt

/// The type of SRTHaishinKit supports srt modes.
public enum SRTMode: String, Sendable {
    /// The caller mode.
    case caller
    /// The listener mode.
    case listener
    /// The rendezvous mode.
    case rendezvous
}
