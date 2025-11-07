import SwiftUI
import simd
import XemuCore
import MetalKit

struct EmulatorIndexedRenderView: View {
    class Model {
        let textureRegion: MTLRegion
        var palette: MTLBuffer? = nil
        var texture: MTLTexture? = nil
        var sampler: MTLSamplerState? = nil
        var commandQueue: MTLCommandQueue? = nil
        var pipelineState: MTLRenderPipelineState? = nil
        
        weak var view: MTKView?

        init(
            textureRegion: MTLRegion
        ) {
            self.textureRegion = textureRegion
        }
    }
    
    @Binding var isRunning: Bool
    private let emulator: Emulator
    private var palette: [SIMD3<Float>]
    private let onUpdate: (TimeInterval) -> Void

    private let model: Model

    init(
        _ isRunning: Binding<Bool>,
        _ emulator: Emulator,
        _ palette: [SIMD3<Float>],
        _ onUpdate: @escaping (TimeInterval) -> Void
    ) {
        self._isRunning = isRunning
        self.emulator = emulator
        self.palette = palette
        self.onUpdate = onUpdate
        
        let region = MTLRegionMake2D(0, 0, emulator.frameWidth, emulator.frameHeight)
        model = .init(textureRegion: region)
    }
    
    var body: some View {
        MetalView(
            isRunning: $isRunning,
            onSetup: { view in
                setup(view)
            },
            onUpdate: { delta in
                onUpdate(delta)
            },
            onDraw: { view in
                draw(view)
            }
        )
        .aspectRatio(emulator.frameAspectRatio, contentMode: .fit)
    }
    
    private func setup(_ view: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return // TODO: set error
        }
        
        view.device = device
        model.view = view
        model.commandQueue = commandQueue
        model.pipelineState = createPipeline(device)

        model.palette = device.makeBuffer(
            bytes: palette,
            length: palette.count * MemoryLayout<SIMD3<Float>>.size
        )
        model.texture = createTexture(device)
        model.sampler = createSampler(device)
    }
    
    private func draw(_ view: MTKView) {
        guard let buffer = model.commandQueue?.makeCommandBuffer(),
              let passDescriptor = view.currentRenderPassDescriptor,
              let pipelineState = model.pipelineState else {
            return
        }
        
        model.texture?.replace(
            region: model.textureRegion,
            mipmapLevel: 0,
            withBytes: emulator.frameBuffer,
            bytesPerRow: emulator.frameWidth
        )
        
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: passDescriptor) else {
            return
        }

        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBuffer(model.palette, offset: 0, index: 0)
        encoder.setFragmentTexture(model.texture, index: 0)
        encoder.setFragmentSamplerState(model.sampler, index: 0)
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        encoder.endEncoding()

        if let drawable = view.currentDrawable {
            buffer.present(drawable)
        }

        buffer.commit()
    }
    
    private func createPipeline(_ device: MTLDevice) -> MTLRenderPipelineState? {
        let library = device.makeDefaultLibrary()
        
        let fragmentConstants = MTLFunctionConstantValues()
        fragmentConstants.setConstantValue(palette, type: .array, index: 0)
        
        let vertex = library?.makeFunction(name: "standard_vertex")
        let fragment = library?.makeFunction(name: "standard_fragment")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createTexture(_ device: MTLDevice) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r8Uint,
            width: emulator.frameWidth,
            height: emulator.frameHeight,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead]
        
        return device.makeTexture(descriptor: descriptor)
    }
    
    private func createSampler(_ device: MTLDevice) -> MTLSamplerState? {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .nearest
        descriptor.magFilter = .nearest
        descriptor.mipFilter = .notMipmapped
        descriptor.sAddressMode = .clampToEdge
        descriptor.tAddressMode = .clampToEdge
        descriptor.maxAnisotropy = 1

        return device.makeSamplerState(descriptor: descriptor)
    }
}
