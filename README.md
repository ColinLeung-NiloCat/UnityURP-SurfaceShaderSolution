# UnityURP-SurfaceShaderSolution
 A tiny and flexible "surface shader" solution for Unity URP.
 
Do I need this?
-----------------------
Since URP doesn't support surface shader anymore, if shader graph alone can't fulfill all your needs and writing raw vert/frag lit shader supporting all light & shadow in URP is just too much work, try download this project, and start writing your own surface shader in URP.

Surface shader makes shader development much easier and faster in URP, because user don't need to know/write lighting related concrete code at all.

How flexible is it?
-----------------------
 ![screenshot](https://i.imgur.com/pLNO4aR.png)
 
left sphere = our surface shader with:
- vertex animation
- added an extra custom pass (this image's surface shader used that  extra custom pass as an outline pass)
- selectable lighting method (this image's surface shader selected a cel shade PBR lighting method)
- local postprocess
- auto support DepthOnly and ShadowCaster pass

right sphere = default URP PBR lit shader

Features
-----------------------
- "surface shader" is still a regular .shader file, can compile normally
- SRP batcher compatible
- can do everything shader graph can do, but 100% in code, version control friendly!
- can add extra custom pass (e.g. outline pass)
- can switch to any lighting function just by editing 1 line of code
- support using your own lighting function .hlsl
- can apply any additional local postprocess
- everything are just regular .shader/.hlsl files, no C#

Editable options
-----------------------

    struct UserGeometryOutputData
    {
        float3 positionOS;
        float3 normalOS;
        float4 tangentOS;
    };

    struct UserSurfaceOutputData
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
    
- selectable lighting function .hlsl (you can pick PBR lit, PBR lit cel shade, or your own lighting function .hlsl)
- local postprocess method (e.g. you can support lerp to red if the current object is selected, by adding 1 line of code)

How to try this surface shader in my own existing URP project, instead of cloning a complete project?
-----------------------
1) only clone Assets/NiloCat/NiloURPSurfaceShader folder into your URP project
2) In your project, open NiloURPSurfaceShader_Example.shader, edit 
- UserGeometryDataOutputFunction(...)
- UserSurfaceDataOutputFunction(...)
- FinalPostProcessFrag(...)
- #include "../LightingFunctionLibrary/XXXLightingFunction.hlsl"
to see render result change.
3)If you want to create your own "surface shader", clone a copy of NiloURPSurfaceShader_Example.shader before edit it, it is easier.

Note
-----------------------
It is a very early WIP project and will change a lot, but I need to finish this in order to build more complex toon shaders on top of this project.
If you are interested, you can clone it, try writing your own surface shader functions, see if the current "surface shader" design can fulfill your shader development needs.

You can send me suggestions/bug report, or open discussion/just chat in Issues tab, or even send pull requests are very welcome!

Editor environment requirement
-----------------------
- URP 7.3.1 or above
- Unity 2019.4 LTS or above
