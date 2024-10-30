#include <metal_stdlib>
using namespace metal;

constant float4 vertices[6] = {
    float4(-1.0, -1.0, 0.0, 1.0),
    float4(-1.0,  1.0, 0.0, 1.0),
    float4( 1.0,  1.0, 0.0, 1.0),
    float4(-1.0, -1.0, 0.0, 1.0),
    float4( 1.0,  1.0, 0.0, 1.0),
    float4( 1.0, -1.0, 0.0, 1.0)
};

constant float2 textureCoordinates[6] = {
    float2(0.0, 1.0),
    float2(0.0, 0.0),
    float2(1.0, 0.0),
    float2(0.0, 1.0),
    float2(1.0, 0.0),
    float2(1.0, 1.0)
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinates [[user(tex_coords)]];
};

vertex VertexOut standard_vertex(uint vertexID [[vertex_id]]) {
    VertexOut outVertex;
    outVertex.position = vertices[vertexID];
    outVertex.textureCoordinates = textureCoordinates[vertexID];
    return outVertex;
}

fragment half4 standard_fragment(
    VertexOut in [[stage_in]],
    device float3 *palette [[buffer(0)]],
    texture2d<ushort> texture [[texture(0)]],
    sampler textureSampler [[sampler(0)]]
) {
    ushort index = texture.sample(textureSampler, in.textureCoordinates).r;
    float3 color = palette[index];
    
    return half4(color.r, color.g, color.b, 1.0);
}
