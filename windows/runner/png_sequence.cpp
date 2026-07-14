#include "png_sequence.h"

#include <wincodec.h>

#include <iomanip>
#include <sstream>

#pragma comment(lib, "windowscodecs.lib")

namespace keti {

namespace {

// Formats a frame index into the 5-digit zero-padded suffix used by the
// macOS asset catalog.
std::wstring FormatFramePath(const std::wstring& directory,
                             const std::wstring& resource_name,
                             int frame_index) {
  std::wostringstream ss;
  ss << directory;
  if (!directory.empty() && directory.back() != L'\\' &&
      directory.back() != L'/') {
    ss << L'\\';
  }
  ss << resource_name << L'_' << std::setw(5) << std::setfill(L'0')
     << frame_index << L".png";
  return ss.str();
}

bool ConvertToPremultipliedBitmap(IWICBitmapSource* source,
                                  HBITMAP* out_bitmap,
                                  HDC* out_dc,
                                  int* out_width,
                                  int* out_height) {
  if (source == nullptr || out_bitmap == nullptr || out_dc == nullptr) {
    return false;
  }

  UINT width = 0;
  UINT height = 0;
  HRESULT hr = source->GetSize(&width, &height);
  if (FAILED(hr) || width == 0 || height == 0) {
    return false;
  }

  BITMAPINFO bmi = {};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = static_cast<LONG>(width);
  bmi.bmiHeader.biHeight = -static_cast<LONG>(height);  // top-down DIB
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  void* bits = nullptr;
  HDC screen_dc = GetDC(nullptr);
  HBITMAP bitmap = CreateDIBSection(screen_dc, &bmi, DIB_RGB_COLORS, &bits,
                                    nullptr, 0);
  ReleaseDC(nullptr, screen_dc);

  if (bitmap == nullptr || bits == nullptr) {
    return false;
  }

  HDC mem_dc = CreateCompatibleDC(nullptr);
  if (mem_dc == nullptr) {
    DeleteObject(bitmap);
    return false;
  }
  SelectObject(mem_dc, bitmap);

  UINT stride = width * 4;
  UINT buffer_size = stride * height;
  hr = source->CopyPixels(nullptr, stride, buffer_size,
                          static_cast<BYTE*>(bits));
  if (FAILED(hr)) {
    DeleteDC(mem_dc);
    DeleteObject(bitmap);
    return false;
  }

  *out_bitmap = bitmap;
  *out_dc = mem_dc;
  if (out_width != nullptr) {
    *out_width = static_cast<int>(width);
  }
  if (out_height != nullptr) {
    *out_height = static_cast<int>(height);
  }
  return true;
}

}  // namespace

PngSequence::PngSequence() = default;

PngSequence::~PngSequence() {
  Clear();
}

bool PngSequence::Load(const std::wstring& directory,
                       const std::wstring& resource_name,
                       int frame_count) {
  Clear();

  if (frame_count <= 0) {
    return false;
  }

  IWICImagingFactory* factory = nullptr;
  HRESULT hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr,
                                CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory));
  if (FAILED(hr) || factory == nullptr) {
    return false;
  }

  frames_.reserve(frame_count);

  bool all_loaded = true;
  for (int i = 0; i < frame_count; ++i) {
    std::wstring path = FormatFramePath(directory, resource_name, i);

    IWICBitmapDecoder* decoder = nullptr;
    hr = factory->CreateDecoderFromFilename(
        path.c_str(), nullptr, GENERIC_READ,
        WICDecodeMetadataCacheOnDemand, &decoder);
    if (FAILED(hr) || decoder == nullptr) {
      all_loaded = false;
      break;
    }

    IWICBitmapFrameDecode* frame = nullptr;
    hr = decoder->GetFrame(0, &frame);
    decoder->Release();
    if (FAILED(hr) || frame == nullptr) {
      all_loaded = false;
      break;
    }

    IWICFormatConverter* converter = nullptr;
    hr = factory->CreateFormatConverter(&converter);
    if (FAILED(hr) || converter == nullptr) {
      frame->Release();
      all_loaded = false;
      break;
    }

    hr = converter->Initialize(
        frame, GUID_WICPixelFormat32bppPBGRA,
        WICBitmapDitherTypeNone, nullptr, 0.0,
        WICBitmapPaletteTypeCustom);
    frame->Release();
    if (FAILED(hr)) {
      converter->Release();
      all_loaded = false;
      break;
    }

    PngFrame png_frame;
    if (!ConvertToPremultipliedBitmap(converter, &png_frame.bitmap,
                                      &png_frame.dc, &png_frame.width,
                                      &png_frame.height)) {
      converter->Release();
      all_loaded = false;
      break;
    }
    converter->Release();

    frames_.push_back(png_frame);
  }

  factory->Release();

  if (!all_loaded) {
    Clear();
    return false;
  }

  return true;
}

void PngSequence::Clear() {
  for (auto& frame : frames_) {
    if (frame.dc != nullptr) {
      DeleteDC(frame.dc);
      frame.dc = nullptr;
    }
    if (frame.bitmap != nullptr) {
      DeleteObject(frame.bitmap);
      frame.bitmap = nullptr;
    }
  }
  frames_.clear();
}

const PngFrame* PngSequence::GetFrame(int index) const {
  if (index < 0 || index >= static_cast<int>(frames_.size())) {
    return nullptr;
  }
  return &frames_[index];
}

}  // namespace keti
