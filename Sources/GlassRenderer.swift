import SwiftUI
import MetalKit
import CoreVideo

// Independent implementation of eye -> hinged display -> fixed content plane.
// Reference model: https://github.com/Atomicx7/Duo-animation
// Adapted to a MacBook's horizontal bottom hinge. Shaders compile at runtime.
struct GlassSurface: NSViewRepresentable {
    let image: NSImage
    let tilt: Double
    let frost: Double
    let distance: Double

    func makeNSView(context: Context) -> GlassMetalView { GlassMetalView() }
    func updateNSView(_ view: GlassMetalView, context: Context) {
        view.configure(image: image, tilt: tilt, frost: frost, distance: distance)
    }
}

final class GlassMetalView: MTKView, MTKViewDelegate {
    private var queue: MTLCommandQueue?
    private var pipeline: MTLRenderPipelineState?
    private var texture: MTLTexture?
    private var sourceImage: NSImage?
    private var target: Float = 0
    private var displayed: Float = 0
    private var frost: Float = 0.027
    private var eyeDistance: Float = 2.0
    private var lastTime = CACurrentMediaTime()
    private var videoCache: CVMetalTextureCache?
    private var frameGeneration = 0
    private var textureReady = false
    private var presentedGeneration = -1
    private var uploadsInFlight = 0
    private(set) var hasRenderingError = false
    private(set) var renderedFrameCount = 0
    var isOperational: Bool { pipeline != nil && queue != nil && videoCache != nil }
    var readyForDisplay: Bool { textureReady && presentedGeneration == frameGeneration && isOperational }
    var renderingEnabled = true {
        didSet {
            if renderingEnabled && !oldValue { requestFrame() }
            if !renderingEnabled { isPaused = true }
        }
    }

    private func requestFrame() {
        guard renderingEnabled else { return }
        if isPaused { lastTime = CACurrentMediaTime() }
        isPaused = false
    }

    func resetLiveFrame() {
        frameGeneration += 1
        texture = nil
        sourceImage = nil
        textureReady = false
        presentedGeneration = -1
        hasRenderingError = false
        target = 0
        displayed = 0
        isPaused = true
    }

    func configureLive(tilt: Double, frost: Double, distance: Double) {
        let newTarget = Float(tilt.isFinite ? min(80, max(0, tilt)) : 0)
        let newFrost = Float(frost.isFinite ? min(0.18, max(0, frost)) : 0.027)
        let newDistance = Float(distance.isFinite ? min(4, max(1.4, distance)) : 2.0)
        let changed = abs(newTarget - target) > 0.001 || newFrost != self.frost || newDistance != eyeDistance
        target = newTarget
        self.frost = newFrost
        eyeDistance = newDistance
        if changed || !settled { requestFrame() }
    }
    var settled: Bool { abs(displayed - target) < 0.03 }

    func setLiveAngle(_ angle: Double) {
        configureLive(tilt: angle, frost: Double(frost), distance: Double(eyeDistance))
    }

