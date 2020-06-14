# UnityURP-SurfaceShaderSolution
 A simple and flexible "surface shader" solution for Unity URP.
 
Since URP don't support surface shader anymore, if shader graph alone can't fulfill all your needs and writing raw vert/frag lit shader supporting all light & shadow in URP is just too much work, try download this project, and start writing your own surface shader in URP.
Surface shader makes shader development much easier and faster.
 ![screenshot](https://i.imgur.com/pLNO4aR.png)
 
left sphere = our surface shader with:
- vertex animation
- added an extra custom pass (this image's surface shader used that extra pass as an outline pass)
- selectable lighting method (this image's surface shader selected a cel shade PBR lighting method)
- local postprocess
- auto support DepthOnly and ShadowCaster pass

right sphere = URP default PBR lit shader

Note
-----------------------
It is a very early WIP project, I wish you can clone the project, try create your own surface shader, see if it fulfill your shader development needs.
Send me suggestion/bug report in Issues tab, or even pull request is very welcome!

Editor environment requirement
-----------------------
- URP 7.3.1 or above
- Unity 2019.4 LTS or above
