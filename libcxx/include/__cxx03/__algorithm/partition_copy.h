//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef _LIBCPP___CXX03___ALGORITHM_PARTITION_COPY_H
#define _LIBCPP___CXX03___ALGORITHM_PARTITION_COPY_H

#include <__cxx03/__config>
#include <__cxx03/__iterator/iterator_traits.h>
#include <__cxx03/__utility/pair.h>

#if !defined(_LIBCPP_HAS_NO_PRAGMA_SYSTEM_HEADER)
#  pragma GCC system_header
#endif

_LIBCPP_BEGIN_NAMESPACE_STD

template <class _InputIterator, class _OutputIterator1, class _OutputIterator2, class _Predicate>
_LIBCPP_HIDE_FROM_ABI pair<_OutputIterator1, _OutputIterator2> partition_copy(
    _InputIterator __first,
    _InputIterator __last,
    _OutputIterator1 __out_true,
    _OutputIterator2 __out_false,
    _Predicate __pred) {
  for (; __first != __last; ++__first) {
    if (__pred(*__first)) {
      *__out_true = *__first;
      ++__out_true;
    } else {
      *__out_false = *__first;
      ++__out_false;
    }
  }
  return pair<_OutputIterator1, _OutputIterator2>(__out_true, __out_false);
}

_LIBCPP_END_NAMESPACE_STD

#endif // _LIBCPP___CXX03___ALGORITHM_PARTITION_COPY_H
