# Cosmo Tree Gen
![Cosmo Tree Gen](.github/images/render.png)

Procedural tree generator. Work in progress!  

Mainly inspired by Dan Shiffman and EZTree.  

_100% Human made. No AI was or ever will be used in this project._  

## Requirements
Godot 4.4+ required. Developed in 4.6.2.stable.  

## Features
- Procedural tree generator with configurable branch levels.
- All the generation is live and auto-updated in the editor.
- Configurable tree parameters using custom Resources.
	- Multiple trunks per tree.
	- Optional roots.
	- Broken branches by chance.
	- Branch level length and leaf card size by curve.
- Optional flat shading for PSX/PS2 aesthetic.
- Foliage:
	- Icospheres, with configurable subdivisions level.
	- Card leaves, configurable amount and double sided.
- Automatic collision generation.
	- Three shape types: one convex shape per branch, one convex shape per branch segment, or a single trimesh.
	- Covers branches up to a configurable level (0 = trunk only).
	- Collision preview in the editor.
	- Pending: optional foliage collision.
- Automatic LOD generation:
	- LOD0, LOD1 and LOD2 MeshInstance3Ds can be generated with customizable ratios and distances.
	- The trunk is simplified and the rest of the tris budget goes to the leaves.
	- Leaf cards are not simplified, fewer and bigger cards are kept instead.
- Save and load tree presets, saved as `CosmoTreePreset` resource.
- Export generated tree as glb/glTF, option to link used materials to the ".import" file.

## Installation
Copy the `addons/cosmo_tree_gen/` folder into your project, enable it.  
You can see some examples and presets in the `demo` folder.  
There's a leaves shader with a simple vertex displacement for wind and mipmap limitation to avoid alpha scissor making all the leaves transparent. 

## Usage
Add a `CosmoTreeGen` node.  
Add `TrunkParams`, `BranchLevels` and `FoliageParams` resources and tweak them.  
Add bark and foliage materials.  
Optionally, to generate collisions, set `collision_type` and `collision_level`. Preview it toggling `preview_collision`.  
Optionally, toggle `generate_lod` for LODs.  
Tris budgets and distances can be configured in the project settings: `cosmo_tree_gen/generator`.  
Can be used as is for quick prototyping or exported as glb/glTF. LODs are exported too.  

## Showcase
![presets](.github/images/example_presets.gif)  
Save and load presets fast.

![seed](.github/images/example_lean_wobble_seed.gif)  
Randomize by seed.

![livegen](.github/images/example_leaf_size.gif)  
Live generation.

![curves](.github/images/example_curve.gif)  
Curve editor for fine changes.

## TODOs
- Add documentation comments to resources parameters.
- Create documentation page.
- Texture and UV scaling, custom texel density setter.
- Billboard impostor PNG generation for the last LOD.
- More low-poly foliage variations. (Pine, Boxes)
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
- Icosphere foliage: Made manually with GIMP.
- Logo: Procreate + Inkscape
- Logo background render: Blender
- Logo font: Neuropol - https://www.dafont.com/es/neuropol.font

## LICENSE - MIT License
