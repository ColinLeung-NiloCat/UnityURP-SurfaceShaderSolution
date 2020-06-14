# UnityURP-SurfaceShaderSolution
 A simple and flexible "surface shader" solution for Unity URP.
 
Why starting this project?
-----------------------
Since URP don't support surface shader anymore, if shader graph alone can't fulfill all your needs and writing raw vert/frag lit shader supporting all light & shadow in URP is just too much work, try download this project, and start writing your own surface shader in URP.
Surface shader makes shader development much easier and faster.

How is this project looks like now?
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
- surface shader is still a regular .shader file, can compile normally
- SRP batcher compatible
- can do everything shader graph can do, but 100% in code, version control friendly!
- can add extra custom pass (e.g. outline)
- can select any lighting function just by editing 1 line of code
- support using your own lighting function .hlsl
- no 

Note
-----------------------
It is a very early WIP project, I hope you will clone the complete project, try create your own surface shader, see if the current surface shader design can fulfill your shader development needs.

Send me suggestion/bug report in Issues tab, or even pull request is very welcome!

Editor environment requirement
-----------------------
- URP 7.3.1 or above
- Unity 2019.4 LTS or above
