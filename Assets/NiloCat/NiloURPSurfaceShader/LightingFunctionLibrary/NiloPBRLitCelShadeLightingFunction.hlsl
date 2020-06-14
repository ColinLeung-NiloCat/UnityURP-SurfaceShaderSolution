//see doc here: https://github.com/ColinLeung-NiloCat/UnityURP-SurfaceShaderSolution

//it is just an example of custom lighting function.hlsl, it is not a good looking cel shade lighting function.hlsl
//I will try converting https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample using this surface shader structure.
#ifndef NiloPBRLitCelShadeLightingFunction_INCLUDE
#define NiloPBRLitCelShadeLightingFunction_INCLUDE

// Based on Minimalist CookTorrance BRDF
// Implementation is slightly different from original derivation: http://www.thetenthplanet.de/archives/255
//
// * NDF [Modified] GGX
// * Modified Kelemen and Szirmay-Kalos for Visibility term
// * Fresnel approximated with 1/LdotH
half3 DirectBDRFCelShade(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
#ifndef _SPECULARHIGHLIGHTS_OFF
    float3 halfDir = SafeNormalize(float3(lightDirectionWS) + float3(viewDirectionWS));

    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
    // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);
    specularTerm = floor(specularTerm + 0.5);//***********************cel shade add line**************************
    // On platforms where half actually means something, the denominator has a risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

    half3 color = specularTerm * brdfData.specular + brdfData.diffuse;
    return color;
#else
    return brdfData.diffuse;
#endif
}

half3 LightingPhysicallyBasedCelShade(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    NdotL = smoothstep(0.45,0.5,NdotL);//***********************cel shade add line**************************
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    return DirectBDRFCelShade(brdfData, normalWS, lightDirectionWS, viewDirectionWS) * radiance;
}
half3 LightingPhysicallyBasedCelShade(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    light.shadowAttenuation = smoothstep(0.45,0.5,light.shadowAttenuation);//***********************cel shade add line**************************
    return LightingPhysicallyBasedCelShade(brdfData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS);
}

half4 CalculateSurfaceFinalResultColor(Varyings IN, UserSurfaceOutputData surfaceData, LightingData lightingData)
{
    // BRDFData holds energy conserving diffuse and specular material reflections and its roughness.
    // It's easy to plugin your own shading fuction. You just need replace LightingPhysicallyBased function
    // below with your own.
    BRDFData brdfData;
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, 0, surfaceData.smoothness, surfaceData.alpha, brdfData);

    half3 rgb = GlobalIllumination(brdfData, lightingData.bakedIndirectDiffuse, surfaceData.occlusion, lightingData.normalWS, lightingData.viewDirectionWS);

    // LightingPhysicallyBased computes direct light contribution.
    //this line adds main directional light's contribution 
    rgb += LightingPhysicallyBasedCelShade(brdfData, lightingData.mainDirectionalLight, lightingData.normalWS, lightingData.viewDirectionWS);

    //this forloop adds each additional light's contribution
    int additionalLightCount = lightingData.additionalLightCount;
    for(int i = 0; i < additionalLightCount; i++)
    {
        Light light = GetAdditionalLight(i,lightingData.positionWS);
        rgb += LightingPhysicallyBasedCelShade(brdfData, light, lightingData.normalWS, lightingData.viewDirectionWS);
    }

    //emission
    rgb += surfaceData.emission * surfaceData.occlusion;

    //fog
    float fogFactor = IN.positionWSAndFogFactor.w;
    // Mix the pixel color with fogColor. You can optionaly use MixFogColor to override the fogColor
    // with a custom one.
    rgb = MixFog(rgb, fogFactor);
       
    return half4(rgb,surfaceData.alpha);
}

#endif