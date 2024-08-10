import Foundation

enum RTMPChunkError: Swift.Error {
    case bufferUnderflow
    case unknowChunkType(value: UInt8)
}

enum RTMPChunkType: UInt8 {
    case zero = 0
    case one = 1
    case two = 2
    case three = 3

    var headerSize: Int {
        switch self {
        case .zero:
            return 11
        case .one:
            return 7
        case .two:
            return 3
        case .three:
            return 0
        }
    }
}

enum RTMPChunkStreamId: UInt16 {
    case control = 0x02
    case command = 0x03
    case audio = 0x04
    case video = 0x05
    case data = 0x08
}

final class RTMPChunkMessageHeader {
    static let chunkSize = 128
    static let maxTimestamp: UInt32 = 0xFFFFFF

    var timestamp: UInt32 = 0
    var messageLength: Int = 0 {
        didSet {
            guard payload.count != messageLength else {
                return
            }
            payload = Data(count: messageLength)
            position = 0
        }
    }
    var messageTypeId: UInt8 = 0
    var messageStreamId: UInt32 = 0
    private(set) var payload = Data()
    private var position = 0

    init() {
    }

    init(timestmap: UInt32, messageLength: Int, messageTypeId: UInt8, messageStreamId: UInt32) {
        self.timestamp = timestmap
        self.messageLength = messageLength
        self.messageTypeId = messageTypeId
        self.messageStreamId = messageStreamId
        self.payload = Data(count: messageLength)
    }

    func put(_ buffer: RTMPChunkBuffer, chunkSize: Int) throws {
        let length = min(chunkSize, messageLength - position)
        if buffer.remaining < length {
            throw RTMPChunkError.bufferUnderflow
        }
        self.payload.replaceSubrange(position..<position + length, with: buffer.get(length))
        position += length
    }

    func reset() {
        position = 0
    }

    func makeMessage() -> (any RTMPMessage)? {
        if position < payload.count {
            return nil
        }
        switch messageTypeId {
        case 0x01:
            return RTMPSetChunkSizeMessage(self)
        case 0x02:
            return RTMPAbortMessge(self)
        case 0x03:
            return RTMPAcknowledgementMessage(self)
        case 0x04:
            return RTMPUserControlMessage(self)
        case 0x05:
            return RTMPWindowAcknowledgementSizeMessage(self)
        case 0x06:
            return RTMPSetPeerBandwidthMessage(self)
        case 0x08:
            return RTMPAudioMessage(self)
        case 0x09:
            return RTMPVideoMessage(self)
        case 0x0F:
            return RTMPDataMessage(self, objectEncoding: .amf3)
        case 0x10:
            return RTMPSharedObjectMessage(self, objectEncoding: .amf3)
        case 0x11:
            return RTMPCommandMessage(self, objectEncoding: .amf3)
        case 0x12:
            return RTMPDataMessage(self, objectEncoding: .amf0)
        case 0x13:
            return RTMPSharedObjectMessage(self, objectEncoding: .amf0)
        case 0x14:
            return RTMPCommandMessage(self, objectEncoding: .amf0)
        case 0x16:
            return RTMPAggregateMessage(self)
        default:
            return nil
        }
    }
}

final class RTMPChunkBuffer {
    var payload: Data {
        return data[position..<length]
    }

    var chunkSize: Int = RTMPChunkMessageHeader.chunkSize

    var remaining: Int {
        return length - position
    }

    var hasRemaining: Bool {
        return 0 < length - position
    }

    var position = 0

    private var data: Data
    private var length = 0

    init(_ data: Data) {
        self.data = data
    }

    func flip() -> Self {
        length = position
        position = 0
        return self
    }

    func get(_ length: Int) -> Data {
        defer {
            position += length
        }
        return data[position..<position + length]
    }

    func getBasicHeader() throws -> (RTMPChunkType, UInt16) {
        let rawValue = (data[position] & 0b11000000) >> 6
        guard let type = RTMPChunkType(rawValue: rawValue) else {
            throw RTMPChunkError.unknowChunkType(value: rawValue)
        }
        switch data[position] & 0b00111111 {
        case 0:
            defer {
                position += 2
            }
            return (type, UInt16(data[position + 1]) + 64)
        case 1:
            defer {
                position += 3
            }
            return (type, UInt16(data: data[position + 1...position + 2]) + 64)
        default:
            defer {
                position += 1
            }
            return (type, UInt16(data[position] & 0b00111111))
        }
    }

