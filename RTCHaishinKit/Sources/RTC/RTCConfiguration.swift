import Foundation
import libdatachannel

protocol RTCConfigurationConvertible: Sendable {
    var iceServers: [String] { get }
    var bindAddress: String? { get }
    var certificateType: RTCCertificateType? { get }
    var iceTransportPolicy: RTCTransportPolicy? { get }
    var isIceUdpMuxEnabled: Bool { get }
    var isAutoNegotionEnabled: Bool { get }
    var isForceMediaTransport: Bool { get }
    var portRange: Range<UInt16>? { get }
    var mtu: Int32? { get }
    var maxMesasgeSize: Int32? { get }
}

extension RTCConfigurationConvertible {
    func createPeerConnection() -> Int32 {
        return iceServers.withCStringArray { cIceServers in
            return [bindAddress ?? ""].withCStrings { cStrings in
                var config = rtcConfiguration()
                if !iceServers.isEmpty {
                    config.iceServers = cIceServers
                    config.iceServersCount = Int32(iceServers.count)
                }
                if bindAddress != nil {
                    config.bindAddress = cStrings[0]
                }
                if let certificateType {
                    config.certificateType = certificateType.cValue
                }
                if let iceTransportPolicy {
                    config.iceTransportPolicy = iceTransportPolicy.cValue
                }
                config.enableIceUdpMux = isIceUdpMuxEnabled
                config.disableAutoNegotiation = !isAutoNegotionEnabled
                config.forceMediaTransport = isForceMediaTransport
                if let portRange {
                    config.portRangeBegin = portRange.lowerBound
                    config.portRangeEnd = portRange.upperBound
                }
                if let mtu {
                    config.mtu = mtu
                }
                if let maxMesasgeSize {
                    config.maxMessageSize = maxMesasgeSize
                }
                return rtcCreatePeerConnection(&config)
            }
        }
    }
}

struct RTCConfiguration: RTCConfigurationConvertible {
    let iceServers: [String]
    let bindAddress: String?
    let certificateType: RTCCertificateType?
    let iceTransportPolicy: RTCTransportPolicy?
    let isIceUdpMuxEnabled: Bool
    let isAutoNegotionEnabled: Bool
    let isForceMediaTransport: Bool
    let portRange: Range<UInt16>?
    let mtu: Int32?
    let maxMesasgeSize: Int32?

    init(iceServers: [String] = [],
         bindAddress: String? = nil,
         certificateType: RTCCertificateType? = nil,
         iceTransportPolicy: RTCTransportPolicy? = nil,
         isIceUdpMuxEnabled: Bool = false,
         isAutoNegotionEnabled: Bool = true,
         isForceMediaTransport: Bool = false,
         portRange: Range<UInt16>? = nil,
         mtu: Int32? = nil,
         maxMesasgeSize: Int32? = nil
    ) {
        self.iceServers = iceServers
        self.bindAddress = bindAddress
        self.certificateType = certificateType
        self.iceTransportPolicy = iceTransportPolicy
        self.isIceUdpMuxEnabled = isIceUdpMuxEnabled
        self.isAutoNegotionEnabled = isAutoNegotionEnabled
        self.isForceMediaTransport = isForceMediaTransport
        self.portRange = portRange
        self.mtu = mtu
        self.maxMesasgeSize = maxMesasgeSize
    }
}
