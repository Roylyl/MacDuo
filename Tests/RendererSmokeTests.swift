import Foundation
import MetalKit

@main
struct RendererSmokeTests {
    static func main() throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
            throw NSError(domain: "RendererSmoke", code: 1, userInfo: [NSLocalizedDescriptionKey: "Metal GPU unavailable"])
        }
        let library = try device.makeLibrary(source: GlassMetalView.shader, options: nil)
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexMain")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "glassMain")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        let pipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        let width = 64, height = 48
        let sourceDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: true)
        sourceDescriptor.storageMode = .shared
        sourceDescriptor.usage = [.shaderRead]
        let source = device.makeTexture(descriptor: sourceDescriptor)!
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                pixels[i] = UInt8(40 + x * 2)
                pixels[i + 1] = UInt8(30 + y * 3)
                pixels[i + 2] = UInt8(60 + (x + y) % 80)
            }
        }
        pixels.withUnsafeBytes { pointer in
            source.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: pointer.baseAddress!, bytesPerRow: width * 4)
        }
        let mipCommand = queue.makeCommandBuffer()!
        let blit = mipCommand.makeBlitCommandEncoder()!
        blit.generateMipmaps(for: source)
        blit.endEncoding()
        mipCommand.commit()
        mipCommand.waitUntilCompleted()
        precondition(mipCommand.status == .completed)
        func render(angle: Float, frost: Float) -> [UInt8] {
            let outputDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            outputDescriptor.storageMode = .shared
            outputDescriptor.usage = [.renderTarget]
            let output = device.makeTexture(descriptor: outputDescriptor)!
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = output
            pass.colorAttachments[0].loadAction = .clear
            pass.colorAttachments[0].storeAction = .store
            let command = queue.makeCommandBuffer()!
            let encoder = command.makeRenderCommandEncoder(descriptor: pass)!
            var parameters: [Float] = [Float(width), Float(height), angle, frost, 2.4, Float(width) / Float(height), 0, 0]
            encoder.setRenderPipelineState(pipeline)
            encoder.setFragmentTexture(source, index: 0)
            encoder.setFragmentBytes(&parameters, length: parameters.count * MemoryLayout<Float>.size, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
            command.commit()
            command.waitUntilCompleted()
            precondition(command.status == .completed, "GPU command failed")
            var bytes = [UInt8](repeating: 0, count: pixels.count)
            bytes.withUnsafeMutableBytes { pointer in
                output.getBytes(pointer.baseAddress!, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
            }
            return bytes
        }
        let clear = render(angle: 0, frost: 0.09)
        let maximumDifference = zip(clear, pixels).map { abs(Int($0) - Int($1)) }.max()!
        precondition(maximumDifference <= 1, "Zero angle must reproduce source pixels, max error \(maximumDifference)")
        let tilted = render(angle: 35, frost: 0.09)
        precondition(zip(tilted, clear).filter { $0 != $1 }.count > pixels.count / 3, "Tilt must visibly transform the image")
        precondition(stride(from: 3, to: tilted.count, by: 4).allSatisfy { tilted[$0] == 255 }, "Output must stay opaque")
        let extreme = render(angle: 80, frost: 0.18)
        precondition(extreme.contains { $0 != 0 })
        print("PASS: Metal shader compilation, zero-angle pixel identity (±1), tilted/frosted rendering, opaque extreme-angle output on \(device.name)")
    }
}
