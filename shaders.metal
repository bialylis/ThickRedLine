#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct MyNodeBuffer {
    float4x4 modelViewProjectionTransform;
};

struct lineDataBuffer {
    int width;
    int verticleCount;
    int miter;
    int loop;
};

struct SimpleVertex
{
    float4 position [[position]];
    float4 color;
};

vertex SimpleVertex thickLinesVertex(constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                             constant MyNodeBuffer& scn_node [[buffer(1)]],
                             constant float3* vertices [[buffer(2)]],
                             constant lineDataBuffer& lineData [[buffer(3)]],
                             constant float4* color [[buffer(4)]],
                             uint v_id [[vertex_id]])
{
    
    uint point_id = v_id/4; //line point id (not vertex)
    float sign = v_id%2?-1:1; //should point be up or down in line

    SimpleVertex vert;
    vert.color = *color; //pass the color data to fragment shader
    
    float2 aspect = float2( scn_frame.viewportSize.x / scn_frame.viewportSize.y, 1); //aspect ratio

    vert.position = scn_node.modelViewProjectionTransform * float4(vertices[v_id], 1.0); //position of the point

    if (lineData.miter == 0 || point_id == 0 || point_id + 1 == uint(lineData.verticleCount)){
        //Active when there it's first point, last point or no mitter middle point
        //TODO: get rid of conditionals
        
        uint currentPointToProcess;
        uint nextPointToProcess;
        
        int lineToNext = 0; //should line be calcualted from current point to next, or from current to previous
        lineToNext |= point_id == 0 && !lineData.loop; //always go to next if its first point
        lineToNext |= point_id*4+2 == v_id; //always go to next if its third or fourth vertex of current point
        lineToNext |= point_id*4+3 == v_id;
        lineToNext &= point_id + 1 != uint(lineData.verticleCount) || lineData.loop; //always go to prevous if its a last point
        
        currentPointToProcess = (point_id-1+lineToNext + lineData.verticleCount)  % lineData.verticleCount;
        nextPointToProcess = (point_id+lineToNext) % lineData.verticleCount;
    
        //calculate MVP transform for both points
        float4 currentProjection = scn_node.modelViewProjectionTransform * float4(vertices[currentPointToProcess*4], 1.0);
        float4 nextProjection = scn_node.modelViewProjectionTransform * float4(vertices[nextPointToProcess*4], 1.0);
        
        //get 2d position in screen space
        float2 currentScreen = currentProjection.xy / currentProjection.w * aspect;
        float2 nextScreen = nextProjection.xy / nextProjection.w * aspect;
        
        //get vector of the line
        float2 dir = normalize(nextScreen - currentScreen);
        //vector of diretion of thickness
        float2 normal = float2(-dir.y, dir.x);
        normal /= aspect;
        
        //get thickness in pixels in screen space
        float thickness = float(lineData.width)/scn_frame.viewportSize.y;
        
        //move current point up or down, by thickness, with the same distance independent on depth
        vert.position += float4(sign*normal*thickness*vert.position.w, 0, 0 );

    }else {
        //TODO: Switch to normal mode of miter size is to big
        //other points, calculate mitter
 
        //Similar to previus case, but looking always at 3 points - current, prevoius and next
        
        float4 previousProjection= scn_node.modelViewProjectionTransform * float4(vertices[(point_id - 1)*4], 1.0);
        float4 currentProjection= scn_node.modelViewProjectionTransform * float4(vertices[point_id*4], 1.0);
        float4 nextProjection = scn_node.modelViewProjectionTransform * float4(vertices[(point_id + 1)*4], 1.0);
        
        float2 previousScreen = previousProjection.xy / previousProjection.w * aspect;
        float2 currentScreen = currentProjection.xy / currentProjection.w * aspect;
        float2 nextScreen = nextProjection.xy / nextProjection.w * aspect;
        
        //vector tangential to the joint
        float2 tangent = normalize( normalize(nextScreen-currentScreen) + normalize(currentScreen-previousScreen) );
        
        float2 dir = normalize(nextScreen - currentScreen);
        float2 normal = float2(-dir.y, dir.x);
        
        //mitter line - normal to the tangent
        float2 miter = float2( -tangent.y, tangent.x );
        
        float thickness = float(lineData.width)/scn_frame.viewportSize.y;
        
        //mitter length - crossing of one of the edges with mitter line
        float miterLength = thickness / dot( miter, normal );
        miter /= aspect;
        
        vert.position += float4(sign*miter*miterLength*vert.position.w, 0,0 );
    }

    return vert;
}

fragment float4 thickLinesFragment(SimpleVertex in [[stage_in]])
{
    float4 color;
    color = in.color;
    return color;
}