    func getMessageHeader(_ type: RTMPChunkType, messageHeader: RTMPChunkMessageHeader) throws {
        switch type {
        case .zero:
            messageHeader.timestamp = UInt32(data: data[position..<position + 3]).bigEndian
            messageHeader.messageLength = Int(Int32(data: data[position + 3..<position + 6]).bigEndian)
            messageHeader.messageTypeId = data[position + 6]
            messageHeader.messageStreamId = UInt32(data: data[position + 7..<position + 11])
            position += 11
        case .one:
            messageHeader.timestamp = UInt32(data: data[position..<position + 3]).bigEndian
            messageHeader.messageLength = Int(Int32(data: data[position + 3..<position + 6]).bigEndian)
            messageHeader.messageTypeId = data[position + 6]
            position += 7
        case .two:
            messageHeader.timestamp = UInt32(data: data[position..<position + 3]).bigEndian
            position += 3
        case .three:
            break
        }

        if messageHeader.timestamp == RTMPChunkMessageHeader.maxTimestamp {
            messageHeader.timestamp = UInt32(data: data[position..<position + 4]).bigEndian
            position += 4
        }

        try messageHeader.put(self, chunkSize: chunkSize)
    }

    func put(_ data: Data) {
        let payload = payload
        let length = payload.count
        if self.data.count < data.count + length {
            self.data = Data(count: data.count + length)
        }
        self.data.replaceSubrange(0..<length, with: payload)
        self.data.replaceSubrange(length..<length + data.count, with: data)
        position = 0
        self.length = length + data.count
    }

    func putBasicHeader(_ chunkType: RTMPChunkType, chunkStreamId: UInt16) -> Self {
        if chunkStreamId <= 63 {
            data[position] = chunkType.rawValue << 6 | UInt8(chunkStreamId)
            position += 1
            return self
        }
        if chunkStreamId <= 319 {
            data[position + 0] = chunkType.rawValue << 6 | 0b0000000
            data[position + 1] = UInt8(chunkStreamId - 64)
            position += 2
            return self
        }
        data[position + 0] = chunkType.rawValue << 6 | 0b00000001
        let streamId = (chunkStreamId - 64).bigEndian.data
        data[position + 1] = streamId[0]
        data[position + 2] = streamId[1]
        position += 3
        return self
    }

    func putMessage(_ chunkType: RTMPChunkType, chunkStreamId: UInt16, message: some RTMPMessage) -> Self {
        let length = message.payload.count

        switch chunkType {
        case .zero:
            data.replaceSubrange(position...position + 3, with: message.timestamp.bigEndian.data[1...3])
            position += 3
            data.replaceSubrange(position...position + 3, with: UInt32(length).bigEndian.data[1...3])
            position += 3
            data[position] = message.type.rawValue
            position += 1
            data.replaceSubrange(position...position + 4, with: message.streamId.littleEndian.data)
            position += 4
        case .one:
            data.replaceSubrange(position...position + 3, with: message.timestamp.bigEndian.data[1...3])
            position += 3
            data.replaceSubrange(position...position + 3, with: UInt32(length).bigEndian.data[1...3])
            position += 3
            data[position] = message.type.rawValue
            position += 1
        case .two:
            data.replaceSubrange(position...position + 3, with: message.timestamp.bigEndian.data[1...3])
            position += 3
        case .three:
            break
        }

        var offset = 0
        var remaining = min(chunkSize, length)
        let payload = message.payload
        repeat {
            if 0 < offset {
                _ = putBasicHeader(.three, chunkStreamId: chunkStreamId)
            }
            data.replaceSubrange(position..<position + remaining, with: payload[offset..<offset + remaining])
            position += remaining
            offset += remaining
            remaining = min(chunkSize, length - offset)
        } while (0 < remaining)

        return self
    }
}

extension RTMPChunkMessageHeader: CustomDebugStringConvertible {
    // MARK: CustomStringConvertible
    var debugDescription: String {
        Mirror(reflecting: self).debugDescription
    }
}
