// RUN: %clang_cc1 -std=c++17 -fsyntax-only -verify %s

namespace nv {
namespace target {
struct target_description {};
constexpr target_description is_host = {};
} // namespace target
} // namespace nv

void test() {
  [[nv::if_target]] if (nv::target::is_host) {
  } // expected-error@-1 {{'[[nv::if_target]] if' is only supported in CUDA}}
}
