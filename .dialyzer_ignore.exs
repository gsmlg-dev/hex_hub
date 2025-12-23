[
  # Ignore pattern match warning in repositories.ex
  ~r/lib\/hex_hub\/mcp\/tools\/repositories\.ex.*pattern_match/,
  # Ignore mix task callback warning (Mix.Task behaviour not available during dialyzer)
  ~r/lib\/mix\/tasks\/test\.e2e\.ex.*callback_info_missing/,
  # Ignore mix task no_return warning (expected for task that runs tests)
  ~r/lib\/mix\/tasks\/test\.e2e\.ex.*no_return/,
  # Ignore Mix.shell/0 and ExUnit functions in mix task and test support
  # These are available at runtime but not during dialyzer analysis
  ~r/lib\/mix\/tasks\/test\.e2e\.ex.*unknown_function/,
  ~r/test\/support\/conn_case\.ex.*unknown_function/
]
