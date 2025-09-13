/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */
export default (val: string): string => {
  // Replace closing
  const re = /<\/\W*script/gi;
  return val.replace(re, '(/script');
};
