//see doc here: https://github.com/ColinLeung-NiloCat/UnityURP-SurfaceShaderSolution

//In user's perspective, this "URP surface shader" .shader file: 
//- must be just one regular .shader file
//- must be as short as possible, user should only need to care & write surface function, no lighting related code should be exposed to user
//- must be always SRP batcher compatible if user write uniforms in CBUFFER correctly
//- must be able to do everything that shader graph can already do
//- must support DepthOnly & ShadowCaster pass with minimum code
//- must not contain any lighting related concrete code in this file, only allowing "one line" selecting a reusable lighting function .hlsl by user.
//- must be "very easy to use & flexible", even if performance cost is higher
//- must support atleast 1 extra custom pass(e.g. outline pass) with minimum code
//(WIP)- this file must be a template that can be created using unity's editor GUI (right click in project window, Create/Shader/NiloURPSurfaceShader)

//* In this file, user should only care sections with [User editable section] tag, other code should be ignored by user in most cases

//__________________________________________[User editable section]__________________________________________\\
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//change this line to any unique path you like, so you can pick it in material's shader dropdown menu
Shader "Universal Render Pipeline/CustomSurfaceShader/01"
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
{
    Properties
    {
        //__________________________________________[User editable section]__________________________________________\\
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //write all per material settings here, just like a regular .shader,
        //make sure to match all uniforms inside CBUFFER_START(UnityPerMaterial) in the next [User editable section],
        //in order to make SRP batcher compatible

        //just some example use case
        [Header(base color)]
        [MainColor] _BaseColor("BaseColor", Color) = (1,1,1,1)
        [MainTexture] _BaseMap("BaseMap", 2D) = "white" {}

        [Header(AO)]
        _AmbientOcclusion("_AmbientOcclusion", range(0,1)) = 1

        [Header(Metallic)]
        _Metallic("_Metallic", range(0,1)) = 0

        [Header(Smoothness)]
        _Smoothness("_Smoothness", range(0,1)) = 0.5

        [Header(NormalMap)]
        [Toggle(_NORMALMAP)]_NORMALMAP("_NORMALMAP?", Float) = 1
        _NormalMap("_NormalMap", 2D) = "normal" {}
        _NormalMapScale("_NormalMapScale", float) = 1

        [Header(SharedDataTexture)]
        _MetallicOcclusionSmoothnessTex("_MetallicOcclusionSmoothnessTex", 2D) = "white" {}

        [Header(Emission)]
        [HDR]_Emission("_Emission", Color) = (0,0,0,1)

        [Header(GameplayUseColorOverride)]
        [Toggle(_IsTakingDamage)]_IsTakingDamage("_IsTakingDamage?", Float) = 0
        [Toggle(_IsSelected)]_IsSelected("_IsSelected?", Float) = 0
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    }

    HLSLINCLUDE

    //this section are multi_compile keywords set by unity:
    //-Sadly there seems to be no way to hide #pragma from user, 
    // so multi_compile must be copied to every .shader due to shaderlab's design,
    // which makes updating this section in future almost impossible once users already produced lots of .shader files
    //-The good part is exposing multi_compiles which makes user edit possible, 
    // but it contradict with the goal of surface shader - "hide lighting implementation from user"
    //==================================================================================================================
    //copied some URP multi_compile note from UniversalPipelineTemplateShader.shader by Felipe Lira
    //https://gist.github.com/phi-lira/225cd7c5e8545be602dca4eb5ed111ba

    // Universal Render Pipeline keywords
    // When doing custom shaders you most often want to copy and paste these #pragmas,
    // These multi_compile variants are stripped from the build depending on:
    // 1) Settings in the URP Asset assigned in the GraphicsSettings at build time
    // e.g If you disable AdditionalLights in the asset then all _ADDITIONA_LIGHTS variants
    // will be stripped from build
    // 2) Invalid combinations are stripped. e.g variants with _MAIN_LIGHT_SHADOWS_CASCADE
    // but not _MAIN_LIGHT_SHADOWS are invalid and therefore stripped.

    //100% copied from URP PBR shader graph's generated code
    // Pragmas
    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0
    #pragma multi_compile_fog
    #pragma multi_compile_instancing

    //100% copied from URP PBR shader graph's generated code
    // Keywords
    #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile _ DIRLIGHTMAP_COMBINED
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
    #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
    #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
    #pragma multi_compile _ _SHADOWS_SOFT
    #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
    //==================================================================================================================


    //the core .hlsl of the whole URP surface shader structure, must be included
    #include "Assets/NiloCat/NiloURPSurfaceShader/NiloURPSurfaceShaderInclude.hlsl"


    //__________________________________________[User editable section]__________________________________________\\
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //first, select a .hlsl which contains the concrete body of CalculateSurfaceFinalResultColor(...)
    //you can select any .hlsl you want here, default is NiloPBRLitLightingFunction.hlsl, you can always change it
    //#include "Assets/NiloCat/NiloURPSurfaceShader/LightingFunctionLibrary/NiloPBRLitLightingFunction.hlsl"
    #include "Assets/NiloCat/NiloURPSurfaceShader/LightingFunctionLibrary/NiloToonLightingFunction.hlsl"
    //#include "..........YourOwnLightingFunction.hlsl" //you can always write your own!

    //put your custom #pragma here as usual
    #pragma shader_feature _NORMALMAP 
    #pragma multi_compile _ _IsSelected
    #pragma multi_compile _ _IsTakingDamage

    //define texture & sampler as usual
    TEXTURE2D(_BaseMap);
    SAMPLER(sampler_BaseMap);
    TEXTURE2D(_NormalMap);
    SAMPLER(sampler_NormalMap);
    TEXTURE2D(_MetallicOcclusionSmoothnessTex);
    SAMPLER(sampler_MetallicOcclusionSmoothnessTex);

    //you must write all your per material uniforms inside this CBUFFER to make SRP batcher compatible
    CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    half4 _BaseColor;
    half _AmbientOcclusion;
    half _Metallic;
    half _Smoothness;
    half _NormalMapScale;
    half3 _Emission;
    CBUFFER_END

    //IMPORTANT: write your surface shader's vertex logic here
    //you ONLY need to re-write things that you want to change, you don't need to fill in all data inside UserGeometryOutputData!
    //unedited data inside UserGeometryOutputData will always use it's default values, just like shader graph's master node's default values.
    //see struct UserGeometryOutputData inside NiloURPSurfaceShaderInclude.hlsl for all editable data and default values of it
    //copy the whole struct UserGeometryOutputData here as reference
    /*
    //100% same as PBR shader graph's vertex input
    struct UserGeometryOutputData
    {
        float3 positionOS;
        float3 normalOS;
        float4 tangentOS;
    };
    */
    void UserGeometryDataOutputFunction(Attributes IN, inout UserGeometryOutputData geometryOutputData, bool isExtraCustomPass)
    {
        geometryOutputData.positionOS += sin(_Time * geometryOutputData.positionOS * 10) * 0.0125; //random sin() vertex anim

        if(isExtraCustomPass)
        {
            geometryOutputData.positionOS += geometryOutputData.normalOS * 0.025; //outline enlarge mesh
        }

        //No need to write to other geometryOutputData.XXX if you don't want to edit geometryOutputData.XXX
        //it will use default value instead
    }

    //MOST IMPORTANT: write your fragment surface shader logic here
    //you ONLY need re-write things that you want to change, you don't need to fill in all data inside UserSurfaceDataOutput!
    //unedited data inside UserSurfaceDataOutput will always use it's default value, just like shader graph's master node's default values.
    //see struct UserSurfaceDataOutput inside NiloURPSurfaceShaderInclude.hlsl for all editable data and their default values 
    //copy the whole struct UserSurfaceDataOutput here as reference
    /*
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
    */
    void SurfaceFunctionFrag(Varyings IN, inout UserSurfaceDataOutput surfaceData, bool isExtraCustomPass)
    {
        float2 uv = TRANSFORM_TEX(IN.uv, _BaseMap);
        
        half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor;
        surfaceData.albedo = color.rgb;
        surfaceData.alpha = color.a;

#if _NORMALMAP
        surfaceData.normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv), _NormalMapScale);
