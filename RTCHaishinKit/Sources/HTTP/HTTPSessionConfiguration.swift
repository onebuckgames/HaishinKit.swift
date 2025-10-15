import HaishinKit

/// A configuration object that defines options for an HTTPSession.
///
/// The properties of this structure are internally converted into
/// an `RTCConfiguration` and applied when creating the underlying
/// `RTCPeerConnection`.
///
public struct HTTPSessionConfiguration: SessionConfiguration, RTCConfigurationConvertible {
    /// A list of ICE server URLs used to establish the connection.
    public var iceServers: [String] = []

    /// The local IP address to bind sockets to.
    public var bindAddress: String?

    /// The type of certificate to generate for DTLS handshakes.
    public var certificateType: RTCCertificateType?

    /// The ICE transport policy that controls how candidates are gathered.
    public var iceTransportPolicy: RTCTransportPolicy?

    /// A Boolean value that indicates whether ICE UDP multiplexing is enabled.
    public var isIceUdpMuxEnabled: Bool = false

    /// A Boolean value that indicates whether negotiation is performed automatically.
    public var isAutoNegotionEnabled: Bool = true

    /// A Boolean value that forces the use of media transport even for data sessions.
    public var isForceMediaTransport: Bool = false

    /// The port range available for allocating ICE candidates.
    public var portRange: Range<UInt16>?

    /// The maximum transmission unit (MTU) for outgoing packets.
    public var mtu: Int32?

    /// The maximum message size allowed for data channels.
    public var maxMesasgeSize: Int32?
}
