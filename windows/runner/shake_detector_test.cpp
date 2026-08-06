// Unit tests for the pure keti::ShakeDetector state machine (the algorithm
// behind mouse-shake reminder dismissal). Self-contained: uses only
// <cassert> and a tiny failure counter, so it builds with the plain C++
// toolchain. Run via `ctest` or directly as a console executable.
#include <cmath>
#include <cstdint>
#include <iostream>

#include "shake_detector.h"

namespace {

int g_failures = 0;

#define EXPECT_TRUE(cond)                                                     \
  do {                                                                        \
    if (!(cond)) {                                                            \
      ++g_failures;                                                           \
      std::cerr << "FAIL (line " << __LINE__ << "): " << #cond << std::endl;  \
    }                                                                         \
  } while (0)

// Feeds a horizontal shake with the given amplitude, interval and number of
// direction flips. Returns whether the detector fired at any point.
bool FeedHorizontalShake(keti::ShakeDetector* detector,
                         double amplitude = 50.0,
                         uint64_t interval_ms = 16,
                         int flips = 3,
                         double y = 100.0) {
  bool fired = false;
  double x = 0;
  double direction = 1.0;
  uint64_t t = 0;
  detector->Seed(x, y, t);
  for (int i = 0; i <= flips + 1; ++i) {
    x += direction * amplitude;
    t += interval_ms;
    if (detector->Sample(x, y, t)) {
      fired = true;
    }
    direction *= -1.0;
  }
  return fired;
}

void TestQuickHorizontalShakeTriggers() {
  keti::ShakeDetector detector;
  EXPECT_TRUE(FeedHorizontalShake(&detector));
}

void TestSlowHorizontalDriftDoesNotTrigger() {
  keti::ShakeDetector detector;
  EXPECT_TRUE(!FeedHorizontalShake(&detector, 50.0, 320));
}

void TestTinyAmplitudeDoesNotTrigger() {
  keti::ShakeDetector detector;
  EXPECT_TRUE(!FeedHorizontalShake(&detector, 5.0));
}

void TestSingleDirectionMovementDoesNotTrigger() {
  keti::ShakeDetector detector;
  detector.Seed(0, 100, 0);
  bool fired = false;
  for (int step = 1; step <= 12; ++step) {
    if (detector.Sample(step * 50.0, 100.0, step * 16)) {
      fired = true;
    }
  }
  EXPECT_TRUE(!fired);
}

void TestVerticalShakeTriggers() {
  keti::ShakeDetector detector;
  detector.Seed(200, 0, 0);
  bool fired = false;
  double y = 0;
  double direction = 1.0;
  uint64_t t = 0;
  for (int i = 0; i <= 4; ++i) {
    y += direction * 50.0;
    t += 16;
    if (detector.Sample(200.0, y, t)) {
      fired = true;
    }
    direction *= -1.0;
  }
  EXPECT_TRUE(fired);
}

void TestCooldownSuppressesSecondTrigger() {
  keti::ShakeDetector detector;
  EXPECT_TRUE(FeedHorizontalShake(&detector));

  bool fired_again = false;
  double x = 200;
  double direction = 1.0;
  uint64_t t = 90;
  for (int i = 0; i <= 4; ++i) {
    x += direction * 50.0;
    t += 16;
    if (detector.Sample(x, 100.0, t)) {
      fired_again = true;
    }
    direction *= -1.0;
  }
  EXPECT_TRUE(!fired_again);
}

void TestStalePauseResetsGesture() {
  keti::ShakeDetector detector;
  detector.Seed(0, 100, 0);
  bool fired = false;

  // Burst A: two reversals (+50, -50, +50) — not enough to fire.
  uint64_t t = 0;
  for (double x : {50.0, 0.0, 50.0}) {
    t += 16;
    if (detector.Sample(x, 100.0, t)) {
      fired = true;
    }
  }
  EXPECT_TRUE(!fired);

  // Long pause (stale) resets the gesture state.
  t += 500;
  detector.Sample(0, 100.0, t);

  // Burst B: only two reversals (+50, -50). If the pause had NOT reset the
  // counter, the cumulative 4 reversals would fire here.
  for (double x : {50.0, 0.0}) {
    t += 16;
    if (detector.Sample(x, 100.0, t)) {
      fired = true;
    }
  }
  EXPECT_TRUE(!fired);
}

}  // namespace

int main() {
  TestQuickHorizontalShakeTriggers();
  TestSlowHorizontalDriftDoesNotTrigger();
  TestTinyAmplitudeDoesNotTrigger();
  TestSingleDirectionMovementDoesNotTrigger();
  TestVerticalShakeTriggers();
  TestCooldownSuppressesSecondTrigger();
  TestStalePauseResetsGesture();

  if (g_failures == 0) {
    std::cout << "All shake detector tests passed." << std::endl;
    return 0;
  }
  std::cerr << g_failures << " test(s) failed." << std::endl;
  return 1;
}
