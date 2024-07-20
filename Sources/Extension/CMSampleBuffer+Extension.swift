import Accelerate
import AVFoundation
import CoreMedia

extension CMSampleBuffer {
    @inlinable @inline(__always) var isNotSync: Bool {
        get {
            guard !sampleAttachments.isEmpty else {
                return false
            }
            return sampleAttachments[0][.notSync] != nil
        }
        set {
            guard !sampleAttachments.isEmpty else {
                return
            }
            sampleAttachments[0][.notSync] = newValue ? 1 : nil
        }
    }
    
    @available(iOS, obsoleted: 13.0)
    @available(tvOS, obsoleted: 13.0)
    @available(macOS, obsoleted: 10.15)
    var dataBuffer: CMBlockBuffer? {
        get {
            CMSampleBufferGetDataBuffer(self)
        }
        set {
            _ = newValue.map {
                CMSampleBufferSetDataBuffer(self, newValue: $0)
            }
        }
    }
}
