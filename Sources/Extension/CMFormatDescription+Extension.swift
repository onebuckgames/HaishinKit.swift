import CoreMedia
import Foundation

extension CMFormatDescription {
    var _mediaType: CMMediaType {
        CMFormatDescriptionGetMediaType(self)
    }

    var _mediaSubType: FourCharCode {
        CMFormatDescriptionGetMediaSubType(self)
    }

    @available(iOS, obsoleted: 13.0)
    @available(tvOS, obsoleted: 13.0)
    @available(macOS, obsoleted: 10.15)
    var audioStreamBasicDescription: AudioStreamBasicDescription? {
        return CMAudioFormatDescriptionGetStreamBasicDescription(self)?.pointee
    }

    var streamType: ESStreamType {
        switch mediaSubType {
        case .hevc:
            return .h265
        case .h264:
            return .h264
        case .mpeg4AAC_LD:
            return .adtsAac
        default:
            return .unspecific
        }
    }
}
