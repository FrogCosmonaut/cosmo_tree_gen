# Parameters

Work in progress. Right now they're just copy pasted from code.
I'll add the explanation when I document the parameters in the code, now they're almost all undocumented.

## CosmoTreeGen
- *Generate tree*:
- *auto_generate*:
- *noise_seed*:

### Tree Parameters
- *trunk_params*: see CosmoTrunkParams
- *branch_levels*: Array containing CosmoBranchLevel
- *foliage_params*: see CosmoFoliageParams

### Meshes
- *generate_lod*:
- *lod_trunk_share*:
- *combine_trunk_and_foliage*:
- *flat_shading*:
- *create_trunk*:
- *create_foliage*:

### Collision
- *collision_type*:
- *collision_level*:
- *collision_max_height*:
- *foliage_collision_type*:
- *preview_collision*:
- *collision_layer*:
- *collision_mask*:

### Materials
- *trunk_material*:
- *foliage_material*:
- *texel_density*:

## CosmoTrunkParams
- *quality*:
- *amount*:
- *spread*:
- *height*:
- *radius_bottom*:
- *radius_top*:
- *lean*:
- *wobble*:
- *flare*:
- *flare_height*:
- *flare_lobes*:
- *sink_depth*:
- *roots*:

## CosmoBranchLevel
- *count*:
- *terminal*:
- *start*:
- *end*:
- *angle*:
- *length*:
- *length_curve*:
- *radius*:
- *segments*:
- *gnarl*:
- *up_force*:
- *broken_chance*:

## CosmoFoliageParams
- *type*: Icospheres/Leaves

### Icospheres
- *icosphere_length_influence*:
- *icosphere_radius*:
- *icosphere_subdivisions*:
- *icosphere_amplitude*:
- *icosphere_frequency*:

### Leaves
- *leaf_count*:
- *leaf_tip*:
- *leaf_size*:
- *leaf_aspect*:
- *leaf_size_curve*:
- *leaf_length_influence*:
- *leaf_size_variance*:
- *leaf_start*:
- *leaf_angle*:
- *leaf_double*:
- *leaf_canopy_normals*:
- *leaf_inner_ao*:
