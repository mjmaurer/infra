#!/usr/bin/env bash
# colmap_head_pipeline.sh
# Automate a COLMAP photogrammetry pipeline (Linux, NVIDIA GPU-friendly)
# - From a folder of photos -> sparse model -> dense depth -> fused point cloud -> optional mesh -> optional texture
# - Fails if output directory already exists (no overwrite)
# - Forces you to choose exactly one option for each major pipeline decision (except texturing, which defaults to off)

set -Eeuo pipefail

#-------------------------
# Helpers
#-------------------------
die() { echo "Error: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
title() { printf "\n===== %s =====\n" "$*"; }

usage() {
    cat <<'EOF'
COLMAP Head Reconstruction Pipeline
Usage:
    colmap_head_pipeline.sh \
    --images /path/to/images \
    --out /path/to/output_dir \
    --camera-model MODEL \
    --matching STRATEGY [--vocab-tree /path/to/tree.bin] \
    --mesher METHOD \
    --gpu MODE \
    [--texturing on|off] \
    [--help]

Required:
    --images PATH
        Folder containing your photos (JPG/PNG). Keep EXIF if possible (focal length helps).

    --out PATH
        Output directory. Must not exist; it will be created.

    --camera-model MODEL   [choose exactly one]
        One of:
        SIMPLE_RADIAL   - Recommended default for phones and most consumer cameras.
                            Good when you don't know lens parameters; robust and simple.
        SIMPLE_PINHOLE  - Pinhole without distortion. Only if you are sure distortion is negligible.
        PINHOLE         - Full fx/fy/cx/cy. Use if you know your lens is well-behaved and want full intri
        nsics.
        RADIAL          - Pinhole + 2 radial distortion params. Good compromise for mild distortion.
        OPENCV          - Brown–Conrady model (radial + tangential). Best if you have stronger distortion
        .
        OPENCV_FISHEYE  - For fisheye lenses.

    --matching STRATEGY    [choose exactly one]
        One of:
        exhaustive   - Compares all images with all others.
                        Best accuracy, OK when you have <= ~500 images. Recommended for head scans with 5
                        50–200 photos.
        sequential   - Matches neighbors in a sequence (video frames or ordered orbit).
                        Fast for video/turntable captures; name/ordering should reflect actual capture or
                        der.
        vocab_tree   - Uses a vocabulary tree for large sets; fast but requires --vocab-tree.
                        Good when you have lots of images (>1k) or mixed viewpoints.

        --vocab-tree PATH  (required if --matching vocab_tree)
            Path to a vocabulary tree file (e.g., COLMAP’s flickr100K or similar).

    --mesher METHOD        [choose exactly one]
        One of:
        poisson     - Produces a smooth, watertight mesh from fused point cloud.
                        Good for organic shapes (faces/heads). Can over-smooth and fill gaps.
        delaunay    - Reconstructs mesh from depth maps; preserves edges; may produce holes where data is
        missing.
                        Often good with clean coverage.
        none        - Skip meshing (you’ll still get fused.ply point cloud).

    --gpu MODE             [choose exactly one]
        One of:
        cuda   - Use NVIDIA GPU for SIFT and dense stereo (fastest). Requires COLMAP built with CUDA and
        a working NVIDIA setup.
        cpu    - Force CPU for the parts that allow it (slower).
        auto   - Use CUDA if available (checks nvidia-smi), fall back to CPU otherwise.

Optional:
    --texturing on|off     Default: off
        Attempt to texture the mesh (requires extra tools; see notes below). If off, you can texture later
        in other tools.

    --help
        Show this help and option guidance.

Notes and tips:
- Image capture: use even, diffuse light; overlap 60–80%; keep the subject still; neutral expression; hai
r can be difficult.
- For head scans with 50–200 images from a phone:
    --camera-model SIMPLE_RADIAL
    --matching exhaustive
    --mesher poisson
    --gpu cuda
- Output directory structure:
    out/
        database.db
        sparse/      (SfM recon)
        dense/       (undistorted imgs, depth maps, fused.ply, mesh if chosen)
        logs/        (logs)

Examples:
    Beginner-friendly (phone photos, strong GPU):
    colmap_head_pipeline.sh \
        --images ~/pics/head \
        --out ~/recon/head \
        --camera-model SIMPLE_RADIAL \
        --matching exhaustive \
        --mesher poisson \
        --gpu cuda

    Video frames or turntable sequence (ordered filenames):
    colmap_head_pipeline.sh \
        --images ~/pics/head_seq \
        --out ~/recon/head_seq \
        --camera-model SIMPLE_RADIAL \
        --matching sequential \
        --mesher delaunay \
        --gpu auto

    Large dataset with vocabulary tree:
    colmap_head_pipeline.sh \
        --images ~/pics/huge \
        --out ~/recon/huge \
        --camera-model OPENCV \
        --matching vocab_tree --vocab-tree /usr/share/colmap/vocab_tree_flickr100K_words256K.bin \
        --mesher poisson \
        --gpu cuda

Texturing (optional, off by default):
- COLMAP does not provide full texture baking to a mesh in-core. Common options:
    - OpenMVS: InterfaceCOLMAP -> ReconstructMesh -> TextureMesh
    - MVS-Texturing (texrecon): requires compatible inputs (see the project’s docs)
- This script will try to call texrecon if you enable --texturing on and texrecon is found,
    but you’ll likely need to adjust paths/options for best results.

EOF
}

#-------------------------
# Parse args
#-------------------------
IMAGES=""
OUT_DIR=""
CAMERA_MODEL=""
MATCHING=""
VOCAB_TREE=""
MESHER=""
GPU_MODE=""
TEXTURING="off"

while [[ $# -gt 0 ]]; do
    case "$1" in
    -i|--images) IMAGES="${2:-}"; shift 2 ;;
    -o|--out) OUT_DIR="${2:-}"; shift 2 ;;
    -c|--camera-model) CAMERA_MODEL="${2:-}"; shift 2 ;;
    -m|--matching) MATCHING="${2:-}"; shift 2 ;;
    --vocab-tree) VOCAB_TREE="${2:-}"; shift 2 ;;
    --mesher) MESHER="${2:-}"; shift 2 ;;
    --gpu) GPU_MODE="${2:-}"; shift 2 ;;
    --texture|--texturing) TEXTURING="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# If required choices are missing, show help with guidance
