// RUN: %clang_cc1 -std=c++17 -triple x86_64-unknown-linux-gnu \
// RUN:   -aux-triple nvptx64-nvidia-cuda -fsyntax-only -verify=host,expected %s
// RUN: %clang_cc1 -std=c++17 -triple nvptx64-nvidia-cuda -target-cpu sm_80 \
// RUN:   -fcuda-is-device -aux-triple x86_64-unknown-linux-gnu \
// RUN:   -fsyntax-only -verify=dev,expected %s
// RUN: %clang_cc1 -std=c++17 -triple nvptx64-nvidia-cuda -target-cpu sm_70 \
// RUN:   -fcuda-is-device -aux-triple x86_64-unknown-linux-gnu \
// RUN:   -fsyntax-only -verify=sm70,expected %s

#include "Inputs/cuda.h"

#ifndef __CUDA_ARCH__
#define __CUDA_ARCH__ 0
#endif

namespace nv {
namespace target {
namespace detail {

struct target_description {
  constexpr target_description(int) {}
};

enum class sm_selector {
  sm_70,
  sm_80,
};

constexpr target_description provides(sm_selector) { return 0; }
constexpr target_description is_exactly(sm_selector) { return 0; }
constexpr target_description operator!(target_description) { return 0; }
constexpr target_description operator&&(target_description,
                                        target_description) {
  return 0;
}
constexpr target_description operator||(target_description,
                                        target_description) {
  return 0;
}

} // namespace detail

using detail::is_exactly;
using detail::provides;
using detail::sm_selector;
using detail::target_description;

constexpr target_description is_host = 0;
constexpr target_description is_device = 0;
constexpr target_description any_target = 0;
constexpr target_description no_target = 0;

constexpr sm_selector sm_70 = sm_selector::sm_70;
constexpr sm_selector sm_80 = sm_selector::sm_80;

} // namespace target
} // namespace nv

template <bool> struct require_true;
template <> struct require_true<true> {};

__host__ int host_only();
__device__ int device_only();

__host__ __device__ int select_host_device() {
  [[nv::if_target]] if (nv::target::is_device) {
    return device_only();
  } else {
    return host_only();
  }
}

template <int Arch = __CUDA_ARCH__> __host__ __device__ int select_sm80() {
  [[nv::if_target]] if (nv::target::provides(nv::target::sm_80)) {
    require_true<Arch >= 800> check;
    return 80;
  } else {
    require_true<Arch < 800> check;
    return 70;
  }
}

template <int Arch = __CUDA_ARCH__>
__host__ __device__ int select_exact_sm70() {
  [[nv::if_target]] if (nv::target::is_exactly(nv::target::sm_70) ||
                     !nv::target::is_device) {
    require_true<Arch == 700 || Arch == 0> check;
    return 70;
  } else {
    require_true<Arch != 700 && Arch != 0> check;
    return 0;
  }
}

__host__ __device__ int instantiate_target_selectors() {
  return select_sm80<>() + select_exact_sm70<>();
}

void invalid_conditions() {
  [[nv::if_target]] if (true) {
  } // expected-error@-1 {{'[[nv::if_target]] if' condition must be a constant nv::target selector expression}}

  [[nv::if_target]] if constexpr (nv::target::is_host) {
  } // expected-error@-1 {{'[[nv::if_target]] if' cannot also be a constexpr or consteval if statement}}
}
