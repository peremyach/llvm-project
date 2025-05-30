//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// <vector>
// vector<bool>

// iterator insert(const_iterator position, const value_type& x);

#include <vector>
#include <cassert>
#include <cstddef>

#include "test_macros.h"
#include "min_allocator.h"

TEST_CONSTEXPR_CXX20 bool tests() {
  {
    std::vector<bool> v(100);
    std::vector<bool>::iterator i = v.insert(v.cbegin() + 10, 1);
    assert(v.size() == 101);
    assert(i == v.begin() + 10);
    std::size_t j;
    for (j = 0; j < 10; ++j)
      assert(v[j] == 0);
    assert(v[j] == 1);
    for (++j; j < v.size(); ++j)
      assert(v[j] == 0);
  }
  {
    std::vector<bool> v(100);
    while (v.size() < v.capacity())
      v.push_back(false);
    std::size_t sz                = v.size();
    std::vector<bool>::iterator i = v.insert(v.cbegin() + 10, 1);
    assert(v.size() == sz + 1);
    assert(i == v.begin() + 10);
    std::size_t j;
    for (j = 0; j < 10; ++j)
      assert(v[j] == 0);
    assert(v[j] == 1);
    for (++j; j < v.size(); ++j)
      assert(v[j] == 0);
  }
  {
    std::vector<bool> v(100);
    while (v.size() < v.capacity())
      v.push_back(false);
    v.pop_back();
    v.pop_back();
    std::size_t sz                = v.size();
    std::vector<bool>::iterator i = v.insert(v.cbegin() + 10, 1);
    assert(v.size() == sz + 1);
    assert(i == v.begin() + 10);
    std::size_t j;
    for (j = 0; j < 10; ++j)
      assert(v[j] == 0);
    assert(v[j] == 1);
    for (++j; j < v.size(); ++j)
      assert(v[j] == 0);
  }
#if TEST_STD_VER >= 11
  {
    std::vector<bool, explicit_allocator<bool>> v(10);
    std::vector<bool, explicit_allocator<bool>>::iterator i = v.insert(v.cbegin() + 10, 1);
    assert(v.size() == 11);
    assert(i == v.begin() + 10);
    assert(*i == 1);
  }
  {
    std::vector<bool, min_allocator<bool>> v(100);
    std::vector<bool, min_allocator<bool>>::iterator i = v.insert(v.cbegin() + 10, 1);
    assert(v.size() == 101);
    assert(i == v.begin() + 10);
    std::size_t j;
    for (j = 0; j < 10; ++j)
      assert(v[j] == 0);
    assert(v[j] == 1);
    for (++j; j < v.size(); ++j)
      assert(v[j] == 0);
  }
#endif

  return true;
}

int main(int, char**) {
  tests();
#if TEST_STD_VER > 17
  static_assert(tests());
#endif
  return 0;
}