if [[ -z "${IMAGES:-}" || -z "${OUT_DIR:-}" || -z "${CAMERA_MODEL:-}" || -z "${MATCHING:-}" || -z "${MESHER:-}" || -z "${GPU_MODE:-}" ]]; then
    echo "Missing required options." >&2
    usage
    exit 2
fi

# Normalizations
CAMERA_MODEL=$(echo "$CAMERA_MODEL" | tr '[:lower:]' '[:upper:]')
MATCHING=$(echo "$MATCHING" | tr '[:upper:]' '[:lower:]')
MESHER=$(echo "$MESHER" | tr '[:upper:]' '[:lower:]')
GPU_MODE=$(echo "$GPU_MODE" | tr '[:upper:]' '[:lower:]')
TEXTURING=$(echo "$TEXTURING" | tr '[:upper:]' '[:lower:]')

# Validate values
case "$CAMERA_MODEL" in
    SIMPLE_RADIAL|SIMPLE_PINHOLE|PINHOLE|RADIAL|OPENCV|OPENCV_FISHEYE) ;;
    *) die "--camera-model must be one of SIMPLE_RADIAL|SIMPLE_PINHOLE|PINHOLE|RADIAL|OPENCV|OPENCV_FISHEYE
    " ;;
esac
case "$MATCHING" in
    exhaustive|sequential|vocab_tree) ;;
    *) die "--matching must be one of exhaustive|sequential|vocab_tree" ;;
esac
if [[ "$MATCHING" == "vocab_tree" && -z "$VOCAB_TREE" ]]; then
    die "--vocab-tree PATH is required when --matching vocab_tree"
fi
case "$MESHER" in
    poisson|delaunay|none) ;;
    *) die "--mesher must be one of poisson|delaunay|none" ;;
esac
case "$GPU_MODE" in
    cuda|cpu|auto) ;;
    *) die "--gpu must be one of cuda|cpu|auto" ;;
esac
case "$TEXTURING" in
    on|off) ;;
    *) die "--texturing must be on|off (default off)" ;;
esac

# Validate env
have colmap || die "COLMAP not found in PATH. Install/build COLMAP (with CUDA for GPU)."

[[ -d "$IMAGES" ]] || die "--images directory not found: $IMAGES"

# Decide GPU usage flags
USE_GPU=0
PATCHMATCH_GPU_INDEX=-1
if [[ "$GPU_MODE" == "cuda" ]]; then
    USE_GPU=1
    PATCHMATCH_GPU_INDEX=0
elif [[ "$GPU_MODE" == "auto" ]]; then
    if have nvidia-smi; then
    USE_GPU=1
    PATCHMATCH_GPU_INDEX=0
    else
    USE_GPU=0
    PATCHMATCH_GPU_INDEX=-1
    fi
fi

# Prepare outputs (fail if exists)
if [[ -e "$OUT_DIR" ]]; then
    die "--out directory already exists: $OUT_DIR (refusing to overwrite). Please choose a new path or remove it."
fi
mkdir -p "$OUT_DIR"/{sparse,dense,logs}
DB_OUT="$OUT_DIR/database.db"
DB="/tmp/colmap_database.db"
rm -f "$DB"
SPARSE="$OUT_DIR/sparse"
DENSE="$OUT_DIR/dense"
LOGS="$OUT_DIR/logs"

logfile="$LOGS/colmap.log"
run() {
    echo "+ $*" | tee -a "$logfile"
    "$@" 2>&1 | tee -a "$logfile"
}

#-------------------------
# Pipeline
#-------------------------
title "1) Feature Extraction"
run colmap feature_extractor \
    --database_path "$DB" \
    --image_path "$IMAGES" \
    --ImageReader.single_camera 1 \
    --ImageReader.camera_model "$CAMERA_MODEL" \
    --SiftExtraction.use_gpu "$USE_GPU"

