//ifndef+define safe guard for any .hlsl file
#ifndef NiloSurfaceShaderInclude
#define NiloSurfaceShaderInclude

//good "surface shader in URP" reference by Felipe Lira:
//https://github.com/phi-lira/UniversalShaderExamples/blob/master/Assets/_ExampleScenes/CustomShading.hlsl

//good "lit shader in URP" reference by Felipe Lira:
//https://gist.github.com/phi-lira/225cd7c5e8545be602dca4eb5ed111ba

//good "lit shader in URP" reference by URP:
//create a new PBR shader graph, open it, right click on master node->show generated code

//we always include these .hlsl if writing a lit shader in URP
//100% copied from PBR shader graph's generated code
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

//all possible data from unity application to any vertex shader will use this same struct
struct Attributes
{
    float3  positionOS  : POSITION;
    float3  normalOS    : NORMAL;
    float4  tangentOS   : TANGENT;
    half4   color       : COLOR;
    float2  uv          : TEXCOORD0;
    float2  uv2         : TEXCOORD1; //uvLightmap

    float2  uv3         : TEXCOORD2;
    float2  uv4         : TEXCOORD3;
    float2  uv5         : TEXCOORD4;
    float2  uv6         : TEXCOORD5;
    float2  uv7         : TEXCOORD6;
    float2  uv8         : TEXCOORD7;

    #if UNITY_ANY_INSTANCING_ENABLED
    uint instanceID : INSTANCEID_SEMANTIC; //user can get instanceID by UNITY_GET_INSTANCE_ID(Attributes)
    #endif 
};

//all possible data from vertex shader to fragment shader will use this same struct
struct Varyings
{
    float2  uv                          : TEXCOORD0;
    float2  uv2                         : TEXCOORD1; //uvLightmap
    float4  uv34                        : TEXCOORD2;
    float4  uv56                        : TEXCOORD3;
    float4  uv78                        : TEXCOORD4;

    float4  positionWSAndFogFactor      : TEXCOORD5;

    half3   normalWS                    : NORMAL;
    half3   tangentWS                   : TANGENT;
    half3   bitangentWS                 : TEXCOORD6;

    half3   color                       : COLOR;

    float4  positionCS                  : SV_POSITION;

    #if UNITY_ANY_INSTANCING_ENABLED
    uint instanceID : CUSTOM_INSTANCE_ID;
    #endif

