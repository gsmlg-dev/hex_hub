defmodule E2eTestPkg do
  @moduledoc """
  Minimal test package for E2E publish testing.

  This module exists solely to provide a valid Elixir module
  for the hex.publish command to package.
  """

  @doc """
  Returns the package name.
  """
  def name, do: :e2e_test_pkg

  @doc """
  Returns the package version.
  """
  def version, do: "0.1.0"
end
