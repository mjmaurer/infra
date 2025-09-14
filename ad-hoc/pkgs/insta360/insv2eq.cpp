// file: insv2eq.cpp
// build: g++ -std=c++17 -I${MEDIASDK_ROOT}/include -I/path/to/cxxopts -L${MEDIASDK_ROOT}/lib -lins_media_sdk -ldl -pthread -o insv2eq insv2eq.cpp

#include <cxxopts.hpp>                 // single-header CLI parser
#include <filesystem>
#include <iostream>
#include <vector>

#include <ins_media_sdk.h>             // main Media-SDK header

namespace fs = std::filesystem;
using namespace ins;                   // SDK namespace

// Convert one clip -----------------------------------------------------------
bool convert_clip(const fs::path& in,
                  const fs::path& out,
                  int width,
                  int height,
                  int bitrate_kbps,
                  StitchingType stitch_type,
                  bool enable_flow_stab)
{
    // --- 1. configure export -----------------------------------------------
    ExportConfig cfg;
    cfg.width            = width;
    cfg.height           = height;
    cfg.bitrate          = bitrate_kbps * 1000;      // SDK expects bps
    cfg.stitch_type      = stitch_type;              // Template / Dynamic / OF / AI
    cfg.enable_flow_stab = enable_flow_stab;
    cfg.color_space      = ColorSpace::kBT709;       // SDR output

    // optional: cfg.custom_log_callback = ...

    // --- 2. run export ------------------------------------------------------
    VideoExporter exporter(in.string(), out.string(), cfg);
    ErrorCode err = exporter.Export();               // synchronous call

    if (err != ErrorCode::OK) {
        std::cerr << "❌  " << in.filename()
                  << " failed (error " << static_cast<int>(err) << ")\n";
        return false;
    }
    std::cout << "✅  " << in.filename() << " → "
              << out.filename() << '\n';
    return true;
}

// Main -----------------------------------------------------------------------
int main(int argc, char* argv[])
{
    cxxopts::Options opt("insv2eq",
        "Batch convert Insta360 .insv files to stitched equirectangular .mp4");

    opt.add_options()
        ("i,input",     "Input folder",      cxxopts::value<std::string>())
        ("o,output",    "Output folder",     cxxopts::value<std::string>()->default_value("converted"))
        ("w,width",     "Output width",      cxxopts::value<int>()->default_value("5760"))
        ("h,height",    "Output height",     cxxopts::value<int>()->default_value("2880"))
        ("b,bitrate",   "Bit-rate (kbps)",   cxxopts::value<int>()->default_value("60000"))
        ("p,preset",    "Stitch preset (template|dynamic|of|ai)",
                                            cxxopts::value<std::string>()->default_value("dynamic"))
        ("s,stabilize", "Enable FlowState stabilisation", cxxopts::value<bool>()->default_value("true"))
        ("recursive",   "Recurse into sub-folders")
        ("help",        "Show help");

    auto args = opt.parse(argc, argv);
    if (args.count("help") || !args.count("input")) {
        std::cout << opt.help() << "\n";
        return 0;
    }

    fs::path in_dir  = args["input"].as<std::string>();
    fs::path out_dir = args["output"].as<std::string>();
    fs::create_directories(out_dir);

    int  w       = args["width"].as<int>();
    int  h       = args["height"].as<int>();
    int  br_kbps = args["bitrate"].as<int>();

    StitchingType stitch = StitchingType::kDynamic;
    std::string pstr = args["preset"].as<std::string>();
    if      (pstr == "template") stitch = StitchingType::kTemplate;
    else if (pstr == "of")       stitch = StitchingType::kOpticalFlow;
    else if (pstr == "ai")       stitch = StitchingType::kAI;

    bool flow_stab = args["stabilize"].as<bool>();

    // SDK environment must be initialised once per process
    InitEnv();                                                // GPU required in v3.x ✔  [oai_citation:0‡GitHub](https://github.com/Insta360Develop/MediaSDK-Cpp)
    SetLogPath("insv2eq.log");

    // walk directory ---------------------------------------------------------
    auto walk_opt =  args.count("recursive") ?
                     fs::directory_options::follow_directory_symlink :
                     fs::directory_options::none;

    size_t converted = 0;
    for (auto&& entry : fs::recursive_directory_iterator(in_dir, walk_opt)) {
        if (!entry.is_regular_file()) continue;
        if (entry.path().extension() != ".insv")   continue;

        fs::path out_file = out_dir / entry.path().stem();
        out_file += ".mp4";

        if (convert_clip(entry.path(), out_file, w, h, br_kbps,
                         stitch, flow_stab))
            ++converted;
    }

    std::cout << "\n==> Finished.  " << converted << " clip(s) converted.\n";
    return 0;
}