    #if VARYINGS_NEED_CULLFACE
    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
    #endif
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Vertex Shader Section
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
float3 _LightDirection;
float4 GetShadowPositionHClip(Varyings input)
{
    float3 positionWS = input.positionWSAndFogFactor.xyz;
    float3 normalWS = input.normalWS;

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif

    return positionCS;
}

//same as PBR shader graph's vertex input
struct UserGeometryOutputData
{
    float3 positionOS;
    float3 normalOS;
    float4 tangentOS;
};

//Forward declaration of UserGeometryDataOutputFunction. 
//This function must be implemented by user, inside user's .shader surface shader file, even if it is empty
void UserGeometryDataOutputFunction(Attributes IN, inout UserGeometryOutputData outputData, bool isExtraCustomPass);

UserGeometryOutputData BuildUserGeometryOutputData(Attributes IN, bool isExtraCustomPass = false)
{
    UserGeometryOutputData outputData;

    //first, init UserGeometryOutputData by default value, just like in shader graph
    outputData.positionOS = IN.positionOS.xyz;
    outputData.normalOS = IN.normalOS;
    outputData.tangentOS = IN.tangentOS;

    //then, let user optionally override UserGeometryOutputData's values
    UserGeometryDataOutputFunction(IN, outputData, isExtraCustomPass);

    return outputData;
}
Varyings VertAllWork(Attributes IN, bool shouldApplyShadowBias = false, bool isExtraCustomPass = false)
{
    UserGeometryOutputData geometryData = BuildUserGeometryOutputData(IN, isExtraCustomPass);


    Varyings OUT;

    // VertexPositionInputs contains position in multiple spaces (world, view, homogeneous clip space)
    // The compiler will strip all unused references.
    // Therefore there is more flexibility at no additional cost with this struct.
    VertexPositionInputs vertexInput = GetVertexPositionInputs(geometryData.positionOS.xyz);

    // Similar to VertexPositionInputs, VertexNormalInputs will contain normal, tangent and bitangent
    // in world space. If not used it will be stripped.
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(geometryData.normalOS, geometryData.tangentOS);

    OUT.uv = IN.uv;    
#if LIGHTMAP_ON
    OUT.uv2 = IN.uv2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
    OUT.uv34 = float4(IN.uv3,IN.uv4);
    OUT.uv56 = float4(IN.uv5,IN.uv6);
    OUT.uv78 = float4(IN.uv7,IN.uv8);

    OUT.color = IN.color;

    // Computes fog factor per-vertex.
    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    OUT.positionWSAndFogFactor = float4(vertexInput.positionWS,fogFactor);

    OUT.normalWS = vertexNormalInput.normalWS;
    OUT.tangentWS = vertexNormalInput.tangentWS;
    OUT.bitangentWS = vertexNormalInput.bitangentWS;

    OUT.positionCS = vertexInput.positionCS; 

    //because this bool is a compile time constant, this if() line will be removed in shader compile time, 
    //so this if() line has 0 performance cost, don't worry.
    if(shouldApplyShadowBias)
    {
        //write shadow bias code here
        OUT.positionCS = GetShadowPositionHClip(OUT);
    }
    return OUT;  
}

//functions used by user's .shader surface shader
Varyings vertUniversalForward(Attributes IN)
{
    return VertAllWork(IN);
}
Varyings vertShadowCaster(Attributes IN)
{
    return VertAllWork(IN, true, false);
}
Varyings vertExtraCustomPass(Attributes IN)
{
    return VertAllWork(IN, false, true);
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Fragment Shader Section
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// defined in 9.0 URP, we can remove it in the future
/////////////////////////////////////////////////////////////////
#if SHADER_LIBRARY_VERSION_MAJOR < 9
// Computes the world space view direction (pointing towards the viewer).
float3 GetWorldSpaceViewDir(float3 positionWS)
{
    if (unity_OrthoParams.w == 0)
    {
        // Perspective
        return _WorldSpaceCameraPos - positionWS;
    }
    else
    {
        // Orthographic
        float4x4 viewMat = GetWorldToViewMatrix();
        return viewMat[2].xyz;
    }
}
#endif
/////////////////////////////////////////////////////////////////

//100% same as PBR shader graph's fragment input
struct UserSurfaceDataOutput
{
    half3   albedo;             
    half3   normalTS;          
    half3   emission;     
    half    metallic;
    half    smoothness;
    half    occlusion;                
    half    alpha;          
    half    alphaClipThreshold;
};
//extra data for lighting, to help CalculateSurfaceFinalResultColor()
struct LightingData 
{
    Light   mainDirectionalLight;   //brightest direction light
    int     additionalLightCount;   //use forloop, each loop calls GetAdditionalLight(i, positionWS) to get each addition light
    half3   bakedIndirectDiffuse;   //raw color from light probe or light map
    half3   bakedIndirectSpecular;  //raw color from reflection probe, affected by UserSurfaceDataOutput.smoothness
    half3   viewDirectionWS;
    half3   reflectionDirectionWS;
    half3   normalWS;
    float3  positionWS;
};

// Forward declaration of SurfaceFunctionFrag. This function must be defined in user's .shader surface shader file
void SurfaceFunctionFrag(Varyings IN, inout UserSurfaceDataOutput surfaceData, bool isExtraCustomPass);

UserSurfaceDataOutput ProduceUserSurfaceDataOutput(Varyings IN, bool isExtraCustomPass)
{
    UserSurfaceDataOutput surfaceData;

    //first init UserSurfaceDataOutput by default value (following PBR shader graph's default value)
    surfaceData.albedo = 1;                 //default white             
    surfaceData.normalTS = half3(0,0,1);    //default pointing out, no difference to vertex normal        
    surfaceData.emission = 0;               //default black  
    surfaceData.metallic = 0;               //default 100% non-metal
    surfaceData.smoothness = 0.5;           //default 50% smooth
    surfaceData.occlusion = 1;              //default no occlusion                
    surfaceData.alpha = 1;                  //default fully opaque          
    surfaceData.alphaClipThreshold = 0;     //default 0, not 0.5, following PBR shader graph's default value

    //then let user optionally override some/al; UserSurfaceDataOutput's values
    SurfaceFunctionFrag(IN,surfaceData, isExtraCustomPass);

    //safe guard user provided data (not sure if it is needed, because it cost performance here)
    surfaceData.albedo = max(0,surfaceData.albedo);
    surfaceData.normalTS = normalize(surfaceData.normalTS);
    surfaceData.emission = max(0,surfaceData.emission);
    surfaceData.metallic = saturate(surfaceData.metallic);
    surfaceData.smoothness = saturate(surfaceData.smoothness);
    surfaceData.occlusion = saturate(surfaceData.occlusion);
    surfaceData.alpha = saturate(surfaceData.alpha);
    surfaceData.alphaClipThreshold = saturate(surfaceData.alphaClipThreshold);

    return surfaceData;
}
// Forward declaration of CUSTOM_LIGHTING_FUNCTION. This function must be defined in user's .shader surface shader file
half4 CalculateSurfaceFinalResultColor(Varyings IN, UserSurfaceDataOutput surfaceData, LightingData lightingData);
void FinalPostProcessFrag(Varyings IN, UserSurfaceDataOutput surfaceData, LightingData lightingData, inout half4 inputColor);
half4 fragAllWork(Varyings IN, bool shouldOnlyDoAlphaClipAndEarlyExit = false, bool isExtraCustomPass = false)
{
    //re-normalize all directions vector after interpolation
    IN.normalWS = normalize(IN.normalWS);
    IN.tangentWS.xyz = normalize(IN.tangentWS);
    IN.bitangentWS = normalize(IN.bitangentWS);

    //use user's surface function to produce final surface data
    UserSurfaceDataOutput surfaceData = ProduceUserSurfaceDataOutput(IN,isExtraCustomPass);

    //do alphaclip asap
    clip(surfaceData.alpha - surfaceData.alphaClipThreshold);

    //early exit if we only want to do alphaclip test, and don't care result color
    //because this bool is a compile time constant, this if() line will be removed in shader compile time, 
    //so this if() line has 0 performance cost, don't worry.
    if(shouldOnlyDoAlphaClipAndEarlyExit)
    {
        return 0;
    }

    //========================================================================
    LightingData lightingData;
    half3 T = IN.tangentWS.xyz;
    half3 B = IN.bitangentWS;
    half3 N = IN.normalWS;

    lightingData.normalWS = TransformTangentToWorld(surfaceData.normalTS, half3x3(T,B,N));

    float3 positionWS = IN.positionWSAndFogFactor.xyz;
    half3 viewDirectionWS = normalize(GetWorldSpaceViewDir(positionWS));
    half3 reflectionDirectionWS = reflect(-viewDirectionWS, lightingData.normalWS);
    
    // shadowCoord is position in shadow light space
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    lightingData.mainDirectionalLight = GetMainLight(shadowCoord);

    //light probe or lightmap depends on unity's keyword "LIGHTMAP_ON"
    lightingData.bakedIndirectDiffuse = SAMPLE_GI(IN.uv2, SampleSH(lightingData.normalWS), lightingData.normalWS);

    //reflection probe
    lightingData.bakedIndirectSpecular = GlossyEnvironmentReflection(reflectionDirectionWS, 1-surfaceData.smoothness, 1);//perceptualRoughness = 1 - smoothness

    lightingData.viewDirectionWS = viewDirectionWS;
    lightingData.reflectionDirectionWS = reflectionDirectionWS;

    lightingData.additionalLightCount = GetAdditionalLightsCount();
    lightingData.positionWS = positionWS;

    half4 finalColor = CalculateSurfaceFinalResultColor(IN, surfaceData, lightingData);
    FinalPostProcessFrag(IN, surfaceData, lightingData, finalColor);
    return finalColor;
}
half4 fragUniversalForward(Varyings IN) : SV_Target
{
    return fragAllWork(IN);
}
half4 fragDoAlphaClipOnlyAndEarlyExit(Varyings IN) : SV_Target
{
    return fragAllWork(IN, true);
}

half4 fragExtraCustomPass(Varyings IN) : SV_Target
{
    return fragAllWork(IN, false, true);
}
#endif