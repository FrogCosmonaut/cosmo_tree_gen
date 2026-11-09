# Parameters

All the parameters of the `CosmoTreeGen` node and its resources.  
The same descriptions are in the inspector, hover a parameter to see them.

## How a tree is built
1. **Trunks**: `trunk_params` makes one or more trunks, growing from the same base. They can have roots.
1. **Branches**: each `CosmoBranchLevel` in `branch_levels` grows branches from every branch of the previous level. The first level grows from the trunks.
1. **Foliage**: `foliage_params` puts icospheres or leaf cards on the branches of the last level, or on the trunks if there are no branch levels.

Branches are relative to their parent: `length` and `radius` are fractions of the parent ones, and `start`, `end` and the curves go from 0 (base of the parent) to 1 (its tip).
So taller trunks also get longer branches.

Every change rebuilds the tree, unless `auto_generate` is off.

## CosmoTreeGen
| Parameter | Default | Description |
| --------- | ------- | ----------- |
| *Generate tree* | | Button. Rebuilds the meshes, collisions and LODs from the current parameters. Use it when `auto_generate` is off, or after changing the [settings](settings.md). |
| `auto_generate` | `true` | Rebuilds the tree every time a parameter changes. Turn it off for heavy trees and use *Generate tree*. |
| `noise_seed` | `42` | Seed of all the random values. The same seed and parameters always make the same tree. The `Seed` button in the toolbar sets a random one. |

