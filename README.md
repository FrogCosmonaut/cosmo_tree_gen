# Cosmo Tree Gen
<img width="757" height="526" alt="image" src="https://github.com/user-attachments/assets/b05ba419-0642-4415-9e9c-c6571a31925a" />

Work in progress!  

Godot 4.4+ required. Developed in 4.6.2.stable.  
Procedural low-poly tree generator.  

Mainly inspired by Dan Shiffman and EZTree.  

_100% Human made. No AI was or ever will be used in this project._  

## Features
- Procedural tree generator with configurable branch levels.
- All the generation is live and auto-updated in the editor.
- Configurable tree parameters using custom Resources.
- Optional flat shading for PSX/PS2 aesthetic.
- Foliage:
	- Icospheres, with configurable subdivisions level.
	- Leaves, configurable amount and double sided cards.
- Automatic convex collision generation for the trunk. Optional with a toggle.
	- Pending: optional foliage collision.
- Save and load tree presets, saved as `CosmoTreePreset` resource.

## Usage
Add a `CosmoTreeGen` node.  
Add `TrunkParams`, `BranchLevels` and `FoliageParams` resources and tweak them.  
Add bark and foliage materials.  
Optionally, toggle `use_collision` for convex collision.  
Can be used as is for quick prototyping. gLTF and glb export coming soon.  

## TODOs
- Support multiple trunks per tree.
- GLB/gLTF mesh export.
- Texture and UV scaling, custom texel density setter.
- Auto LOD generation.
	- Billboard impostor PNG generation.
- More low-poly foliage variations. (Pine, Boxes)
- Wind shader.
- Graph editor. (Probably not needed)

## References used
Icosphere:
- https://blog.lslabs.dev/posts/generating_icosphere_with_code
- https://schneide.blog/2016/07/15/generating-an-icosphere-in-c/

Trees/branching:
- EZ-Tree author: https://tympanus.net/codrops/2025/01/27/fractals-to-forests-creating-realistic-3d-trees-with-three-js/
- Coding Train / Dan Shiffman: https://www.youtube.com/watch?v=MwLyeEWnMCY
- https://algorithmicbotany.org/
- https://en.wikipedia.org/wiki/L-system

## Assets/Credits
- Leaves: https://opengameart.org/content/60-cc0-vegetation-textures
- Bark: https://ambientcg.com/view?id=Bark014
- Foliage: Made it manually with GIMP.

## LICENSE - MIT License
