import Foundation

/// 元素级容错数组：单个元素解码失败只丢弃该元素，并记录丢弃数量。
struct LossyArray<Element: Decodable>: Decodable {
    let elements: [Element]
    let droppedCount: Int

    init(elements: [Element], droppedCount: Int = 0) {
        self.elements = elements
        self.droppedCount = droppedCount
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var decodedElements: [Element] = []
        var dropped = 0

        while !container.isAtEnd {
            let indexBefore = container.currentIndex
            do {
                let element = try container.decode(Element.self)
                decodedElements.append(element)
            } catch {
                dropped += 1
                if container.currentIndex == indexBefore {
                    _ = try? container.superDecoder()
                }
                if container.currentIndex == indexBefore {
                    break
                }
            }
        }

        self.elements = decodedElements
        self.droppedCount = dropped
    }
}

/// 备用包装：把可能失败的单个值降级为 nil。
struct LossyValue<Wrapped: Decodable>: Decodable {
    let value: Wrapped?

    init(value: Wrapped?) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        value = try? Wrapped(from: decoder)
    }
}