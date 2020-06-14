//see doc here: https://github.com/ColinLeung-NiloCat/UnityURP-SurfaceShaderSolution

//this lighting function's result should be 99% the same as URP PBR lit shader if material properties are the same
//if there are big difference, it is a bug

#ifndef NiloPBRLitLightingFunction_INCLUDE
#define NiloPBRLitLightingFunction_INCLUDE

half4 CalculateSurfaceFinalResultColor(Varyings IN, UserSurfaceOutputData surfaceData, LightingData lightingData)
{
    // BRDFData holds energy conserving diffuse and specular material reflections and its roughness.
    // It's easy to plugin your own shading fuction. You just need replace LightingPhysicallyBased function
    // below with your own.
    BRDFData brdfData;
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, lightingData.bakedIndirectSpecular, surfaceData.smoothness, surfaceData.alpha, brdfData);

    half3 rgb = GlobalIllumination(brdfData, lightingData.bakedIndirectDiffuse, surfaceData.occlusion, lightingData.normalWS, lightingData.viewDirectionWS);

    // LightingPhysicallyBased computes direct light contribution.
    //this line adds main directional light's contribution 
    rgb += LightingPhysicallyBased(brdfData, lightingData.mainDirectionalLight, lightingData.normalWS, lightingData.viewDirectionWS);

    //this forloop adds each additional light's contribution
    int additionalLightCount = lightingData.additionalLightCount;
    for(int i = 0; i < additionalLightCount; i++)
    {
        Light light = GetAdditionalLight(i,lightingData.positionWS);
        rgb += LightingPhysicallyBased(brdfData, light, lightingData.normalWS, lightingData.viewDirectionWS);
    }

    //emissive
    rgb += surfaceData.emission;

    //fog
    float fogFactor = IN.positionWSAndFogFactor.w;
    // Mix the pixel color with fogColor. You can optionaly use MixFogColor to override the fogColor
    // with a custom one.
    rgb = MixFog(rgb, fogFactor);

    return half4(rgb,surfaceData.alpha);
}

#endif