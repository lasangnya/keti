#ifndef RUNNER_PNG_SEQUENCE_H_
#define RUNNER_PNG_SEQUENCE_H_

#include <windows.h>

#include <string>
#include <vector>

namespace keti {

// Holds a decoded PNG frame as a DIB section selected into a memory DC.
// The bitmap is in 32bpp premultiplied-alpha BGRA format, suitable for
// UpdateLayeredWindow.
struct PngFrame {
  HBITMAP bitmap = nullptr;
  HDC dc = nullptr;
  int width = 0;
  int height = 0;
};

// Loads a sequence of individual PNG files (e.g. resource_00000.png) as
// used by the macOS asset catalog.
class PngSequence {
 public:
  PngSequence();
  ~PngSequence();

  // Disable copy.
  PngSequence(const PngSequence&) = delete;
  PngSequence& operator=(const PngSequence&) = delete;

  // Loads frames from |directory| using the naming pattern:
  //   <directory>\\<resource_name>_<5-digit-frame>.png
  // Loads frames 0 through |frame_count - 1|.
  bool Load(const std::wstring& directory,
            const std::wstring& resource_name,
            int frame_count);

  void Clear();

  bool IsLoaded() const { return !frames_.empty(); }
  int frame_count() const { return static_cast<int>(frames_.size()); }
  const PngFrame* GetFrame(int index) const;

 private:
  std::vector<PngFrame> frames_;
};

}  // namespace keti

#endif  // RUNNER_PNG_SEQUENCE_H_