title "2) Feature Matching ($MATCHING)"
case "$MATCHING" in
    exhaustive)
    run colmap exhaustive_matcher \
        --database_path "$DB" \
        --SiftMatching.use_gpu "$USE_GPU"
    ;;
    sequential)
    # Tip: adjust overlap if needed (default is fine for most cases)
    run colmap sequential_matcher \
        --database_path "$DB" \
        --SiftMatching.use_gpu "$USE_GPU"
    ;;
    vocab_tree)
    [[ -f "$VOCAB_TREE" ]] || die "Vocabulary tree not found: $VOCAB_TREE"
    run colmap vocab_tree_matcher \
        --database_path "$DB" \
        --VocabTreeMatching.vocab_tree_path "$VOCAB_TREE" \
        --SiftMatching.use_gpu "$USE_GPU"
    ;;
esac

title "3) Sparse Reconstruction (Incremental SfM)"
run colmap mapper \
    --database_path "$DB" \
    --image_path "$IMAGES" \
    --output_path "$SPARSE"

# Choose model 0 (default primary model). Adjust here if you need to pick another.
MODEL_PATH="$SPARSE/0"
[[ -d "$MODEL_PATH" ]] || die "No sparse model found in $SPARSE (mapper may have failed or produced a dif
ferent model index)."

title "4) Undistort Images for Dense MVS"
run colmap image_undistorter \
    --image_path "$IMAGES" \
    --input_path "$MODEL_PATH" \
    --output_path "$DENSE" \
    --output_type COLMAP

title "5) Dense Depth Estimation (PatchMatch Stereo)"
# Geometric consistency generally improves robustness on heads; GPU index -1 means CPU.
run colmap patch_match_stereo \
    --workspace_path "$DENSE" \
    --workspace_format COLMAP \
    --PatchMatchStereo.geom_consistency true \
    --PatchMatchStereo.gpu_index "$PATCHMATCH_GPU_INDEX"

title "6) Depth Fusion (Fused Point Cloud)"
run colmap stereo_fusion \
    --workspace_path "$DENSE" \
    --workspace_format COLMAP \
    --input_type geometric \
    --output_path "$DENSE/fused.ply"

# Meshing (optional, but you chose one)
if [[ "$MESHER" == "poisson" ]]; then
    title "7) Meshing (Poisson)"
    run colmap poisson_mesher \
    --input_path "$DENSE/fused.ply" \
    --output_path "$DENSE/meshed-poisson.ply"
elif [[ "$MESHER" == "delaunay" ]]; then
    title "7) Meshing (Delaunay)"
    run colmap delaunay_mesher \
    --input_path "$DENSE" \
    --output_path "$DENSE/meshed-delaunay.ply"
else
    title "7) Meshing skipped (--mesher none)"
fi

# Optional texturing
if [[ "$TEXTURING" == "on" ]]; then
    title "8) Texturing (best-effort; requires external tool)"
    if have texrecon; then
    # Best-effort texrecon call (you may need to tailor this for your setup/tooling)
    MESH_IN=""
    if [[ -f "$DENSE/meshed-delaunay.ply" ]]; then
        MESH_IN="$DENSE/meshed-delaunay.ply"
    elif [[ -f "$DENSE/meshed-poisson.ply" ]]; then
        MESH_IN="$DENSE/meshed-poisson.ply"
    else
        echo "No mesh found to texture; skipping." | tee -a "$logfile"
        MESH_IN=""
    fi

    if [[ -n "$MESH_IN" ]]; then
        # texrecon invocation patterns vary by build; this is a placeholder.
        # Consult texrecon docs for the correct adapter (COLMAP/MVE/OpenMVG input).
        TEX_OUT_DIR="$OUT_DIR/texture"
        mkdir -p "$TEX_OUT_DIR"
        echo "texrecon detected, but automatic COLMAP<->texrecon wiring varies." | tee -a "$logfile"
        echo "Saving mesh for manual texturing workflows in: $MESH_IN" | tee -a "$logfile"
        echo "Tip: Consider OpenMVS (InterfaceCOLMAP -> TextureMesh) or adjust texrecon command to your bui
        ld." | tee -a "$logfile"
    fi
    else
    echo "texrecon not found. For texturing consider installing OpenMVS or MVS-Texturing." | tee -a "$logfile"
    fi
else
    title "8) Texturing disabled (default)."
fi

title "Done"
# Move database from /tmp to output dir and clean up
if [[ -f "$DB" ]]; then
    cp -f "$DB" "$DB_OUT"
    rm -f "$DB"
fi
echo "Outputs:"
echo "  Sparse model:  $MODEL_PATH"
echo "  Dense folder:  $DENSE"
[[ -f "$DENSE/fused.ply" ]] && echo "  Fused cloud:   $DENSE/fused.ply"
[[ -f "$DENSE/meshed-poisson.ply" ]] && echo "  Mesh (poisson):  $DENSE/meshed-poisson.ply"
[[ -f "$DENSE/meshed-delaunay.ply" ]] && echo "  Mesh (delaunay): $DENSE/meshed-delaunay.ply"
echo "  Logs:          $LOGS"
