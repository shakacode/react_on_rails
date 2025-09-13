# frozen_string_literal: true
# Copyright (c) 2015–2025 ShakaCode, LLC
# SPDX-License-Identifier: MIT


class HelloWorldController < ApplicationController
  layout "hello_world"

  def index
    @hello_world_props = { name: "Stranger" }
  end
end