    @discardableResult func receive(_ buffer: CVPixelBuffer) -> Bool {
        guard isOperational, uploadsInFlight < 3,
              let device, let queue, let cache = videoCache else { return false }
        let width = CVPixelBufferGetWidth(buffer), height = CVPixelBufferGetHeight(buffer)
        var wrapped: CVMetalTexture?
        guard CVMetalTextureCacheCreateTextureFromImage(nil, cache, buffer, nil, .bgra8Unorm,
              width, height, 0, &wrapped) == kCVReturnSuccess,
              let wrapped, let source = CVMetalTextureGetTexture(wrapped) else { return false }
        if texture?.width != width || texture?.height != height {
            frameGeneration += 1
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                width: width, height: height, mipmapped: true)
            descriptor.usage = [.shaderRead]
            descriptor.storageMode = .private
            texture = device.makeTexture(descriptor: descriptor)
            textureReady = false
            presentedGeneration = -1
        }
        guard let texture, let command = queue.makeCommandBuffer(),
              let blit = command.makeBlitCommandEncoder() else { return false }
        blit.copy(from: source, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(),
                  sourceSize: MTLSize(width: width, height: height, depth: 1),
                  to: texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOrigin())
        blit.generateMipmaps(for: texture)
        blit.endEncoding()
        let generation = frameGeneration
        uploadsInFlight += 1
        command.addCompletedHandler { [weak self] completed in
            _ = wrapped; _ = buffer
            let success = completed.status == .completed
            DispatchQueue.main.async {
                guard let self else { return }
                self.uploadsInFlight = max(0, self.uploadsInFlight - 1)
                guard self.frameGeneration == generation else { return }
                self.textureReady = success
                if !success { self.hasRenderingError = true }
                if success { self.requestFrame() }
            }
        }
        command.commit()
        return true
    }

    init() {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        colorPixelFormat = .bgra8Unorm
        framebufferOnly = true
        preferredFramesPerSecond = 60
        isPaused = true
        enableSetNeedsDisplay = false
        clearColor = MTLClearColorMake(0.015, 0.018, 0.025, 1)
        autoresizingMask = [.width, .height]
        guard let device else { return }
        queue = device.makeCommandQueue()
        CVMetalTextureCacheCreate(nil, nil, device, nil, &videoCache)
        do {
            let library = try device.makeLibrary(source: Self.shader, options: nil)
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "vertexMain")
            descriptor.fragmentFunction = library.makeFunction(name: "glassMain")
            descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
            pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            NSLog("MacDuo renderer: %@", String(describing: error))
        }
        delegate = self
    }
    required init(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func configure(image: NSImage, tilt: Double, frost: Double, distance: Double) {
        if sourceImage !== image, let device,
           let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            do {
                // NSImage drawing handlers and some HEIC images produce float or
                // extended-range CGImages that MTKTextureLoader cannot decode.
                // Normalize screenshot inputs to a defined 8-bit sRGB bitmap.
                guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                      let context = CGContext(data: nil, width: cgImage.width, height: cgImage.height,
                          bitsPerComponent: 8, bytesPerRow: cgImage.width * 4, space: colorSpace,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
                      cgImage.width > 0, cgImage.height > 0 else { return }
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
                guard let normalized = context.makeImage() else { return }
                texture = try MTKTextureLoader(device: device).newTexture(cgImage: normalized,
                    options: [.SRGB: false, .generateMipmaps: true])
                sourceImage = image
                frameGeneration += 1
                textureReady = true
                presentedGeneration = -1
            } catch { NSLog("Image texture failed: %@", String(describing: error)) }
        }
        renderingEnabled = true
        configureLive(tilt: tilt, frost: frost, distance: distance)
        if presentedGeneration != frameGeneration { requestFrame() }
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { requestFrame() }
    func draw(in view: MTKView) {
        guard renderingEnabled, textureReady, let pipeline, let texture, let queue,
              let drawable = currentDrawable, let pass = currentRenderPassDescriptor,
              let command = queue.makeCommandBuffer(), let encoder = command.makeRenderCommandEncoder(descriptor: pass)
        else { return }
        let now = CACurrentMediaTime()
        let dt = min(max(now - lastTime, 1.0 / 120), 0.05)
        lastTime = now
        displayed += (target - displayed) * Float(1 - exp(-dt / 0.045))
        var parameters = [Float(drawableSize.width), Float(drawableSize.height),
                          displayed, frost, eyeDistance, Float(texture.width) / Float(texture.height), 0, 0]
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentBytes(&parameters, length: parameters.count * MemoryLayout<Float>.size, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        let generation = frameGeneration
        command.addCompletedHandler { [weak self] completed in
            let success = completed.status == .completed
            DispatchQueue.main.async {
                guard let self, self.frameGeneration == generation else { return }
                guard success else {
                    self.hasRenderingError = true
                    self.textureReady = false
                    self.presentedGeneration = -1
                    self.isPaused = true
                    return
                }
                self.presentedGeneration = generation
                self.renderedFrameCount += 1
            }
        }
        command.present(drawable)
        command.commit()
        if abs(target - displayed) < 0.005 { isPaused = true }
    }

    static let shader = """
    #include <metal_stdlib>
    using namespace metal;
    struct VertexOut { float4 position [[position]]; float2 uv; };
    struct Params { float2 size; float angle; float frost; float eye; float imageAspect; float2 pad; };
    vertex VertexOut vertexMain(uint id [[vertex_id]]) {
        float2 uv = float2((id << 1) & 2, id & 2);
        return {float4(uv.x * 2 - 1, 1 - uv.y * 2, 0, 1), uv};
    }
    float3 sampleScene(texture2d<float> tex, float2 point, constant Params& p, float lod) {
        // Aspect fill covers the display including the areas beside the notch.
        float screenAspect = p.size.x / p.size.y;
        float2 fit = screenAspect > p.imageAspect
            ? float2(1, screenAspect / p.imageAspect) : float2(p.imageAspect / screenAspect, 1);
        float2 uv = (point / p.size - 0.5) / fit + 0.5;
        if (any(uv < 0.0) || any(uv > 1.0)) return float3(0.015, 0.018, 0.025);
        constexpr sampler s(filter::linear, mip_filter::linear, address::clamp_to_edge);
        return tex.sample(s, uv, level(lod)).rgb;
    }
    fragment float4 glassMain(VertexOut in [[stage_in]], texture2d<float> tex [[texture(0)]], constant Params& p [[buffer(0)]]) {
        float2 pixel = in.uv * p.size;
        float angle = p.angle * M_PI_F / 180.0;
        float d = p.size.y - pixel.y;
        float gap = d * sin(angle);
        float2 glass = float2(pixel.x, p.size.y - d * cos(angle));
        float eye = p.size.y * p.eye;
        float2 center = p.size * 0.5;
        float2 hit = center + (glass - center) * eye / max(eye - gap, eye * 0.15);
        float radius = min(abs(gap) * p.frost, p.size.y * 0.055);
        float lod = max(0.0f, log2(max(1.0f, radius * 0.22)));
        float3 color = float3(0);
        // Clear regions need one sample; blurred regions use a mip-filtered disk.
        if (radius < 0.75) {
            color = sampleScene(tex, hit, p, 0.0);
        } else {
            const int taps = 12;
            for (int i = 0; i < taps; i++) {
                float r = sqrt((float(i) + 0.5) / float(taps)) * radius;
                float a = float(i) * 2.39996323;
                color += sampleScene(tex, hit + float2(cos(a), sin(a)) * r, p, lod);
            }
            color /= float(taps);
        }
        float depth = abs(gap) / p.size.y;
        color *= 1.0 - min(depth * 0.45, 0.35);
        // Grazing reflection remains screen-attached; the image moves behind it.
        float sheen = exp(-pow((in.uv.y - (0.25 + sin(angle) * 0.7)) / 0.19, 2.0));
        color += float3(0.78, 0.87, 1.0) * sheen * abs(sin(angle)) * 0.055;
        return float4(color, 1);
    }
    """
}