#endif

        half4 metallicOcclusionSmoothnessTex = SAMPLE_TEXTURE2D(_MetallicOcclusionSmoothnessTex, sampler_MetallicOcclusionSmoothnessTex, uv);
        surfaceData.occlusion = _AmbientOcclusion * metallicOcclusionSmoothnessTex.g; //ao in g
        surfaceData.metallic = _Metallic * metallicOcclusionSmoothnessTex.r; //metallic in r
        surfaceData.smoothness = _Smoothness * metallicOcclusionSmoothnessTex.a; //smoothness in a (default)

        surfaceData.emission = _Emission;

        //isExtraCustomPass is a compile time constant, writing this if() has 0 performance cost
        //in this example, isExtraCustomPass is true only when executing the outline pass
        if(isExtraCustomPass)
        {
            //make outline darker
            surfaceData.albedo = 0;
            surfaceData.smoothness = 0;
            surfaceData.metallic = 0;
            surfaceData.occlusion = 0;
        }
    }

    //IMPORTANT: write your final fragment color edit logic here
    //usually for gameplay logic's color override like "loop: lerp to red" for selectable targets, or flash white on taking damage.
    //you can replace this function by a #include "Your own .hlsl" call, to share logic between different surface shaders
    void FinalPostProcessFrag(Varyings IN, UserSurfaceDataOutput surfaceData, LightingData lightingData, inout half4 inputColor)
    {
#if _IsTakingDamage
        inputColor.rgb = lerp(inputColor.rgb,half3(1,1,1), (sin(_Time.y * 80) * 0.5 + 0.5) > 0.5 ? 1 : 0.4);
#endif
#if _IsSelected
        inputColor.rgb = lerp(inputColor.rgb,half3(1,0,0), (sin(_Time.y * 5) * 0.5 + 0.5));
#endif
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ENDHLSL

    SubShader
    {
        Tags 
        { 
            "RenderPipeline"="UniversalRenderPipeline"

            //__________________________________________[User editable section]__________________________________________\\
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
            //You can edit per SubShader tags here as usual
            //doc: https://docs.unity3d.com/Manual/SL-SubShaderTags.html
            
            "Queue" = "Geometry+0"
            "RenderType" = "Opaque"

            "DisableBatching" = "False"
            "ForceNoShadowCasting" = "False"
            "IgnoreProjector" = "True"
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
        }

        //UniversalForward pass
        Pass
        {
            Name "Universal Forward"
            Tags { "LightMode"="UniversalForward" }

            //__________________________________________[User editable section]__________________________________________\\
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
            //You can edit per Pass Render State here as usual
            //doc: https://docs.unity3d.com/Manual/SL-Pass.html
            
            Cull Back
            ZTest LEqual
            ZWrite On
            Offset 0,0
            Blend One Zero
            ColorMask RGBA

            //stencil also 
            //doc: https://docs.unity3d.com/Manual/SL-Stencil.html
            Stencil
            {
                //...
            }
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

            HLSLPROGRAM
            #pragma vertex vertUniversalForward
            #pragma fragment fragUniversalForward
            ENDHLSL
        }

 
        //__________________________________________[User editable section]__________________________________________\\
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //User can insert 1 extra custom passes
        //for example, an outline pass
        Pass
        {
            //no LightMode is needed for extra custom pass
            Cull front
            HLSLPROGRAM
            #pragma vertex vertExtraCustomPass
            #pragma fragment fragExtraCustomPass
            ENDHLSL
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
          
        //ShadowCaster pass, for rendering this shader into URP's shadowmap renderTextures
        //User should not need to edit this pass in most cases
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            ColorMask 0 //optimization: ShadowCaster pass don't care fragment shader output value, disable color write to reduce bandwidth usage

            HLSLPROGRAM

            #pragma vertex vertShadowCaster
            #pragma fragment fragDoAlphaClipOnlyAndEarlyExit

            ENDHLSL
        }

        //DepthOnly pass, for rendering this shader into URP's _CameraDepthTexture
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            ColorMask 0 //optimization: DepthOnly pass don't care fragment shader output value, disable color write to reduce bandwidth usage

            HLSLPROGRAM

            //__________________________________________[User editable section]__________________________________________\\
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
            //disabled due to outline pass, because we edited positionOS by bool isExtraCustomPass in UserGeometryDataOutputFunction(...)
            //#pragma vertex vertUniversalForward

            //because of outline pass, we use this instead, this will inlcude positionOS change in UserGeometryDataOutputFunction
            #pragma vertex vertExtraCustomPass
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

            #pragma fragment fragDoAlphaClipOnlyAndEarlyExit

            ENDHLSL
        }
    }
}