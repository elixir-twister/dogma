use Dogma.RuleBuilder

defrule Dogma.Rule.ModuleDoc do
  @moduledoc """
  A rule which states that all modules must have documentation in the form of a
  `@moduledoc` attribute.

  This rule does run check interpreted Elixir files, i.e. those with the file
  extension `.exs`.

  This would be valid according to this rule:

      defmodule MyModule do
        @moduledoc \"\"\"
        This module is valid as it has a moduledoc!
        Ideally the documentation would be more useful though...
        \"\"\"
      end

  This would not be valid:

      defmodule MyModule do
      end

  If you do not want to document a module, explicitly do so by setting the
  attribute to `false`.

      defmodule MyModule do
        @moduledoc false
      end
  """

  @file_to_be_skipped ~r/\.exs\z/

  def test(_rule, script) do
    if Regex.match?( @file_to_be_skipped, script.path ) do
      []
    else
      script |> Script.walk( &check_ast(&1, &2) )
    end
  end

  defp check_ast({:defmodule, m, [mod, [do: module_body]]} = ast, errors) do
    if moduledoc?(module_body) do
      {ast, errors}
    else
      {ast, [error( m[:line], module_name(mod) ) | errors]}
    end
  end
  defp check_ast(ast, errors) do
    {ast, errors}
  end


  defp module_name(name) when is_atom(name) do
    inspect(name)
  end
  defp module_name({:__aliases__, _, names}) do
    if Enum.all?( names, &is_atom/1 ) do
      Enum.join(names, ".")
    else
      nil
    end
  end
  defp module_name(_) do
    nil
  end


  defp moduledoc?(ast) do
    {_, pred} = Macro.prewalk( ast, false, &moduledoc?(&1, &2) )
    pred
  end

  # moduledocs inside child modules don't count
  defp moduledoc?({:defmodule, _, _}, found_or_not) do
    {[], found_or_not}
  end

  # We've found a moduledoc
  defp moduledoc?({:@, _, [{:moduledoc, _, _} | _]}, _) do
    {[], true}
  end

  # We've already found one, so don't check further
  defp moduledoc?(_, true) do
    {[], true}
  end

  # Nothing here, keep looking
  defp moduledoc?(ast, false) do
    {ast, false}
  end

  defp error(position, nil) do
    %Error{
      rule:    __MODULE__,
      message: "Unknown module is missing a @moduledoc.",
      line:    position,
    }
  end
  defp error(position, module_name) do
    %Error{
      rule:    __MODULE__,
      message: "Module #{module_name} is missing a @moduledoc.",
      line:    position,
    }
  end
end
