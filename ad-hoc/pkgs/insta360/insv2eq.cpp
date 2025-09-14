// file: insv2eq.cpp
// build: g++ -std=c++17 -I${MEDIASDK_ROOT}/include -I/path/to/cxxopts -L${MEDIASDK_ROOT}/lib -lins_media_sdk -ldl -pthread -o insv2eq insv2eq.cpp

#include <cxxopts.hpp>                 // single-header CLI parser
#include <filesystem>
#include <iostream>
#include <vector>
#include <mutex>
#include <condition_variable>

#include <ins_stitcher.h>              // main Media-SDK header

namespace fs = std::filesystem;
using namespace ins;                   // SDK namespace

// Convert one clip -----------------------------------------------------------
bool convert_clip(const std::vector<std::string>& in_paths,
                  const fs::path& out,
                  int width,
                  int height,
                  int bitrate_kbps,
                  STITCH_TYPE stitch_type,
                  bool enable_flow_stab,
                  bool use_h265,
                  bool use_cpu)
{
    std::mutex m;
    std::condition_variable cv;
    bool finished = false;
    bool success = false;
    int progress = -1;

    auto stitcher = std::make_shared<VideoStitcher>();

    stitcher->SetInputPath(in_paths);
    stitcher->SetOutputPath(out.string());
    stitcher->SetOutputSize(width, height);
    stitcher->SetOutputBitRate((int64_t)bitrate_kbps * 1000);
    stitcher->SetStitchType(stitch_type);
    stitcher->EnableFlowState(enable_flow_stab);
    stitcher->EnableCuda(false);
    // stitcher->SetSoftwareCodecUsage(true, true);
    stitcher->EnableStitchFusion(true);
    if (use_cpu) {
        stitcher->SetImageProcessingAccelType(ins::ImageProcessingAccel::kCPU);
    }
    if (use_h265) {
        stitcher->EnableH265Encoder();
    }

    stitcher->SetStitchProgressCallback([&](int process, int error) {
        if (progress != process) {
            progress = process;
            std::cout << "\r⏳  Processing " << fs::path(in_paths[0]).filename() << " ... " << progress << "%" << std::flush;
        }
        if (progress == 100) {
            std::unique_lock<std::mutex> lck(m);
            success = true;
            finished = true;
            cv.notify_one();
        }
    });

    stitcher->SetStitchStateCallback([&](int error, const char* err_info) {
        std::cerr << "❌  " << fs::path(in_paths[0]).filename()
                  << " failed: " << err_info << "\n";
        std::unique_lock<std::mutex> lck(m);
        success = false;
        finished = true;
        cv.notify_one();
    });

    stitcher->StartStitch();

    std::unique_lock<std::mutex> lck(m);
    cv.wait(lck, [&] { return finished; });

    if (success) {
        std::cout << "\r✅  " << fs::path(in_paths[0]).filename() << " → "
                  << out.filename() << std::string(20, ' ') << '\n';
    }
    return success;
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
        ("h265",        "Use H.265/HEVC encoder")
        ("cpu",        "Use CPU rather than GPU")
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

    STITCH_TYPE stitch = STITCH_TYPE::DYNAMICSTITCH;
    std::string pstr = args["preset"].as<std::string>();
    if      (pstr == "template") stitch = STITCH_TYPE::TEMPLATE;
    else if (pstr == "dynamic")  stitch = STITCH_TYPE::DYNAMICSTITCH;
    else if (pstr == "of")       stitch = STITCH_TYPE::OPTFLOW;
    else if (pstr == "ai")       stitch = STITCH_TYPE::AIFLOW;

    bool flow_stab = args["stabilize"].as<bool>();
    bool use_h265  = args.count("h265") > 0;
    bool use_cpu  = args.count("cpu") > 0;

    // SDK environment must be initialised once per process
    InitEnv();                                                // GPU required in v3.x ✔  [oai_citation:0‡GitHub](https://github.com/Insta360Develop/MediaSDK-Cpp)
    SetLogPath("insv2eq.log");

    // walk directory ---------------------------------------------------------
    auto walk_opt =  args.count("recursive") ?
                     fs::directory_options::follow_directory_symlink :
                     fs::directory_options::none;

    size_t converted = 0;
    for (auto&& entry : fs::recursive_directory_iterator(in_dir, walk_opt)) {
        if (!entry.is_regular_file() || entry.path().extension() != ".insv") {
            continue;
        }
    
        std::string filename_str = entry.path().filename().string();
        if (filename_str.find("_10_") != std::string::npos) {
            // _10_ files are handled with their _00_ counterparts
            continue;
        }
    
        std::vector<std::string> input_paths;
        input_paths.push_back(entry.path().string());
    
        if (filename_str.find("_00_") != std::string::npos) {
            std::string pair_filename = filename_str;
            size_t pos = pair_filename.find("_00_");
            pair_filename.replace(pos, 4, "_10_");
            fs::path pair_path = entry.path().parent_path() / pair_filename;
            if (fs::exists(pair_path)) {
                input_paths.push_back(pair_path.string());
            }
        }
    
        fs::path out_file = out_dir / entry.path().stem();
        out_file += ".mp4";
    
        // Clear the line for new progress output
        std::cout << "\r" << std::string(80, ' ') << "\r";
    
        if (convert_clip(input_paths, out_file, w, h, br_kbps,
                         stitch, flow_stab, use_h265, use_cpu))
            ++converted;
    }

    std::cout << "\n==> Finished.  " << converted << " clip(s) converted.\n";
    return 0;
}