### Tree Parameters
| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `trunk_params` | | Shape of the trunks and their roots. See [CosmoTrunkParams](#cosmotrunkparams). |
| `branch_levels` | Empty | Branch levels, from the trunk out. The first level grows from the trunks, the second from the first level branches, and so on. See [CosmoBranchLevel](#cosmobranchlevel). |
| `foliage_params` | | Foliage type and shape. It grows on the branches of the last level, or on the trunks if there are none. See [CosmoFoliageParams](#cosmofoliageparams). |

### Meshes
| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `generate_lod` | `false` | Generates 3 LODs (`_LOD0`, `_LOD1` and `_LOD2`) that swap with the distance. Their triangle ratios and distances are in `Project Settings > Cosmo Tree Gen > Generator`, see [Settings](settings.md). |
| `lod_trunk_share` | `0.33` | Share of each LOD triangle budget kept for the trunk, the foliage gets the rest. Raise it to keep more trunk detail, lower it to keep more leaves. Only used with `generate_lod`. See [How the triangle budget works](settings.md#how-the-triangle-budget-works). |
| `combine_trunk_and_foliage` | `true` | Puts the trunk and the foliage in a single mesh, one surface each. Turn it off to get separate `Trunk` and `Foliage` nodes, e.g. to change the shadows of the foliage only. Both ways it's 2 draw calls (2 materials). |
| `flat_shading` | `false` | One normal per face for a low-poly/PSX look, on the trunk, branches, roots and icospheres. Leaf cards aren't affected. |
| `create_trunk` | `true` | Builds the trunk, branches and roots mesh. When off, the branches are still generated, so the foliage and the collisions don't change. |
| `create_foliage` | `true` | Builds the foliage mesh. When off, there's no foliage collision either. |

### Collision
| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `collision_type` | `None` | Type of collision to generate for the trunk, roots and branches. See the types below. |
| `collision_level` | `0` | Maximum level of branches to create collisions for. Level 0 generates collisions just for the trunk/s and level 1 for trunks, roots and first level of branches. |
| `collision_max_height` | `0 m` | Cuts the trunk, root and branch collisions at this height, in local space. Branches starting above it get no collision. 0 means no limit. |
| `foliage_collision_type` | `None` | Type of collision to generate for the foliage. See the types below. |
| `preview_collision` | `false` | Draws the collision shapes on top of the tree. Editor only, never exported. |
| `collision_layer` | `1` | Physics layers of the generated StaticBody3Ds, trunk and foliage. |
| `collision_mask` | `1` | Physics layers scanned by the generated StaticBody3Ds, trunk and foliage. |

The collisions are `StaticBody3D` child nodes: `Collision` for the trunk, roots and branches, and `FoliageCollision` for the foliage.

`collision_type`:

| Type | Description |
| ---- | ----------- |
| `None` | Do not generate collision shapes. |
| `Simple Convex` | One convex collision shape per branch, up to `collision_level`. Curved branches get a looser fit. |
| `Multiple Convex` | One convex collision shape per branch segment, up to `collision_level`. More precise than Simple Convex, it's solid so pushes out bodies. Uses more memory than Trimesh. |
| `Trimesh` | A single trimesh collision shape, using branch levels up to `collision_level`. The cheapest and closest fit, but hollow and one-sided. Fast or overlapping bodies can pass through it. Doesn't work on a `RigidBody3D`. Avoid this if you want falling trees. |

`foliage_collision_type`:

| Type | Description |
| ---- | ----------- |
| `None` | Do not generate collision shapes for foliage. |
| `Hull` | One convex collision shape around the whole canopy. |
| `Spheres` | One `SphereShape3D` per branch tip. |

### Materials
| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `trunk_material` | Empty | Material of the trunk, branches and roots. The width of its albedo texture (the `albedo_texture` uniform on a ShaderMaterial) and `texel_density` set the bark UV scale. |
| `foliage_material` | Empty | Material of the leaf cards or the icospheres. Leaf cards take the shape of its albedo texture (the `albedo_texture` uniform on a ShaderMaterial), see `leaf_aspect`. Icospheres have no UVs, they need a material with UV1 Triplanar. The included leaves shader adds wind sway and uses `leaf_inner_ao`. |
| `texel_density` | `64 px/m` | Bark texture pixels per meter, the same on trunks, branches and roots. The texture repeats every `texture width / texel_density` meters, e.g. a 1024 px texture with 64 px/m repeats every 16 m. Without an albedo texture, 128 px is used. |

The addon includes some materials in `addons/cosmo_tree_gen/materials`: `bark.tres` for the trunk, `leaves_01.tres` and `leaves_03.tres` for leaf cards, and `foliage.tres` for icospheres (it already has UV1 Triplanar).

## CosmoTrunkParams
Shape of the trunks of a `CosmoTreeGen`, and their roots.

| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `quality` | `1` | Mesh detail of the trunks, branches and roots. Trunks get 6 × quality sides and 3 × quality height segments, branches and roots 2 sides less. Branch segments are set per level, in `CosmoBranchLevel.segments`. |
| `amount` | `1` | Number of trunks, growing from the same base in a circle. Each one gets its own branches. |
| `spread` | `1.0` | Distance between the trunk bases, relative to `radius_bottom`. 0 grows them all from the same point and 1 makes them touch. Only used with 2 or more trunks. |
| `height` | `4.5 m` | Height of the trunks. Branch lengths are relative to their parent, so taller trunks also get longer branches. |
| `radius_bottom` | `0.35 m` | Radius at the base of the trunks, before the `flare`. |
| `radius_top` | `0.1 m` | Radius at the top of the trunks. It goes linearly from `radius_bottom` to this. |
| `lean` | `0.6 m` | How far the top of the trunks moves sideways. It bends more towards the top. The direction comes from the seed. Multiple trunks lean away from each other. |
| `wobble` | `0.15 m` | Random sideways bending of the trunks. Strongest in the middle, the base and the top don't move. |
| `flare` | `0.0` | Widens the base of the trunks. 1 doubles the radius at the ground, 0 disables it. |
| `flare_height` | `0.15` | How high the flare reaches, as a fraction of `height`. |
| `flare_lobes` | `0.6` | How uneven the flare is around the trunk. 0 keeps it round, 1 makes strong lobes. |
| `sink_depth` | `0 m` | Extends the trunks this many meters underground, so they don't float on slopes. |
| `roots` | Empty | Branch level that grows the roots from each trunk. Roots get no foliage. Use a low `end`, a high `angle` and a negative `up_force` so they spread near the ground, see the Ash preset. It's a [CosmoBranchLevel](#cosmobranchlevel). |

## CosmoBranchLevel
A level of branches of a `CosmoTreeGen`, grown from every branch of the previous level, or from the trunks for the first one.  
It's also used for the `roots` of [CosmoTrunkParams](#cosmotrunkparams).

| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `count` | `6` | Branches grown from each parent branch, spread around it between `start` and `end`. |
| `terminal` | `false` | Grows one more branch from the tip of each parent, with its direction and radius, meshed as a single tube with it. Use it to continue the trunk or the branches past the child branches. It isn't counted in `count`. |
| `start` | `0.4` | Where the branches start along the parent, 0 is its base and 1 its tip. |
| `end` | `0.9` | Where the branches end along the parent, 0 is its base and 1 its tip. |
| `angle` | `50°` | Angle between the branches and their parent. 0 grows them along the parent, 90 perpendicular. |
| `length` | `0.4` | Length of the branches, as a fraction of their parent's length. |
| `length_curve` | Empty | Multiplies `length` by the curve value where each branch grows on the parent (0 base, 1 tip). For example, a curve going down makes a conical, pine-like shape. Branches where it's 0 aren't grown. |
| `radius` | `0.6` | Radius of the branches at their base, as a fraction of the parent radius where they grow. Branches taper to 20% of it at the tip. Terminal branches keep the parent radius instead. |
| `segments` | `3` | Segments per branch. More segments make smoother bends with `gnarl` and `up_force`. With Multiple Convex collision, each segment is a collision shape. |
| `gnarl` | `0.3` | Random bending of the branches. 0 keeps them straight. |
| `up_force` | `0.5` | Bends the branches up when positive, or down when negative, like a willow. Broken branches always bend down, see `broken_chance`. |
| `broken_chance` | `0.0` | Chance for each branch to be broken: shorter, bent down, and without child branches or foliage. |

## CosmoFoliageParams
Foliage of a `CosmoTreeGen`: icospheres or leaf cards on the branches of the last level.  
Only the parameters of the selected `type` are shown in the inspector.

| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `type` | `Icospheres` | Foliage type. See the types below. |

| Type | Description |
| ---- | ----------- |
| `None` | No foliage. |
| `Icospheres` | One noisy icosphere at the tip of each branch of the last level, and at the top of each trunk. Needs a material with UV1 Triplanar. |
| `Leaves` | Textured cards along the branches of the last level. |

### Icospheres
| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `icosphere_length_influence` | `0.4` | How much the branch length scales the icospheres. 0 gives them all `icosphere_radius`, 1 scales it by the branch length relative to the trunk. |
| `icosphere_radius` | `1.0 m` | Radius of the icospheres, before `icosphere_length_influence`. |
| `icosphere_subdivisions` | `1` | Detail of the icospheres, each level has 4 times the triangles: 20, 80, 320, 1280 and 5120 per icosphere. |
| `icosphere_amplitude` | `0.4` | How much the noise deforms the icospheres, as a fraction of their radius. 0 keeps them round. |
| `icosphere_frequency` | `1.5` | Frequency of the deformation noise. Higher values make more and smaller bumps. |

### Leaves
| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `leaf_count` | `12` | Leaves per branch, spread from `leaf_start` to the tip. With `leaf_double`, each leaf is 2 cards. |
| `leaf_tip` | `false` | Adds one more leaf at the tip of each branch, pointing along it. |
| `leaf_size` | `0.6 m` | Height of the leaf cards, before `leaf_size_variance`, `leaf_size_curve` and `leaf_length_influence`. |
| `leaf_aspect` | `0.0` | Width / height of the leaf cards, their height is `leaf_size`. 0 takes it from the albedo texture of the foliage material, or square if it has none. |
| `leaf_size_curve` | Empty | Multiplies `leaf_size` by the curve value where each leaf grows on the branch (0 base, 1 tip). Leaves where it's 0 are skipped. |
| `leaf_length_influence` | `0.0` | How much the branch length scales the leaves. 0 gives them all the same size, 1 scales them by the branch length relative to the longest branch. |
| `leaf_size_variance` | `0.3` | Random size variation of each leaf, 0.3 is ±30%. |
| `leaf_start` | `0.3` | Where the leaves start along the branch, 0 is its base and 1 its tip. |
| `leaf_position_offset` | `Vector3.ZERO` | Offset applied to each leaf's position relative to its attachment point. |
| `leaf_angle` | `40°` | Angle between the leaf cards and the branch. 0 points them along the branch, 90 perpendicular. |
| `leaf_gravity` | `0.0` | How strong leaves are tilted toward the down direction. |
| `leaf_double` | `true` | Adds a second card to each leaf, crossed at 90°, so they don't look flat from the side. Doubles the foliage triangles. |
| `leaf_canopy_normals` | `0.8` | Blends the card normals towards a rounded shape around the whole canopy, so it's lit as one volume. 0 keeps the flat card normals. |
| `leaf_inner_ao` | `0.35` | Brightness of the leaves in the center of the canopy, it fades to 1 towards the edges. 1 disables it. Stored in the vertex color, the included leaves shader uses it as AO. |

## CosmoTreePreset
A saved tree type: the parameters and materials of a `CosmoTreeGen`.  
The toolbar `Preset` menu lists every `CosmoTreePreset` saved as `.tres` in the project, and `Preset > Save Preset` saves the current tree as a new one.

A preset saves:
- `trunk_params`, `branch_levels` and `foliage_params`.
- `trunk_material`, `foliage_material` and `texel_density`.
- `combine_trunk_and_foliage`, `flat_shading`, `create_trunk`, `create_foliage` and `lod_trunk_share`.

The rest stays as it is on the node when you load a preset: `noise_seed`, `auto_generate`, `generate_lod`, and the collision parameters.

Loading a preset copies its parameters, so editing the tree doesn't change the preset file. Use `Preset > Save Preset` to keep the changes.
