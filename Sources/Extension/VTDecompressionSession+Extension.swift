import Foundation
import VideoToolbox

extension VTDecompressionSession: VTSessionConvertible {
    static let defaultDecodeFlags: VTDecodeFrameFlags = [
        ._EnableAsynchronousDecompression,
        ._EnableTemporalProcessing
    ]

    @inline(__always)
    func convert(_ sampleBuffer: CMSampleBuffer, continuation: AsyncThrowingStream<CMSampleBuffer, any Error>.Continuation?) {
        var flagsOut: VTDecodeInfoFlags = []
        var _: VTEncodeInfoFlags = []
        VTDecompressionSessionDecodeFrame(
            self,
            sampleBuffer: sampleBuffer,
            flags: Self.defaultDecodeFlags,
            infoFlagsOut: &flagsOut,
            outputHandler: { status, _, imageBuffer, presentationTimeStamp, duration in
                guard let imageBuffer else {
                    continuation?.finish(throwing: VTSessionError.failedToConvert(status: status))
                    return
                }
                var status = noErr
                var outputFormat: CMFormatDescription?
                status = CMVideoFormatDescriptionCreateForImageBuffer(
                    allocator: kCFAllocatorDefault,
                    imageBuffer: imageBuffer,
                    formatDescriptionOut: &outputFormat
                )
                guard let outputFormat, status == noErr else {
                    continuation?.finish(throwing: VTSessionError.failedToConvert(status: status))
                    return
                }
                var timingInfo = CMSampleTimingInfo(
                    duration: duration,
                    presentationTimeStamp: presentationTimeStamp,
                    decodeTimeStamp: .invalid
                )
                var sampleBuffer: CMSampleBuffer?
                status = CMSampleBufferCreateForImageBuffer(
                    allocator: kCFAllocatorDefault,
                    imageBuffer: imageBuffer,
                    dataReady: true,
                    makeDataReadyCallback: nil,
                    refcon: nil,
                    formatDescription: outputFormat,
                    sampleTiming: &timingInfo,
                    sampleBufferOut: &sampleBuffer
                )
                if let sampleBuffer {
                    continuation?.yield(sampleBuffer)
                } else {
                    continuation?.finish(throwing: VTSessionError.failedToConvert(status: status))
                }
            }
        )
    }

    func invalidate() {
        VTDecompressionSessionInvalidate(self)
    }
}
